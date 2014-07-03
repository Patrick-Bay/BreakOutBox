package swag.events {
	
	/**
	 * Event object dispatched from SQLiteDatabase instances via the SwagDispatcher.
	 *  
	 * @author Patrick Bay
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
	 * 
	 */
	import flash.data.SQLResult;
	public class SQLiteDatabaseEvent extends SwagEvent {
		
		/**
		 * Dispatched when a database query responds with a result. 
		 */
		public static const ONRESULT:String="SwagEvent.SQLiteDatabaseEvent.ONRESULT";		
		
		/**
		 * Contains the result of the query for which the event was broadcast, or <em>null</em> otherwise. 
		 */
		public var result:SQLResult=null;
		/**
		 * All the updated rows that the query affected (same as the <code>result.data</code> property), or <em>null</em> if no rows were affected.
		 */
		public var resultRows:Array=null;
		/**
		 * The number of rows in the returned <code>resultRows</code> array, or 0 if no rows are included. 
		 */
		public var numRows:uint=0;
		/**
		 * The number of rows that were changed or affected by the query. This number will only be greated than 0 if a query such as
		 * INSERT, UPDATE, or DELETE was used. 
		 */
		public var numRowsChanged:uint=0;
		
		public function SQLiteDatabaseEvent(eventType:String=null) {
			super(eventType);
		}//constructor
		
	}//SQLiteDatabaseEvent class
	
}//package