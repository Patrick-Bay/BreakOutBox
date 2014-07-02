package instances 
{
	import events.HTTPServerEvent;
	import events.HTTPServerSessionEvent;
	import flash.net.ServerSocket;
	import flash.net.Socket;
	import flash.events.ServerSocketConnectEvent;	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import swag.core.SwagDispatcher;
	
	/**
	 * Provides a basic HTTP server on the specified address/port.
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
	public class HTTPServer {
				
		public static const protocolVersion:String = "HTTP/1.1";
		private var _serverSocket:ServerSocket = null;
		private var _socketListenAddress:String = "";
		private var _socketListenPort:int = -1;		
		
		public function HTTPServer(listenAddress:String = "", listenPort:int = -1) 		{
			super();
			this._socketListenAddress = listenAddress;
			this._socketListenPort = listenPort;
			if ((listenAddress == "") || (listenPort < 0)) {
				return;
			}//if
			this.start();					
		}//constructor
		
		public function set listenAddress(addressSet:String):void {
			this._socketListenAddress = addressSet;
		}//set listenAddress
		
		public function set listenPort(portSet:int):void {
			this._socketListenPort = portSet;
		}//set listenPort
		
		public function get listenAddress():String {
			return (this._socketListenAddress);
		}//get listenAddress
		
		public function get listenPort():int {
			return (this._socketListenPort);
		}//get listenPort
				
		/**
		 * Start the server socket (all initialization data must be set at this point).
		 * 
		 * @return True if the server socket listener could be started properly, false otherwise.
		 */
		public function start():Boolean {
			try {
				if (ServerSocket.isSupported == true) {				
					this._serverSocket = new ServerSocket();
					this._serverSocket.bind(this.listenPort, this.listenAddress);
					this.addSocketListeners();
					this._serverSocket.listen();
					var startEvent:HTTPServerEvent = new HTTPServerEvent(HTTPServerEvent.ONSTART);					
					SwagDispatcher.dispatchEvent(startEvent, this);
					return (true);
				}//if
			} catch (err:*) {				
			}//catch
			return (false);
		}//start
		
		private function addSocketListeners():void {
			if (this._serverSocket!=null) {
				this._serverSocket.addEventListener(ServerSocketConnectEvent.CONNECT, this.onServerSocketConnect);
				this._serverSocket.addEventListener(Event.CLOSE, this.onServerSocketDisconnect);
			}//if			
		}//addSocketListeners
				
		private function removeSocketListeners():void {
			if (_serverSocket!=null) {
				this._serverSocket.removeEventListener(ServerSocketConnectEvent.CONNECT, this.onServerSocketConnect);
				this._serverSocket.removeEventListener(Event.CLOSE, this.onServerSocketDisconnect);
			}//if	
		}//removeSocketListeners		
		
		public function onSessionDisconnect(eventObj:HTTPServerSessionEvent):void {		
		}//onSessionDisconnect		
		
		private function onServerSocketDisconnect(eventObj:Event):void {			
			this.removeSocketListeners();
			this._serverSocket = null;
			this._socketListenAddress = null;
			this._socketListenPort = -1;
			var stopEvent:HTTPServerEvent = new HTTPServerEvent(HTTPServerEvent.ONSTOP);			
			SwagDispatcher.dispatchEvent(stopEvent, this);
		}//onServerSocketDisconnect
		
		private function onServerSocketConnect(eventObj:ServerSocketConnectEvent):void {
			var session:HTTPServerSession = HTTPServerSession.getSessionBySocket(eventObj.socket);
			//if (session==null) {
				session = new HTTPServerSession(eventObj.socket, this);			
				SwagDispatcher.addEventListener(HTTPServerSessionEvent.ONDISCONNECT, this.onSessionDisconnect, this, session);
			//}//if
			Debug.print ("*** Server socket connection established...");
			var connectEvent:HTTPServerEvent = new HTTPServerEvent(HTTPServerEvent.ONCONNECT);
			connectEvent.session = session;
			SwagDispatcher.dispatchEvent(connectEvent, this);
		}//onServerSocketConnect
		
	}//HTTPServer class

}//package