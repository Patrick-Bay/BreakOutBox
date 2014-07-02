package ui.instances {
	
	import flash.display.Bitmap;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import swag.effects.SwagColour;
	
	/**
	 * A simple dynamic icon button with some mouse effects.
	 * 
	 * Copyright (c) 2014 Patrick Bay
	 * 
	 * Permission is hereby granted, free of charge, to any person obtaining a copy
	 * of this software and associated documentation files (the "Software"), to deal
	 * in the Software without restriction, including without limitation the rights
	 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	 * copies of the Software, and to permit persons to whom the Software is
	 * furnished to do so, subject to the following conditions:
	 *
	 * The above copyright notice and this permission notice shall be included in
	 * all copies or substantial portions of the Software.
	 * 
	 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	 * THE SOFTWARE.
	 * 
	 * @author Patrick Bay
	 */
	public class IconButton extends MovieClip {
		
		private var _buttonImage:Bitmap;
		private var _launchID:String = "";
		private var _originalDims:Rectangle;
		private var _clickOffset:Point=new Point()
		private var _pressed:Boolean = false;
		private var _over:Boolean = false;
		
		public var scaleOnClick:Number = 0.95;		
		public var hoverOutline:SwagColour = new SwagColour(0x0A0A0A);
		public var hoverOutlineSize:Number = 3;
		public var hoverTint:SwagColour = new SwagColour(0xA0A0A0);
		public var hoverTintIntensity:Number = 0.5;
		
		private static var _buttons:Vector.<IconButton> = new Vector.<IconButton>();
		
		public function IconButton(iconObj:Object) {
			this._buttonImage = iconObj.icon;
			this._launchID = iconObj.name;
			_buttons.push(this);		
			this.addEventListener(Event.ADDED_TO_STAGE, this.setDefaults);
		}
		
		public function get id():String {
			return (this._launchID);
		}
		
		public function get previousButton():IconButton {
			var previousButton:IconButton = null;
			for (var count:uint = 0; count < _buttons.length; count++) {
				var currentButton:IconButton = _buttons[count];
				if (currentButton == this) {
					return (previousButton);
				}
				previousButton = currentButton;				
			}
			return (null);
		}
		
		public function get nextButton():IconButton {
			var previousButton:IconButton = null;
			for (var count:uint = 0; count < _buttons.length; count++) {
				var currentButton:IconButton = _buttons[count];
				if (previousButton == this) {
					return (currentButton);
				}
				previousButton = currentButton;				
			}
			return (null);
		}		
		
		private function onMouseMotion(eventObj:MouseEvent):void {	
			if (this.isTarget(eventObj)) {
				if (!this._over) {
					this.onRollOver(eventObj);
				}
			} else {
				if (this._over) {
					this.onRollOut(eventObj);
				}
			}
		}
		
		private function onRollOver(eventObj:MouseEvent):void {			
			this._over = true;
			this.setOverState();
		//	var eventObj:MouseEvent = new MouseEvent(MouseEvent.MOUSE_OVER);
		//	this.dispatchEvent(eventObj);
		}
		
		private function onRollOut(eventObj:MouseEvent):void {				
			this._over = false;
			if (!this._pressed) {
				this.setNormalState();
			}
		//	var eventObj:MouseEvent = new MouseEvent(MouseEvent.MOUSE_OUT);
		//	this.dispatchEvent(eventObj);
		}
		
		private function onPress(eventObj:MouseEvent):void {			
			if (!this._over) {
				return;
			}
			this._pressed = true;			
			var xOffs:Number = (this.width - (this.width * this.scaleOnClick))/2;
			var yOffs:Number = (this.height - (this.height * this.scaleOnClick))/2;
			this._clickOffset = new Point(xOffs, yOffs);
			this.width *= this.scaleOnClick;
			this.height *= this.scaleOnClick;
			this.x += xOffs;
			this.y += yOffs;					
		//	var eventObj:MouseEvent = new MouseEvent(MouseEvent.MOUSE_DOWN);
		//	this.dispatchEvent(eventObj);
		}
		
		private function onRelease(eventObj:MouseEvent):void {		
			if (!this._pressed) {
				return;
			}
			this._pressed = false;
			this.width = this._originalDims.width;
			this.height = this._originalDims.height;
			this.x -= this._clickOffset.x;
			this.y -= this._clickOffset.y;
			if (!this._over) {
				this.onRollOut(eventObj);
			}//if
		//	var eventObj:MouseEvent = new MouseEvent(MouseEvent.MOUSE_UP);
		//	this.dispatchEvent(eventObj);
			eventObj = new MouseEvent(MouseEvent.CLICK);
			this.dispatchEvent(eventObj);
		}
		
		public function setOverState(... args):void {			
			var glowFilter:GlowFilter = new GlowFilter(this.hoverOutline.RGB, 1, this.hoverOutlineSize, this.hoverOutlineSize, 22, 3, false, false);
			this.hoverTint.applyTint(this._buttonImage, this.hoverTintIntensity);
			this.filters = [glowFilter];
		}
		
		public function setNormalState(... args):void {
			this.filters = [];
			this.hoverTint.removeTint(this._buttonImage);
			this.width = this._originalDims.width;
			this.height = this._originalDims.height;
		}
		
		private function isTarget(eventObj:MouseEvent):Boolean {			
			return (this.hitTestPoint(eventObj.stageX, eventObj.stageY, true));
		}
		
		private function setDefaults(eventObj:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, this.setDefaults);
			this.addChild(this._buttonImage);
			this._buttonImage.smoothing = true;
			//Let parent list handle UI for now...
			return;
			this._originalDims = new Rectangle(0, 0, this.width, this.height);
			this.stage.addEventListener(MouseEvent.MOUSE_MOVE, this.onMouseMotion);			
			this.stage.addEventListener(MouseEvent.MOUSE_DOWN, this.onPress);
			this.stage.addEventListener(MouseEvent.MOUSE_UP, this.onRelease);
			this.stage.addEventListener(MouseEvent.RELEASE_OUTSIDE, this.onRelease);			
			this.buttonMode = true;
			this.useHandCursor = true;
		}
		
	}

}