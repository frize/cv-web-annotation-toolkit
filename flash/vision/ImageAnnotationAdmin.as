﻿/********************************************************************** Software License Agreement (BSD License)**  Copyright (c) 2008, University of Illinois at Urbana-Champaign*  All rights reserved.**  Redistribution and use in source and binary forms, with or without*  modification, are permitted provided that the following conditions*  are met:**   * Redistributions of source code must retain the above copyright*     notice, this list of conditions and the following disclaimer.*   * Redistributions in binary form must reproduce the above*     copyright notice, this list of conditions and the following*     disclaimer in the documentation and/or other materials provided*     with the distribution.*   * Neither the name of the University of Illinois nor the names of its*     contributors may be used to endorse or promote products derived*     from this software without specific prior written permission.**  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS*  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT*  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS*  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE*  COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,*  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,*  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;*  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER*  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT*  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN*  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE*  POSSIBILITY OF SUCH DAMAGE.*********************************************************************//***** Author: Alexander Sorokin, Department of Computer Science,*                                  University of Illinois at Urbana-Champaign.* Advised by: David Forsyth.*****/package vision{	import flash.display.*;	import fl.controls.CheckBox;	import fl.controls.List;	import fl.controls.ComboBox;	import fl.controls.Button;	import fl.data.DataProvider;	//import flash.display.Shape;	import fl.controls.Label;	import flash.events.MouseEvent;	import flash.events.Event;	import flash.xml.XMLDocument;	import flash.xml.XMLNode;	import flash.text.*;	import flash.net.*;	import flash.utils.Timer;    import flash.events.TimerEvent;    import flash.events.Event;		import vision.BBoxInputToken;	import vision.BBox2InputToken;	import vision.PolygonalDisplay;	import vision.MarkSymbol2;	import vision.TwoLevelInputToken;	import vision.ColorManager;	//import vision.CheckBox2;	import vision.BBoxInput;	import vision.Person14Joints;	import flash.xml.XMLDocument;	import vision.InputSpecsControl;	import fl.controls.List;		import ros.flash.Parameters;		dynamic public class ImageAnnotationAdmin extends MovieClip	{						var image_base="../";		var image_URL;		var task_URL;		var assignmentID:String;				var display_mode:String;				var annotationID:String="";				var the_video:String;		var the_frame:String;		var the_target_object:String;		var grid_source:String;				var save_target:String;				var the_image;		var all_sites:Array= new Array();		var all_shapes:Array= new Array();				var activeShape=void;		var active_marker=null;		var last_object_id:Number=0;				public var opMode;		var hit_id;				public var color_manager:vision.ColorManager;				var now:Date;		var loadTime;								var targetX=500;		var targetY=500;		var originalW=-1;		var originalH=-1;		var ratio;		var oX;		var oY;						var all_data_;				var saveBtn;		var save_button_visibility_stack_;				var ver_release;		var ver_major;		var ver_minor;		var version_check_failed;				var parameters_:ros.flash.Parameters;				var can_submit_:Boolean;				function ImageAnnotationAdmin() {			now= new Date();			loadTime = now.getTime();						color_manager=new vision.ColorManager();			m_detail_ctl.set_root(this);						m_detail_ctl.visible=false;							all_data_="";			display_mode="none";			save_button_visibility_stack_=new Array();			save_button_visibility_stack_.push(true);						can_submit_=true;						ver_release=0;			ver_major=1;			ver_minor=16;			version_check_failed=false;			parameters_=new ros.flash.Parameters();			var all_data_;		}		function getParameters():ros.flash.Parameters		{			return parameters_;		}				function loaded(event:Event):void		{			var content = event.target.content;					originalW=content.width;			originalH=content.height;			var rW=content.width/targetX;			var rH=content.height/targetY;			ratio= Math.max(rW,rH);			//txtShapeLabel.text= ratio;			//txtShapeLabel.visible=false;			content.width = content.width/ratio;//the_sites_holder.width;			content.height = content.height/ratio;//the_sites_holder.height;			oX=(targetX-content.width)/2;			oY=(targetY-content.height)/2;			content.x = oX;			content.y = oY;			the_image=content;					//this.the_sites_holder.bg_image=the_image;			this.the_sites_holder.setBG(the_image);			//build_regular_grid_sites();		}				public function setSaveBtn(btn):void		{			saveBtn=btn;		}		public function hideSaveBtn():void		{			//save_button_visibility_stack_.push(saveBtn.visible);			//saveBtn.visible=false;			save_button_visibility_stack_.push(can_submit_);			saveBtn.enabled=false;			can_submit_=false;		}				public function showSaveBtn():void		{			can_submit_=save_button_visibility_stack_.pop();			//saveBtn.visible=save_button_visibility_stack_.pop();			saveBtn.enabled=can_submit_;		}		public function canSubmit():Boolean		{			return can_submit_;		}				public function getAssignmentId():String		{			return assignmentID;		}										var pictLdr:Loader;					function set_background_image(image_name:String,bAddExtraHandler:Boolean=false):void		{			//image_name="file:///Users/syrnick/projects/research_uiuc/data/activity/youtube/frames/youtube_AaO1aLwk53Y/001001.jpg"			pictLdr=new Loader();						var pictURL:String = image_name;			var pictURLReq:URLRequest = new URLRequest(pictURL);			the_sites_holder.addChild(pictLdr);									if(all_shapes.length==0)			{							}						pictLdr.contentLoaderInfo.addEventListener(Event.COMPLETE, loaded);			if(bAddExtraHandler){				pictLdr.contentLoaderInfo.addEventListener(Event.COMPLETE, on_task_loaded);			}			pictLdr.load(pictURLReq);				}						function on_license_loaded(event:Event):void		{			var loader:URLLoader = URLLoader(event.target);			//trace("completeHandler: " + loader.data);			var t:String=loader.data;			var short=t.replace("http://creativecommons.org/licenses/","");			m_license_info.imageLicense.htmlText="<a href='"+loader.data+"' target='_blank'>"+short+"(more)</a>";		}				var licLoader:flash.net.URLLoader;				function load_license(url:String):void		{						licLoader=new URLLoader();									var req:URLRequest = new URLRequest(url);			licLoader.addEventListener(Event.COMPLETE, on_license_loaded);			licLoader.load(req);		}				function on_source_loaded(event:Event):void		{			var loader:URLLoader = URLLoader(event.target);			//trace("completeHandler: " + loader.data);			m_license_info.imageOrigin.text=loader.data;		}				var srcLoader:URLLoader;				function load_origin(url:String):void		{						srcLoader=new URLLoader();									var req:URLRequest = new URLRequest(url);			srcLoader.addEventListener(Event.COMPLETE, on_source_loaded);			srcLoader.load(req);		}						public function get_default_line_width():Number		{			if(this.opMode=="display" && this.display_mode=="thumbnail")			{				return 6;			}else{				return 2;			}		}										var nOutstandingTasks:Number=0;		var taskLoader:URLLoader=null;		var annotationLoader:URLLoader=null;						function on_task_loaded(event:Event):void		{			//trace("completeHandler: " + loader.data);					nOutstandingTasks=nOutstandingTasks-1;			if (nOutstandingTasks>0){				return;			}						var task_definition:XML=new XML(taskLoader.data);									var version_data=task_definition.required_version;			try{			//if(version_data)			{				var r=parseFloat(version_data[0].@release);				var major=parseFloat(version_data[0].@major);				var minor=parseFloat(version_data[0].@minor);				if(r<ver_release){					failVersionCheck();					return;				}else if(r==ver_release){					if(major>ver_major)					{						failVersionCheck();						return;					}else if(major==ver_major)					{						if(minor>ver_minor)						{							failVersionCheck();							return;						}					}				}			}			}catch(e)			{			}						try{				parameters_.add_parameters_from_xml(task_definition.parameters[0],"/taskdef/");			}catch(e){			}						if(annotationLoader != null){				var annotation:XML=new XML(annotationLoader.data);				m_input_specs.read_task_w_annotation(task_definition,task_definition,annotation.annotation[0],this);				if(opMode=="debug_edit"||opMode=="edit"){					m_input_specs.enable_edit();				}				the_sites_holder.orderElementsByVisibility();			}else{				m_input_specs.read_task(task_definition,task_definition,this);					}			m_input_specs.activate();			m_load_indicator.visible=false;		}		function failVersionCheck()		{			saveBtn.root.gotoAndStop(21);		}						function load_task(url:String):void		{			this.nOutstandingTasks=this.nOutstandingTasks+1;			taskLoader=new URLLoader();									var req:URLRequest = new URLRequest(url);			taskLoader.addEventListener(Event.COMPLETE, on_task_loaded);			taskLoader.load(req);		}								function load_annotation(task_URL:String,annotation_URL:String)		{						load_task(task_URL);						annotationLoader=new URLLoader();							var req:URLRequest = new URLRequest(annotation_URL);			annotationLoader.addEventListener(Event.COMPLETE, on_task_loaded);			annotationLoader.load(req);			}								 public function decOutstandingTasks():Number		 {			 num_outstanding=num_outstanding-1;			 return num_outstanding;		 }		 public function getOutstandingTasks():Number		 {			 return num_outstanding;		 }		 public var num_outstanding:Number;		 var hold_saved;		 public function onChildDoneSaving(event:Event):void		 {			 var NO=decOutstandingTasks();			 if(NO==0 && ~hold_saved){				var data_ready_evt:Event = new Event("my_all_data_saved");				this.dispatchEvent(data_ready_evt);			 }		 }		public function getSaveTarget():String		{			return save_target;		}				var save_timer;				public function collect_site_labels(compression):String		{			num_outstanding=1;			hold_saved=1;			var minTime=0;			var maxTime=0;			var del1=",";			var del2=";";			var idxS;			var labels="";					//m_input_specs.addEventListener("my_all_data_saved", this.onChildDoneSaving);			var results_data=m_input_specs.collect_results();						var now:Date = new Date();			var submitTime=now.getTime();			var image_xml="<image url='"+image_URL+"' />";			var task_xml="<task url='"+task_URL+"' />";			var results_xml="<results>\n"+image_xml+"\n"+results_data+"\n"+				'<meta load_time="'+this.loadTime.toString()+'" submit_time="'+submitTime.toString() +'"/></results>';						this.all_data_=results_xml;			//save_timer=new Timer(2000,1);			//save_timer.addEventListener(TimerEvent.TIMER_COMPLETE, this.onChildDoneSaving);			//save_timer.start();			//this.addChild(save_timer);						//hold_saved=0;			//if(getOutstandingTasks()==0)			//{				var data_ready_evt:Event = new Event("my_all_data_saved");				this.dispatchEvent(data_ready_evt);			//}			return results_xml;		}/*		  private function completeHandler(e:Event):void {			var data_ready_evt:Event = new Event("my_all_data_saved");			this.dispatchEvent(data_ready_evt);        }*/		public function get_all_data():String		{			return this.all_data_;		}		public function parseParameters():void		{			var keyStr:String;			var valueStr:String;			//var image_base="http://s3.amazonaws.com/visual-hits/frames/";			var target_URL;			var annotation_URL;					var data_host;			var data_unit;					var task_name;			//return;			var paramObj:Object = LoaderInfo(this.root.loaderInfo).parameters;			if("mode" in paramObj){				opMode=paramObj["mode"];									}else{				opMode="debug";			}									if ("img_base" in paramObj){				image_base=paramObj["img_base"];			}else{				image_base="http://vision-app1.cs.uiuc.edu:8080/";			}						if("task_url" in paramObj)			{				task_URL=paramObj["task_url"];			}else if("task" in paramObj){				task_name=paramObj["task"];				task_URL=image_base+"tasks/"+task_name+".xml"			}						if("image_url" in paramObj)			{				image_URL=paramObj["image_url"];			}else{				the_video=paramObj["video"];				the_frame=paramObj["frame"];				image_URL=image_base+"frames/"+the_video+"/"+the_frame+".jpg";			}						if("assignmentId" in paramObj)			{				assignmentID=paramObj["assignmentId"];							}else{				assignmentID="default";			}			if( "annotation_url" in paramObj ){				annotation_URL=paramObj["annotation_url"];			}else if( "annotationURL" in paramObj ){				annotation_URL=paramObj["annotationURL"];			}else{				annotationID=paramObj["annotationID"];				annotation_URL=image_base+"annotations/"+annotationID+".xml"			}						if ("save_target" in paramObj){				save_target=paramObj["save_target"];			}else{				save_target="sites";			}												if(opMode=="debug")			{				image_base="http://127.0.0.1:8080/";				//image_base="http://vision-app1.cs.uiuc.edu:8080/";				//image_base="http://vm7.willowgarage.com:8080/";				assignmentID="ASSIGNMENT_ID_NOT_AVAILABLEX";								the_video="VOC2008";				the_frame="2007_004538"				//the_video="prg-jun-8-L1p";				//the_frame=""				task_name="voc2008";								//the_video="LabelMe";				//the_frame="05june05_static_street_boston/p1010736"				//task_name="labelme_box";				image_URL=image_base+"frames/"+the_video+"/"+the_frame+".jpg";				//image_URL=image_base+"datastore/wnd2/VOC2008/2007_004538.jpg/1,1,500,500/";								//image_URL=image_base+"datastore/wnd2/car_subset/n02958343_10429.JPEG/1/1/640/480/"				//task_name="vehicle_material";				//task_name="willow-doors";				//task_name="willow-whiteboard";				task_URL=image_base+"tasks/"+task_name+".xml"				opMode="display"				//opMode="debug"				annotationID="demo_annotation_voc08_2";				annotation_URL=image_base+"annotations/"+annotationID+".xml"								//image_URL=image_base+"frames/prf-jul-08-L1p/dbcec01b-3498-4be9-be9f-ad121474763a.jpg"				task_URL=image_base+"tasks/test-layer-2.xml";								image_URL="http://vm7.willowgarage.com:8080/frames/bottles-p-3/1250235010.848749000.jpg"				image_URL="http://vm7.willowgarage.com:8080/frames/show-and-tell-outline/bcb90f18-3f85-447c-964f-a0a7b92ee42f-1.jpg"				task_URL="http://vm7.willowgarage.com:8080/tasks/PersonOutlineOnly.xml"				annotation_URL="http://vm7.willowgarage.com/mt/submission_data_xml/38963/bcb90f18-3f85-447c-964f-a0a7b92ee42f-1/"				//task_URL="http://vm7.willowgarage.com/tasks/example_layout.xml"				//annotation_URL="http://vm7.willowgarage.com/mt/submission_data_xml/15236/5fb1fa01-3ac8-482a-a3eb-2b35a505e98a-217/"				//task_URL=image_base+"tasks/voc2008_v2.xml";								//image_URL=image_base+"frames/prf-jul-08-L1p/f4b7f867-eb66-4a6d-8e2e-dedb96f3c0da.jpg"				//task_URL=image_base+"tasks/example_task.xml";				//task_URL=image_base+"tasks/hands-1.xml";								//annotation_URL="http://vm7.willowgarage.com:8080/mt/submission_data_xml/5913/06b36aba-42cd-4e2e-a515-497469714118-12/";							//annotation_URL="http://vm7.willowgarage.com:8080/annotations/example_annotation.xml";				//task_URL=image_base+"tasks/w-env-layer-1p.xml"				//image_URL=image_base+"frames/prf-jul-08-L1p/6d1507b7-d45f-452a-bed1-a35660afa4d7.jpg"				//annotation_URL=image_base+"mt/submission_data_xml/5966/c677848e-45ce-4c12-b79e-687ff8c3150a-38/"											}else if(opMode=="input" ){															}else if(opMode=="display"  ){																if("display_mode" in paramObj){					display_mode=paramObj["display_mode"];									}else{					display_mode="full";				}											}else if(opMode=="edit"  ){							}else if(opMode=="demo_local"){				the_video="youtube_j7GsuTqC_Sw";				the_frame="000906";				the_target_object="002";						assignmentID="XASSIGNMENT_ID_NOT_AVAILABLE";				image_base="file:///Users/syrnick/projects/research_uiuc/data/activity/youtube/"				image_URL=image_base+"frames/"+the_video+"/"+the_frame+".jpg";			}else if(opMode=="demo"){								if ("img_base" in paramObj){					image_base=paramObj["img_base"];				}else{					image_base="http://vision-app1.cs.uiuc.edu:8080/";				}								the_video=paramObj["video"];				the_frame=paramObj["frame"];				image_URL=image_base+"frames/"+the_video+"/"+the_frame+".jpg";				task_name=paramObj["task"];								//image_base="file:///Users/syrnick/projects/research_uiuc/data/activity/youtube/"				image_URL=image_base+"frames/"+the_video+"/"+the_frame+".jpg";				task_URL=image_base+"tasks/"+task_name+".xml";									assignmentID=paramObj["assignmentId"];									}else if(opMode=="demo2"){				data_host=paramObj["data_host"];				data_unit=paramObj["data_unit"];						assignmentID=paramObj["assignmentId"];				image_URL=""+data_host+""+data_unit;			}else if(opMode=="MT2" || opMode=="sandbox" || opMode=="sandbox2"){			}else if(opMode=="local_annotation"){				assignmentID="ignore" //paramObj["assignmentId"];							}else if(opMode=="AmazonMTproduction" || opMode=="AmazonMTsandbox" ){						}else if(opMode=="display2"  ){							}else{						}									//var request:URLRequest = new URLRequest(grid_source);			//var loader:URLLoader = new URLLoader();			//loader.addEventListener(Event.COMPLETE,grid_load_completeHandler);			//loader.load(request);					//for (keyStr in paramObj) {			//        valueStr = String(paramObj[keyStr]);			//}					//set_target_image(target_URL);											//markDotContainer.load_from_url_simple(image_base+"mt/hit_data/"+hit_id+"/");					//load_origin(image_base+"frames/metadata/"+the_video+".attribution");			//load_license(image_base+"frames/metadata/"+the_video+".license");					if(opMode=="display"  || opMode=="display2"  || opMode=="debug_display" ){				this.nOutstandingTasks=this.nOutstandingTasks+2;				load_annotation(task_URL,annotation_URL);				set_background_image(image_URL,true);								if(display_mode=="thumbnail")				{					the_sites_holder.x=0;					the_sites_holder.y=0;					the_sites_holder.height=this.height;					the_sites_holder.width=this.width;					m_license_info.visible=false;				}			}else if(opMode=="debug_edit" || opMode=="edit" ){				this.nOutstandingTasks=this.nOutstandingTasks+2;				load_annotation(task_URL,annotation_URL);				set_background_image(image_URL,true);			}else{				set_background_image(image_URL);				load_task(task_URL);			}		}			}}