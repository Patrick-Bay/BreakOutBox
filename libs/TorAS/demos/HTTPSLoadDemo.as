package demos {
			
	import flash.net.URLVariables;
	import org.torproject.events.TorControlEvent;
	import org.torproject.model.HTTPResponseHeader;
	import org.torproject.TorControl;
	import org.torproject.events.SOCKS5TunnelEvent
	import org.torproject.SOCKS5Tunnel;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	
	/**
	 * Demonstrates how to use make a HTTPS (TLS / SSL) request using Tor.
	 * 
	 * @author Patrick Bay
	 * 
	 * The MIT License (MIT)
	 * 
	 * Copyright (c) 2013 Patrick Bay
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
	 */
	public class HTTPSLoadDemo {
				
		private var tunnel:SOCKS5Tunnel = null;		
		
		public function HTTPSLoadDemo() {
			trace ("Running HTTPSLoadDemo...");
			this.sendHTTPRequest();	
		}					
						
		private function onHTTPResponse(eventObj:SOCKS5TunnelEvent):void {
			trace ("--------------------------------------------------------");
			trace ("Loaded via Tor: ");
			trace(" ");
			trace ("STATUS: " + eventObj.httpResponse.statusCode + " " + eventObj.httpResponse.status);
			trace(" ");
			trace ("HEADERS: ");
			trace(" ");
			if (eventObj.httpResponse.headers!=null) {
				for (var count:uint = 0; count < eventObj.httpResponse.headers.length; count++) {
					var httpHeader:HTTPResponseHeader = eventObj.httpResponse.headers[count];
					trace (httpHeader.name + ": " + httpHeader.value);
				}//for
			} else {
				trace ("No response headers -- either a bad response or a severe error.");
			}
			trace(" ");			
			trace ("RESPONSE BODY: ");
			trace(" ");
			trace (eventObj.httpResponse.body);		
			trace ("--------------------------------------------------------");			
		}
		
		/* PRIVATE */
		private function onHTTPRedirect(eventObj:SOCKS5TunnelEvent):void {
			trace ("Received HTTP redirect error " + eventObj.httpResponse.statusCode);
			trace ("Redirecting to: " + SOCKS5Tunnel(eventObj.target).activeRequest.url);			
			var headers:Vector.<HTTPResponseHeader> = eventObj.httpResponse.headers;
			trace ("HEADERS >>>");
			for (var count:uint = 0; count < headers.length; count++) {
				trace (headers[count].name + ": " + headers[count].value);
			}
		}
		
		/* PRIVATE */
		private function onSOCKS5TunnelDisconnect(eventObj:SOCKS5TunnelEvent):void {
			trace ("SOCKS5 tunnel disconnected.");		
		}		
				
		/* PRIVATE */
		private function sendHTTPRequest():void {
			//Create an anonymous tunnel connection for streaming HTTP requests through Tor...
			this.tunnel = new SOCKS5Tunnel();
			//Use a known HTTPS URL for testing...
			var proxyRequest:URLRequest = new URLRequest("https://msp.f-secure.com/web-test/common/test.html");
			//Create some variables to send with the request...			
			this.tunnel.addEventListener(SOCKS5TunnelEvent.ONHTTPRESPONSE, this.onHTTPResponse);			
			this.tunnel.addEventListener(SOCKS5TunnelEvent.ONHTTPREDIRECT, this.onHTTPRedirect);
			this.tunnel.addEventListener(SOCKS5TunnelEvent.ONDISCONNECT, this.onSOCKS5TunnelDisconnect);
			this.tunnel.loadHTTP(proxyRequest);			
		}	
		
	}

}