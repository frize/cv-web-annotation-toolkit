﻿/********************************************************************** Software License Agreement (BSD License)**  Copyright (c) 2008, University of Illinois at Urbana-Champaign*  All rights reserved.**  Redistribution and use in source and binary forms, with or without*  modification, are permitted provided that the following conditions*  are met:**   * Redistributions of source code must retain the above copyright*     notice, this list of conditions and the following disclaimer.*   * Redistributions in binary form must reproduce the above*     copyright notice, this list of conditions and the following*     disclaimer in the documentation and/or other materials provided*     with the distribution.*   * Neither the name of the University of Illinois nor the names of its*     contributors may be used to endorse or promote products derived*     from this software without specific prior written permission.**  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS*  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT*  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS*  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE*  COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,*  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,*  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;*  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER*  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT*  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN*  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE*  POSSIBILITY OF SUCH DAMAGE.*********************************************************************//***** Author: Alexander Sorokin, Department of Computer Science,*                                  University of Illinois at Urbana-Champaign.* Advised by: David Forsyth.*****/package vision{	import flash.display.*;	import fl.controls.CheckBox;	import flash.text.TextField;	import fl.controls.List;	import fl.controls.ComboBox;	import fl.controls.Button;	import fl.data.DataProvider;	//import flash.display.Shape;	import fl.controls.Label;	import flash.events.MouseEvent;	import flash.events.KeyboardEvent;	import flash.events.Event;	import flash.xml.XMLDocument;	import flash.xml.XMLNode;	import flash.text.*;	import flash.geom.Rectangle;		import vision.BBoxInputToken;	import vision.BBox2InputToken;	import vision.GraphInputToken;	import vision.PolygonalDisplay;	import vision.MarkSymbol2;	import vision.TwoLevelInputToken;	//import vision.CheckBox2;	dynamic public class InputSpecsControl extends MovieClip	{		var presence_targets:Array;		var option_targets:Array;		var bbox_targets:Array;		var polygon_targets:Array;		var segment_targets:Array;		var all_controls:Array;		var all_controls_by_name:Array;				var offsetY;		var offsetX;		var offsetX_key;		var rootObj;				var finishBtn:Button;		var key_mapping;				function InputSpecsControl() {						key_mapping=['q','w','e','r','t','a','s','d','f','g','z','x','c','v'];			presence_targets=new Array();			option_targets=new Array();			bbox_targets=new Array();			polygon_targets=new Array();			segment_targets=new Array();						all_controls=new Array();						all_controls_by_name=new Array();						finishBtn=null;			m_cb.visible=false;		}				public function activate():void		{			stage.addEventListener(KeyboardEvent.KEY_DOWN, reportKeyDown);			this.visible=true;		}				public function deactivate():void		{			stage.removeEventListener(KeyboardEvent.KEY_DOWN, reportKeyDown);			this.visible=false;		}				public function reportKeyDown(event:KeyboardEvent):void		{			var code:String=String.fromCharCode(event.charCode);			for(var i=0;i<key_mapping.length;i++)			{				if(code==key_mapping[i])				{					activate_target_by_idx(i);					break;				}			}			if(event.charCode==13)			{				onFinish(null);			}		}						public function activate_target_by_idx(idx:int):void		{			if(idx>all_controls.length)				return;							var ctl=all_controls[idx];			if(ctl is CheckBox)			{				ctl.selected=!ctl.selected;			}else if (ctl is ComboBox)			{				var cb:ComboBox=ComboBox(ctl);				if(cb.selectedIndex==-1){					cb.selectedIndex=0;				}else if(cb.selectedIndex<cb.length-1)				{					cb.selectedIndex+=1;				}else				{					cb.selectedIndex=0;				}				}else if(ctl is PolygonInputToken)			{				ctl.shapeADD(null);			}			else if(ctl is TwoLevelInputToken)			{				ctl.shapeADD(null);			}			else if(ctl is BBox2InputToken)			{				ctl.shapeADD(null);			}			else if(ctl is GraphInputToken)			{				ctl.shapeADD(null);			}		}				///////////////////// Interface setup ////////////////////////				public function get_input_control_by_name(name:String,objType:String="bbox"):Object{			if( name in  all_controls_by_name){				return all_controls_by_name[name];			}else if( objType=="bbox" && ("object" in all_controls_by_name)){				return all_controls_by_name["object"];			}else if( objType=="polygon" && ("object polygon" in all_controls_by_name)){				return all_controls_by_name["object polygon"];			}else{				return null;			}		}		public function read_task(task_definition:XML,rootAnnotation:XML,newRootObj,bViewOnly:Boolean=false):void{			//var c:XMLNode;			this.rootObj=newRootObj;						var targets:XMLList=task_definition.targets.target;			setup_lists2(bViewOnly,rootAnnotation,targets);		}		function add_key_lbl(num:int):void		{			if(num<key_mapping.length)			{			var l:Label=new Label();			l.text="("+key_mapping[num-1]+")";			l.x=offsetX_key;			l.y=offsetY;			this.addChild(l);			}		}						function setup_lists2(bViewOnly:Boolean,rootAnnotation:XML,targets:XMLList):void		{ 			offsetY=5;			offsetX=20;			offsetX_key=0;			var HBox=32;			var width_full=200;			var offsetX_full=5;							for each(var c in targets){				var o = c;				var annotation=c.annotation;				var ref=null;				try{					ref=annotation.@ref;										if(ref.length()==0){						ref=null;					}				}catch(e){				}				if(ref!=null){					annotation=rootAnnotation.annotation.(@id=ref);				}				if(annotation.@type=="presence"){					var ctl:CheckBox=new CheckBox();					if(bViewOnly){						ctl.enabled=false;					}					ctl.width=160;					//ctl.name=o.@name;										//ctl.data=o.@name;					ctl.label=o.@name;										ctl.x=offsetX;					ctl.y=offsetY;					presence_targets.push(new Array(c,ctl,-1));					ctl.addEventListener(Event.CHANGE, this.record_checkbox_time);					add_key_lbl(all_controls.length+1);					this.addChild(ctl);										//offsetY+=ctl.height;					offsetY += HBox;					all_controls.push(ctl);					all_controls_by_name[o.@name]=ctl;				}else if(annotation.@type=="select"){					var cb:ComboBox=new ComboBox();					//this.addChild(cb);										cb.editable=false;					if(bViewOnly){						cb.enabled=false;					}					//cb.setSize(200, 22);		 	        cb.width=160;					//var o = oA[0];					cb.prompt = "Choose "+o.@name;					for each(var opt in o.annotation.option){						cb.addItem( { label: o.@name + ":" + opt.@name, data :[o.@name,opt.@name]} );					}					//ctl.name=o.@name;										//ctl.label=o.@name;					cb.x=offsetX;					cb.y=offsetY;					//cb.addEventListener(Event.CHANGE, this.record_checkbox_time);					add_key_lbl(all_controls.length+1);					this.addChild(cb);					//offsetY+=cb.height;					offsetY+=HBox;					all_controls.push(cb);					all_controls_by_name[o.@name]=cb;										option_targets.push(new Array(c,cb,-1));				}else if((annotation.@type=="bbox") || (annotation.@type=="bbox2")|| (annotation.@type=="2level")){					if(annotation.@type=="bbox"){						var ctlBox:BBoxInputToken=new BBoxInputToken();						if(bViewOnly){							ctlBox.m_input_btn.enabled=false;						}						//ctl.name=o.@name;						ctlBox.set_name(o.@name);						ctlBox.set_root(this.rootObj);						o.ctl=ctlBox;						ctlBox.x=offsetX;						ctlBox.y=offsetY;						add_key_lbl(all_controls.length+1);						this.addChild(ctlBox);						offsetY+=HBox;					}else if(annotation.@type=="bbox2"){						var ctlBox2:BBox2InputToken=new BBox2InputToken();						if(bViewOnly){							ctlBox2.m_input_btn.enabled=false;						}						//ctl.name=o.@name;						ctlBox2.set_name(o.@name);						ctlBox2.set_root(this.rootObj);						try{							ctlBox2.min_size=parseInt(o.annotation.@min_size);						}finally{						}						o.ctl=ctlBox2;						ctlBox2.x=offsetX;						ctlBox2.y=offsetY;						add_key_lbl(all_controls.length+1);						this.addChild(ctlBox2);						offsetY+=HBox;												all_controls.push(ctlBox2);						all_controls_by_name[o.@name]=ctlBox2;						//offsetY+=ctlBox.height;									}else if(annotation.@type=="2level"){						var ctlTwoLvl:TwoLevelInputToken=new TwoLevelInputToken();						if(bViewOnly){							ctlTwoLvl.m_input_btn.enabled=false;						}						//ctl.name=o.@name;						ctlTwoLvl.set_name(o.@name);						ctlTwoLvl.set_root(this.rootObj);						try{							ctlTwoLvl.min_size=parseInt(annotation.@min_size);						}catch(e){						}						o.ctl=ctlTwoLvl;												ctlTwoLvl.x=offsetX;						ctlTwoLvl.y=offsetY;						add_key_lbl(all_controls.length+1);						this.addChild(ctlTwoLvl);						all_controls.push(ctlTwoLvl);						all_controls_by_name[o.@name]=ctlTwoLvl;												ctlTwoLvl.read_task(annotation.level2[0],rootAnnotation,this.rootObj,this,bViewOnly)						offsetY+=HBox;					}				}else if(annotation.@type=="outline"){					var ctlBoxPoly:PolygonInputToken=new PolygonInputToken();					if(bViewOnly){						ctlBoxPoly.m_input_btn.enabled=false;					}										//ctl.name=o.@name;					ctlBoxPoly.set_name(o.@name);					ctlBoxPoly.set_root(this.rootObj);					o.ctl=ctlBoxPoly;					ctlBoxPoly.x=offsetX;					ctlBoxPoly.y=offsetY;					add_key_lbl(all_controls.length+1);					this.addChild(ctlBoxPoly);					//offsetY+=ctlBox.height;					offsetY+=HBox;					all_controls.push(ctlBoxPoly);					all_controls_by_name[o.@name]=ctlBoxPoly;										polygon_targets.push(c);														}else if(annotation.@type=="outline_text"){					var ctlBoxTextLabeledPoly:TextLabeledPolygonInputToken=new TextLabeledPolygonInputToken();					if(bViewOnly){						ctlBoxTextLabeledPoly.m_input_btn.enabled=false;					}										//ctl.name=o.@name;					ctlBoxTextLabeledPoly.set_name(o.@name);					ctlBoxTextLabeledPoly.set_root(this.rootObj);					o.ctl=ctlBoxTextLabeledPoly;					ctlBoxTextLabeledPoly.x=offsetX;					ctlBoxTextLabeledPoly.y=offsetY;					add_key_lbl(all_controls.length+1);					this.addChild(ctlBoxTextLabeledPoly);					//offsetY+=ctlBox.height;					offsetY+=HBox;					all_controls.push(ctlBoxTextLabeledPoly);					all_controls_by_name[o.@name]=ctlBoxTextLabeledPoly;					all_controls_by_name["OUTLINE_TEXT"]=ctlBoxTextLabeledPoly;										polygon_targets.push(c);														}else if(annotation.@type=="graph"){					var ctlBoxGraph:GraphInputToken=new GraphInputToken();					if(bViewOnly){						ctlBoxGraph.m_input_btn.enabled=false;					}										//ctl.name=o.@name;					ctlBoxGraph.set_name(o.@name);					ctlBoxGraph.set_root(this.rootObj);					o.ctl=ctlBoxGraph;					ctlBoxGraph.x=offsetX;					ctlBoxGraph.y=offsetY;					add_key_lbl(all_controls.length+1);					this.addChild(ctlBoxGraph);					ctlBoxGraph.set_xml_config(o.annotation[0]);					//offsetY+=ctlBox.height;					offsetY+=HBox;					all_controls.push(ctlBoxGraph);					all_controls_by_name[o.@name]=ctlBoxGraph;																								}else if(annotation.@type=="segmentation"){					var ctlSegment:SegmentationInputToken=new SegmentationInputToken();					if(bViewOnly){							ctlSegment.m_input_btn.enabled=false;					}					//ctl.name=o.@name;					ctlSegment.set_name(o.@name);					ctlSegment.set_root(this.rootObj);					c.ctl=ctlSegment;					ctlSegment.x=offsetX;					ctlSegment.y=offsetY;					add_key_lbl(all_controls.length+1);					this.addChild(ctlSegment);					//offsetY+=ctlBox.height;					offsetY+=HBox;					all_controls.push(ctlSegment);					all_controls_by_name[c.@name]=ctlSegment;					segment_targets.push(c);				}else if(annotation.@type=="instructions"){					var ctlTxt:TextField=new TextField();					//ctl.name=o.@name;										//ctl.data=o.@name;										ctlTxt.x=offsetX_full;					ctlTxt.y=offsetY;					this.addChild(ctlTxt);					ctlTxt.multiline=true;										var str_instructions=annotation.html.toXMLString();					ctlTxt.htmlText=str_instructions.replace("&amp;","&");					//ctlTxt.htmlText="<html>abcdasdas<br/><b>Welcome</b><img src='http://vision-app1.cs.uiuc.edu:8080/frames/bottles-p-3/1250235010.848749000.jpg' width='30' height='30'/></html>"					//offsetY+=ctl.height;					ctlTxt.width=215;					if(annotation.@height)					{						var h=int(annotation.@height);						offsetY += h;						ctlTxt.height = h;					}else{						offsetY += HBox;					}				}else{					trace('Unknown');				}			}									}								///////////////////// Annotation Serialization ////////////////////////						public function read_task_w_annotation(task_definition:XML,task_definition_root:XML,annotations:XML,newRootObj):void{			//var c:XMLNode;			read_task(task_definition,task_definition_root,newRootObj,true);						read_xml_annotation(annotations);		}				public function read_xml_annotation(annotation:XML):void{			var binary_decisions:Array=new Array();			var o;			var attributes:XMLList=annotation.attribute;			for each(var a in attributes){				binary_decisions[a.@name]=parseInt(a.@value);							}						for each(var oA in presence_targets){					var ctl:CheckBox=oA[1];					var o = oA[0];					ctl.selected=binary_decisions[o.@name];					oA[2]=o.@ct;								}			var bboxes:XMLList=annotation.bbox;			for each( o in bboxes){				var n=o.@name;				var tgtControl=get_input_control_by_name(o.@name);				if(tgtControl!=null){					tgtControl.add_xml_annotation(o);				}			}			var bboxes2:XMLList=annotation.bbox2;			for each( o in bboxes2){				var bbox2Input:BBox2Input=new BBox2Input();				bbox2Input.set_root(rootObj);				bbox2Input.set_xml_annotation(o);								bbox2Input.setDisplayMode();				rootObj.the_sites_holder.addChild(bbox2Input);			}						var polygons:XMLList=annotation.polygon;			for each( o in polygons){								var tgtControl=get_input_control_by_name(o.@name);				if(tgtControl!=null){					tgtControl.add_xml_annotation(o);									}else{					tgtControl=get_input_control_by_name("OUTLINE_TEXT");					if(tgtControl!=null){						tgtControl.add_xml_annotation(o);					}				}			}			var graphs:XMLList=annotation.graph;			for each( o in graphs){								var tgtControl=get_input_control_by_name(o.@name);				if(tgtControl!=null){					tgtControl.add_xml_annotation(o);									}			}						var segmentations:XMLList=annotation.segmentation;			for each( o in segmentations ){				var seg_input:SegmentationInput=new SegmentationInput();				var sh=rootObj.the_sites_holder;				var bgim=sh.getBG();								seg_input.set_background_image_inline(bgim);				seg_input.load_segmentation(o.@url);				seg_input.setDisplayMode();				rootObj.the_sites_holder.addChildAt(seg_input,2);			}						var selects:XMLList=annotation.select;			for each( o in selects){				var tgtControl=get_input_control_by_name(o.@name);				var selCtl:ComboBox=ComboBox(tgtControl);				var dt=selCtl.dataProvider;				var idx=-1;				for (var i=0;i<dt.length;i++){					var di=dt.getItemAt(i);					if(di.data[1]==o.@value){						idx=i;						break;					}				}				if(idx>-1){					selCtl.selectedIndex=idx;				}			}		}		public function get_summary_text():String		{			var summary:String="";									for each(var oS:Object in all_controls){				if (oS is CheckBox)				{					var chkBox:CheckBox=CheckBox(oS);					if(chkBox.selected){						if(summary.length>0)							summary+=","						summary+=chkBox.label;					}				}else if (oS is ComboBox)				{					var cb:ComboBox=ComboBox(oS);					var ct = 0;										var sel_name=null;					var sel_value=null;					if(cb.selectedIndex!=-1){						var itm=cb.selectedItem;						sel_name=itm.data[0];						sel_value=itm.data[1];					}					if(summary.length>0)						summary+=","					summary+=sel_name+":"+sel_value;				}			}			return summary;		}						 public function decOutstandingTasks():Number		 {			 num_outstanding=num_outstanding-1;			 return num_outstanding;		 }		 public var num_outstanding:Number;		 var hold_saved;		 public function onChildDoneSaving(event:Event):void		 {			 var NO=decOutstandingTasks();			 if(NO==0 && ~hold_saved){				var data_ready_evt:Event = new Event("my_all_data_saved");				this.dispatchEvent(data_ready_evt);			 }		 }		 		 public function get_xml_annotation():String		{			return collect_results();		}		public function collect_results():String		{			var xmlStr:String="";			num_outstanding=0;			hold_saved=1;						for each(var oS:Object in all_controls){				if (oS is BBoxInput)				{					var bboxInput:BBoxInput=BBoxInput(oS);					xmlStr+=bboxInput.get_xml_annotation() ;						}else if (oS is BBox2InputToken)				{					var bbox2Input:BBox2InputToken=BBox2InputToken(oS);					xmlStr+=bbox2Input.get_xml_annotation() ;						}else if (oS is SegmentationInputToken){					var segInput:SegmentationInputToken=SegmentationInputToken(oS);					num_outstanding=num_outstanding+1;					segInput.addEventListener("my_all_data_saved",this.onChildDoneSaving);					xmlStr+=segInput.get_xml_annotation();				}else if(oS is TextLabeledPolygonInputToken)				{					var outlineInput:TextLabeledPolygonInputToken=TextLabeledPolygonInputToken(oS);					xmlStr+=outlineInput.get_xml_annotation() ;						}else if(oS is PolygonInputToken)				{					var outlineInput2:PolygonInputToken=PolygonInputToken(oS);					xmlStr+=outlineInput2.get_xml_annotation() ;						}else if(oS is GraphInputToken)				{					var graphInput:GraphInputToken=GraphInputToken(oS);					xmlStr+=graphInput.get_xml_annotation() ;						}else if (oS is TwoLevelInputToken)				{					var twoLvl:TwoLevelInputToken=TwoLevelInputToken(oS);					xmlStr+=twoLvl.get_xml_annotation() ;						}else if (oS is CheckBox)				{					var chkBox:CheckBox=CheckBox(oS);					var ct = 0;					var v=0;					if(chkBox.selected)						v=1;					xmlStr+='<attribute name="'+chkBox.label+'" value="'+v+'" ct="'+ct+'"/>\n';				}else if (oS is ComboBox)				{					var cb:ComboBox=ComboBox(oS);					var ct = 0;										var sel_name=null;					var sel_value=null;					if(cb.selectedIndex!=-1){						var itm=cb.selectedItem;						sel_name=itm.data[0];						sel_value=itm.data[1];					}					if(sel_name!=null){						xmlStr+='<select name="'+sel_name+'" value="'+sel_value+'" ct="'+ct+'"/>\n';					}				}else if (oS is TwoLevelInputToken)				{					var twoLvl:TwoLevelInputToken=TwoLevelInputToken(oS);					xmlStr+=twoLvl.get_xml_annotation() ;						}			}			var w=rootObj.originalW;			var h=rootObj.originalH;			var size_str="<size><width>"+w+"</width><height>"+h+"</height></size>\n";			//var frame_str="<frame_id>parent_box</frame_id>\n";			hold_saved=0;			if(num_outstanding==0)			{				var data_ready_evt:Event = new Event("my_all_data_saved");				this.dispatchEvent(data_ready_evt);			}			return "<annotation>\n"+size_str+xmlStr+"</annotation>\n";		}												///////////////////// Edit support ////////////////////////		function add_finish_button():void{			finishBtn=new Button()			finishBtn.label="finish";			this.addChild(finishBtn);			finishBtn.y=this.height-finishBtn.height;			finishBtn.x=(this.width-finishBtn.width)/2;						finishBtn.addEventListener(MouseEvent.CLICK,onFinish);		}		function onFinish(event:Event):void{			var done_event:Event = new Event("my_input_finished");    		this.dispatchEvent(done_event);				}		public function enable_edit():void{			for each(var oS:Object in all_controls){				if (oS is BBoxInput)				{					var bboxInput:BBoxInput=BBoxInput(oS);											}else if (oS is TwoLevelInputToken)				{					var twoLvl:TwoLevelInputToken=TwoLevelInputToken(oS);					twoLvl.enable_edit();									}else if (oS is BBox2InputToken)				{					var bbox2Input:BBox2InputToken=BBox2InputToken(oS);					bbox2Input.enable_edit();								}else if (oS is SegmentationInputToken){					var segInput:SegmentationInputToken=SegmentationInputToken(oS);					segInput.enable_edit();									}else if(oS is PolygonInputToken)				{					var outlineInput:PolygonInputToken=PolygonInputToken(oS);					outlineInput.enable_edit();				}else if(oS is GraphInputToken)				{					var graphInput:GraphInputToken=GraphInputToken(oS);					graphInput.enable_edit();								}else if (oS is CheckBox)				{					var chkBox:CheckBox=CheckBox(oS);					chkBox.enabled=true;				}else if (oS is ComboBox)				{					var cb:ComboBox=ComboBox(oS);					cb.enabled=true;								}			}		}		public function enable_edit_no_add_visual():void{			for each(var oS:Object in all_controls){				if (oS is BBoxInput)				{					var bboxInput:BBoxInput=BBoxInput(oS);											}else if (oS is TwoLevelInputToken)				{					var twoLvl:TwoLevelInputToken=TwoLevelInputToken(oS);					//twoLvl.enable_edit();									}else if (oS is BBox2InputToken)				{					var bbox2Input:BBox2InputToken=BBox2InputToken(oS);					//bbox2Input.enable_edit();								}else if (oS is SegmentationInputToken){					var segInput:SegmentationInputToken=SegmentationInputToken(oS);					//segInput.enable_edit();									}else if(oS is PolygonInputToken)				{					var outlineInput:PolygonInputToken=PolygonInputToken(oS);					//outlineInput.enable_edit();								}else if (oS is CheckBox)				{					var chkBox:CheckBox=CheckBox(oS);					chkBox.enabled=true;				}else if (oS is ComboBox)				{					var cb:ComboBox=ComboBox(oS);					cb.enabled=true;								}			}					}				public function update_coordinate_system(newCoords:flash.geom.Rectangle,oldCoords:flash.geom.Rectangle):void		{			for each(var oS:Object in all_controls){				if (oS is BBoxInput)				{					//var bboxInput:BBoxInput=BBoxInput(oS);					//bboxInput.update_coordinate_system(newCoords:Rectangle,oldCoords:Rectangle)											}else if (oS is TwoLevelInputToken)				{					var twoLvl:TwoLevelInputToken=TwoLevelInputToken(oS);					//twoLvl.enable_edit();					//twoLvl.update_coordinate_system(newCoords,oldCoords);									}else if (oS is BBox2InputToken)				{					var bbox2Input:BBox2InputToken=BBox2InputToken(oS);					bbox2Input.update_coordinate_system(newCoords,oldCoords);								}else if (oS is SegmentationInputToken){					var segInput:SegmentationInputToken=SegmentationInputToken(oS);					//segInput.update_coordinate_system(newCoords,oldCoords);					//segInput.enable_edit();									}else if(oS is PolygonInputToken)				{					var outlineInput:PolygonInputToken=PolygonInputToken(oS);					//outlineInput.update_coordinate_system(newCoords,oldCoords);					//outlineInput.enable_edit();								}else if (oS is CheckBox)				{					var chkBox:CheckBox=CheckBox(oS);					chkBox.enabled=true;				}else if (oS is ComboBox)				{					var cb:ComboBox=ComboBox(oS);					cb.enabled=true;								}			}									}		public function disable_edit():void{			for each(var oS:Object in all_controls){				if (oS is BBoxInput)				{					var bboxInput:BBoxInput=BBoxInput(oS);				}else if (oS is TwoLevelInputToken)				{					var twoLvl:TwoLevelInputToken=TwoLevelInputToken(oS);												twoLvl.disable_edit();									}else if (oS is BBox2InputToken)				{					var bbox2Input:BBox2InputToken=BBox2InputToken(oS);					bbox2Input.disable_edit();								}else if (oS is SegmentationInputToken){					var segInput:SegmentationInputToken=SegmentationInputToken(oS);					segInput.disable_edit();									}else if(oS is PolygonInputToken)				{					var outlineInput:PolygonInputToken=PolygonInputToken(oS);					outlineInput.disable_edit();								}else if(oS is GraphInputToken)				{					var graphInput:GraphInputToken=GraphInputToken(oS);					graphInput.disable_edit();													}else if (oS is CheckBox)				{					var chkBox:CheckBox=CheckBox(oS);					chkBox.enabled=false;				}else if (oS is ComboBox)				{					var cb:ComboBox=ComboBox(oS);					cb.enabled=false;									}else if (oS is TwoLevelInputToken)				{					var twoLvl:TwoLevelInputToken=TwoLevelInputToken(oS);				}			}					}				function record_checkbox_time(event:Event):void {			var now:Date=new Date();				var click_time=now.getTime();			for each(var oA in presence_targets){				if(oA[1]==event.target){					oA[2]=click_time;					break;				}			}		}	}}