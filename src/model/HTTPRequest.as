package model {
	
	import flash.utils.ByteArray;
	import model.HTTPRequestHeader;
	import flash.net.URLVariables;
	
	/**	 
	 * Handles the analysis and parsing of a HTTP request.
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
	public class HTTPRequest  {
		
		public static const CR:String = String.fromCharCode(13);
		public static const LF:String = String.fromCharCode(10);
		public static const CRLF:String = CR+LF;
		public static const doubleCRLF:String = CRLF + CRLF;
		public static const SPACE:String = String.fromCharCode(32);	
		public static const cookieSetHeader:String = "set-Cookie";
		public static const charSet:String = "iso-8859-1";
		
		private var _rawRequest:String = null;
		private var _requestMethod:String = null;
		private var _requestResource:String = null;
		private var _HTTPVersion:String = null;
		private var _body:String = null;
		private var _headers:Vector.<HTTPRequestHeader> = null;
		private var _variables:URLVariables = null;
		
		public function HTTPRequest():void {
			
		}
		
		public function parseRequestLine(rawRequestData:ByteArray):Boolean {
			if (!this.requestLineComplete(rawRequestData)) {
				return (false);
			}//if			
			try {
				rawRequestData.position = 0;
				var requestString:String = rawRequestData.readMultiByte(rawRequestData.length, charSet);
				this._rawRequest = requestString;
				var headerLines:Array = requestString.split(CRLF);
				var statusLine:String = headerLines[0] as String;				
				var statusSplit:Array = statusLine.split(SPACE);
				var methodStr:String = statusSplit[0] as String;
				var resourceStr:String = statusSplit[1] as String;
				Debug.print ("resourceStr=" + resourceStr);
				var vars:Array = resourceStr.split("?");
				Debug.print ("vars=" + vars);
				Debug.print ("vars.length=" + vars.length);
				if (vars != null) {
					if (vars.length > 1) {
						var varsStr:String = vars[1] as String;						
						Debug.print ("varsStr=" + varsStr);
						try {
							this._variables = new URLVariables(varsStr);
						} catch (err:*) {
							Debug.print(err);
						}
						Debug.print ("this._variables=" + this._variables);
					}//if
				}//if					
				var versionStr:String = statusSplit[2] as String;				
				this._requestMethod = methodStr;
				this._requestResource = resourceStr;
				this._HTTPVersion = versionStr;				
				return (true);
			} catch (err:*) {
				return (false);
			}//catch
			return (false);
		}//parseRequestLine
		
		public function parseRequestHeaders(rawRequestData:ByteArray):Boolean {
			if (!this.headerSectionComplete(rawRequestData)) {
				return (false);
			}//if
			try {
				rawRequestData.position = 0;
				this._headers = new Vector.<HTTPRequestHeader>();
				var requestString:String = rawRequestData.readMultiByte(rawRequestData.length, charSet);
				this._rawRequest = requestString;
				var requestHeader:String = requestString.split(doubleCRLF)[0] as String;
				var headerLines:Array = requestHeader.split(CRLF);
				//Start at 1 since 0 is the status line
				for (var count:uint = 1; count < headerLines.length; count++) {
					var currentHeaderText:String = headerLines[count] as String;					
					var newHeader:HTTPRequestHeader = new HTTPRequestHeader(currentHeaderText);
					if (newHeader.name!="") {
						this._headers.push(newHeader);
					}//if
				}//for
				this.parseRequestCookies(); //Call ONLY after parsing headers since this is where cookies are stored
				return (true);
			} catch (err:*) {
				return (false);
			}//catch
			return (false);
		}//parseRequestHeaders
		
		public function parseRequestBody(rawRequestData:ByteArray):Boolean {			
			if (!this.bodySectionComplete(rawRequestData)) {
				return (false);
			}//if
			try {				
				rawRequestData.position = 0;
				this._body = rawRequestData.readMultiByte(rawRequestData.length, charSet);
				this._rawRequest = this._body;
				var headerEndPos:int = this._body.indexOf(doubleCRLF) + 4;
				var bodyEndPos:int = this._body.lastIndexOf(doubleCRLF);
				var bodyLength:int = bodyEndPos - headerEndPos;	
				if (this.headerSectionComplete(rawRequestData)) {
					var contentLengthHeader:int = -1;
					try { 						
						contentLengthHeader = int(this.getHeader("Content-Length", false).value);
					} catch (err:*) {
						contentLengthHeader = -1;
					}//catch
					if (contentLengthHeader > 0) {
						bodyEndPos = contentLengthHeader + headerEndPos;
					}//if				
				}//if
				this._body = this._body.substring(headerEndPos, bodyEndPos);				
				if (this.responseIsChunked) {					
					this._body = this.parseChunkedBody(this._body);
				}//if				
				return (true);
			} catch (err:*) {
				return (false);
			}//catch
			return (false);
		}//parseRequestBody
		
		public function get responseIsChunked():Boolean {
			try {
				var header:HTTPRequestHeader = this.getHeader("Transfer-Encoding", false);
				if (header == null) {
					return (false);
				}//if
				if (header.value.toLowerCase() == "chunked") {
					return (true);
				}//if			
			} catch (err:*) {
				return (false);
			}//catch
			return (false);
		}//get responseIsChunked
		
		private function parseChunkedBody(chunkedBody:String):String {			
			var assembledBody:String = new String();
			var workingCopy:String = new String(chunkedBody);
			var chunkSection:Object = this.getChunkSection(workingCopy);
			while (chunkSection.size > 0) {
				assembledBody += chunkSection.chunk;
				workingCopy = chunkSection.remainder;			
				chunkSection = this.getChunkSection(workingCopy);				
			}//while		
			return (assembledBody);
		}//parseChunkedBody
		
		private function getChunkSection(chunkedBody:String):Object {
			try {
				//Chunk length header may be variable length...
				var chunkLengthHeader:String = chunkedBody.substr(0, chunkedBody.indexOf(CR));
				chunkLengthHeader = chunkLengthHeader.split(LF)[0] as String; //Make sure to strip possible linefeed
				var chunkHeader:String = "0x" + chunkedBody.substr(0, Number(chunkLengthHeader.length)); //Make it hex				
				var chunkSize:Number = new Number(chunkHeader);								
				var chunkStart:int = chunkHeader.length;
				var chunkEnd:int = chunkStart + chunkSize;			
				var returnData:Object = new Object();
				returnData.chunk = chunkedBody.substring(chunkStart, chunkEnd);
				returnData.chunk = returnData.chunk.substr(0, returnData.chunk.length);				
				returnData.size = chunkSize;
				returnData.original = chunkedBody;
				returnData.remainder = chunkedBody.substring(chunkEnd + CRLF.length);				
			} catch (err:*) {
				returnData = new Object();
				returnData.chunk = null;
				returnData.size = 0;
				returnData.original = chunkedBody;
				returnData.remainder = null;
			}//catch
			return (returnData);
		}//getChunkSection
		
		private function parseRequestCookies():void {
			/*
			if (this.headers == null) {
				return;
			}//if
			if (this.headers.length<1) {
				return;
			}//if
			this._cookies = new Vector.<HTTPCookie>();
			for (var count:uint = 0; count < this.headers.length; count++) {
				var currentHeader:HTTPResponseHeader = this.headers[count];
				if (currentHeader.name.toLowerCase()==cookieSetHeader) {
					var newCookie:HTTPCookie = new HTTPCookie(currentHeader.value);
					if (newCookie.isValid) {
						this._cookies.push(newCookie);
					}//if
				}//if
			}//for
			*/
		}
				
		private function requestLineComplete(rawRequestData:ByteArray):Boolean {
			try {
				rawRequestData.position = 0;
				var requestString:String = rawRequestData.readMultiByte(rawRequestData.length, charSet);
				if (requestString.indexOf(CRLF) > -1) {
					return (true);
				} else {
					return (false);
				}//else
			} catch (err:*) {
				return (false);
			}//catch
			return (false);
		}//requestLineComplete
				
		public function headerSectionComplete(rawRequestData:ByteArray):Boolean {
			try {
				rawRequestData.position = 0;
				var requestString:String = rawRequestData.readMultiByte(rawRequestData.length, charSet);
				if (requestString.indexOf(doubleCRLF) > -1) {
					return (true);
				} else {
					return (false);
				}//else
			} catch (err:*) {
				return (false);
			}//catch
			return (false);
		}//headerSectionComplete
		
		public function bodySectionComplete(rawRequestData:ByteArray):Boolean {
			try {
				rawRequestData.position = 0;
				var requestString:String = rawRequestData.readMultiByte(rawRequestData.length, charSet);
				var indexPos1:int = requestString.indexOf(doubleCRLF);
				var indexPos2:int = requestString.lastIndexOf(doubleCRLF);
				if (indexPos1 != indexPos2) {					
					return (true);
				} else {
					if ((indexPos1 > -1) && (!this.responseIsChunked)) {
						//Body section is empty
						return (true);
					}//if					
					return (false);
				}//else
			} catch (err:*) {				
				return (false);
			}//catch			
			return (false);
		}//bodySectionComplete
		
		public function set rawRequest(requestSet:String):void {
			this._rawRequest = requestSet;
		}
		
		public function get rawRequest():String {
			return (this._rawRequest);
		}
		
		public function get method():String {
			return (this._requestMethod);
		}
		
		public function get resource():String {
			return (this._requestResource);
		}
		
		public function get version():String {
			return (this._HTTPVersion);
		}
		
		public function get headers():Vector.<HTTPRequestHeader> {
			return (this._headers);
		}
		
		public function get variables():URLVariables {
			return (this._variables);
		}//get variables
		
		public function get body():String {
			return (this._body);
		}
		
		public function getHeader(headerName:String, caseSensitive:Boolean=true):HTTPRequestHeader {
			if (this._headers == null) {
				return(null);
			}//if
			if (this._headers.length==0) {
				return(null);
			}//if
			for (var count:uint = 0; count < this._headers.length; count++) {
				var currentHeader:HTTPRequestHeader = this._headers[count];
				if (caseSensitive) {
					if (currentHeader.name == headerName) {
						return(currentHeader);
					}//if
				} else {
					if (currentHeader.name.toLowerCase() == headerName.toLowerCase()) {
						return(currentHeader);
					}//if
				}//else
			}//for
			return (null);
		}//getHeader
		
	}

}