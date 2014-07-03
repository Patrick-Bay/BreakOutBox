package {
	
	import model.WindowsRegistryEntry;
	import WindowsRegistryEditor;
	import flash.display.Sprite;
	import events.WindowsRegistryEvent;
	import model.WindowsRegistryKey;
	import model.WindowsRegistryDefaults;

	/**
	 * A demo.
	 * 
	 * In WRASE, the Registry is managed in a hierarchy. At the top is the WindowsRegistryEditor which uses "regedit.exe"
	 * to read and update the Windows Registry. Once the data is retrieved into a .reg file, it's read and parsed into
	 * WindowsRegistryKey instances. 
	 * 
	 * A key, or WindowsRegistryKey instance, is identified by it's key path...the "HKEY_CURRENT_USER\\Identities" below, 
	 * for example. The WindowsRegistryKey then creates WindowsRegistryEntry instances, which are the entries, or data 
	 * items within the key. Each data item has a name, value, and type properties. 
	 * 
	 * The WindowsRegistryEntry attepts to manage the type based on the value in order to dynamically convert between
	 * native Flash data types and Windows Registry data types.
	 * 
	 * Don't forget to set the desktop profile to "Extended Desktop" before running this!
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
	 */
	public class Main extends Sprite {
		
		public var regEdit:WindowsRegistryEditor;		
		
		public function Main():void {
			this.regEdit = new WindowsRegistryEditor();
			this.regEdit.addEventListener(WindowsRegistryEvent.ONLOAD, this.onLoadRegistry);
			this.regEdit.addEventListener(WindowsRegistryEvent.ONLOADERROR, this.onLoadRegistryError);
			this.regEdit.addEventListener(WindowsRegistryEvent.ONPARSEERROR, this.onParseRegistryError);
			//Don't forget to double-escape the slashes...
			var keyToLoad:String = "HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings";
			trace ("Loading: " + keyToLoad);
			trace ("Will read operation require Admin privileges? " + WindowsRegistryDefaults.keyPathRequiresReadAdminRights(keyToLoad));
			this.regEdit.loadRegistry(keyToLoad, WindowsRegistryDefaults.keyPathRequiresReadAdminRights(keyToLoad), false);
		}
		
		private function onLoadRegistry(eventObj:WindowsRegistryEvent):void {			
			trace ("-- REGISTRY LOADED --");
			trace ("Key requested: " + eventObj.loadedKey.keyPath); // Should be: HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings
			trace (" --- ");
			trace (this.regEdit); //...every object in WRASE toString()'s to a formatted Windows Registry object...
			//trace  (eventObj.loadedKey); //...for example...
			//trace (eventObj.loadedKey.entries[0]); //...and so on...
			//trace (eventObj.loadedKey.entries[0].name); //Each WindowsRegistryEntry has three properties: a name...
			//trace (eventObj.loadedKey.entries[0].value); //...a value...
			//trace (eventObj.loadedKey.entries[0].type); //...and a type (which is based on the value).
			//eventObj.loadedKey.entries[0].value = "The value has been updated" //An example of how to update registry data
			//this.regEdit.removeKey(eventObj.loadedKey);
			var newKey:WindowsRegistryKey = new WindowsRegistryKey();
			newKey.keyPath = "HKEY_CURRENT_USER\\WRASE_New_Test_Key"; //Make a new key (this shouldn't exist!) -- note how this is not a child or sibbling of the loaded key (not a problem).
			this.regEdit.appendKey(newKey); //Append the key to the registry editor instance
			var newEntry:WindowsRegistryEntry = new WindowsRegistryEntry(); //Create a new entry
			newEntry.name = "A_new_entry" //Give the entry a name (variable name)
			newEntry.type = WindowsRegistryEntry.type_string; //Give the variable a type (variable data type)
			newEntry.value = "This is some data in the entry"; //Put some data into the entry (variable data)
			newKey.appendEntry(newEntry); //Append the new entry to the new key
			newEntry = new WindowsRegistryEntry(); //Create a new entry
			newEntry.name = "A_numeric_value" //Another entry
			newEntry.value = 23; //This time the data type will be automatically determined
			newKey.appendEntry(newEntry); //Append the new entry to the new key again
			trace ("Loaded registry data updated with: ");
			trace (this.regEdit);
			trace (" ");
			trace ("About to update Windows Registry.");
			trace ("Will update operation require Admin privileges? "+WindowsRegistryDefaults.keyPathRequiresUpdateAdminRights(eventObj.loadedKey.keyPath))
			this.regEdit.updateRegistry(WindowsRegistryDefaults.keyPathRequiresUpdateAdminRights(eventObj.loadedKey.keyPath)); //And commit everything to the registry
			//You should now run "regedit.exe" and open "HKEY_CURRENT_USER"; you should see a folder there named
			//"WRASE_New_Test_Key", and there should be some values in there. Feel free to play around with ir
			//or delete it.
			//Many registry keys require admin rights, but typically many of the settings that an application will
			//want to access exist in the "HKEY_CURRENT_USER" key, which is mostly accessible. At least that is
			//my understanding at this time...
		}
		
		private function onLoadRegistryError(eventObj:WindowsRegistryEvent):void {			
			trace ("There was a problem loading the registry!");
		}
		
		private function onParseRegistryError(eventObj:WindowsRegistryEvent):void {			
			trace ("There was a problem parsing the registry information!");
		}
		
	}
	
}