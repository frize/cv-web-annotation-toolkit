#!/usr/bin/env python
# Do this before running
#export DJANGO_SETTINGS_MODULE=web_annotations_server.settings


import os,sys,time
from evaluation.models import *
from django.conf import settings

VOCdevkit=settings.VOC_DEV_KIT
MCRroot=settings.MCR_ROOT


def writeError(report,msg):
    fError=open(report+'.error','a')
    print >>fError,msg
    fError.close()

def writeMessage(report,msg):
    fError=open(report,'a')
    print >>fError,msg
    fError.close()    

def run_evaluation():
	submissions=Submission.objects.filter(state=2);
	for s in submissions:
            try:
		print s.id,s.title
		
	        submission_rt=os.path.join(s.to_challenge.data_root,'submissions/%d/' % s.id);
		submission_input_rt=os.path.join(submission_rt,'input');
		work_root=os.path.join(submission_input_rt,'results');

		report=os.path.join(submission_rt,'report.txt' );
			
		challenges_file=os.path.join(submission_input_rt,'challenges.txt')
		if not os.path.exists(challenges_file):
			msg="Missing challenges.txt. Most likely the submission is old. Please resubmit results. "
			writeError(report,msg)
			writeMessage(report,msg)
			s.state=4;
			s.save();
			continue

		hasError=False
		challenges = open(challenges_file,'r').readlines();
		scores_report_filename=os.path.join(submission_rt,'report.txt.score');
		final_scores_report_filename=os.path.join(submission_rt,'report.txt.final_score');
		scores_file=open(scores_report_filename,'w');
		all_scores=[];
		for c in ['5']: #challenges:
			c=int(c.strip())
			print c
			if c == 0:
				continue

			if c == 1  or c == 2:
				iComp=1;
				jComp=c;

			if c == 3  or c == 4:
				iComp=3;
				jComp=c;

			if c == 5  or c == 6:
				iComp=5;
				jComp=c;

			if c == 7  or c == 8:
				iComp=7;
				jComp=c;				
				
			report_filename=os.path.join(submission_rt,'comp%d_report.txt' % jComp);

			cmd=(("%s/run_eval_comp%d.sh " % (VOCdevkit,iComp))+ \
			     ("%s/ " % MCRroot)+ \
			     "/home/sorokin2/voc_data/VOCdevkit " + \
			     work_root+"/ " + \
			     report_filename + (" comp%d"% jComp) + \
			     (" | tee %s.log" % report_filename))
			print cmd
			if os.system(cmd):
				msg="Error while evaluating challenge %d." % jComp
				writeError(report,msg)
				writeMessage(report,msg)
				hasError=True
				break
			if os.path.exists(report_filename+'.error'):
				msg="Error while evaluating challenge %d." % jComp
				writeError(report,msg)
				writeMessage(report,msg)
				hasError=True
				break

			try:				
				if iComp==1 or iComp==3:
					f_results=open(report_filename + '.score','r');
					for score_str in f_results.readlines():
						(score,category)=score_str.strip().split(' ');
					print >>scores_file,"%s\tcomp%d.%s" % (score,jComp,category)
					f_results.close()
			except:
				msg="Failed to get evaluation results by category for challenge %d." % jComp
				writeError(report,msg)
				writeMessage(report,msg)
				hasError=True

				
			try:
				f_results_final=open(report_filename + '.final_score','r');
				score=f_results_final.readlines()[0].strip();
				f_results_final.close()
				all_scores.append(float(score));
				print >>scores_file,"%s\tcomp%d" % (score,jComp)
			except:
				msg="Error while evaluating challenge %d. Results were not generated properly." % jComp
				writeError(report,msg)
				writeMessage(report,msg)
				hasError=True
				
		scores_file.close()
		
		if len(all_scores)==0:
			msg="Error while submission. No scores were generated."
			writeError(report,msg)
			writeMessage(report,msg)
			hasError=True
		else:	
			final_score=sum(all_scores)/len(all_scores)
			final_scores_file=open(final_scores_report_filename,'w');			
			print >>final_scores_file,final_score
			final_scores_file.close()

		if hasError:
			s.state=4;
			s.save();
		else:
			s.score=str(final_score);
			s.state=3;
			s.save();
            except:
                print "Mysterious error"
                s.state=4;
                s.save();

def run_evaluation_cycle():
    while True:
        try:
            run_evaluation();
        except:
            print "Mysterious error while running all evaluations"            
        time.sleep(5)
        print time.localtime()

if __name__=="__main__":
	run_evaluation_cycle();
