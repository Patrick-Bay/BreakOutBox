package {
	
	import flash.net.SharedObject;
	import events.SettingsEvent;
	import swag.core.instances.SwagLoader;
	import swag.core.instances.SwagTime;
	import swag.events.SwagLoaderEvent;
	import swag.events.SwagTimeEvent;
	import swag.core.SwagDispatcher;
	import flash.utils.describeType;

	/**
	 * Manages loading, retrieval, and storage of application data. This class' methods and
	 * properties are all static so no instantiation of Settings needs to be done.
	 * 
	 * The MIT License (MIT)
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
	public final class Settings {
				
		/**
		 * Auto-save settings.
		 * Set the interval to "0" to disable auto-save. Time format is:
		 * HH:MM:SS:MS
		 */
		private static var _autoSaveInterval:String = "00:00:10:00";
		private static var _autoSaveTimer:SwagTime;
		
		private static var _settingsLoader:SwagLoader;
		private static var _settingsFilePath:String = "xml/settings.xml";		
		private static var _settingsData:XML;		
		private static const _lsoName:String = "breakoutbox_settings";
		private static var _isDynamic:Boolean = true;
		
		public static function get defaultSettingsFilePath():String {
			return (_settingsFilePath);
		}//get defaultSettingsFilePath
		
		/**
		 * Load settings data from the specified XML file. If the paramater is <em>null</em> or a blank
		 * string, the internal default path of "xml/settings.xml" is used instead.
		 * 
		 * @param	filePath The path of the XML file to load.
		 * @param   reset If <em>true</em>, the settings data will be loaded from disk (the specified file
		 * path). If <em>false</em>, settings data will be loaded from the local shared object instead
		 * (in case the data was previously saved or updated). If no settings data can be found in the local
		 * shared object, a reset will be forced.
		 */
		public static function loadSettings(filePath:String=null, reset:Boolean=false):void {
			if ((filePath == null) || (filePath == "")) {
				filePath = _settingsFilePath;
			}//if
			_settingsFilePath = filePath;
			if (_settingsLoader != null) {
				SwagDispatcher.removeEventListener(SwagLoaderEvent.COMPLETE, onLoadSettings, Settings);
				_settingsLoader = null;
			}//if
			if (!reset) {
				//Try loading from local shared object...
				try {
					var localSO:SharedObject = SharedObject.getLocal(_lsoName);
					_settingsData = localSO.data.settings;
					if ((_settingsData == null) || (_settingsData.toString == "")) {						
						reset = true;
					} else {
						_settingsData.@reset = "false";						
						broadcastLoadComplete();
						return;
					}//else
				} catch (err:*) {
					reset = true;
				}//catch
			}//if
			if (reset) {				
				//If LSO has failed or reset was explicitly specified...
				_settingsLoader = new SwagLoader();
				SwagDispatcher.addEventListener(SwagLoaderEvent.COMPLETE, onLoadSettings, Settings, _settingsLoader);
				_settingsLoader.load(filePath, XML);
			}//if
		}//loadSettings
		
		/**
		 * Forces the current XML settings data to be saved to the local shared object.
		 * 
		 * @return <em>True</em> if the settings could be successfully saved, <em>false</em> otherwise.
		 */
		public static function saveSettings():Boolean {
			try {
				var localSO:SharedObject = SharedObject.getLocal(_lsoName);
				localSO.data.settings = _settingsData;				
				localSO.flush();
			} catch (err:*) {
				return (false);
			}//catch
			return (false);
		}//saveSettings
		
		private static function broadcastLoadComplete():void {
			SwagDispatcher.dispatchEvent(new SettingsEvent(SettingsEvent.ONLOAD), Settings);
		}//broadcastLoadComplete
		
		/**
		 * Invoked when settings data has been loaded. Not intended to be called directly.
		 * 
		 * @param	eventObj
		 */
		public static function onLoadSettings(eventObj:SwagLoaderEvent):void {			
			SwagDispatcher.removeEventListener(SwagLoaderEvent.COMPLETE, onLoadSettings, Settings);
			_settingsData = new XML(_settingsLoader.loadedData.toString()); //Copy XML data so that loader can be disposed
			//Explicitly set the "reset" attribute should we need to know whether or not this data is loaded...
			_settingsData.@reset = "true";
			_settingsLoader = null;			
			broadcastLoadComplete();
		}//onLoadSettings
		
		/**
		 * Returns a top-level node (a child node to the top XML / document), based on its name. Such
		 * nodes are considered category nodes as sub-nodes are considered settings within those categories.
		 * 
		 * Example:
		 * <game>
		 *  	<messages>
		 * 		...
		 * In this case, "messages" is considered a top-level, or category node.
		 * 
		 * @param	categoryName The settings category node to search for.
		 * 
		 * @return A reference to the first found XML node, or <em>null</em> if none found.
		 */
		public static function getSettingsCategory(categoryName:String):XML {
			try {
				var childNodes:XMLList = data.child(categoryName);
				if (childNodes.length() < 1) {
					return (null);
				} else {
					return (childNodes[0] as XML);
				}//else
			} catch (err:*) {
				return (null);
			}//catch
			return (null);
		}//getSettingsCategory
		
		/**
		 * Returns a setting node, a child node of a top-level category node, based on both category name and
		 * setting name.
		 * 
		 * Example:
		 * <settings>
		 *  	<messages>
		 * 			<welcome>Welcome to the application!</welcome>
		 * 		...
		 * In this case, "messages" is the category and "welcome" is the setting.
		 * 
		 * @param	categoryName The settings category node to search for.
		 * @param	settingName The settings category node to search for.
		 * 
		 * @return A reference to the first found setting node, or <em>null</em> if none found.
		 */
		public static function getSetting(categoryName:String, settingName:String):XML {
			try {
				var categoryNode:XML = getSettingsCategory(categoryName);
				if (categoryNode == null) {
					return (null);
				}//else
				var childNodes:XMLList = categoryNode.child(settingName);
				if (childNodes.length() < 1) {
					return (null);
				} else {
					return (childNodes[0] as XML);
				}//else
			} catch (err:*) {
				return (null);
			}//catch
			return (null);
		}//getSetting
		
		/**
		 * Returns the contents of a setting node.
		 * 
		 * Example:
		 * <game>
		 *  	<messages>
		 * 			<welcome>Welcome to the application!</welcome>
		 * 		...
		 * In this case, "Welcome to the application!" is considered the content of the "messages" category
		 * and "welcome" setting.
		 * 
		 * @param	categoryName The settings category node to search for.
		 * @param	settingName The settings name node to search for.
		 * 
		 * @return The content of the first matching node, as a string, or <em>null</em> if none found.
		 */
		public static function getSettingData(categoryName:String, settingName:String):String {
			try {
				var categoryNode:XML = getSettingsCategory(categoryName);
				if (categoryNode == null) {
					return (null);
				}//else
				if ((categoryNode == "") || (settingName=="")) {
					return (null);
				}//else
				var childNodes:XMLList = categoryNode.child(settingName);
				if (childNodes.length() < 1) {
					return (null);
				} else {
					var currentChild:XML = childNodes[0] as XML;
					var childData:String = new String(currentChild.children().toString());
					return (childData);
				}//else
			} catch (err:*) {
				return (null);
			}//catch
			return (null);
		}//getSettingData
		
		/**
		 * Sets the data content of the specified setting node.
		 * 
		 * Example:
		 * <game>
		 *  	<messages>
		 * 			<welcome>Welcome to the application!</welcome>
		 * 		...
		 * In this case, "Welcome to the application!" is considered the content of the "messages" category
		 * and "welcome" setting. Updating this content would replace the existing string. If no matching 
		 * category or setting node can be found
		 * 
		 * @param	categoryName The settings category node to search for.
		 * @param	settingName The settings name node to search for.
		 * @param 	data The string data to assign as a child of the matching node.	If this value is <em>null</em>,
		 * a settings node will be created with no children (no data).
		 * 
		 * @return The updated or newly created setting data node (<em>null</em> if there was a problem).
		 */
		public static function setSettingData(categoryName:String, settingName:String, settingData:String):XML {
			if ((categoryName == null) || (settingName == null)) {
				return (null);
			}//else
			try {				
				var categoryNode:XML = getSettingsCategory(categoryName);
				if (categoryNode == null) {
					if (isDynamic) {
						//Create new category node...
						var newNodeStr:String = "<" + categoryName + " />";
						categoryNode = new XML(newNodeStr);
						data.appendChild(categoryNode);
					} else {
						return (null);
					}//else
				}//if
				var childNodes:XMLList = categoryNode.child(settingName);
				if (childNodes.length() < 1) {
					if (isDynamic) {
						//Create new setting node...
						newNodeStr = "<" + settingName + " />";
						var currentChild:XML = new XML(newNodeStr);
						categoryNode.appendChild(currentChild);																		
					} else {
						return (null);
					}//else					
				} else {
					currentChild = childNodes[0] as XML;						
				}//else
				if (settingData != null) {
					var childData:String = "<![CDATA[" + settingData + "]]>";
					var dataNode:XML = new XML(childData);
					currentChild.setChildren(dataNode);		
				}//if				
				return (currentChild);
			} catch (err:*) {
				return (null);
			}//catch	
			return (null);
		}//setSettingData
		
		/**
		 * Records the current data state of a class instance. Only publicly available data and objects
		 * can be enumerated and saved so be sure to declare any data that is required to be saved as public.
		 * This data is stored in the XML data under the category "states" with the setting name being the
		 * same as the class name:
		 * <game>
		 *  	<states>
		 * 			<Main>
		 * 				<x><![CDATA[0]]></x>
		 * 				<y><![CDATA[0]]></y>
		 * 		...
		 * 
		 * Properties of the class are stored as settings within the category. Note that this method
		 * doesn't save the data, only records it into the settings XML data.
		 * 
		 * @param	classInstance The class for which to record the state for.
		 */
		public static function recordState(classInstance:*):void {
			var typeDef:XML = describeType(classInstance);			
			var className:String = new String(typeDef.@name);
			className = className.split("::")[1] as String;
			var stateNode:XML = setSettingData("states", className, null);
			var stateNodeName:String = className;
			var variableList:XMLList = typeDef.child("variable");
			var accessorList:XMLList = typeDef.child("accessor");
			for (var count:uint = 0; count < variableList.length(); count++) {
				try {
					var currentVar:XML = variableList[count] as XML;
					var varName:String = new String(currentVar.@name);
					var varType:String = new String(currentVar.@type);
					if ((varType == "XML") || (varType == "XMLList"))					 {
						var varData:String = new String(classInstance[varName].toXMLString());
					} else {
						varData = new String(classInstance[varName]);
					}//else
					if (isValidSaveStateType(varType)) {
						stateNode.appendChild(createVarNode(varName, varType, varData));						
					}//if
				} catch (err:*) {					
				}//catch
			}//for			
			for (count = 0; count < accessorList.length(); count++) {
				try {
					currentVar = accessorList[count] as XML;
					varName = new String(currentVar.@name);
					varType = new String(currentVar.@type);
					varData = new String(classInstance[varName]);
					if (isValidSaveStateType(varType)) {
						stateNode.appendChild(createVarNode(varName, varType, varData));
					}//if
				} catch (err:*) {					
				}//catch
			}//for			
		}//recordState
		
		/**
		 * Attempts to restore the state of a class by assigning all of the stored values in
		 * the settings data to the instance. Only public properties are affected, though no
		 * validation is done to ensure that properties exist or are public.
		 * 
		 * @param	classInstance The class for which to restore the state for.
		 */
		public static function restoreState(classInstance:*):void {
			var typeDef:XML = describeType(classInstance);			
			var className:String = new String(typeDef.@name);
			className = className.split("::")[1] as String;
			var stateNode:XML = getSetting("states", className);
			if (stateNode == null) {
				return;
			}//if
			var stateNodes:XMLList = stateNode.children();
			for (var count:uint = 0; count < stateNodes.length(); count++) {
				var currentNode:XML = stateNodes[count] as XML;
				var varName:String = new String(currentNode.localName());
				try {
					classInstance[varName] = createVariable(currentNode);
				} catch (err:*) {					
				}//catch
			}//for			
		}//restoreState
		
		/**
		 * @private 
		 * 
		 * @param	sourceNode
		 * @return
		 */
		private static function createVariable(sourceNode:XML):* {
			var varType:String = sourceNode.@type;
			switch (varType) {
				case "Number" :
					return (Number(sourceNode.children().toString()));
					break;
				case "String" :
					return (String(sourceNode.children().toString()));
					break;
				case "Boolean" :
					return (Boolean(sourceNode.children().toString()));
					break;
				case "XML" :
					return (new XML(sourceNode.children().toString()));
					break;
				case "XMLList" :
					return (new XMLList(sourceNode.children().toString()));
					break;					
				case "int" :
					return (int(sourceNode.children().toString()));
					break;
				case "uint" :
					return (uint(sourceNode.children().toString()));
					break;
				default:
					return (null);
					break;
			}//switch
			return (null);
		}//createVariable
		
		/**
		 * @private
		 * 
		 * @param	varName
		 * @param	varType
		 * @param	varData
		 * @return
		 */
		private static function createVarNode(varName:String, varType:String, varData:String):XML {
			var varNode:XML = new XML("<" + varName + " />");
			varNode.@type = varType;
			var dataNode:XML = new XML("<![CDATA[" + varData + "]]>");
			varNode.appendChild(dataNode);			
			return (varNode);
		}//createVarNode
		
		/**
		 * Returns true if the defined data type can be stored in a save state operation (essentially,
		 * can the data be converted to/from a string?)
		 * 
		 * @param	typeDef The type of definition to test against.
		 * 
		 * @return True if the definition can be stringified and saved, false otherwise.
		 */
		private static function isValidSaveStateType(typeDef:String):Boolean {
			switch (typeDef) {				
				case "Number" :
					return (true);
					break;
				case "String" :
					return (true);
					break;
				case "Boolean" :
					return (true);
					break;
				case "XML" :
					return (true);
					break;
				case "XMLList" :
					return (true);
					break;					
				case "int" :
					return (true);
					break;
				case "uint" :
					return (true);
					break;
				default:
					return (false);
					break;
			}//switch
			return (false);
		}//isValidSaveStateType
		
		/**
		 * Returns the loaded XML data at the root node, or <em>null</em> if none is loaded.
		 */
		public static function get data():XML {
			if (_settingsData == null) {
				return (null);
			}//if
			if ((_settingsData.toString() == null) || (_settingsData.toString() == "")) {
				return (null);
			}//if
			return (_settingsData);
		}//get data
		
		/**
		 * Handler for auto-save timer ticks.
		 * 
		 * @param	eventObj A <code>SwagTimeEvent</code> object.
		 */
		public static function onAutoSaveInterval(eventObj:SwagTimeEvent):void {			
			_autoSaveTimer.resetCountDown();
			saveSettings();
			_autoSaveTimer.startCountDown();			
		}//onAutoSaveInterval
		
		/**
		 * Enables or disables autosave of the settings data. If the interval is
		 * set to 0, autosave is disabled, otherwise auto-save will run at 
		 * the specified interval. Valid interval format is:
		 * HH:MM:SS:ms
		 */
		public static function set autoSave(intervalSet:String):void {			
			_autoSaveInterval = intervalSet;
			if (_autoSaveTimer != null) {
				SwagDispatcher.removeEventListener(SwagTimeEvent.ENDCOUNTDOWN, onAutoSaveInterval, Settings);
				_autoSaveTimer.stopCountDown();
				_autoSaveTimer = null;
			}//if
			_autoSaveTimer = new SwagTime(intervalSet);			
			if (_autoSaveTimer.totalMilliseconds > 0) {				
				SwagDispatcher.addEventListener(SwagTimeEvent.ENDCOUNTDOWN, onAutoSaveInterval, Settings, _autoSaveTimer);
				_autoSaveTimer.startCountDown();
			} else {
				_autoSaveTimer = null;
			}//else
		}//set autoSave
		
		public static function get autoSave():String {
			return (_autoSaveInterval);
		}//get autoSave

		/**
		 * Determines whether values assigned to the settings data are created if they don't exist (<em>true</em>),
		 * or not (<en>false</em>). Default is <em>true</em>.
		 */
		public static function set isDynamic(dynamicSet:Boolean):void {
			_isDynamic = dynamicSet;
		}//set isDynamic
		
		public static function get isDynamic():Boolean {
			return (_isDynamic);
		}//get isDynamic
		
	}//Settings class

}//package