package swag.events {
	
	import swag.events.SwagEvent;
	import swag.interfaces.events.ISwagLoaderEvent;
	
	/**
	 * 
	 * Event object dispatched from SwagLoader instances via the SwagDispatcher.
	 * 
	 * The MIT License (MIT)
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
	 */
	public class SwagLoaderEvent extends SwagEvent implements ISwagLoaderEvent	{
		
		/**
		 * This event type is dispatched just before the associated <code>SwagLoader</code> object begins
		 * a load or send operation. 
		 */
		public static const START:String="SwagEvent.SwagLoaderEvent.START";
		/**
		 * This event type is dispatched whenever the associated <code>SwagLoader</code> receives or sends data.
		 */
		public static const DATA:String="SwagEvent.SwagLoaderEvent.DATA";
		/**
		 * This event type is dispatched when the associated <code>SwagLoader</code> completes its load or send
		 * operation.
		 * <p>Any loaded data at this point will have been converted to the desired format and may be fully read.</p>
		 */
		public static const COMPLETE:String = "SwagEvent.SwagLoaderEvent.COMPLETE";
		/**
		 * This event type is dispatched when the associated <code>SwagLoader</code> receives header information
		 * as part of the server response.		 
		 */
		public static const HEADER:String = "SwagEvent.SwagLoaderEvent.HEADER";
		
		/*
		 * The following three values store the transfer information for the following up/download.
		 * If no load is active, these values will all default to 0.
		 */
		public var bytesLoaded:Number = 0;
		public var bytesTotal:Number = 0;
		public var bytesPercent:Number = 0;
		public var BPS:Number = 0; //Bytes per second (sampled on ever load progress event)
		public var msecsElapsed:Number = 0;
		public var msecsRemainEst:Number = 0;
		
		/**
		 * The default constructor for the class.
		 *  
		 * @param event Type the event type to set this event object to.
		 * 
		 */
		public function SwagLoaderEvent(eventType:String=null)	{
			super(eventType);
		}//constructor
		
	}//SwagLoaderEvent class
	
}//package