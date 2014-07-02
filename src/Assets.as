package  {	
	
	import flash.display.Bitmap;
	import flash.text.Font;
	import flash.text.TextFormat;
	import mx.core.BitmapAsset;
	import flash.utils.describeType;
	import fl.controls.*; //via libary SWC (fl.control.swc) -- found in assets flder
	
	/**
	 * Embedded (library) assets to be included with application.
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
	public class Assets {
		
		[Embed(source = "../assets/graphics/icons/chrome_64x64.png")]
		private static var chromeIconClass:Class;
		[Embed(source = "../assets/graphics/icons/firefox_64x64.png")]
		private static var firefoxIconClass:Class;
		[Embed(source = "../assets/graphics/icons/internet-explorer_64x64.png")]
		private static var IEIconClass:Class;
		[Embed(source = "../assets/graphics/icons/opera_64x64.png")]
		private static var operaIconClass:Class;
		[Embed(source = "../assets/graphics/icons/safari_64x64.png")]
		private static var safariIconClass:Class;
		[Embed(source="../assets/fonts/pakenham.ttf", fontFamily="Pakenham")]
		private static var pakenhamFontClass:Class;
		
		private static var pakenhamFont:Font = new pakenhamFontClass() as Font;
		
		[Embed(source = "../assets/graphics/icons/forward.png")]
		private static var launchIconClass:Class;
		[Embed(source="../assets/graphics/icons/folder_green_open.png")]
		private static var openGreenFolderIconClass:Class;
		[Embed(source="../assets/graphics/icons/folder_grey_open.png")]
		private static var openGrayFolderIconClass:Class;
		[Embed(source="../assets/graphics/icons/folder_important.png")]
		private static var closedAlertFolderIconClass:Class;
		[Embed(source="../assets/graphics/icons/folder_txt.png")]
		private static var closedEditFolderIconClass:Class;
				
		/**
		 * Be sure to update icons getter below if the following references change in type.
		 * Name corresponds directly with XML id attribute.
		 */
		public static function get launchIcon():Bitmap {
			return (new launchIconClass());
		}	
		public static function get chrome_icon():Bitmap {
			return (new chromeIconClass());
		}		
		public static function get firefox_icon():Bitmap {
			return (new firefoxIconClass());
		}
		public static function get ie_icon():Bitmap {
			return (new IEIconClass());
		}
		public static function get opera_icon():Bitmap {
			return (new operaIconClass());
		}
		public static function get safari_icon():Bitmap {
			return (new safariIconClass());
		}		
		/**
		 * Generic UI folder icons...
		 */
		public static function get openGreenFolderIcon():Bitmap {
			return (new openGreenFolderIconClass());
		}		
		public static function get openGrayFolderIcon():Bitmap {
			return (new openGrayFolderIconClass());
		}		
		public static function get closedAlertFolderIcon():Bitmap {
			return (new closedAlertFolderIconClass());
		}		
		public static function get closedEditFolderIcon():Bitmap {
			return (new closedEditFolderIconClass());
		}
		
		public static function getIconByName(iconName:String):Object {			
			var classAccItems:XMLList = describeType(Assets).child("accessor");						
			for (var count:uint = 0; count < classAccItems.length(); count++) {
				var currentItem:XML = classAccItems[count] as XML;
				if (currentItem.@type == "flash.display::Bitmap") {
					var iconFullName:String = currentItem.@name;
					var nameSplit:Array = iconFullName.split("_");
					if (nameSplit.length > 1) {
						var iconRootName:String = nameSplit[0] as String;
						if (iconName==iconRootName) {
							var iconRef:Bitmap = Assets[iconFullName];
							var returnObj:Object = new Object();
							returnObj.name = iconRootName;
							returnObj.icon = iconRef;
							return (returnObj);
						}//if
					}//if
				}//if
			}//for
			return (null);
		}//getIconByName
		
		public static function get icons():Vector.<Object> {			
			var classAccItems:XMLList = describeType(Assets).child("accessor");			
			var returnVec:Vector.<Object> = new Vector.<Object>();
			for (var count:uint = 0; count < classAccItems.length(); count++) {
				var currentItem:XML = classAccItems[count] as XML;
				if (currentItem.@type == "flash.display::Bitmap") {
					var iconName:String = currentItem.@name;
					var nameSplit:Array = iconName.split("_");
					if (nameSplit.length > 1) {
						var iconRootName:String = nameSplit[0] as String;
						var iconRef:Bitmap = Assets[iconName];
						var returnObj:Object = new Object();
						returnObj.name = iconRootName;
						returnObj.icon = iconRef;
						returnVec.push(returnObj);
					}//if
				}//if
			}//for
			return (returnVec);
		}
		
		public static function getFontFormat(embeddedFontName:String):TextFormat {
			//Don't forget to set embedFonts in the target text field to true before applying format!				
			var returnFormat:TextFormat = new TextFormat();
			returnFormat.font = embeddedFontName;			
			return (returnFormat);
		}	
		
	}

}