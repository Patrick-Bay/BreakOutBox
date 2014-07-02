package ui.instances  {
		
	import events.FileFinderEvent;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	import References;
	import Settings;
	import Assets;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFieldType;
	import flash.text.TextFieldAutoSize;
	import flash.display.MovieClip;
	import flash.filesystem.File;
	import flash.events.FileListEvent;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import FileFinder;	
	import ui.instances.ModalDialog;
	import swag.core.SwagDispatcher;
	import events.ModalDialogEvent;
	import flash.net.FileFilter;
		
	/**
	 * Handles the display and functionality of a file path edit field. Handles
	 * both automatic file finding and manual file finding.
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
	public class PathEditField extends MovieClip {
		
		private var _currentPath:File = null;
		private var _savedPath:File = null;
		private var _fileName:String = null;
		private var _pathField:TextField = null;
		private var _fieldIcon:Bitmap = null;
		private var _browserDefData:XML = null;
		private var _clickArea:Sprite = null;
		private var _editActive:Boolean = false;
		private var _searchActive:Boolean = false;
		private var _finder:FileFinder = null;
		
		public function PathEditField(initialPath:*=null, fileName:String=null, browserDefinitionData:XML=null) {
			this.path = initialPath;
			this._fileName = fileName;
			this._browserDefData = browserDefinitionData;
			this.addEventListener(Event.ADDED_TO_STAGE, this.setDefaults);
			super();			
		}
		
		public function updatePathString():void {			
			if (this._pathField == null) {
				return;
			}//if
			this.updateFieldIcon();
			if (this._currentPath!=null) {
				this._pathField.text = this._currentPath.nativePath;
			} else {
				this._pathField.text = "Click here to set location of program file \"" + this._fileName + "\".";
			}
			this._pathField.y = this._fieldIcon.y + (this._fieldIcon.height / 2) - (this._pathField.height / 2);
			this._pathField.x = this._fieldIcon.x + this._fieldIcon.width + 10;	
			this.updateClickArea();
		}
		
		public function updateFieldIcon():void {
			if (this._fieldIcon != null) {
				this.removeChild(this._fieldIcon);
				this._fieldIcon = null;
			}//if
			if (this._editActive) {
				this._fieldIcon = Assets.closedEditFolderIcon;
				this.addChild(this._fieldIcon);	
				this._fieldIcon.x += 5;
			} else {
				if (this._currentPath!=null) {
					this._fieldIcon = Assets.openGreenFolderIcon;
					this.addChild(this._fieldIcon);
					this._fieldIcon.x += 5;
				} else {
					this._fieldIcon = Assets.closedAlertFolderIcon;
					this.addChild(this._fieldIcon);
				}
			}//else
		}
		
		public function set path(pathSet:*):void {
			if ((pathSet == null) || (pathSet == "")) {
				return;
			}
			if (pathSet is File) {
				this._currentPath = pathSet;
			}//if
			if (pathSet is String) {
				this._currentPath = FileFinder.resolveToFile(pathSet);
			}//if
			this.updatePathString();
		}//set path
		
		public function get path():File {
			return (this._currentPath);
		}//get path
		
		private function browseForExecutable():void {
			this._currentPath = File.desktopDirectory;
			var filterArray:Array = new Array();
			filterArray.push(new FileFilter("Executable", "*.exe"));
			this._currentPath.addEventListener(Event.SELECT, this.onSelectExecPath);
			this._currentPath.addEventListener(Event.CANCEL, this.onSelectCancel);
			this._currentPath.browseForOpen("Find location of \"" + this._fileName + "\"", filterArray);			
		}
		
		public function onSearchProgress(eventObj:FileFinderEvent):void {
			this._currentPath = eventObj.currentSearchItem;
			this._searchActive = true;
			this.updatePathString();
		}
		
		public function onSearchComplete(eventObj:FileFinderEvent):void {
			this._currentPath = eventObj.currentSearchDir;
			this._searchActive = false;
			this._editActive = false;			
			this.updatePathString();
			this.clearSearchListeners();
			var pathNode:XML = this._browserDefData.child("path")[0] as XML;
			var exeNode:XML = this._browserDefData.child("executable")[0] as XML;
			var pathParts:Array = eventObj.currentSearchItem.nativePath.split("\\");
			var exeName:String = pathParts[pathParts.length - 1];
			var pathData:XML = new XML("<![CDATA[" + eventObj.currentSearchDir.nativePath + "]]>");			
			pathNode.setChildren(pathData);			
			Settings.saveSettings();
			var modalDialog:ModalDialog = new ModalDialog(new Rectangle(0, 0, 260, 130));				
			modalDialog.prompt = "File \""+exeName+"\" found at: \n"+eventObj.currentSearchDir.nativePath;
			var buttonDimensions:Rectangle = new Rectangle(0, 0, 260, 40);
			modalDialog.addSelection("OKAY", { action:"okay" });				
			SwagDispatcher.addEventListener(ModalDialogEvent.ONSELECT, this.onConfirmSelect, this, modalDialog);
			this.stage.addChild(modalDialog);
		}
		
		public function onConfirmSelect(eventObj:ModalDialogEvent):void {
			SwagDispatcher.removeEventListener(ModalDialogEvent.ONSELECT, this.onConfirmSelect, eventObj.source);
			eventObj.source.destroy();
			this.stage.removeChild(eventObj.source);
		}
		
		public function onSearchFail(eventObj:FileFinderEvent):void {
			this._currentPath = null;
			this._searchActive = false;
			this._editActive = false;
			this.updateFieldIcon();
			this.updatePathString();			
			this.clearSearchListeners();
			var modalDialog:ModalDialog = new ModalDialog(new Rectangle(0, 0, 260, 130));				
			modalDialog.prompt = "Search for \""+this._fileName+"\" found no results.";
			var buttonDimensions:Rectangle = new Rectangle(0, 0, 260, 40);
			modalDialog.addSelection("OKAY", { action:"okay" });				
			SwagDispatcher.addEventListener(ModalDialogEvent.ONSELECT, this.onConfirmSelect, this, modalDialog);
			this.stage.addChild(modalDialog);
			modalDialog.y += 14;
			modalDialog.x += 1;				
		}
		
		private function clearSearchListeners():void {
			SwagDispatcher.removeEventListener(FileFinderEvent.ONPROGRESS, this.onSearchProgress, this._finder);
			SwagDispatcher.removeEventListener(FileFinderEvent.ONFOUND, this.onSearchProgress, this._finder);
			SwagDispatcher.removeEventListener(FileFinderEvent.ONNOTFOUND, this.onSearchProgress, this._finder);
		}
		
		private function createSearchListeners():void {
			SwagDispatcher.addEventListener(FileFinderEvent.ONPROGRESS, this.onSearchProgress, this, this._finder);
			SwagDispatcher.addEventListener(FileFinderEvent.ONFOUND, this.onSearchComplete, this, this._finder);
			SwagDispatcher.addEventListener(FileFinderEvent.ONNOTFOUND, this.onSearchFail, this, this._finder);
		}
		
		private function searchForExecutable():void {
			this._savedPath=this._currentPath;
			this._finder = new FileFinder("\\", this._fileName);
			this.createSearchListeners();
			this._searchActive = true;
			this._finder.findFile();
		}
		
		private function onSelectCancel(eventObj:Event):void {			
			this._editActive = false;
			this.updateFieldIcon();			
			this._currentPath.removeEventListener(Event.SELECT, this.onSelectExecPath);
			this._currentPath.removeEventListener(Event.CANCEL, this.onSelectCancel);
		}
		
		private function onSelectExecPath(eventObj:Event):void {			
			this._currentPath.removeEventListener(Event.SELECT, this.onSelectExecPath);
			this._currentPath.removeEventListener(Event.CANCEL, this.onSelectCancel);
			this._editActive = false;			
			this.updatePathString();
			this.updateFieldIcon();
			var pathNode:XML = this._browserDefData.child("path")[0] as XML;
			var pathData:XML = new XML("<![CDATA[" + this._currentPath.nativePath + "]]>");
			pathNode.setChildren(pathData);
			Settings.saveSettings();
		}
			
		
		private function cancelSearch():void {			
			this.clearSearchListeners();
			this._finder.cancelFind();			
			this._finder = null;
			this._currentPath = this._savedPath;
			this._searchActive = false;
			this._editActive = false;
			this.updateFieldIcon();
			this.updatePathString();
		}
		
		public function onSearchCancelSelect(eventObj:ModalDialogEvent):void {			
			SwagDispatcher.removeEventListener(ModalDialogEvent.ONSELECT, this.onSearchCancelSelect, eventObj.source);
			switch (eventObj.selectionData.action) {
				case "yes": 
					this.cancelSearch();
					break;
				case "no": 					
					break;				
				default: 
					this._editActive = false;
					this.updateFieldIcon();	
					break;
			}
			eventObj.source.destroy();
			this.stage.removeChild(eventObj.source);
		}
		
		public function onPathEditTypeSelect(eventObj:ModalDialogEvent):void {			
			SwagDispatcher.removeEventListener(ModalDialogEvent.ONSELECT, this.onPathEditTypeSelect, eventObj.source);
			switch (eventObj.selectionData.action) {
				case "manualsearch": 
					this.browseForExecutable();
					break;
				case "autosearch": 
					this.searchForExecutable();
					break;
				case "cancel": 
					this._editActive = false;
					this.updateFieldIcon();	
					break;
				default: 
					this._editActive = false;
					this.updateFieldIcon();	
					break;
			}
			eventObj.source.destroy();
			this.stage.removeChild(eventObj.source);
		}
		
		private function onClick(MouseEvent:Event):void {
			if (this._searchActive) {
				var modalDialog:ModalDialog = new ModalDialog(new Rectangle(0, 0, 260, 130));	
				//Currently these must be set BEFORE adding dialog to stage. Maybe update in future version?
				modalDialog.prompt = "Cancel current search for \""+this._fileName+"\"?";
				var buttonDimensions:Rectangle = new Rectangle(0, 0, 260, 40);
				modalDialog.addSelection("YES", { action:"yes" }, buttonDimensions);
				modalDialog.addSelection("NO", { action:"no" }, buttonDimensions);				
				SwagDispatcher.addEventListener(ModalDialogEvent.ONSELECT, this.onSearchCancelSelect, this, modalDialog);
				this.stage.addChild(modalDialog);
				modalDialog.y += 14;
				modalDialog.x += 1;	
			} else {
				this._editActive = true;
				this.updateFieldIcon();
				modalDialog = new ModalDialog(new Rectangle(0, 0, 260, 170));	
				//Currently these must be set BEFORE adding dialog to stage. Maybe update in future version?
				modalDialog.prompt = "Select desired method to find file \"" + this._fileName + "\":";
				buttonDimensions = new Rectangle(0, 0, 260, 40);
				modalDialog.addSelection("AUTOMATICALLY SEARCH FOR IT", { action:"autosearch" }, buttonDimensions);
				modalDialog.addSelection("LET ME FIND IT", { action:"manualsearch" }, buttonDimensions);						
				modalDialog.addSelection("CANCEL", { action:"cancel" }, buttonDimensions );
				
				SwagDispatcher.addEventListener(ModalDialogEvent.ONSELECT, this.onPathEditTypeSelect, this, modalDialog);
				this.stage.addChild(modalDialog);
				modalDialog.y += 14;
				modalDialog.x += 1;					
			}//else
		}//onClick
		
		private function updateClickArea():void {
			if (this._clickArea == null) {
				this._clickArea = new Sprite();
				this._clickArea.graphics.moveTo(0, 0);
				this._clickArea.graphics.lineStyle(1, 0x00FF00, 0);
				this._clickArea.graphics.beginFill(0x00FF00, 0);
				this._clickArea.graphics.lineTo((this._pathField.x + this._pathField.textWidth), 0);
				this._clickArea.graphics.lineTo((this._pathField.x + this._pathField.textWidth), (this._pathField.y + this._pathField.textHeight));
				this._clickArea.graphics.lineTo(0, (this._pathField.y + this._pathField.textHeight));
				this._clickArea.graphics.lineTo(0, 0);
				this._clickArea.graphics.endFill();
				this.addChild(this._clickArea);
			}
			this._clickArea.x = this._fieldIcon.x;
			this._clickArea.y = this._fieldIcon.y;
			this._clickArea.width = this._pathField.x + this._pathField.textWidth;
			this._clickArea.height = this._pathField.y + this._fieldIcon.height;
		}
		
		private function setDefaults(eventObj:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, this.setDefaults);
			this._pathField = new TextField();
			var format:TextFormat = Assets.getFontFormat("Pakenham");
			format.size = 11;
			format.font = "_sans"; //
			this._pathField.selectable = false;
			this._pathField.type = TextFieldType.DYNAMIC;
			this._pathField.autoSize = TextFieldAutoSize.LEFT;			
			this._pathField.defaultTextFormat = format;
			//this._pathField.embedFonts = true;
			this._pathField.setTextFormat(format);
			this.addChild(this._pathField);			
			this.updatePathString();
			this._pathField.setTextFormat(format);			
			this.addEventListener(MouseEvent.CLICK, this.onClick);
			this.useHandCursor = true;
			this.buttonMode = true;
		}
		
	}

}