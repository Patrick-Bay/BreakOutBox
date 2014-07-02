package  {
	
	import References;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	/**
	 * Centralized debugging message module.
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
	public final class Debug {
		
		private static var _output:TextField = null;
		private static var _format:TextFormat;
		private static var _buffer:Vector.<String> = new Vector.<String>();
		public static var enableStageDisplay:Boolean = false;
		
		public static function print(msg:*, clearField:Boolean = false):void {		
			trace (msg);
			_buffer.push(msg);			
			if ((References.main == null) || (enableStageDisplay==false)) {
				return;
			}//if		
			if (_output==null) {
				_output = new TextField();
				_output.mouseWheelEnabled = true;
				References.main.addChild(_output);
				_format = new TextFormat();
				_format.font = "_sans";
				_format.size = 18;
				_output.setTextFormat(_format);
				_output.width = References.main.stage.stageWidth;
				_output.height = References.main.stage.stageHeight;
			}//if				
			try {
				_output.setTextFormat(_format);
				if (!clearField) {
					_output.appendText(msg + "\n");			
				} else {
					_output.text = msg + "\n";
				}
				_output.setTextFormat(_format);
			} catch (err:*) {
			}
		}
		
		public static function get buffer():Vector.<String> {
			return (_buffer);
		}
		
		
	}

}