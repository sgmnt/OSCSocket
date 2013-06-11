/**
 *
 * Copyright (c) 2010 - 2013, http://sgmnt.org/
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
	
	import flash.utils.Timer;
	
	/**
	 * グループ内でクライアント一覧を管理する際に扱う
	 * １クライアント分のデータを扱うためのクラス.
	 * @author sgmnt.org
	 */
	internal class OSCSyncGroupClient{
		
		// ------- MEMBER ---------------------------------------------
		
		private var _ip:String;
		private var _timer:Timer;
		
		internal var _stable:Boolean;
		internal var _createdTime:Number;
		
		// ------- PUBLIC ---------------------------------------------
		
		/**
		 * @param ip
		 * @param createdTime
		 */
		public function OSCSyncGroupClient( ip:String, createdTime:Number ):void{
			_ip          = ip;
			_timer       = new Timer( 10000, 1 );
			_stable      = false;
			_createdTime = createdTime;
		}
		
		/** クライアントの IP アドレス. */
		public function get ip():String{
			return _ip;
		}
		
		/**
		 * このクライアントが同期処理対象として決定されているか.
		 * OSCSyncGroup がこのクライアントを同期対象に含めるかはこの値をもって決定される.
		 * @return 
		 */
		public function get stable():Boolean{
			return _stable;
		}
		
		/**
		 * 生存時間を司るタイマー.
		 * このタイマーが TIMER_COMPLETE した場合はクライアント保持期限が過ぎた事となる.
		 * 延長する場合にはこのタイマーを reset() start() してください.
		 */
		public function get timer():Timer{
			return _timer;
		}
		
		/** グループの生成時刻. */
		public function get createdTime():Number{
			return _createdTime;
		}
		
		// ------- PROTECTED ------------------------------------------
		// ------- PRIVATE --------------------------------------------
		// ------- INTERNAL -------------------------------------------
		
	}
	
}