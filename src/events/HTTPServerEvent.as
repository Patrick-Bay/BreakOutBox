package events {
	
	import instances.HTTPServerSession;
	import swag.events.SwagEvent;
		
	/**
	 * Events broadcast by the HTTPServer class.
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
	public class HTTPServerEvent extends SwagEvent {
		
		/**
		 * Dispatched when the HTTPServer instance has been started (has been bound and is listening for new connections).
		 */
		public static const ONSTART:String = "SwagEvent.HTTPServerEvent.ONSTART";		
		/**
		 * Dispatched when the HTTPServer instance has been stop (has been unbound is no longer listening for connections).
		 */
		public static const ONSTOP:String = "SwagEvent.HTTPServerEvent.ONSTOP";	
		/**
		 * Dispatched when a new client connection is established. This may happen many times while HTTPServer is active (after an ONSTART event).
		 */
		public static const ONCONNECT:String = "SwagEvent.HTTPServerEvent.ONCONNECT";		
		/**
		 * Dispatched when a HTTPServer instance is disconnected. The may happen many times within an active HTTPServer instance (after an ONSTART event).
		 */
		public static const ONDISCONNECT:String = "SwagEvent.HTTPServerEvent.ONDISCONNECT";
		
		/**
		 * The session broadcasting a session-related event, or null if this is an ONSTART or ONSTOP event (not session-related).
		 */
		public var session:HTTPServerSession = null;
		
		public function HTTPServerEvent(eventType:String=null) {
			super(eventType);
			
		}
		
	}

}