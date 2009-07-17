﻿/********************************************************************** Software License Agreement (BSD License)**  Copyright (c) 2008, University of Illinois at Urbana-Champaign*  All rights reserved.**  Redistribution and use in source and binary forms, with or without*  modification, are permitted provided that the following conditions*  are met:**   * Redistributions of source code must retain the above copyright*     notice, this list of conditions and the following disclaimer.*   * Redistributions in binary form must reproduce the above*     copyright notice, this list of conditions and the following*     disclaimer in the documentation and/or other materials provided*     with the distribution.*   * Neither the name of the University of Illinois nor the names of its*     contributors may be used to endorse or promote products derived*     from this software without specific prior written permission.**  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS*  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT*  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS*  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE*  COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,*  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,*  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;*  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER*  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT*  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN*  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE*  POSSIBILITY OF SUCH DAMAGE.*********************************************************************//***** Author: Alexander Sorokin, Department of Computer Science,*                                  University of Illinois at Urbana-Champaign.* Advised by: David Forsyth.*****/package vision{					import flash.display.*;	import fl.controls.Label;	import flash.events.MouseEvent;	import flash.events.Event;	import flash.geom.Rectangle;	import flash.text.*;	import flash.geom.*;		import vision.InputSpecsControl;	import vision.SiteHolder;	import vision.CoordinateConverter;	 	 dynamic public class TwoLevelInputToken extends BBox2InputToken 	 {   		var m_input_specs:InputSpecsControl; 		var m_parend_input_specs:InputSpecsControl ;		var savedSH;		var current_input_target;		var current_box_input;		var all_inputs_l1:Array;		var stored_task_definition; 		var stored_newRootObj; 		var stored_parentInputSpec;		var stored_bViewOnly;		var stored_rootAnnotation;				var iChildBox;		 function TwoLevelInputToken()		 {			 all_inputs_l1=new Array();					 }			function read_task(task_definition:XML,rootAnnotation:XML,newRootObj,parentInputSpec:InputSpecsControl,bViewOnly:Boolean=false):void{			m_parend_input_specs=parentInputSpec;			stored_task_definition=task_definition;			rootObj=newRootObj;			stored_parentInputSpec=parentInputSpec;			stored_bViewOnly=bViewOnly;			stored_rootAnnotation=rootAnnotation;		}				function create_input_specs(){			m_input_specs=new InputSpecsControl();			m_input_specs.read_task(stored_task_definition,stored_rootAnnotation,rootObj,stored_bViewOnly);			m_input_specs.enable_edit();			m_input_specs.visible=false;						m_input_specs.add_finish_button();			m_input_specs.addEventListener("my_input_finished", onLevel2_InputFinished);						m_parend_input_specs.parent.addChild(m_input_specs);		}		 		override function shapeADD(event:Event):void		{			if(rootObj.active_marker!=null){				rootObj.active_marker.removeEditMode();				rootObj.active_marker=null;			}						rootObj.last_object_id=rootObj.last_object_id+1;			var newShape:BBox2Input= new BBox2Input();			newShape.set_root(rootObj);			newShape.lineColor=this.all_colors[rootObj.last_object_id % all_colors.length];			newShape.x=0;//the_sites_holder.x;			newShape.y=0;//the_sites_holder.y;			var shapeLabel=m_input_btn.label+"_"+rootObj.last_object_id.toString();			newShape.label=shapeLabel;			newShape.data=shapeLabel;			newShape.bbox=null;			newShape.min_size=min_size;						rootObj.the_sites_holder.addChild(newShape);			newShape.baseImage=rootObj.the_image;			newShape.addEventListener("my_input_finished", onBox_InputFinished_l2);			newShape.detail_object=null;						current_input_target=newShape;					}						override public function enable_edit():void{			for(var iC=0;iC<all_inputs_l1.length;iC++){				all_inputs_l1[iC].enable_edit();							} 			m_input_btn.enabled=true;		}		override public function disable_edit():void{			for(var iC=0;iC<all_inputs_l1.length;iC++){				all_inputs_l1[iC].disable_edit();							} 			m_input_btn.enabled=false;		}				function alignXY(a,b){			a.x=b.x;			a.y=b.y;		}		function align(a,b){			a.x=b.x;			a.y=b.y;			a.width=b.width;			a.height=b.height;		}				function align500(a,b){			var mDim=Math.max(b.width,b.height);			var S=Math.min((b.width/500),(b.height/500));			var oX=(mDim-b.width)/2;			var oY=(mDim-b.height)/2;						a.x=b.x+oX;			a.y=b.y+oY;			a.width=a.width*S;			a.height=a.height*S;		}		function onBox_InputFinished_l2(event:Event):void		{			iChildBox=0;			current_box_input=event.currentTarget;			current_box_input.visible=false;			if(iChildBox<current_box_input.get_num_boxes()){				start_child_box();			}		}						function start_child_box():void{			create_input_specs();			m_parend_input_specs.deactivate();			m_input_specs.activate();						alignXY(m_input_specs,m_parend_input_specs);						var box=current_box_input.boxes[iChildBox];			//var box_input=event.currentTarget;						var lx,ly,lw,lh;			lx=box.x;						ly=box.y;			lw=box.width;			lh=box.height;			bX=lx;			bY=ly;			bW=lw;			bH=lh;			lx=(lx-rootObj.oX)*rootObj.ratio;			ly=(ly-rootObj.oY)*rootObj.ratio;						lw=lw*rootObj.ratio;			lh=lh*rootObj.ratio;			var box_point:Point=new Point(box.x,box.y);			var box_point2:Point=new Point(box.x+box.width,box.y+box.height);						var box_point_global = rootObj.the_sites_holder.localToGlobal(box_point);			var box_point2_global = rootObj.the_sites_holder.localToGlobal(box_point2);						var img_point_local = rootObj.the_sites_holder.getBG().globalToLocal(box_point_global);			var img_point2_local = rootObj.the_sites_holder.getBG().globalToLocal(box_point2_global);			lx=img_point_local.x;			ly=img_point_local.y;			lw=img_point2_local.x-img_point_local.x;			lh=img_point2_local.y-img_point_local.y;						var bmd2:BitmapData = new BitmapData(lw,lh, false, 0x0000CC44);			var rect:Rectangle = new Rectangle(lx,ly, lw,lh);			var pt:Point = new Point(0,0);									var p0:Point = new Point(lx,ly);			rootObj.the_sites_holder.transform			var im=rootObj.the_sites_holder.getBG();			bmd2.copyPixels(im.bitmapData, rect, pt);			var bm2:Bitmap = new Bitmap(bmd2);			lx,ly, lw,lh			var cx=bX+bW/2;			var cy=bY+bH/2;			var mSz=Math.max(bW,bH);			var virtual_square:Rectangle = new Rectangle(cx-mSz/2,cy-mSz/2, mSz,mSz);						var targetX=500;			var targetY=500;						var t2X=targetX;			var t2Y=targetY;			var oX2,oY2,ratio2;						var rW=bm2.width/t2X;			var rH=bm2.height/t2Y;			ratio2= Math.max(rW,rH);			bm2.width = bm2.width/ratio2;//the_sites_holder.width;			bm2.height = bm2.height/ratio2;//the_sites_holder.height;			oX2=(targetX-bm2.width)/2;			oY2=(targetY-bm2.height)/2;			bm2.x = oX2;			bm2.y = oY2;										this.detail_image=bm2;						var sh:SiteHolder=new SiteHolder();			//sh.the_image=bm2;						rootObj.addChild(sh);			align(sh,rootObj.the_sites_holder);			sh.width=500;			sh.height=500;			sh.setBG(this.detail_image);						savedSH=rootObj.the_sites_holder;			rootObj.the_sites_holder=sh;						current_input_target.child_sh=sh;			current_input_target.child_sh.sourceBox=virtual_square;						sh.setBG(bm2);			sh.addChild(bm2);			sh.setMode(sh.MODE_OPAQUE);			//trace("onInputFinished:"+event.toString())		}				function onLevel2_InputFinished(event:Event):void{			if(rootObj.active_marker!=null){				rootObj.active_marker.removeEditMode();				rootObj.active_marker=null;			}						finish_child_box();									iChildBox+=1;			if(iChildBox<current_box_input.get_num_boxes()){				start_child_box();			}else{				all_inputs_l1.push(current_input_target);				current_box_input.visible=true;			}		}	 			function finish_child_box():void{			rootObj.the_sites_holder=savedSH;			//this.visible=false;			m_input_specs.deactivate();			m_parend_input_specs.activate();						m_parend_input_specs.parent.removeChild(m_input_specs);						align500(current_input_target.child_sh,current_input_target.child_sh.sourceBox)						rootObj.the_sites_holder.addChild(current_input_target.child_sh);			current_input_target.child_sh.setMode(current_input_target.child_sh.MODE_TRANSPARENT);			//current_input_target.child_input_specs=m_input_specs;						var box=current_box_input.boxes[iChildBox];			box.detail_input_specs=m_input_specs;			box.detail_sh=current_input_target.child_sh;			m_input_specs.disable_edit();			rootObj.addEventListener("set_attr_text_event",box.on_set_attr_text);			box.addEventListener("my_start_edit_mode",on_child_start_edit);			box.addEventListener("my_finish_edit_mode",on_child_finish_edit);		}		var saved_box_sz:Rectangle;		var active_box;		public  function onLevel2_InputFinished_inline(event:Event):void		{			if(rootObj.active_marker!=null){				rootObj.active_marker.removeEditMode();				rootObj.active_marker=null;			}			update_child_annotations();		}		public  function on_child_start_edit(event:Event):void		{			var box=event.target;			active_box=box;			saved_box_sz = new Rectangle(box.x,box.y,box.width,box.height);			m_input_specs=event.target.detail_input_specs;						m_input_specs.visible=true;			m_parend_input_specs.visible=false;						m_parend_input_specs.parent.addChild(m_input_specs);						align(m_input_specs,m_parend_input_specs);						m_input_specs.removeEventListener("my_input_finished", onLevel2_InputFinished);			m_input_specs.addEventListener("my_input_finished", onLevel2_InputFinished_inline);			//m_input_specs.enable_edit();			m_input_specs.enable_edit_no_add_visual();						box.detail_sh.parent.addChild(box.detail_sh);			/*			rootObj.addChild(sh);			align(sh,rootObj.the_sites_holder);			sh.width=500;			sh.height=500;						savedSH=rootObj.the_sites_holder;			rootObj.the_sites_holder=sh;						current_input_target.child_sh=sh;			current_input_target.child_sh.sourceBox=virtual_square;						sh.setBG(bm2);			sh.addChild(bm2);			sh.setMode(sh.MODE_OPAQUE);			*/		}		public function on_child_finish_edit(event:Event):void		{			//rootObj.the_sites_holder=savedSH;			//this.visible=false;			m_input_specs.visible=false;			m_parend_input_specs.visible=true;						m_parend_input_specs.parent.removeChild(m_input_specs);			m_input_specs.disable_edit();			update_child_annotations();		}		public function update_child_annotations():void{			var new_box_sz = new Rectangle(active_box.x,active_box.y,active_box.width,active_box.height);			if(new_box_sz.equals(saved_box_sz))			{				return;			}									m_input_specs.update_coordinate_system(new_box_sz,saved_box_sz);			var cc=new vision.CoordinateConverter(new_box_sz,saved_box_sz);			cc.convert_container(active_box.detail_sh);				/*for(var iC=0;iC<active_box.detail_sh.numChildren;iC++)			{								var c=active_box.detail_sh.getChildAt(iC);				if( c is vision.Box2Marker2){					c.width *= sX;					c.height *= sY;				}			}*/			saved_box_sz=new_box_sz;		}		public override function get_xml_annotation():String		{			var xmlStr:String="";				//xmlStr+="<twoLevel>";			//xmlStr+="<twoLevel name='"+ m_input_btn.label +"'>";			for(var iO=0;iO<all_inputs_l1.length;iO++){				//xmlStr+="<objects>";				//xmlStr+="<box>";				xmlStr+=all_inputs_l1[iO].get_xml_annotation();				//xmlStr+="</box>";				//xmlStr+="<detail>";				//xmlStr+=all_inputs_l1[iO].child_input_specs.get_xml_annotation();				//xmlStr+="</detail>";				//xmlStr+="</objects>";							}				//xmlStr+="</twoLevel>";			return xmlStr;		}				public override function add_xml_annotation(definition:XML):void{						//current_box_input.boxes[iChildBox+1];						//var l1inputs:XMLList=definition.objects;			var o=definition;			//for each( var o in l1inputs ){				shapeADD(null);				/*var newShape:BBox2Input= new BBox2Input();				rootObj.the_sites_holder.addChild(newShape);				newShape.set_xml_annotation(o.bbox2);				newShape.setDisplayMode();								current_box_input=newShape;				rootObj.the_sites_holder.addChild(newShape);				rootObj.shapesListBox.addItem(newShape);				rootObj.all_shapes.push(newShape);								current_input_target=newShape;*/				iChildBox=0;				//current_input_target=event.currentTarget;								current_input_target.set_xml_annotation2(o);				current_input_target.setDisplayMode();				current_input_target.visible=true;				current_box_input=current_input_target;				for(iChildBox=0;iChildBox<current_input_target.boxes.length;iChildBox++)				{									start_child_box();					var b=current_input_target.boxes[iChildBox];					if(b.xml_annotation.annotation[0]!=null){											m_input_specs.read_xml_annotation(b.xml_annotation.annotation[0]);					}					finish_child_box();				//current_box_input.boxes[iChildBox+1]				}				all_inputs_l1.push(current_input_target);			//}					}						}}