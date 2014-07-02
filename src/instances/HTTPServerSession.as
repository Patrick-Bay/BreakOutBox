package instances {
		
	import flash.net.Socket;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.utils.ByteArray;
	import model.HTTPRequestHeader;
	import References;
	import Settings;
	import swag.core.SwagDataTools;
	import swag.core.SwagDispatcher;
	import events.HTTPServerSessionEvent;
	import model.HTTPRequest;

	
	/**
	 *
	 * A (very) basic HTTP server socket implementation. 
	 * Note that a single session must be able to support multiple requests and responses.
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
	public class HTTPServerSession extends Socket {
		
		public static const CR:String = String.fromCharCode(13);	
		public static const LF:String = String.fromCharCode(10);	
		public static const CRLF:String = CR + LF;	
		public static const doubleCRLF:String = CRLF + CRLF;	
		public static const SPACE:String = String.fromCharCode(32);	
		public static const charSet:String = "iso-8859-1";	
				
		private var _serverInstance:HTTPServer = null;
		private var _socket:Socket = null;
		private var _requestLineParsed:Boolean = false;
		private var _requestHeadersParsed:Boolean = false;
		private var _requestBodyParsed:Boolean = false;
		private var _request:HTTPRequest = null;		
		private var _requestBuffer:ByteArray = null;
		private static var _sessions:Vector.<HTTPServerSession> = new Vector.<HTTPServerSession>();	
		private var _responseSent:Boolean = false;
		
		/**
		 * Creates a HTTPServerSession instance and binds it to an existing socket.
		 * 
		 * @param	sourceSocket
		 */
		public function HTTPServerSession (sourceSocket:Socket, parentServer:HTTPServer=null) {
			if (!this.sessionExists) {				
				this._socket = sourceSocket;
				this._serverInstance = parentServer;
				this.addCurrentSession();
				this.setDefaults();
				Debug.print ("HTTPServerSession instance #"+this.sessionIndex+" created.");
			} else {
				Debug.print ("HTTPServerSession instance not created, socket isn't unique.");
			}//else			
		}//constructor
		
		private function onSocketData(eventObj:ProgressEvent):void {
			Debug.print("onSocket data for sesssion: " + this.sessionIndex);			
			var dataEvent:HTTPServerSessionEvent = new HTTPServerSessionEvent(HTTPServerSessionEvent.ONDATA);					
			this._socket.readBytes(this._requestBuffer, this._requestBuffer.length);
			this._request.rawRequest = this._requestBuffer.readMultiByte(this._requestBuffer.bytesAvailable, charSet);			
			dataEvent.request = this._request;			
			SwagDispatcher.dispatchEvent(dataEvent, this);
			if (!this._requestLineParsed) {
				if (this._request.parseRequestLine(this._requestBuffer)) {					
					this._requestLineParsed = true;
					var sessionEvent:HTTPServerSessionEvent = new HTTPServerSessionEvent(HTTPServerSessionEvent.ONREQUESTHEADER);
					sessionEvent.request = this._request;
					SwagDispatcher.dispatchEvent(sessionEvent, this);
				} else {
					return;
				}//else
			}//if
			if (!this._requestHeadersParsed) {
				if (this._request.parseRequestHeaders(this._requestBuffer)) {					
					this._requestHeadersParsed = true;
					sessionEvent = new HTTPServerSessionEvent(HTTPServerSessionEvent.ONHEADERS);
					sessionEvent.request = this._request;
					SwagDispatcher.dispatchEvent(sessionEvent, this);
				} else {
					return;
				}//else
			}//if
			if (!this._requestBodyParsed) {
				if (this._request.parseRequestBody(this._requestBuffer)) {				
					this._requestBodyParsed = true;
					//Do we need another event for the body?					
				} else {
					return;
				}//else
			}//if				
			Debug.print("Session " + this.sessionIndex + " broadcasting ONREQUEST completion event.");
			sessionEvent = new HTTPServerSessionEvent(HTTPServerSessionEvent.ONREQUEST);
			sessionEvent.request = this._request;
			SwagDispatcher.dispatchEvent(sessionEvent, this);						
		}//onSocketData
		
		public function respond(responseCode:int = 200, rawData:*= null, contentType:String = null, headers:Vector.<HTTPRequestHeader> = null):Boolean {			
			if (this._socket == null) {					
				return (false);
			}//if
			if (!this._socket.connected) {								
				return (false);
			}//if			
			var sendString:String = this.createHTTPResponse(responseCode, rawData, contentType, headers);
			Debug.print("Responding with: " + sendString);
			this._socket.writeMultiByte(sendString, charSet);
			this._socket.flush();
			this._requestBuffer = new ByteArray();	
			this._request = new HTTPRequest();
			this._requestHeadersParsed = false;
			this._requestLineParsed = false;
			this._requestHeadersParsed = false;		
			return (true);
		}//respond
		
		private function responseStatusString(responseCode:int):String {
			//There is a better way to do this...
			switch (responseCode) {
				case 200: return ("OK");
						  break;
				case 400: return ("ERROR");
						  break;
				case 404: return ("NOT FOUND");
						  break;
				case 500: return ("ERROR");
						  break;
				default: return ("");
						 break;
			}//switch
			return ("");
		}//responseStatusString
		
		/**
		 *       Status-Code    =
            "100"  ; Section 10.1.1: Continue
          | "101"  ; Section 10.1.2: Switching Protocols
          | "200"  ; Section 10.2.1: OK
          | "201"  ; Section 10.2.2: Created
          | "202"  ; Section 10.2.3: Accepted
          | "203"  ; Section 10.2.4: Non-Authoritative Information
          | "204"  ; Section 10.2.5: No Content
          | "205"  ; Section 10.2.6: Reset Content
          | "206"  ; Section 10.2.7: Partial Content
          | "300"  ; Section 10.3.1: Multiple Choices
          | "301"  ; Section 10.3.2: Moved Permanently
          | "302"  ; Section 10.3.3: Found
          | "303"  ; Section 10.3.4: See Other
          | "304"  ; Section 10.3.5: Not Modified
          | "305"  ; Section 10.3.6: Use Proxy
          | "307"  ; Section 10.3.8: Temporary Redirect
          | "400"  ; Section 10.4.1: Bad Request
          | "401"  ; Section 10.4.2: Unauthorized
          | "402"  ; Section 10.4.3: Payment Required
          | "403"  ; Section 10.4.4: Forbidden
          | "404"  ; Section 10.4.5: Not Found
          | "405"  ; Section 10.4.6: Method Not Allowed
          | "406"  ; Section 10.4.7: Not Acceptable
          | "407"  ; Section 10.4.8: Proxy Authentication Required
          | "408"  ; Section 10.4.9: Request Time-out
          | "409"  ; Section 10.4.10: Conflict
          | "410"  ; Section 10.4.11: Gone
          | "411"  ; Section 10.4.12: Length Required
          | "412"  ; Section 10.4.13: Precondition Failed
          | "413"  ; Section 10.4.14: Request Entity Too Large
          | "414"  ; Section 10.4.15: Request-URI Too Large
          | "415"  ; Section 10.4.16: Unsupported Media Type
          | "416"  ; Section 10.4.17: Requested range not satisfiable
          | "417"  ; Section 10.4.18: Expectation Failed
          | "500"  ; Section 10.5.1: Internal Server Error
          | "501"  ; Section 10.5.2: Not Implemented
          | "502"  ; Section 10.5.3: Bad Gateway
          | "503"  ; Section 10.5.4: Service Unavailable
          | "504"  ; Section 10.5.5: Gateway Time-out
          | "505"  ; Section 10.5.6: HTTP Version not supported
          | extension-code
		  */
		private function createHTTPResponse(responseCode:int = 200, rawData:*= null, contentType:String = null, headers:Vector.<HTTPRequestHeader> = null):String {						
			//Request begin
			var returnString:String = new String();
			//GET data			
			returnString = HTTPServer.protocolVersion + SPACE + String(responseCode) + SPACE+ this.responseStatusString(responseCode) + CRLF;			
			//Headers
			returnString += "Server: " + Settings.getSetting("server", "serverUserAgent") + CRLF;		
			returnString += "Accept-Ranges: bytes" + CRLF;			
			returnString += "Connection: keep-alive" + CRLF;			
			//Cookies
			//if (request.manageCookies) {
				//returnString += appendHeaderCookies(cookies);		
			//}//if			
			if (headers!=null) {
				for (var count:uint = 0; count < headers.length; count++) {
					var currentHeader:HTTPRequestHeader = headers[count] as HTTPRequestHeader;
					returnString += currentHeader.name + ": " + currentHeader.value + CRLF;
				}//for
			}//if
			//POST data
			if (rawData != null) {	
				var dataStr:String = this.toDataString(rawData);
				returnString += "Content-Type: " + this.contentEncodingType(rawData, contentType) + CRLF;
				returnString += "Content-Length: " + String(rawData.length) + CRLF; //bytes		
				returnString +=  CRLF + rawData;				
			} else {			
				returnString += doubleCRLF;		
			}//else			
			return (returnString);		
		}
		
		private function contentEncodingType(data:*, definedType:String = null):String {
			if (definedType != null) {
				return (definedType);
			}//if
			if ((data is XML) || (data is XMLList)) {
				return ("application/xml");
			}//if
			//Other types to be implemented for binary, XML, etc.	
			return ("application/x-www-form-urlencoded");			
		}//contentEncodingType
		
		private function toDataString(data:*):String {
			if (data==null) {
				return ("");
			}//if
			if (data is String) {
				return (data);
			}//if
			if (data is Boolean) {
				if (data) {
					return ("1");
				} else {
					return ("0");
				}//else
			}//if
			if ((data is Number) || (data is int) || (data is uint)) {
				return (String(data));
			}//if
			if ((data is XML) || (data is XMLList)) {				
				return (XML(data).toXMLString());
			}//if
			if (data is ByteArray) {
				ByteArray(data).position = 0;
				return (ByteArray(data).readMultiByte(ByteArray(data).bytesAvailable, charSet));
			}//if
			return ("");
		}//toDataString
		
		public function get server():HTTPServer {
			return (this._serverInstance);
		}
		
		private function onSocketClose(eventObj:Event):void {
			Debug.print("Session #" + this.sessionIndex + " closed.\n");
			this._socket = null;			
		}//onSocketClose

		private function onIOError(eventObj:IOErrorEvent):void {
			Debug.print("IO error on session #" + this.sessionIndex + ":\n" + eventObj.toString());
			this._socket = null;
		}//onIOError
		
		public function get sessionIndex():int {
			for (var count:uint = 0; count < _sessions.length; count++) {
				var currentSession:HTTPServerSession = _sessions[count] as HTTPServerSession;
				if (currentSession == this) {
					return (int(count));
				}//if
			}//for
			return ( -1);
		}//get sessionIndex
		
		public function get sessionSocket():Socket {
			return (this._socket);
		}//get sessionSocket		
		
		public static function getSessionBySocket (sourceSocket:Socket):HTTPServerSession {
			for (var count:uint = 0; count < _sessions.length; count++) {				
				var currentSession:HTTPServerSession = _sessions[count] as HTTPServerSession;
				try {
					if (currentSession.sessionSocket == sourceSocket) {
						return (currentSession);
					}//if
					if ((currentSession.sessionSocket.localAddress == sourceSocket.localAddress) && (currentSession.sessionSocket.localPort == sourceSocket.localPort)) {
						//Different socket instances can communicate with the same address/port!
						return (currentSession);
					}//if
				} catch (err:*) {				
				}//catch
			}//for			
			return (null);
		}//getSessionBySocket
		
		private function get sessionExists():Boolean {
			for (var count:uint = 0; count < _sessions.length; count++) {
				var currentSession:HTTPServerSession = _sessions[count] as HTTPServerSession;
				if (currentSession == this) {
					return (true);
				}//if
			}//for
			return (false);
		}//get sessionExists
		
		private function addCurrentSession():void {
			_sessions.push(this);
		}//addCurrentSession
		
		private function clearCurrentSession():void {
			var newSessionsVect:Vector.<HTTPServerSession> = new Vector.<HTTPServerSession>();
			for (var count:uint = 0; count < _sessions.length; count++) {
				var currentSession:HTTPServerSession = _sessions[count] as HTTPServerSession;
				if (currentSession != this) {
					newSessionsVect.push(currentSession);
				}//if
			}//for
			_sessions = newSessionsVect;
		}//clearCurrentSession
		
		private function setDefaults():void {						
			this._requestBuffer = new ByteArray();	
			this._request = new HTTPRequest();
			this._requestLineParsed = false;
			this._requestHeadersParsed = false;			
			this._socket.addEventListener(ProgressEvent.SOCKET_DATA, this.onSocketData); 
			this._socket.addEventListener(Event.CLOSE, this.onSocketClose ); 
			this._socket.addEventListener(IOErrorEvent.IO_ERROR, this.onIOError );
		}//setDefaults
		
		public function destroy():void {
			this._socket.removeEventListener( ProgressEvent.SOCKET_DATA, this.onSocketData); 
			this._socket.removeEventListener( Event.CLOSE, this.onSocketClose ); 
			this._socket.removeEventListener( IOErrorEvent.IO_ERROR, this.onIOError );
			this._socket.close();
			this.clearCurrentSession();
		}//destroy
		
	}//HTTPServerSession class

}//package