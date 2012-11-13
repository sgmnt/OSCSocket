/**
 *
 * Copyright (c) 2010 - 2012, http://sgmnt.org/
 * 
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 */
package org.sgmnt.lib.osc{
	
	import flash.utils.ByteArray;
	
	/**
	 * OSC メッセージを解析する機能を提供します.
	 * @author    sgmnt.org
	 * @version    0.1
	 */
	public class OSCPacketParser{
		
		public function OSCPacketParser( pvtClass:PrivateClass ){}
		
		/**
		 * OSC の ByteArray を解析して, { address, values } のオブジェクトにして返します.
		 * @param bytes
		 * @return 
		 */
		public static function parse( bytes:ByteArray ):Object{
			
			var key:String,
				p:int,
				offset:int,
				type:String,
				address:String,
				types:String,
				values:Array;
			
			key = new Date().time + "_" + Math.random();
			
			bytes.position = 0;
			
			// Read Address.
			
			offset = 3;
			while ( bytes[offset] != 0 && offset + 4 < bytes.length ) offset += 4;
			address = bytes.readUTFBytes( offset+1 );
			
			// Read Types.
			
			p = bytes.position;
			offset = 3;
			while ( bytes[p + offset] != 0 && p + offset + 4 < bytes.length ) offset += 4;
			types = bytes.readUTFBytes( offset+1 );
			
			// Read Values.
			
			values = [];
			for ( var i:int = 0, len:int = types.length - 1; i < len; i++ ) {
				type = types.charAt(i + 1).toLowerCase();
				if ( type === "f" ) {
					values[i] = bytes.readFloat();
				}else if( type === "i" ){
					values[i] = bytes.readInt();
				}else if( type === "d" ){
					values[i] = bytes.readDouble();
				}else if( type === "b" ){
					values[i] = bytes.readObject();
					bytes.position += 4 - bytes.position % 4;
				}else if ( type === "s" ) {
					p = bytes.position;
					offset = 3;
					while ( bytes[p + offset] != 0 && p + offset + 4 < bytes.length ) offset += 4;
					values[i] = bytes.readUTFBytes( offset+1 );
				}
			}
			
			return {
				"address"    : address,
				"values"     : values
			}
			
		}
		
	}
	
}

class PrivateClass{}