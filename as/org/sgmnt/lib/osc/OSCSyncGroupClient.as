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
		internal var _createTime:Number;
		
		// ------- PUBLIC ---------------------------------------------
		
		/**
		 * @param ip
		 * @param createTime
		 */
		public function OSCSyncGroupClient( ip:String, createTime:Number ):void{
			_ip         = ip;
			_timer      = new Timer( 100000, 1 );
			_stable     = false;
			_createTime = createTime;
		}
		
		/** クライアントの IP アドレス. */
		public function get ip():String{
			return _ip;
		}
		
		/**
		 * このクライアントが安定しているか.
		 * @return 
		 */
		public function get stable():Boolean{
			return _stable;
		}
		
		/** 生存時間を司るタイマー. */
		public function get timer():Timer{
			return _timer;
		}
		
		/** グループの生成時刻. */
		public function get createTime():Number{
			return _createTime;
		}
		
		// ------- PROTECTED ------------------------------------------
		// ------- PRIVATE --------------------------------------------
		// ------- INTERNAL -------------------------------------------
		
	}
	
}