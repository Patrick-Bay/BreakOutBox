package ui {
	
	/**
	 * Generates and handles functionality for the entire browser launch panel.
	 * 
	 *  Copyright (c) 2014 Patrick Bay
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
	import com.hurlant.util.der.ByteString;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import com.hurlant.crypto.hash.MD5;
	import fl.controls.CheckBox;
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.display.MovieClip;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.filesystem.FileMode;
	import flash.events.MouseEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.ui.Mouse;
	import model.WindowsRegistryDefaults;
	import ui.instances.IconButton;
	import ui.instances.PathEditField;
	import References;
	import Settings;
	import Assets;
	import fl.controls.TileList;
	import fl.controls.ScrollBarDirection;
	import fl.controls.Button;
	import fl.containers.ScrollPane;
	import fl.events.ListEvent;
	import flash.utils.describeType;
	import swag.core.SwagDataTools;
	import swag.core.SwagSystem;
	import swag.core.SwagDispatcher;
	import WindowsRegistryEditor;
	import model.WindowsRegistryKey;
	import model.WindowsRegistryEntry;
	import events.WindowsRegistryEvent;
	import ui.instances.ModalDialog;
	import events.ModalDialogEvent;
	
	public class BrowserLaunchPanel extends MovieClip {
		
		public var iconListWidth:Number = 110;
		public var iconTileHeight:Number = 50;
		private var _currentBrowserDef:XML = null;
		
		private static const defaultCMDPath:String = "app-storage:/launchbrowser.cmd";
		public static const cmdFileEncoding:String = "iso-8895-1";
			
		public var detailListVerticalOffset:Number = 15;
		
		private var _tileList:TileList = null;
		private var _detailsList:ScrollPane = null;
		
		public function BrowserLaunchPanel() {
			this.addEventListener(Event.ADDED_TO_STAGE, this.setDefaults);
			this.addEventListener(Event.REMOVED_FROM_STAGE, this.destroy);
			super();
		}
		
		private function onLaunchClick(eventObj:MouseEvent):void {						
			if (NativeProcess.isSupported) {
				try {					
					var pathNodes:XMLList = this._currentBrowserDef.child("path") as XMLList;
					var exeNameNode:XML = this._currentBrowserDef.child("executable")[0] as XML;			
					var executable:String = new String(exeNameNode.children().toString());						
					var executablePath:String = null;
					for (var count:uint = 0; count < pathNodes.length(); count++) {
						var currentPathNode:XML = pathNodes[count] as XML;
						if (currentPathNode.@os == SwagSystem.settings.environment) {
							executablePath = new String(currentPathNode.children().toString());
						}//if				
					}//for
					if (executablePath == null) {
						return;
					}//if					
					var executableFile:File = FileFinder.resolveToFile(FileFinder.addTrailingSlash(executablePath) + executable);
					try {
						var validationOptionXML:XML = this.getOptionByID("exevalidate", this._currentBrowserDef.child("options")[0].child("option") as XMLList);
					} catch (err:*) {
						validationOptionXML = null;
					}//catch
					var validateEXE:Boolean = false;
					if (validationOptionXML != null) {
						validateEXE = SwagDataTools.toBoolean(validationOptionXML.@enabled, false);
					}//if					
					if (validateEXE) {
						if (this.validateExecutableMD5Hash(executableFile, this._currentBrowserDef)) {
							this.onValidateExecutable();
						} else {
							var dialog:ModalDialog = new ModalDialog(new Rectangle(0,0,260,160));
							dialog.prompt = "Executable \"" + executable + "\" could not be validated and may be insecure!";
							dialog.addSelection("Run Anyway", { run:true } );
							dialog.addSelection("CANCEL", { run:false } );
							this.stage.addChild(dialog);
							//Show validation fail dialog!
						}//else
					} else {
						this.onValidateExecutable();
					}//else										
				} catch (err:*) {
					Debug.print ("BrowserLaunchPanel.onLaunchClick exception: "+err);
				}//catch
			} else {				
			}//else
		}//onLaunchClick
		
		/**
		 * Invoked when either validation passes or validation wasn't enabled (so everything passes).
		 */
		private function onValidateExecutable():void {
			try {
				var pathNodes:XMLList = this._currentBrowserDef.child("path") as XMLList;
				var exeNameNode:XML = this._currentBrowserDef.child("executable")[0] as XML;			
				var executable:String = new String(exeNameNode.children().toString());						
				var executablePath:String = null;
				for (var count:uint = 0; count < pathNodes.length(); count++) {
					var currentPathNode:XML = pathNodes[count] as XML;
					if (currentPathNode.@os == SwagSystem.settings.environment) {
						executablePath = new String(currentPathNode.children().toString());
					}//if				
				}//for
				var executableFile:File = FileFinder.resolveToFile(FileFinder.addTrailingSlash(executablePath) + executable);					
				var workingDir:File = FileFinder.resolveToFile(executablePath);
				var optionsNode:XML = this._currentBrowserDef.child("options")[0] as XML;
				var switches:XMLList = optionsNode.child("switch") as XMLList; //Only process (command line) switches
				this.processPrelaunchActions(this._currentBrowserDef, this, executableFile, workingDir, optionsNode.children());
				var args:Vector.<String> = new Vector.<String>();
				for (count = 0; count < switches.length(); count++) {
					var currentSwitch:XML = switches[count] as XML;	
					var currentSwitchData:String = new String(currentSwitch.children().toString());
					if (SwagDataTools.toBoolean(currentSwitch.@enabled)) {
						args.push(this.parseMeta(currentSwitchData));							
					} else {
					}//else
				}//for	
				var exePath:String = FileFinder.addTrailingSlash(executablePath) + executable;
				if (this.launchViaCMD(exePath, args, defaultCMDPath)) {					
					this.processPostlaunchActions(this._currentBrowserDef, this, executableFile, workingDir, optionsNode.children());		
				} else {						
				}//else
			} catch (err:*) {
				Debug.print ("BrowserLaunchPanel.onValidateExecutable exception: "+err);
			}//catch
		}//onValidateExecutable
		
		private function validateExecutableMD5Hash(fileRef:File, browserRef:XML):String {
			try {
				var stream:FileStream = new FileStream();
				stream.open(fileRef, FileMode.READ)
				var fileData:ByteArray = new ByteArray();
				stream.readBytes(fileData);
				stream.close();
				var md5:MD5 = new MD5();
				var md5Hash:String = SwagDataTools.toHexString(md5.hash(fileData));								
				var exechecksums:XML = this._currentBrowserDef.child("exechecksums")[0] as XML;							
				var checksumsString:String = new String(exechecksums.children().toString());				
				var checksums:Array = checksumsString.split(";");
				for (var count:uint = 0; count < checksums.length; count++) {
					var checksumComplexStr:String = checksums[count] as String;
					var cscSplit:Array = checksumComplexStr.split(":");
					var checksum:String = new String(cscSplit[0]);
					var versionStr:String = new String(cscSplit[1]);		
					if (checksum.toUpperCase() == md5Hash) {
						return (versionStr);
					}//if					
				}//for
				return (null);
			} catch (err:*) {	
				return (null);
			}//catch
			return (null);
		}//validateExecutableMD5Hash
		
		private function launchViaCMD(executablePath:String, args:Vector.<String>, batPath:String = null):Boolean {
			try {
				if ((batPath == null) || (batPath == "")) {
					batPath = defaultCMDPath;
				}//if
				var batchContents:String = new String();				
				var resolvedBatchPath:File = File.applicationDirectory.resolvePath(batPath);
				if (resolvedBatchPath.exists) {
					resolvedBatchPath.deleteFile();
				}//if												
				batchContents = "\""+executablePath+"\"";
				if (args != null) {
					for (var count:uint = 0; count < args.length; count++) {
						var currentArgument:String = args[count];
						var argsSplit:Array = currentArgument.split(String.fromCharCode(32));
						//Add required quotes to configuration data...no single solution works properly here :(
						batchContents += " " + currentArgument;	
					}//for
				}//if
				//Create CMD file...
				var stream:FileStream = new FileStream();
				stream.open(resolvedBatchPath, FileMode.WRITE);
				stream.writeMultiByte(batchContents, cmdFileEncoding);
				stream.close();				
				var processInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
				processInfo.executable = resolvedBatchPath;
				var browserProcess:NativeProcess = new NativeProcess();	
				//Launch process...
				try {
					browserProcess.start(processInfo);
					browserProcess.addEventListener(NativeProcessExitEvent.EXIT, this.onCMDLaunchComplete);
					return (browserProcess.running);
				} catch (err:*) {
					return (false);
				}//catch
				return (false);
			} catch (err:*) {				
				return (false);
			}//catch
			return (false);
		}//launchViaCMD
		
		private function onCMDLaunchComplete(eventObj:NativeProcessExitEvent):void {			
			eventObj.target.removeEventListener(NativeProcessExitEvent.EXIT, this.onCMDLaunchComplete);
			try {
				var resolvedBatchPath:File = File.applicationDirectory.resolvePath(defaultCMDPath);
				//Clean up batch file -- not completely necessary, but good practice...
				resolvedBatchPath.deleteFile();
			} catch (err:*) {
			}//catch
		}//onCMDLaunchComplete

		private function processPrelaunchActions(browserDef:XML, handlerContainer:*= null, executable:File = null, executablePath:File = null, options:XMLList = null):void {						
			if (handlerContainer == null) {
				handlerContainer = this;
			}//if
			try {
				var prelaunchNodes:XMLList = browserDef.child("prelaunch");				
				if (prelaunchNodes == null) {
					return;
				}//if
				for (var count:uint = 0; count < prelaunchNodes.length(); count++) {
					var currentNode:XML = prelaunchNodes[count] as XML;
					var invoke:String = new String(currentNode.@invoke);
					if (invoke == null) {
						return;
					}//if
					if (invoke.length == 0) {
						return;
					}//if					
					handlerContainer[invoke](currentNode, executable, executablePath, options);
				}//for
			} catch (err:*) {				
			}//catch
		}//processPrelaunchActions
		
		private function processPostlaunchActions(browserDef:XML, handlerContainer:*= null, executable:File=null, executablePath:File=null, options:XMLList=null):void {			
			if (handlerContainer == null) {
				handlerContainer = this;
			}//if
			try {
				var postlaunchNodes:XMLList = browserDef.child("postlaunch");
				if (postlaunchNodes == null) {
					return;
				}//if
				for (var count:uint = 0; count < postlaunchNodes.length(); count++) {
					var currentNode:XML = postlaunchNodes[count] as XML;
					var invoke:String = new String(currentNode.@invoke);
					if (invoke == null) {
						return;
					}//if
					if (invoke.length == 0) {
						return;
					}//if
					handlerContainer[invoke](currentNode, executable, executablePath, options); //handlers are at bottom of this class
				}//for
			} catch (err:*) {				
			}//catch
		}//processPostlaunchActions
		
		private function createBrowserLaunchButtons():void {
			this._tileList = new TileList();
			this._tileList.columnCount = 1;
			this._tileList.columnWidth = this.iconListWidth;
			this._tileList.rowHeight = this.iconTileHeight;
			this._tileList.width = this.iconListWidth;
			this._tileList.height = this.stage.stageHeight;// - 28; //There's a better way to adjust this
			this._tileList.direction = ScrollBarDirection.VERTICAL;
			this._tileList.mouseChildren = true;	
			this._tileList.mouseEnabled = true;
			var launcherDef:XML = Settings.getSettingsCategory("launcher");
			var browserDefinitions:XMLList = launcherDef.child("browser");
			for (var count:uint = 0; count < browserDefinitions.length(); count++) {
				var currentDef:XML = browserDefinitions[count] as XML;
				var iconID:String = new String(currentDef.@id);
				var currentIconObj:Object = Assets.getIconByName(iconID);
				var newButton:IconButton = new IconButton(currentIconObj);												
				this._tileList.addItem({source:newButton});
				if (newButton.previousButton!=null) {
					newButton.y = newButton.previousButton.y + newButton.previousButton.height;
				}//if
			}			
			this._tileList.addEventListener(ListEvent.ITEM_CLICK, this.onItemSelect);			
			this._tileList.addEventListener(ListEvent.ITEM_ROLL_OVER, this.onItemOver);
			this._tileList.addEventListener(ListEvent.ITEM_ROLL_OUT, this.onItemOut);
			this.addChild(this._tileList);
		}
			
		
		
		private function onItemSelect(eventObj:ListEvent):void {	
			try {
				var selectedItem:IconButton = eventObj.item.source as IconButton;			
				this.showLaunchDetails(selectedItem.id);				
			} catch (err:*) {				
			}
		}
		
		private function showLaunchDetails(browserID:String = null):void {			
			if ((browserID == null) || (browserID == "")) {
				return;
			}
			var launcherInfo:XML = Settings.getSettingsCategory("launcher");			
			var browserDefinitions:XMLList = launcherInfo.child("browser") as XMLList;
			for (var count:uint = 0; count < browserDefinitions.length(); count++) {
				var currentDef:XML = browserDefinitions[count] as XML;
				if (currentDef.@id == browserID) {
					this._currentBrowserDef = currentDef;
					this.populateDetailsPane (currentDef);
				}
			}
		}
		
		private function onOptionSelectChange(eventObj:Event):void {
			var targetCB:CheckBox = eventObj.target as CheckBox;
			if (targetCB.selected) {
				targetCB.metaData.@enabled = "true";
			} else {
				targetCB.metaData.@enabled = "false";
			}//else
			Settings.saveSettings();
		}
				
		private function populateDetailsPane(browserDefinition:XML):void {			
			if (this._detailsList != null) {
				this._detailsList.source = null;
				this.removeChild(this._detailsList);
				this._detailsList = null;
			}//if
			var yOffset:Number = 0;
			this._detailsList = new ScrollPane();
			this.addChild(this._detailsList);
			this._detailsList.x = this._tileList.x + this._tileList.innerWidth;
			this._detailsList.y = this._tileList.y;
			this._detailsList.width = this.stage.stageWidth-this._detailsList.x;
			this._detailsList.height = this._tileList.height;			
			var details:MovieClip = new MovieClip();
			//Launch path...
			var pathNodes:XMLList = browserDefinition.child("path") as XMLList;
			var exeNameNode:XML = browserDefinition.child("executable")[0] as XML;			
			var executable:String = new String(exeNameNode.children().toString());			
			for (var count:uint = 0; count < pathNodes.length(); count++) {
				var currentPathNode:XML = pathNodes[count] as XML;
				if (currentPathNode.@os == SwagSystem.settings.environment) {
					var executablePath:String = new String(currentPathNode.children().toString());
				}//if				
			}//for
			var buttonContainer:Sprite = new Sprite();
			buttonContainer.addChild(Assets.launchIcon);			
			buttonContainer.mouseEnabled = true;
			buttonContainer.buttonMode = true;
			buttonContainer.useHandCursor = true;
			details.addChild(buttonContainer);	
			buttonContainer.width *= 0.5;
			buttonContainer.height *= 0.5;
			buttonContainer.addEventListener(MouseEvent.CLICK, this.onLaunchClick);
			yOffset += ((buttonContainer.y + buttonContainer.height)/2);
			var launchPathField:PathEditField = new PathEditField(executablePath, executable, browserDefinition);
			details.addChild(launchPathField);
			launchPathField.y = yOffset;
			launchPathField.x = buttonContainer.x + buttonContainer.width;
			yOffset += this.detailListVerticalOffset + launchPathField.height + 10;
			//Command-line switches...
			var optionsNode:XML = browserDefinition.child("options")[0] as XML;
			var options:XMLList = optionsNode.children();
			var previousCB:CheckBox = null;
			for (count = 0; count < options.length(); count++) {
				var currentOption:XML = options[count] as XML;				
				var newCB:CheckBox = new CheckBox();
				newCB.width = this._detailsList.width;
				newCB.label = this.parseMeta(currentOption.@name);
				details.addChild(newCB);
				newCB.addEventListener(Event.CHANGE, this.onOptionSelectChange);
				newCB.metaData = currentOption;
				if (SwagDataTools.toBoolean(currentOption.@enabled)) {
					newCB.selected = true;
				} else {
					newCB.selected = false;
				}//else
				if (SwagDataTools.toBoolean(currentOption.@editable, true)) {
					newCB.enabled = true;
				} else {
					newCB.enabled = false;
				}//else
				if (previousCB != null) {
					yOffset+= previousCB.height;			
				} else {
					yOffset+=this.detailListVerticalOffset;					
				}//else
				newCB.y = yOffset;
				previousCB = newCB;
			}//for			
			this._detailsList.source = details;
			this._detailsList.update();
		}//populateDetailsPane
		
		private function getOptionByID(optionID:String, optionsList:XMLList):XML {
			if ((optionID == null) || (optionsList == null)) {
				return (null);
			}//if
			for (var count:uint = 0; count < optionsList.length(); count++) {
				var currentOption:XML = optionsList[count] as XML;
				if (String(currentOption.@id) == optionID) {
					return (currentOption);
				}//if
			}//for
			return (null);
		}//getOptionByID
		
		private function parseMeta(input:String):String {
			if ((input == null) || (input == "")) {
				return ("");
			}//if
			var output:String = new String(input);
			output = output.split("%tor_launch_url%").join(Settings.getSettingData("tor", "launchurl"));
			output = output.split("%tor_socks_ip%").join(Settings.getSettingData("tor", "socks5address"));
			output = output.split("%tor_socks_port%").join(Settings.getSettingData("tor", "socks5port"));
			output = output.split("%tor_control_ip%").join(Settings.getSettingData("tor", "controlAddress"));
			output = output.split("%tor_control_port%").join(Settings.getSettingData("tor", "controlPort"));
			output = output.split("%tor_control_password%").join(Settings.getSettingData("tor", "controlpass"));
			output = output.split("%api_ip%").join(Settings.getSettingData("apiserver", "localAddress"));
			output = output.split("%api_port%").join(Settings.getSettingData("apiserver", "localPort"));
			output = output.split("%api_useragent%").join(Settings.getSettingData("apiserver", "serverUserAgent"));			
			return (output);
		}//parseMeta
		
		private function onItemOver(eventObj:ListEvent):void {	
			try {
				var selectedItem:IconButton = eventObj.item.source as IconButton;	
				selectedItem.setOverState();
			} catch (err:*) {
				
			}
		}
		
		private function onItemOut(eventObj:ListEvent):void {			
			try {
				var selectedItem:IconButton = eventObj.item.source as IconButton;			
				selectedItem.setNormalState();
			} catch (err:*) {
				
			}
		}
		
		private function setDefaults(eventObj:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, this.setDefaults);
			this.createBrowserLaunchButtons();
			
		}
		
		public function destroy(... args):void {		
			this.removeEventListener(Event.REMOVED_FROM_STAGE, this.destroy);
		}		
		
		private function parseContentOptions(content:String, options:XMLList):String {			
			var updContent:String = new String(content);
			var optionsList:XMLList = options.parent().elements("option");			
			for (var count:uint = 0; count < optionsList.length(); count++) {
				var currentOption:XML = optionsList[count] as XML;				
				var currentOptionID:String = new String(currentOption.@id);
				var currentOptionReplaceID:String = "%option_" + currentOptionID + "%";
				var currentOptionString:String = new String(currentOption.children().toString());
				var optionEnabled:Boolean = SwagDataTools.toBoolean(currentOption.@enabled, false);
				var optionOptional:Boolean = SwagDataTools.toBoolean(currentOption.@optional, false);
				if ((optionOptional) && (!optionEnabled)) {
					updContent = updContent.split(currentOptionReplaceID).join("");
				} else {
					var optionContentNode:XML = this.getOptionByID(currentOptionID, options);
					var optionContent:String = new String(optionContentNode.children().toString());
					//Meta-info find and replace...
					optionContent = this.parseMeta(optionContent);
					//XML attribute find and replace...
					optionContent = optionContent.split("%attribute_enabled%").join(currentOption.@enabled);	
					optionContent = optionContent.split("%attribute_id%").join(currentOption.@id);	
					optionContent = optionContent.split("%attribute_name%").join(currentOption.@name);	
					optionContent = optionContent.split("%attribute_optional%").join(currentOption.@optional);						
					updContent = updContent.split(currentOptionReplaceID).join(optionContent);
				}//else				
			}//for						
			return (updContent);
		}
		
		// Pre/post launch handlers -- defined in config.xml
		private function createFirefoxProfile(launchNode:XML, executable:File, exePath:File, options:XMLList):void {			
			var profilePath:String = new String(launchNode.child("path")[0].toString());
			var profileFileName:String = new String(launchNode.child("filename")[0].toString());
			var profileFileContent:String = new String(launchNode.child("content")[0].children().toString());
			var resolvedPath:File = FileFinder.resolveToFile(profilePath);
			//First ensure that valid/known Firefox profile directory exists...
			var launchInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			launchInfo.executable = executable;
			launchInfo.workingDirectory = exePath;			
			launchInfo.arguments.push("-createprofile"); 
			launchInfo.arguments.push("breakoutbox");			
			launchInfo.arguments.push("\"" + FileFinder.addTrailingSlash(resolvedPath.nativePath) + "\"");
			var profileCreateProcess:NativeProcess = new NativeProcess();	
			trace ("Creating profile: " + resolvedPath.nativePath);
			profileCreateProcess.start(launchInfo);			
			//Overwrite prefs file with supplied content. Parse out metadata first...
			profileFileContent = this.parseContentOptions(profileFileContent, options);				
			trace ("Writing:");
			trace(profileFileContent);
			var prefsFile:File = FileFinder.resolveToFile(FileFinder.addTrailingSlash(resolvedPath.nativePath) + profileFileName);
			var stream:FileStream = new FileStream();
			stream.open(prefsFile, FileMode.WRITE);
			stream.writeUTFBytes(profileFileContent);			
			stream.close();
		}
		
		private function updateWindowsRegistry(launchNode:XML, executable:File, exePath:File, options:XMLList):void {
			var profileFileContent:String = new String(launchNode.child("content")[0].children().toString());			
			profileFileContent = this.parseContentOptions(profileFileContent, options);
			var regKey:WindowsRegistryKey = new WindowsRegistryKey(profileFileContent);
			var registry:WindowsRegistryEditor = new WindowsRegistryEditor();
			registry.appendKey(regKey);
			registry.updateRegistry();			
		}//updateWindowsRegistry
				
		
		
	}

}