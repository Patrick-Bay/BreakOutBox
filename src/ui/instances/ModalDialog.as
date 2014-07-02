package ui.instances {
	
	/**
	 * Handles display and functionality of a modal dialog (content-blocking).
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
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.Stage;	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import fl.controls.Button;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import swag.core.SwagDispatcher;
	import events.ModalDialogEvent;
	
	public class ModalDialog extends MovieClip {
		
		private static var _currentModel:ModalDialog = null; 
		private var _modalCover:Sprite = null;
		private var _dialogBackground:Sprite = null;
		private var _dialogDims:Rectangle = new Rectangle(0, 0, 260, 200);
		private var _selectionItems:Vector.<Object> = new Vector.<Object>();
		private var _contentHolder:MovieClip;
		private var _buttonHolder:MovieClip;
		private var _contentMask:Sprite;
		private var _promptField:TextField;
		private var _prompt:String;
		private var _innerMarginX:Number=5;
		private var _innerMarginY:Number=5;
		
		public function ModalDialog(posDims:Rectangle = null) {
			if (posDims!=null) {
				this._dialogDims = posDims;
			}//if
			this.addEventListener(Event.ADDED_TO_STAGE, this.setDefaults);
			super();			
		}
		
		public function addSelection(selectionText:String, selectionData:Object = null, buttonDims:Rectangle = null):void {
			var buttonObject:Object = new Object();
			var selectionButton:Button = new Button();
			selectionButton.label = selectionText;
			buttonObject.button = selectionButton;
			buttonObject.data = selectionData;
			buttonObject.dimensions = buttonDims;
			try {
				selectionButton["__embedData"] = selectionData;			
			} catch (err:*) {				
			}
			if (buttonDims != null) {
				selectionButton.width = buttonDims.width;
				selectionButton.height = buttonDims.height;
			}
			this._selectionItems.push(buttonObject);
		}
		
		public function removeAllSelections():void {
			for (var count:uint = 0; count < this._selectionItems.length; count++) {
				var currentButtonObj:Object = this._selectionItems[count];
				currentButtonObj.button.removeEventListener(MouseEvent.CLICK, this.onSelection);
				this._buttonHolder.removeChild(currentButtonObj.button);
			}
			this._selectionItems = null;
			this.content.removeChild(this._buttonHolder);
		}
		
		public function destroy():void {
			this.removeAllSelections();
			this.content.removeChild(this._promptField);
			this.removeChild(this._dialogBackground);
			this._modalCover.removeEventListener(MouseEvent.CLICK, this.onCoverClick);			
			this.removeChild(this._modalCover);
		}
		
		private function onSelection(eventObj:MouseEvent): void {
			var source:Button = eventObj.target as Button;
			var selectionObject:Object = this.findSelectionObject(source);
			var newEvent:ModalDialogEvent = new ModalDialogEvent(ModalDialogEvent.ONSELECT);
			newEvent.selectionButton = source;
			newEvent.selectionData = selectionObject.data;
			newEvent.selectionText = selectionObject.label;
			newEvent.selectionIndex = selectionObject.index;
			SwagDispatcher.dispatchEvent(newEvent, this);			
		}
		
		private function findSelectionObject(buttonRef:Button):Object {
			for (var count:uint = 0; count < this._selectionItems.length; count++) {
				var currentButtonObj:Object = this._selectionItems[count];
				if (currentButtonObj.button == buttonRef) {
					currentButtonObj.index = count;
					return (currentButtonObj);
				}
			}
			return (null);
		}
		
		private function renderSelections():void {		
			this._buttonHolder = new MovieClip();
			this.content.addChild(this._buttonHolder);		
			for (var count:uint = 0; count < this._selectionItems.length; count++) {
				var currentButton:Button = this._selectionItems[count].button;
				currentButton.width = 250;
				currentButton.height = 40;
				currentButton.addEventListener(MouseEvent.CLICK, this.onSelection);
				this._buttonHolder.addChild(currentButton);
			}//for
			this.positionButtons();
		}
		
		private function positionButtons():void {
			var currentX:Number = this._innerMarginX;
			var currentY:Number = this._promptField.y + this._promptField.textHeight + 5;			
			var previousButton:Button = null;
			for (var count:uint = 0; count < this._selectionItems.length; count++) {
				var currentButton:Button = this._selectionItems[count].button;	
				if (previousButton!=null) {
					currentButton.x = previousButton.x + previousButton.width + 5;
					currentButton.y = previousButton.y;				
					if (currentButton.x >= this._dialogDims.width) {
						currentButton.x = this._innerMarginX;
						currentButton.y = previousButton.y + previousButton.height + 5;
					}//if
				} else {
					currentButton.x = this._innerMarginX;
					currentButton.y = this._promptField.y+this._promptField.textHeight+10;
				}
				previousButton = currentButton;				
			}//for
		}//positionButtons
		
		private function onCoverClick(eventObj:Event):void {			
		}
		
		public function set prompt(promptSet:String):void {			
			this._prompt = promptSet;
			if (this.content == null) {				
				return;
			}			
			if (this._promptField == null) {
				this._promptField = new TextField();
				this._promptField.defaultTextFormat = new TextFormat("_sans", 11);
				this._promptField.type = TextFieldType.DYNAMIC;
				this._promptField.selectable = false;
				this._promptField.wordWrap = true;
				this._promptField.autoSize = TextFieldAutoSize.CENTER;
				this._promptField.width = this._dialogDims.width-(this._innerMarginX*2);
				this._promptField.height = this._dialogDims.height-(this._innerMarginY*2);
				this.content.addChild(this._promptField);
			}
			this._promptField.text = promptSet;			
			this._promptField.x = this._innerMarginX;
			this._promptField.y = this._innerMarginY;
		}
		
		public function get content():MovieClip {
			return (this._contentHolder);
		}
		
		private function drawDialogBackground():void {
			this._dialogBackground = new Sprite();
			this._dialogBackground.graphics.lineStyle(2, 0x000000, 1);
			this._dialogBackground.graphics.beginFill(0xFFFFFF, 1);
			this._dialogBackground.graphics.drawRoundRect(0, 0, this._dialogDims.width, this._dialogDims.height, 5, 5);
			this._dialogBackground.graphics.endFill();
			this.addChild(this._dialogBackground);
			this._dialogBackground.x = (this.stage.stageWidth / 2) - (this._dialogBackground.width / 2);
			this._dialogBackground.y = (this.stage.stageHeight / 2) - (this._dialogBackground.height / 2);			
		}
		
		private function drawContentMask():void {					
			this._contentMask = new Sprite();
			this._contentMask.graphics.lineStyle(2, 0x000000, 1);
			this._contentMask.graphics.beginFill(0xFFFFFF, 1);
			this._contentMask.graphics.drawRoundRect(0, 0, this._dialogDims.width, this._dialogDims.height, 5, 5);
			this._contentMask.graphics.endFill();
			this.addChild(this._contentMask);
			this._contentMask.x = (this.stage.stageWidth / 2) - (this._contentMask.width / 2);
			this._contentMask.y = (this.stage.stageHeight / 2) - (this._contentMask.height / 2);
		}
		
		private function createContentHolder():void {
			this._contentHolder = new MovieClip();
			this.drawContentMask();
			this._contentHolder.x = this._dialogBackground.x;
			this._contentHolder.y = this._dialogBackground.y;
			this.addChild(this._contentHolder);
			this._contentHolder.mask = this._contentMask;
			
		}
		
		private function drawModalCover():void {
			this._modalCover = new Sprite();
			this._modalCover.graphics.lineStyle(0, 0x000000, 0);
			this._modalCover.graphics.moveTo(0, 0);
			this._modalCover.graphics.beginFill(0x000000, 0.3);
			this._modalCover.graphics.lineTo(this.stage.stageWidth, 0);
			this._modalCover.graphics.lineTo(this.stage.stageWidth, this.stage.stageHeight);
			this._modalCover.graphics.lineTo(0, this.stage.stageHeight);
			this._modalCover.graphics.lineTo(0, 0);
			this._modalCover.graphics.endFill();
			//Disable sub-clicks
			this._modalCover.addEventListener(MouseEvent.CLICK, this.onCoverClick);
			this._modalCover.mouseEnabled = true;
			this._modalCover.mouseChildren = false;
			this._modalCover.useHandCursor = false;
			this.addChild(this._modalCover);
		}
		
		private function setDefaults(eventObj:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, this.setDefaults);				
			this.drawModalCover();
			this.drawDialogBackground();
			this.createContentHolder();
			this.prompt = this._prompt;
			this.renderSelections();
		}
		
	}

}