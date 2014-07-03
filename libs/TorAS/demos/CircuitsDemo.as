package demos {
				
	import org.torproject.model.TorControlCircuit;
	import org.torproject.model.TorControlCircuitHop;
	import org.torproject.TorControl;
	import org.torproject.events.TorControlEvent;	
	
	/**
	 * Demonstrates how to work with Tor circuits.
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
	public class CircuitsDemo {		
		
		private var _torControl:TorControl = null;
		
		public function CircuitsDemo(torControl:TorControl) {
			trace ("Running CircuitsDemo...");
			_torControl = torControl;
			_torControl.addEventListener(TorControlEvent.TOR_CIRC, this.onTorCIRCMessage);
			_torControl.establishNewCircuit();
		}					
		
		/* PRIVATE */
		private function onTorCIRCMessage(eventObj:TorControlEvent):void {			
			var circuitObj:TorControlCircuit = new TorControlCircuit(eventObj.body);
			trace ("---");
			trace ("Tor CIRC Event");
			trace (" ");
			trace ("Circuit ID: " + circuitObj.ID);
			trace ("Circuit status: " + circuitObj.status);
			trace ("Circuit purpose: " + circuitObj.purpose);
			trace ("Circuit info time stamp: " + circuitObj.timeStamp);
			trace ("Circuit flags: " + circuitObj.flags);
			trace ("Circuit hops: ");
			if (circuitObj.hops!=null) {
				for (var count:uint = 0; count < circuitObj.hops.length; count++) {
					var currentHop:TorControlCircuitHop = circuitObj.hops[count];
					trace ("   Hop name:" + currentHop.name);
					trace ("   Hop address:" + currentHop.address);
				}
			} else {
				trace ("   none");
			}
			trace ("---");			
		}
		
	}

}