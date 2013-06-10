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
	
	import flash.events.Event;
	
	/**
	 * OSCSyncGroup で使われるイベントクラスです。
	 * @author    sgmnt.org
	 * @version   0.1.1
	 */
	public class OSCSyncGroupEvent extends Event{
		
		// ------- MEMBER ---------------------------------------------
		
		/** Group の同期対象が確定し処理実行可能と判断された際に通知される. */
		public static const STABLED:String    = "_OscSyncGroupStabled";
		/** Group のメンバーが変化したりホストが失われたりした際に通知される. */
		public static const UNSTABLED:String  = "_OscSyncGroupUnstabled";
		
		/** Group に IP が追加された際に通知される. */
		public static const ADDED:String        = "_OscSyncGroupAdded";
		/** Group から IP が削除された際に通知される. */
		public static const REMOVED:String      = "_OscSyncGroupRemoved";
		
		/** Group が新しいプロセス開始を許可したタイミングで通知される. */
		public static const NEW_PROCESS_BEGIN_ENABLED:String = "_OscSyncGroupNewProcessBeginEnabled";
		
		/** Group に登録されている IP のリストでホスト IP の変更があった場合の処理. */
		public static const HOST_CHANGED:String = "_OscSyncGroupHostChanged";
		
		internal var _ip:String;
		
		// ------- PUBLIC ---------------------------------------------
		
		public function OSCSyncGroupEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false){
			super(type, bubbles, cancelable);
		}
		
		public override function clone():Event {
			return new OSCSyncGroupEvent( type, bubbles, cancelable );
		}
		
		public override function toString():String { 
			return formatToString("OSCSyncManagerGroupEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
		public function get ip():String{
			return _ip;
		}
		
		// ------- PROTECTED ------------------------------------------
		// ------- PRIVATE --------------------------------------------
		// ------- INTERNAL -------------------------------------------
		
	}
}