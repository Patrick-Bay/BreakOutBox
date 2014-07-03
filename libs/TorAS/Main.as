package  {
		
	import flash.display.MovieClip;	
	import flash.utils.ByteArray;
	import org.torproject.events.TorControlEvent;	
	import org.torproject.TorControl;	
	import demos.HTTPLoadDemo;
	import demos.HTTPSLoadDemo;
	import demos.CircuitsDemo;
	
	/**
	 * Sample class to demonstrate dynamically launching Tor network connectivity using the included
	 * application package within an AIR app. Additional demos are included as separate classes and
	 * can be uncommented below as desired.
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
	public class Main extends MovieClip {
		
		private static var torControl:TorControl = null;		
		
		public function Main() {			
			this.launchTorControl();	
		}			
		
		private function onTorLogMessage(eventObj:TorControlEvent):void {
			trace ("Tor log: " + eventObj.body);
		}
		
		private function launchTorControl():void {
			if (torControl==null) {
				torControl = new TorControl(null, -1, null, -1, "TorControlConnectionPassword"); //Use default connection values and custom connection password
				//We want to listen to .ONAUTHENTICATE since .ONCONNECT only signals that a connection has been established.
				torControl.addEventListener(TorControlEvent.ONLOGMSG, this.onTorLogMessage);
				torControl.addEventListener(TorControlEvent.ONAUTHENTICATE, this.onTorControlReady);
				torControl.connect();
			}//if
		}
						
		private function onTorControlReady(eventObj:TorControlEvent):void {
			trace ("Main.as > TorControl is connected, authenticated, and ready for commands.");			
			//Uncomment the demo(s) that you would like to try...
			//var demo1:HTTPLoadDemo = new HTTPLoadDemo();
			var demo2:HTTPSLoadDemo = new HTTPSLoadDemo();
			//var demo3:CircuitsDemo = new CircuitsDemo(torControl);
			
		}	
		
	}

}