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
	 * OSCSyncManagerGroup で使われるイベントクラスです。
	 * @author    sgmnt.org
	 * @version   0.1.1
	 */
	public class OSCSyncManagerGroupEvent extends Event{
		
		// ------- MEMBER ---------------------------------------------
		
		/** Group に IP が追加された際に通知される. */
		public static const ADDED:String        = "_OscSyncManagerGroupAdded";
		/** Group から IP が削除された際に通知される. */
		public static const REMOVED:String      = "_OscSyncManagerGroupRemoved";
		/** Group への IP 追加が見送られた際に通知される. */
		public static const ADD_PENDING:String      = "_OscSyncManagerGroupPending";
		/** Group のアクティベーション完了時に通知される. */
		public static const ACTIVATED:String    = "_OscSyncManagerGroupActivated";
		/** Group のホストが失われた際等にアクティベーションが解除された際に通知される. */
		public static const DEACTIVATED:String  = "_OscSyncManagerGroupDeactivated";
		/** Group に登録されている IP のリストでホスト IP の変更があった場合の処理. */
		public static const HOST_CHANGED:String = "_OscSyncManagerGroupHostChanged";
		/** Group に登録されている IP のリストに変更があった場合の処理. */
		public static const EXPIRED:String      = "_OscSyncManagerGroupExpired";
		
		internal var _ip:String;
		
		// ------- PUBLIC ---------------------------------------------
		
		public function OSCSyncManagerGroupEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false){
			super(type, bubbles, cancelable);
		}
		
		public override function clone():Event {
			return new OSCSyncManagerGroupEvent( type, bubbles, cancelable );
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