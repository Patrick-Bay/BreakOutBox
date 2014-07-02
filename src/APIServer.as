package  {
	
	import Debug;	
	import model.HTTPRequest;
	import model.HTTPRequestHeader;
	import References;
	import Settings;
	import instances.HTTPServer;
	import instances.HTTPServerSession;
	import swag.core.SwagDispatcher;
	import events.HTTPServerEvent;
	import events.HTTPServerSessionEvent;
	
	/**
	 * JavaScript API server to facilitate communication with most desktop & mobile
	 * browsers (for example, to control the Tor instance using a JavaScript app
	 * when running alongside BreakOutBox).
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
	public class APIServer {		
		
		private var _server:HTTPServer = null;
		private var _socketListenAddress:String = "";
		private var _socketListenPort:int = -1;		
				
		[Embed(source = "../js/BOBHostAPI.js",mimeType = "application/octet-stream")]
		public var hostAPI_JS:Class;		
		[Embed(source = "../js/jquery-2.0.3.min.js",mimeType = "application/octet-stream")]
		public var jQuery_JS:Class;		
		
		public function APIServer (listenAddress:String = "", listenPort:int = -1) {			
			this._socketListenAddress = listenAddress;
			this._socketListenPort = listenPort;
			if ((listenAddress == "") || (listenPort < 0)) {
				return;
			}//if
			this.start();
		}
		
		public function onSessionConnect(eventObj:HTTPServerEvent):void {
			var session:HTTPServerSession = eventObj.session;			
			SwagDispatcher.addEventListener(HTTPServerSessionEvent.ONREQUEST, this.onSessionData, this, session);
		}//onSessionConnect
		
		public function onSessionDisconnect(eventObj:HTTPServerEvent):void {
			var session:HTTPServerSession = eventObj.session;			
			SwagDispatcher.removeEventListener(HTTPServerSessionEvent.ONREQUEST, this.onSessionData, session);
		}//onSessionConnect
		
		public function onSessionData(eventObj:HTTPServerSessionEvent):void {					
			try {
				var activeSession:HTTPServerSession = eventObj.source as HTTPServerSession;
				var resource:String = eventObj.request.resource;								
				resource = resource.split("?")[0] as String; //Remove trailing URL variables, if supplied...				
				this.invokeResource(resource, activeSession, eventObj.request);
			} catch (err:*) {				
			}//catch			
		}//onSessionData
		
		private function invokeResource(resource:String = null, targetSession:HTTPServerSession = null, request:HTTPRequest=null):void {
			if ((resource == null) || (targetSession == null)) {
				return;
			}//if			
			Debug.print ("---------------------------------------");
			Debug.print("Got request for resource: " + resource);			
			Debug.print("Session #" + targetSession.sessionIndex);			
			Debug.print("Request body: " + request.body);			
			Debug.print("Request variables: " + request.variables);			
			Debug.print("Raw body: " + request.rawRequest);
			Debug.print("\n\n\n---");
			try {
				var origin:HTTPRequestHeader = request.getHeader("Origin");				
				if (origin==null) {
					origin = request.getHeader("Referer");	
				}//if
				if (origin != null) {
					//Add origin to response if supplied in request, otherwise sender won't receive any data.
					var responseHeaders:Vector.<HTTPRequestHeader> = new Vector.<HTTPRequestHeader>();
					var originHeader:HTTPRequestHeader = new HTTPRequestHeader();
					originHeader.name = "Access-Control-Allow-Origin";
					originHeader.value = origin.value;					
					responseHeaders.push(originHeader);
				} else {
					responseHeaders = null;
				}//else
			} catch (err:*) {
				responseHeaders = null;
			}//catch
			Debug.print ("Now responding to: " + resource);
			//var JSONP_callback:String=request.
			//Content type (second parameter) is used by jQuery to determine how data should be handled. For example, "application/javascript" causes the
			//response to be treated as JavaScript and is interpreted as such.
			switch (resource) {
				case "/" : targetSession.respond(200, this.hostRootHTMLPage, "text/html", responseHeaders);
					break;
				case "/API" : targetSession.respond(200, this.hostJavaScriptAPI(true), "application/javascript", responseHeaders);
					break;
				case "/API_min" : targetSession.respond(200, this.hostJavaScriptAPI(false), "application/javascript", responseHeaders);
					break;
				case "/test" : 
					//Note that the response is a standard JavaScript call (how _box.response is set on the client). This seems to be the most reliable way
					//to get data to the client as all other jqXHR objects properties are often invalid, undefined, or null.
					targetSession.respond(200, "_box.response=\"hello!\";", "application/javascript", responseHeaders);
					break;
				default : break;
			}//switch
			Debug.print ("---------------------------------------");
		}
		
		public function start():void {
			this._server = new HTTPServer();
			this._server.listenAddress = this._socketListenAddress;
			this._server.listenPort = this._socketListenPort;			
			//Only deal with complete requests at this time...
			SwagDispatcher.addEventListener(HTTPServerEvent.ONCONNECT, this.onSessionConnect, this, this._server);
			SwagDispatcher.addEventListener(HTTPServerEvent.ONDISCONNECT, this.onSessionDisconnect, this, this._server);
			this._server.start();
		}//start
		
		public function get hostRootHTMLPage():String {
			return ("");
			/*
			var html:*= new htmlSource();
			var pageHTML:String = new String(html);			
			pageHTML = pageHTML.split("%host%").join(Settings.getSettingData("server", "localAddress"));
			pageHTML = pageHTML.split("%port%").join(Settings.getSettingData("server", "localPort"));
			return (pageHTML);
			*/
		}
		
		public function hostJavaScriptAPI(full:Boolean = true):String {
			var jsSourceString:String = new String();
			var js:*= new hostAPI_JS();
			var APIJSString:String = new String(js);			
			//Replace any meta tags here so that the API can be uses as-is...
			APIJSString = APIJSString.split("%host%").join(Settings.getSettingData("server", "localAddress"));
			APIJSString = APIJSString.split("%port%").join(Settings.getSettingData("server", "localPort"));
			if (full) {
				//Put jQuery first (if using full API) since API makes use of it...
				js = new jQuery_JS();
				var jQueryJSString:String = new String(js);
				jsSourceString = jQueryJSString;
			}//if
			jsSourceString += APIJSString;			
			return (jsSourceString);
		}
		
	}

}