#***********************************************************
#* Software License Agreement (BSD License)
#*
#*  Copyright (c) 2008, Willow Garage, Inc.
#*  All rights reserved.
#*
#*  Redistribution and use in source and binary forms, with or without
#*  modification, are permitted provided that the following conditions
#*  are met:
#*
#*   * Redistributions of source code must retain the above copyright
#*     notice, this list of conditions and the following disclaimer.
#*   * Redistributions in binary form must reproduce the above
#*     copyright notice, this list of conditions and the following
#*     disclaimer in the documentation and/or other materials provided
#*     with the distribution.
#*   * Neither the name of the Willow Garage nor the names of its
#*     contributors may be used to endorse or promote products derived
#*     from this software without specific prior written permission.
#*
#*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#*  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#*  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
#*  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
#*  COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
#*  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
#*  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#*  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
#*  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
#*  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
#*  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#*  POSSIBILITY OF SUCH DAMAGE.
#***********************************************************

import numpy
import datetime
from decimal import Decimal

from django.http import HttpResponse,HttpResponseRedirect
from django.shortcuts import render_to_response,get_object_or_404 
from django.views.generic.list_detail import object_list

from models import *
from common import *

import ros_integration


def advance_next_check_time(training_progress):
    """Compute, when the next validation item will be shown"""
    if training_progress.next_check>=0 and training_progress.next_check < training_progress.num_normal_submissions:
        return

    position=numpy.random.poisson(training_progress.gold_qual.random_check_frequency)
    if training_progress.next_check == -1: #unset
        training_progress.next_check = position;
    else:
        training_progress.next_check += position;
    training_progress.save()

def pick_workitem_from_queue(request,session,worker):
    if not session.use_task_priority:
        return None

    print "PICK FROM QUEUE"
    queue_name=session.priority_queue;
    last_priority=request.session.get('last_task_priority_'+queue_name,-1)
    last_id=request.session.get('last_task_id_'+queue_name,-1);
    restart_countdown=request.session.get('restart_countdown_'+queue_name,settings.QUEUE_RESTART_FREQUENCY);
    if restart_countdown<=0:
        last_priority=100000;
        last_id=0;
        queue=WorkPriorityQueueItem.objects.filter(queue=queue_name)
        restart_countdown=settings.QUEUE_RESTART_FREQUENCY;
    else:
        queue=WorkPriorityQueueItem.objects.filter(queue=queue_name,priority__lte=last_priority)
        restart_countdown -=1;

    new_work_item=None
    for item in queue:
        if item.priority==last_priority and item.id<=last_id:
            continue
        try:
            if item.assignments_left==0:
                continue

            c = SubmittedTask.objects.filter(hit=item.work,worker=worker).count()
            if c>0:
                continue

            item.assignments_left -= 1;
            item.save();
        except:
            continue

        new_work_item=item.work
        request.session['last_task_priority_'+queue_name]=item.priority;
        request.session['last_task_id_'+queue_name]=item.id;
        request.session['restart_countdown_'+queue_name]=restart_countdown;
        break

    return new_work_item



def select_workitem_from_gold(session,worker):
    """Pick the gold workitem if necessary. There are two reasons to pick a gold item: 
        * The worker hasn't done minimum required gold items
        * It's time to show the random sampled work item
    """

    gold_workitem=None
    if session.gold_standard_qualification is None:
        print "No gold standard qualification"
        return None

    gold_qual = session.gold_standard_qualification

    (training_progress,created)=WorkerTrainingProgress.objects.get_or_create(worker=worker,gold_qual=gold_qual);
    if created:
        advance_next_check_time(training_progress);
        training_progress.save();

    if training_progress.num_gold_submissions < gold_qual.num_gold_initial:
        print "Picking initial tasks"
        return pick_random_workitem_for_worker(gold_qual.gold_session,worker)
    else:
        if training_progress.next_check <= training_progress.num_normal_submissions:
            advance_next_check_time(training_progress);
            return pick_random_workitem_for_worker(gold_qual.gold_session,worker)

    return None

def pick_random_workitem_for_worker(gold_session,worker):
    return select_new_gold_workitem(gold_session.id,worker.worker);


def substitute_workitem(worker,task,gold_workitem):
    ttl=datetime.datetime.now()+datetime.timedelta(seconds=2*gold_workitem.session.task_def.duration)
    item_sub=ItemSubstitution(worker=worker,requested_item=task,shown_item=gold_workitem,expires=ttl,state=1);
    item_sub.save();

def finalize_item_substitution(workitem,worker):
    item_substitutions=ItemSubstitution.objects.filter(worker=worker,shown_item=workitem,state=1);
    if len(item_substitutions)==0:
        return 
    item_sub=item_substitutions[0];
    item_sub.state=2;
    item_sub.save();

def grade_submission_with_gold(gold_session,submission,worker):
    te=gold_session.task_def.type.get_engine();
    submission_grade = te.grade(submission,gold_session);
    rcd=GoldStandardGradeRecord(gold_session=gold_session,worker=worker,workitem=submission.hit,submission=submission,grade=str(submission_grade));
    rcd.save();

    qual=GoldStandardQualification.objects.get(gold_session=gold_session);

    (training_progress,created)=WorkerTrainingProgress.objects.get_or_create(worker=worker,gold_qual=qual);
    if created:
        advance_next_check_time(training_progress);

    training_progress.num_gold_submissions += Decimal("1.0")
    training_progress.grade_total += Decimal(str(submission_grade))
    training_progress.grade_average = training_progress.grade_total / training_progress.num_gold_submissions

    if qual.passing_submission_grade<=submission_grade:
        training_progress.num_passing_submissions += 1

    training_progress.save();

def re_grade_submission_with_gold(gold_session,old_submission,worker):
    raise NotImplemented()

def check_worker_performance(worker,session):
    try:
        if not settings.MTURK_BLOCK_WORKERS_ON_GOLD:
            return (True,None)
    except Exception:
        pass

    qual=session.gold_standard_qualification
    (training_progress,created)=WorkerTrainingProgress.objects.get_or_create(worker=worker,gold_qual=qual);
    if created:
        return (True,None)

    if training_progress.num_gold_submissions<qual.min_gold_to_block:
        return (True,None)
    if training_progress.grade_average>=qual.min_gpa:
        return (True,None)

    report="Required GPA is %f, your GPA is %f." % (qual.min_gpa,training_progress.grade_average)
    return (False,report)


def check_submission_for_progress(session,submisison,worker):
    qual=session.gold_standard_qualification
    if qual is None:
        return

    (training_progress,created)=WorkerTrainingProgress.objects.get_or_create(worker=worker,gold_qual=qual);
    if created:
        advance_next_check_time(training_progress);

    training_progress.num_normal_submissions += 1
    training_progress.save();

def get_task_page(request,session_code):
    session = get_object_or_404(Session,code=session_code)

    task_id=None
    try:
        if 'ExtID' in request.REQUEST:
            task_id=request.REQUEST['ExtID']
        else:
            task_id=request.REQUEST['extid']
    except:
        if 'extid' in request.REQUEST:
            task_id=request.REQUEST['extid']

    workitem = get_object_or_404(MTHit,ext_hitid=task_id)

    if "workerId" in request.REQUEST:
        worker_id=request.REQUEST["workerId"]
        print worker_id
        (worker,created)=Worker.objects.get_or_create(session=None,worker=worker_id)
        if created:
            worker.save();
        if worker.utility<settings.MTURK_BLOCK_WORKER_MIN_UTILITY:
            return render_to_response('mturk/not_available.html');

        exclusions=check_session_exclusions(worker,session);
        if len(exclusions)>0:
            reasons="";
            for e in exclusions:
                reasons += e[1];
                break;
            return render_to_response('mturk/not_available_excluded.html',{'reason':reasons} );
    else:
        worker=None

    if workitem is None:
    	return render_to_response('mturk/not_available.html');

    #See, if we need to use the gold task
    if worker:
        if session.gold_standard_qualification is not None:
            (can_work,report) = check_worker_performance(worker,session)
            if not can_work:
                return render_to_response('mturk/not_available_low_performance.html',{"report":report});

        gold_workitem=select_workitem_from_gold(session,worker);
        if gold_workitem:
            substitute_workitem(worker,workitem,gold_workitem);
            workitem=gold_workitem;
        else:
            priority_work_item=pick_workitem_from_queue(request,session,worker);
            if priority_work_item:
                substitute_workitem(worker,workitem,priority_work_item);
                workitem=priority_work_item;

    te=workitem.session.task_def.type.get_engine();
    url=te.get_task_page_url(workitem,request);

    for k,v in request.GET.items():	
        if k=='ExtID' or k=='extid':
            v=workitem.ext_hitid
        url=url+"&"+k+"="+v

    if worker:
        url+="&feedback_url=/mt/gpa/%s/%s/" % (session.code,worker.worker);

    final_url=url;
    return HttpResponseRedirect(final_url)	






def submit_result(request):

    try:
        task_id=""
        if 'ExtID' in request.REQUEST:
            task_id=request.REQUEST['ExtID']
        if task_id=="" and 'extid' in request.REQUEST:
            task_id=request.REQUEST['extid']
    except:
        if 'extid' in request.REQUEST:
            task_id=request.REQUEST['extid']
    print request.POST
    workitem = get_object_or_404(MTHit,ext_hitid=task_id)

    #The HIT can belong to some other session
    session = workitem.session;
    session_code=session.code;

    workerId=request.REQUEST['workerId'];
    if workerId=="":
        workerId=request.user.username;
    assignmentId=request.REQUEST['assignmentId'];

    postS=pickler.dumps((request.GET,request.POST))    
    submission=SubmittedTask(hit=workitem,session_id=session.id,worker=workerId,assignment_id=assignmentId, response=postS);
    submission.save();


    if 'hitId' in request.REQUEST:
        mturk_hit_id=request.REQUEST['hitId']
        try:
            mthit=MechTurkHit.object.get(mechturk_hit_id=mturk_hit_id);
        except:
            mthit=None;
        if mthit:
            mthit.state=2; #Review
            mthit.save();

    session.task_def.type.get_engine().on_submit(submission);

    #num_possibly_valid_submissions=SubmittedTask.objects.filter(hit=workitem,valid=True).count();
    #if num_possibly_valid_submissions>=workitem.get_num_required_submissions():
    workitem.state=2; #Submitted
    workitem.save()

    print "ROS ON SUBMISSION"
    ros_integration.on_submission(submission)

    (worker,created)=Worker.objects.get_or_create(session=None,worker=workerId)
    if created:
        worker.save();
        
    print "GOLD?",session.is_gold,session.code

    if session.is_gold:
        print "GOLD"
        finalize_item_substitution(workitem,worker)
        grade_submission_with_gold(session,submission,worker)
    else:
        check_submission_for_progress(session,submission,worker)
            

    if session.standalone_mode:
        return HttpResponseRedirect("/mt/get_task/"+session.code+"/" );

    if session.sandbox:
	submit_target="http://workersandbox.mturk.com/mturk/externalSubmit"
    else:
	submit_target="http://www.mturk.com/mturk/externalSubmit"
	
    return render_to_response('mturk/after_submit.html',
	{'submit_target':submit_target,
  	'extid': workitem.ext_hitid, 'workerId':workerId,
	'assignmentId':assignmentId   });


def get_submission_data_xml(request,id=None,ext_hitid=None):
    submission = get_object_or_404(SubmittedTask,id=int(id))
	
    str_response=submission.get_xml_str();

    return HttpResponse(str_response,mimetype="text/xml");

def view_submission_page(request,ext_hitid,id):
    submission = get_object_or_404(SubmittedTask,id=int(id))
    if submission.hit.ext_hitid != ext_hitid:
        raise Http404();

    view_url=submission.get_view_url();
    return HttpResponseRedirect(view_url);


def view_gold_for_workitem(request,ext_hitid):
    workitem = get_object_or_404(MTHit,ext_hitid=ext_hitid)
    gold_submissions=SubmittedTask.objects.filter(goldsubmission__workitem=workitem)
    session = workitem.session
    protocol=session.task_def.type.name

    extra_context={'nav':{'session':session} } #,'can_edit':can_edit}
    return object_list(request,queryset=gold_submissions,template_name='protocols/'+protocol+'/show_worker_list.html',extra_context=extra_context);




def respond_in_format(data,format):
    if format==1: #XML
        return HttpResponse(data,mimetype="text/xml");
    elif format==2: #JSON
        resp=HttpResponse();
        resp['X-JSON']=data;
        return resp
    elif format==3: #plain
        return HttpResponse(data,mimetype="text/plain");

def get_task_parameters(request,task_name):
    task = get_object_or_404(Task,name=task_name)
    data=task.interface_xml
    return respond_in_format(data,task.session.task_def.type.data_format)

def send_hit_parameters(request,ext_id):
    hit = get_object_or_404(MTHit,ext_hitid=ext_id)
    return respond_in_format(hit.parameters,hit.session.task_def.type.data_format)
    """
    if hit.parameters.startswith("<?xml"):
        return HttpResponse(hit.parameters,mimetype="text/xml");
    else:
        return HttpResponse(hit.parameters,mimetype="text/plain");
    """

def get_submission_data(request,id=None,ext_hitid=None,format_override=None):
    submission = get_object_or_404(SubmittedTask,id=int(id))
    str_response=submission.get_xml_str();	 # This isn't really XML;
    if format_override is not None:
        return respond_in_format(str_response,int(format_override))
    else:
        return respond_in_format(str_response,submission.session.task_def.type.data_format)



def show_worker_gpa(request,session_code,worker_id):
    session = get_object_or_404(Session,code=session_code)

    qual=session.gold_standard_qualification
    if qual is None:
        return render_to_response('mturk/gpa/inline_blank.html')

    (worker,worker_created)=Worker.objects.get_or_create(session=None,worker=worker_id)
    if worker_created:
        return render_to_response('mturk/gpa/inline_blank.html')

    (progress,progress_created)=WorkerTrainingProgress.objects.get_or_create(worker=worker,gold_qual=qual);
    if progress_created:
        return render_to_response('mturk/gpa/inline_blank.html')

    try:
        last_grade=GoldStandardGradeRecord.objects.filter(gold_session=qual.gold_session, worker=worker).order_by('-id')[0];
    except IndexError:
        last_grade=None

    return render_to_response('mturk/gpa/inline_worker_gpa.html',{'progress':progress,'last_grade':last_grade,'qualification':qual})



def edit_submission(request,submission_id,worker):
    submission=get_object_or_404(SubmittedTask,id=submission_id,worker=worker)
    
    submit_url="/mt/edit/submission/submit/%s/%s/" % (submission_id,worker);
    edit_url=submission.get_edit_url(submit_url)
    
    return HttpResponseRedirect(edit_url);

def submit_edit_submission(request,submission_id,worker):
    print "SUBMIT RESULTS"
    old_submission=get_object_or_404(SubmittedTask,id=submission_id,worker=worker)
    workitem = old_submission.hit;

    session = workitem.session;
    assignmentId="INTERNAL"

    postS=pickler.dumps((request.GET,request.POST))    
    submission=SubmittedTask(hit=workitem,session_id=session.id,worker=worker,assignment_id=assignmentId, response=postS);
    submission.revision=old_submission.revision+1;
    submission.state=old_submission.state;
    submission.approval_state=old_submission.approval_state;
    submission.save();
    
    session.task_def.type.get_engine().on_deactivate(old_submission);
    old_submission.valid=0;
    old_submission.revision_state=2;
    old_submission.save();

    session.task_def.type.get_engine().on_submit(submission);

    ros_integration.on_submission(submission)

    (worker,created)=Worker.objects.get_or_create(session=None,worker=worker)
    if created:
        worker.save();
        
    if session.is_gold:
        re_grade_submission_with_gold(session,old_submission,submission,worker)

    return render_to_response('mturk/edit_complete.html')

def show_session_submissions_base(request,session_code,worker_id,state_is=None):
    return HttpResponseRedirect("p1/");
    
def show_session_submissions(request,session_code,worker_id,page,state_is=None):
    worker = get_object_or_404(Worker,session=None,worker=worker_id)
    session = get_object_or_404(Session,code=session_code)
    can_edit=1

    protocol=session.task_def.type.name

    #Only results from this worker and only active (i.e. unrevised results)
    results=session.submittedtask_set.all().filter(worker=worker_id).filter(revision_state=1) 
    if state_is:
        results=results.filter(state=state_is)

    extra_context={'nav':{'session':session},'can_edit':can_edit}
    return object_list(request,queryset=results,paginate_by=10,page=page,template_name='protocols/'+protocol+'/show_worker_list.html',extra_context=extra_context);


def show_gold_graded_submissions_base(request,grading_record_id,worker_id):
    return HttpResponseRedirect("p1/");
    
def show_gold_graded_submissions(request,grading_record_id,worker_id,page):
    worker = get_object_or_404(Worker,session=None,worker=worker_id)

    worker_training_info=get_object_or_404(WorkerTrainingProgress,id=grading_record_id,worker=worker)
    session = worker_training_info.gold_qual.gold_session

    can_edit=0

    protocol=session.task_def.type.name

    #Only results from this worker and only active (i.e. unrevised results)
    results=session.submittedtask_set.all().filter(worker=worker_id).filter(revision_state=1) 
    extra_context={'nav':{'session':session},'can_edit':can_edit}
    return object_list(request,queryset=results,paginate_by=10,page=page,template_name='protocols/'+protocol+'/show_gold_graded_worker_list.html',extra_context=extra_context);


def show_all_comments(request):
    comments=[]
    for s in SubmittedTask.objects.all().order_by('-submitted'):
        comment=s.get_comments()
        if comment=="":
            continue
        comments.append({"when":s.submitted,"comment":comment})

    return render_to_response('mturk/comments.html',{'comments':comments})



def show_session_comments(request,session_code):
    session = get_object_or_404(Session,code=session_code)
    comments=[]
    for s in session.submittedtask_set.all().order_by('-submitted'):
        comment=s.get_comments()
        if comment=="":
            continue
        comments.append((s.submitted,comment))

    nav={'session':session} 
    return render_to_response('mturk/comments.html',{'comments':comments,'nav':nav})

