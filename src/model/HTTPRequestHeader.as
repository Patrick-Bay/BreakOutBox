package model {
	
	/**
	 * Handles the data and output of a single HTTP request header.
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
	public class HTTPRequestHeader {
		
		public static const delimiter:String = ":";
		
		private var _name:String = new String();
		private var _value:String = new String();
		
		public function HTTPRequestHeader(rawHeader:String = null) {
			if (rawHeader!=null) {
				this.parseHeader(rawHeader);
			}//if
		}
		
		private function parseHeader(rawHeader:String):void {
			try {
				var delimPos:Number = rawHeader.indexOf(delimiter);
				if (delimPos <= 0) {
					return;
				}//if
				this._name = rawHeader.substring(0, delimPos);
				this._value = rawHeader.substring(delimPos + 1, rawHeader.length);
				//Deal with extra space after delimiter.
				if (this._value.indexOf(" ") == 0) {
					this._value = this._value.substring(1, this._value.length);	
				}//if			
			} catch (err:*) {				
			}
		}
		
		public function get name():String {
			return (this._name);
		}
		
		public function get value():String {
			return (this._value);
		}
		
		public function set name(nameSet:String):void {
			this._name = nameSet;
		}
		
		public function set value(valueSet:String):void {
			this._value = valueSet;
		}
	}

}