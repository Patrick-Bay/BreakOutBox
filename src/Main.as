package {
			
	import flash.events.Event;
	import events.SettingsEvent;
	import flash.display.MovieClip;	
	import flash.display.StageScaleMode;	
	import flash.events.InvokeEvent;
	import flash.text.TextField;
	import flash.desktop.NativeApplication;
	import flash.text.TextFormat;
	import instances.HTTPServer;	
	import swag.core.SwagDispatcher;
	import swag.core.SwagDataTools;
	import Settings;
	import References;
	import APIServer;
	import FileFinder;
	import Assets;	
	import ui.BrowserLaunchPanel;
	import org.torproject.TorControl;
	import org.torproject.events.TorControlEvent;	
	

	/**
	 * Main BreakOutBox application entry class.
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
	public dynamic class Main extends MovieClip {
		
		public static const version:String = "1.2.0";
		private var _server:APIServer = null;
		private var _browserLaunchPanel:BrowserLaunchPanel;
		private var _torInstance:TorControl;
				
		private var _resetConfig:Boolean = false; //can be controlled by adding "reset" to application command line
		private var _initProgress:uint = 0;
		
		public function Main():void {
			Debug.print("BreakOutBox v." + version + " instantiated.");
			References.main = this;	
			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, this.onLaunchApplication);
			this.addEventListener(Event.ADDED_TO_STAGE, this.setDefaults);		
		}//constructor
		
		private function onLaunchApplication (eventObj:InvokeEvent):void {
			Debug.print ("BreakOutBox.onLaunchApplication();");
			Debug.print ("   Command line arguments: " + eventObj.arguments);
			for (var count:uint = 0; count < eventObj.arguments.length; count++) {
				var currentParam:String = eventObj.arguments[count] as String;
				this.processCommandLineParam(currentParam);
			}//for
			this._initProgress++;
			this.loadSettings();
		}//onLaunchApplication
		
		private function processCommandLineParam(paramStr:String):void {			
			try {
				paramStr = paramStr.toLowerCase();
				paramStr = SwagDataTools.stripOutsideChars(paramStr, SwagDataTools.WHITESPACE_RANGE);
				switch (paramStr) {
					case "reset":						
						this._resetConfig = true;
						break;
					default: break;
				}//switch
			} catch (err:*) {
				Debug.print("Invalid command line parameter: " + paramStr);
			}//catch
		}//processCommandLineParam
		
		private function destroy(eventObj:Event):void {
			Debug.print ("BreakOutBox.destroy();");
			this.removeEventListener(Event.ADDED_TO_STAGE, this.setDefaults);	
			NativeApplication.nativeApplication.removeEventListener(Event.EXITING, this.destroy);	
			this.stage.nativeWindow.removeEventListener(Event.CLOSING, this.destroy);
			SwagDispatcher.removeEventListener(TorControlEvent.ONAUTHENTICATE, this.onTorInitialize, this._torInstance);
			if (this._torInstance!=null) {
				this._torInstance.stopTorProcess();
			}//if
			if (this._browserLaunchPanel!=null) {
				this._browserLaunchPanel.destroy();
				this.removeChild(this._browserLaunchPanel);
			}//if
			this._torInstance = null;
		}//destroy
		
		private function setDefaults(eventObj:Event):void {
			Debug.print ("BreakOutBox.setDefaults();");
			this.stage.scaleMode = StageScaleMode.NO_SCALE;			
			this.removeEventListener(Event.ADDED_TO_STAGE, this.setDefaults);
			NativeApplication.nativeApplication.addEventListener(Event.EXITING, this.destroy);
			this.stage.nativeWindow.addEventListener(Event.CLOSING, this.destroy);
			NativeApplication.nativeApplication.autoExit = false;
			NativeApplication.nativeApplication["executeInBackground"] = true;
			this._initProgress++;			
			this.loadSettings();			
		}//setDefaults
				
		private function loadSettings():void {			
			if (this._initProgress < 2) {
				//setDefaults and onLaunchApplication must be invoked first...
				return;
			}//if
			Debug.print ("BreakOutBox.loadSettings();");
			Debug.print ("   Settings source file path: " + Settings.defaultSettingsFilePath);
			if (this._resetConfig) {
				Debug.print ("   Reseting configuration data from source file.");	
			}//if
			SwagDispatcher.addEventListener(SettingsEvent.ONLOAD, this.onLoadSettings, this, Settings);			
			Settings.loadSettings("xml/settings.xml", this._resetConfig);
		}//loadSettings
				
		public function onLoadSettings(eventObj:SettingsEvent):void {
			Debug.print ("BreakOutBox.onLoadSettings();");
			SwagDispatcher.removeEventListener(SettingsEvent.ONLOAD, this.onLoadSettings, Settings);
			this._browserLaunchPanel = new BrowserLaunchPanel();
			this.addChild(this._browserLaunchPanel);	
			this._browserLaunchPanel.y += 14; //There must be a better way to adjust this!
			if (SwagDataTools.toBoolean(Settings.getSettingData("tor", "autostart"), false)) {
				Debug.print ("Tor proxy starting on: " + Settings.getSettingData("tor", "socks5address") + ":" + Settings.getSettingData("tor", "socks5port"));			
				Debug.print ("Tor control starting on: " + Settings.getSettingData("tor", "controlAddress") + ":" + Settings.getSettingData("tor", "controlPort"));			
				this._torInstance = new TorControl(Settings.getSettingData("tor", "controlAddress"), int(Settings.getSettingData("tor", "controlPort")), Settings.getSettingData("tor", "socks5address"), int(Settings.getSettingData("tor", "socks5port")), Settings.getSettingData("tor", "controlpass"));
				SwagDispatcher.addEventListener(TorControlEvent.ONAUTHENTICATE, this.onTorInitialize, this, this._torInstance);
				this._torInstance.connect();
			}//if						
			this.initialize();
		}//onLoadSettings
				
		
		public function onTorInitialize(eventObj:TorControlEvent):void {
			Debug.print ("Tor instance connected and authenticated.");			
		}//onTorInitialize
		
		private function initialize():void {
			Debug.print ("BreakOutBox.initialize();");			
			Debug.print ("BreakOutBox version: " + Settings.getSettingData("version", "revision"));
			Debug.print ("AIR runtime version: " + NativeApplication.nativeApplication.runtimeVersion);
			Debug.print ("API deamon starting on: " + Settings.getSettingData("apiserver", "localAddress") + ":" + Settings.getSettingData("apiserver", "localPort"));			
			this._server = new APIServer(Settings.getSettingData("apiserver", "localAddress"), int(Settings.getSettingData("apiserver", "localPort")));			
		}//initialize			
		
		
	}
	
}