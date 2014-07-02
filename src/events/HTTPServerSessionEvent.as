package events 
{
	import model.HTTPRequest;
	import swag.events.SwagEvent;
	
	/**
	 * Events broadcast by the HTTPServerSession class.
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
	public class HTTPServerSessionEvent extends SwagEvent {
		
		/**
		 * Dispatched when the server session has received some data on the server socket.
		 */
		public static const ONDATA:String = "SwagEvent.HTTPServerSessionEvent.ONDATA";
		/**
		 * Dispatched when the server has received information to parse the HTTP request line header (GET, POST, etc.)
		 */
		public static const ONREQUESTHEADER:String = "SwagEvent.HTTPServerSessionEvent.ONREQUESTHEADER";
		/**
		 * Dispatched when the server has received information to parse the HTTP request headers (typically dispatched after ONREQUESTHEADER).
		 */
		public static const ONHEADERS:String = "SwagEvent.HTTPServerSessionEvent.ONHEADERS";
		/**
		 * Dispatched when the server has received a complete HTTP request (including request line, headers, and body).
		 */
		public static const ONREQUEST:String = "SwagEvent.HTTPServerSessionEvent.ONREQUEST";
		/**
		 * Dispatched when a new server session has connected.
		 */
		public static const ONCONNECT:String = "SwagEvent.HTTPServerSessionEvent.ONCONNECT";		
		/**
		 * Dispatched when the server session socket has closed.
		 */
		public static const ONDISCONNECT:String = "SwagEvent.HTTPServerSessionEvent.ONDISCONNECT";
		
		public var request:HTTPRequest = null;
		
		public function HTTPServerSessionEvent(eventType:String=null) 
		{
			super(eventType);
			
		}
		
	}

}