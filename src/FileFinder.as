package  {
	
	import flash.filesystem.File;
	import flash.events.FileListEvent;	
	import events.FileFinderEvent;
	import swag.core.SwagDispatcher;
	import swag.core.SwagDataTools;
	
	/*
	 * Recursive file / folder search for Adobe AIR applications.
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
	public class FileFinder {
				
	
		private var _basePath:* = null;
		private var _fileName:String = null;
		private var _currentDir:File = null;
		private var _directoryStack:Vector.<File> = null;
		private var _completedStack:Vector.<File> = null;
		
		/**
		 * Searches for a specific file from a specified base path, optionally excluding certain paths.
		 * 
		 * @param	basePath The base path (for example, "c:\" or "/") to begin the search at.
		 * @param	fileName The file name ("file.ext") to search for.
		 * @param	exclusions An optional File vector array of paths to exclude. Any File items that are not
		 * directories will be removed.
		 */
		public function FileFinder(basePath:*, fileName:String, exclusions:Vector.<File>=null) {
			this._basePath = basePath;
			this._fileName = fileName;
			if (exclusions != null) {
				//The exclusions are the completed stack, we just need to ensure that they're all directories.
				this._completedStack = exclusions;
				this.pruneNonDirectories(this._completedStack);
			} else {
				this._completedStack = new Vector.<File>();
			}//else			
			this._directoryStack = new Vector.<File>();						
		}//constructor
		
		/**
		 * Begins the file search by resolving the base path and starting the initial asynch file list retrieval.
		 */
		public function findFile():void {
			this._currentDir = resolveToFile(this._basePath);						
			if (this._currentDir == null) {
				trace ("Couldn't resolve root directory: \""+this._basePath+"\"");
				return;
			}//if
			this._currentDir.addEventListener(FileListEvent.DIRECTORY_LISTING, this.onDirectoryListing);
			this._currentDir.getDirectoryListingAsync();
		}//findFile
		
		/**
		 * Cancels any currently running search and clears all results.
		 */
		public function cancelFind():void {
			try {
				this._currentDir.removeEventListener(FileListEvent.DIRECTORY_LISTING, this.onDirectoryListing);
				this._currentDir = null;
				this._completedStack = new Vector.<File>();
				this._directoryStack = new Vector.<File>();
			} catch (err:*) {
			}//catch
		}//cancelFind
		
		/**
		 * Event handler for asynch directory listing.
		 * 
		 * @param	eventObj A FileListEvent object.
		 */
		private function onDirectoryListing(eventObj:FileListEvent):void {
			var dirString:String = new String();
			this._currentDir.removeEventListener(FileListEvent.DIRECTORY_LISTING, this.onDirectoryListing);
			//Current directory being searched: this._currentDir.nativePath			
			var fileList:Array = eventObj.files;
			if (fileList.length == 0)  {
				this._currentDir = this._directoryStack.shift();
				this._completedStack.push(this._currentDir);
				this._currentDir.addEventListener(FileListEvent.DIRECTORY_LISTING, this.onDirectoryListing);
				this._currentDir.getDirectoryListingAsync();
				var newEvent:FileFinderEvent = new FileFinderEvent(FileFinderEvent.ONPROGRESS);
				newEvent.completedItems = this._completedStack;
				newEvent.queuedItems = this._directoryStack;
				newEvent.currentSearchItem = this._currentDir;
				newEvent.currentSearchDir = this._currentDir;
				SwagDispatcher.dispatchEvent(newEvent, this);
				return;
			}//if					
			//Number of directories remaining to be searched: this._directoryStack.length
			//Directories already searched: this._completedStack.length
			for (var count:uint = 0; count < fileList.length; count++) {
				var currentFile:File = fileList[count] as File;
				newEvent = new FileFinderEvent(FileFinderEvent.ONPROGRESS);
				newEvent.completedItems = this._completedStack;
				newEvent.queuedItems = this._directoryStack;
				newEvent.currentSearchItem = currentFile;
				SwagDispatcher.dispatchEvent(newEvent, this);
				if (currentFile.isDirectory) {
					//Current search entry is a directory so search it if not already searched
					if (this._completedStack.indexOf(currentFile)<0) {
						this._directoryStack.push(currentFile);
					}//if
				} else {							
					if (currentFile.name == this._fileName) {
						newEvent = new FileFinderEvent(FileFinderEvent.ONFOUND);
						newEvent.completedItems = this._completedStack;
						newEvent.queuedItems = this._directoryStack;
						newEvent.currentSearchItem = currentFile;
						newEvent.currentSearchDir = this._currentDir;
						SwagDispatcher.dispatchEvent(newEvent, this);						
						return;
					}//if
				}//else
			}//for
			if (this._directoryStack.length == 0) {
				newEvent = new FileFinderEvent(FileFinderEvent.ONNOTFOUND);
				newEvent.completedItems = this._completedStack;
				newEvent.queuedItems = this._directoryStack;						
				SwagDispatcher.dispatchEvent(newEvent, this);
				return;
			}//if			
			this._currentDir = this._directoryStack.shift();
			this._completedStack.push(this._currentDir);
			this._currentDir.addEventListener(FileListEvent.DIRECTORY_LISTING, this.onDirectoryListing);
			this._currentDir.getDirectoryListingAsync();
			newEvent = new FileFinderEvent(FileFinderEvent.ONPROGRESS);
			newEvent.completedItems = this._completedStack;
			newEvent.queuedItems = this._directoryStack;
			newEvent.currentSearchItem = this._currentDir;
			newEvent.currentSearchDir = this._currentDir;
			SwagDispatcher.dispatchEvent(newEvent, this);
		}//onDirectoryListing
				
		/**
		 * Prunes all non-directory items from the supplied File vector array.
		 * 
		 * @param	stackVector An array of File items.
		 * @return  A copy of the input vector array with only the directory items included.
		 */
		private function pruneNonDirectories(stackVector:Vector.<File>):Vector.<File> {
			return (stackVector.filter(this.pruneNonDirFilter, this));
		}//pruneNonDirectories
		
		/**
		 * Filter function used in conjuction with a File vector's "filter" method.
		 * 
		 * @param	item The File item being analyzed.
		 * @param	index The index of the item currently being analyzed.
		 * @param	vector A reference to the File vector currently executing the "filter" method.
		 * 
		 * @return True if the supplied File item is a directory, false otherwise.
		 */
		private function pruneNonDirFilter(item:File, index:int, vector:Vector.<File>):Boolean {
			if (item.isDirectory) {
				return (true);
			} else {
				return (false);
			}//else
		}//pruneNonDirFilter		
		
		/**
		 * Resolves a native path string (for example "c:\Windows\", or relative root paths like "\" or "/"), to an
		 * ActionScript File object.
		 * 
		 * @param	nativePath The native path to convert to a File instance.
		 * 
		 * @return A file instance pointing to the native path specified, or null if something went horribly wrong.
		 */
		public static function resolveToFile(nativePath:String):File {
			try {
				var returnFile:File = File.userDirectory;
				if ((nativePath == "\\") || (nativePath == "/")) {
					//AIR won't resolve slashes as roots so we do a little guessing instead...
					var rootDirs:Array = File.getRootDirectories();
					returnFile = rootDirs[0] as File;		
				} else {			
					returnFile = returnFile.resolvePath(nativePath);
				}//else
				return (returnFile);
			} catch (err:*) {
				return (null);
			}//catch
			return (null);
		}//resolveToFile
		
		/**
		 * Adds a trailing slash to the end of a native path string if one isn't present.
		 * 
		 * @param	inputPath The native path to add a trailing slash to.
		 * 
		 * @return The input native path with a trailing slash appended if necessary.
		 */
		public static function addTrailingSlash(inputPath:String):String {
			if (inputPath == null) {
				return ("");
			}//if
			if (inputPath == "") {
				return ("\\");
			}//if
			if (SwagDataTools.getFinalChar(inputPath, SwagDataTools.WHITESPACE_RANGE) != "\\") {
				inputPath = inputPath + "\\";
			}//if			
			return (inputPath);
		}//addTrailingSlash
		
	}//FileFinder class

}//package