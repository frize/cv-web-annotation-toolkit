#!/usr/bin/env python
# Do this before running
#export DJANGO_SETTINGS_MODULE=web_annotations_server.settings

from django.contrib.sites.models import Site

import os,sys,time,shutil,getopt, random

from cv_models.models import *
from django.conf import settings

import session_results_VOC

def writeError(report,msg):
    fError=open(report+'.error','a')
    print >>fError,msg
    fError.close()

def writeMessage(report,msg):
    fError=open(report,'a')
    print >>fError,msg
    fError.close()    


def ensure_dir(d):
    if not os.path.exists(d):
        os.makedirs(d)

def prepare_data(m):
    model_root=m.location;
    data_root=os.path.join(model_root,'data');
    ensure_dir(data_root)

    if m.model_type==1: # PF-HOG
        done_fn=os.path.join(data_root,'done.txt');
        if not os.path.exists(done_fn):
            bFirst=True;
            for src in m.data_sources.all():
                print src
                parameters=src.source_parameters.split(' ');
                target_size=None
                optlist, args = getopt.getopt(parameters, "", ["resize="])
                for (field, val) in optlist:
                    if field == "--resize":
                        target_size=map(lambda s:int(s),val.split(','))

                print target_size
                #ds_rt=os.path.join(settings.LEARNING_DS_ROOT,str(src.id))
                ds_rt=os.path.join(settings.LEARNING_DS_ROOT,str(src.id))
                if src.source_session is not None:
                    mech = session_results_VOC.MechFetchResults(Site.objects.get_current().domain,
                                                                src.source_session.code, ds_rt,
                                                                target_size);
                    mech.fetch_results()
                    
                    ds_paths   = mech.copy_dataset_to(data_root)
                    image_sets = mech.split_files(mech.all_image_names,float(src.percent_train)/100,
                                     float(src.percent_validation)/100,
                                     float(src.percent_test)/100,src.random_seed);
                    if bFirst:
                        save_mode='w';
                        bFirst=False;
                    else:
                        save_mode='a';                        
                    mech.save_imagesets(image_sets,ds_paths['image_sets_main'],save_mode)

                else:
                    print "Unknown source"
                    return False

            local_dir=os.path.join(data_root,'local/model-%d-ds' % m.id);
            ensure_dir(local_dir)
            results_dir=os.path.join(data_root,'results/model-%d-ds' % m.id);
            ensure_dir(results_dir)
            res_main_dir=os.path.join(results_dir,'Main')
            ensure_dir(res_main_dir)
            
            fDone=open(done_fn,'w')
            print >>fDone,time.strftime('%X %x %Z')
            fDone.close();
        return True

    return False


pf_object_detector_rt='/home/sorokin2/ros/ros-pkg/sandbox/pf_object_detector'


def build_model(m):
    model_root=m.location;
    data_root=os.path.join(model_root,'data');
    ensure_dir(data_root)

    if m.model_type==1: # PF-HOG
        m.model_status=2; #Learning
        m.save();
        models_dir=os.path.join(model_root,'models');
        ensure_dir(models_dir)
        local_dir=os.path.join(data_root,'local/model-%d-ds' % m.id);
        ensure_dir(local_dir)
        results_dir=os.path.join(data_root,'results/model-%d-ds' % m.id);

        num_targets_ready=0
        for target in m.targets.all():
            target_class=target.target_code;
            model_fn=os.path.join(local_dir,'cache',target_class+"_final.mat");
            model_final_fn=os.path.join(models_dir,target_class+".mat");
            print model_final_fn
            print model_fn

            done_fn=os.path.join(model_root,'models',target_class+'.done.txt');
            if os.path.exists(done_fn):
                num_targets_ready += 1
                continue
            
            cmd="rosrun pf_object_detector run_pf_pascal.sh " + \
                 ("%s/ " % settings.MCR_ROOT)+ \
                 target_class + " " + \
                 m.model_arguments + " " + \
                 "%s/  " % data_root + \
                 "0 0"
            print cmd
            sts=os.system(cmd)

            if not os.path.exists(model_fn):
                return False

            shutil.copy(model_fn,model_final_fn);
            
            fDone=open(done_fn,'w')
            print >>fDone,time.strftime('%X %x %Z')
            fDone.close();

            num_targets_ready += 1

        if num_targets_ready == m.targets.count():
            m.model_status=201; #Learning complete
            m.save()


def test_model(m):
    model_root=m.location;
    data_root=os.path.join(model_root,'data');
    ensure_dir(data_root)

    if m.model_type==1: # PF-HOG
        #m.model_status=3; #Testing 
        #m.save();
        
        models_dir=os.path.join(model_root,'models');
        ensure_dir(models_dir)
        local_dir=os.path.join(data_root,'local/model-%d-ds' % m.id);
        ensure_dir(local_dir)
        results_dir=os.path.join(data_root,'results/model-%d-ds' % m.id);

        num_targets_ready=0
        for target in m.targets.all():
            target_class=target.target_code;
            model_fn=os.path.join(local_dir,'cache',target_class+"_final.mat");
            model_final_fn=os.path.join(models_dir,target_class+".mat");
            print model_final_fn
            print model_fn

            done_fn=os.path.join(model_root,'models',target_class+'.test.done.txt');
            if os.path.exists(done_fn):
                num_targets_ready += 1
                continue
            
            cmd="rosrun pf_object_detector run_pf_pascal.sh " + \
                 ("%s/ " % settings.MCR_ROOT)+ \
                 target_class + " " + \
                 m.model_arguments + " " + \
                 "%s/  " % data_root + \
                 "1 1"
            print cmd
            sts=os.system(cmd)

            #if not os.path.exists(model_fn):
            #    return False

            #shutil.copy(model_fn,model_final_fn);
            
            fDone=open(done_fn,'w')
            print >>fDone,time.strftime('%X %x %Z')
            fDone.close();
            num_targets_ready += 1

        if num_targets_ready == m.targets.count():
            m.model_status=301; #Learning complete
            m.save()
        
        
def run_training():
    allmodels=LearnedModel.objects.filter(model_status__in=[2,3]);
    for m in allmodels:
        if m.model_status == 2: #"learning"
            action="train"
        elif m.model_status == 3: #"testing"
            action="test"
        else:
            action="?"

            
        if action=="train":
            isOK=prepare_data(m)
            if not isOK:
                continue
            
            isOK=build_model(m)
            if not isOK:
                continue

        if action=="test":
            isOK=test_model(m)
            if not isOK:
                continue
            


def run_training_cycle():
    while True:
        #try:
        run_training();
        #except:
        print "Mysterious error while running all training"            
        time.sleep(5)
        print time.localtime()

if __name__=="__main__":
	run_training_cycle();
