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
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	/**
	 * 同期処理を行う Group の管理クラス.
	 * @author sgmnt.org
	 */
	internal class OSCSyncManagerGroup extends EventDispatcher{
		
		// ------- MEMBER -----------------------------------------------
		
		private var _name:String;
		private var _length:uint;
		private var _hostIP:String;
		
		private var _clients:Array;
		
		private var _activateTimer:Timer;
		private var _updateTimer:Timer;
		
		// ------- PUBLIC -----------------------------------------------
		
		/**
		 * Constructor.
		 * @param name
		 */		
		public function OSCSyncManagerGroup( name:String ){
			
			_name   = name;
			_length = 0;
			_hostIP = null;
			
			// ---
			
			_clients = new Array();
			
			// --- Create Timer. ---
			
			// このタイマーが完了したら安定したとみなす.
			_activateTimer = new Timer(1000,10);
			_activateTimer.addEventListener(TimerEvent.TIMER, _onTimer );
			_activateTimer.addEventListener(TimerEvent.TIMER_COMPLETE, _onTimerComplete );
			_activateTimer.start();
			
			_updateTimer = new Timer(1000);
			
		}
		
		/**
		 * グループ名.
		 * @return 
		 */		
		public function get name():String{ return _name; }
		
		/**
		 * 所属している
		 * @return
		 */
		public function get numClients():int{ return _length; }
		
		/**
		 * ホストとなるIPアドレス.
		 * @return 
		 */
		public function get hostIP():String{ return _hostIP; }
		public function set hostIP(ip:String):void{
			if( ip == hostIP ) return;
			var hostChanged:Boolean = false;
			if( !_hostIP ){
				_hostIP = ip;
				hostChanged = true;
			}else{
				var lastIP     = int( ip.substring( ip.lastIndexOf(".")+1, ip.length ) );
				var hostLastIP = int( hostIP.substring( hostIP.lastIndexOf(".")+1, hostIP.length ) );
				if( lastIP < hostLastIP ){
					_hostIP = ip;
					hostChanged = true;
				}
			}
			if( hostChanged ){
				trace( name + " Host IP Changed : " + _hostIP );
				dispatchEvent( new Event( Event.CHANGE ) );
			}
		}
		
		/**
		 * グループの更新を行うタイマー.
		 * @return 
		 */		
		public function get timer():Timer{ return _updateTimer; }
		
		/**
		 * 
		 * @param ip
		 */	
		public function add( ip:String ):void{
			var timer:Timer;
			if( !_clients[ip] ){
				timer = new Timer( 100000, 1 );
				timer.addEventListener( TimerEvent.TIMER_COMPLETE, function(e:TimerEvent):void{
					dispatchEvent( new Event("dead") );
				});
				_clients[ip] = timer;
				_length++;
				// --- restart Timer. ---
				if( _activateTimer.running ){
					trace( name + " Timer Reset.");
					_activateTimer.reset();
					_activateTimer.start();
				}
				dispatchEvent( new Event( Event.ADDED ) );
			}else{
				timer = _clients[ip];
			}
			timer.reset();
			timer.start();
		}
		
		/**
		 * 
		 * @param ip
		 */	
		public function remove( ip:String ):void{
			if( _clients[ip] ){
				_clients[ip] = null;
				delete _clients[ip];
				_length--;
				dispatchEvent( new Event( Event.REMOVED ) );
			}
			// --- restart Timer. ---
			if( _activateTimer.running ){
				_activateTimer.reset();
				_activateTimer.start();
			}
		}
		
		/**
		 * 保持しているクライアントの一覧情報を取得します.
		 * @return 
		 */
		override public function toString():String{
			var str:String = name + ":\n";
			for( var ip:String in _clients ){
				if( _hostIP == ip ){
					str += "  *" + ip　+"\n";
				}else{
					str += "  " + ip　+"\n";
				}
			}
			return str;
		}
		
		// ------- PRIVATE ----------------------------------------------
		
		/**
		 * ActivateTimer は 3回 自分のIPを通知し直す事を試みる.
		 * この3回の通知で構成に変化が無かった場合、初めて Activate されたと見なされる.
		 * @param event
		 */
		private function _onTimer(event:TimerEvent):void{
			trace( name + " Checking IP List... " + _activateTimer.currentCount);
			dispatchEvent( new Event(Event.ADDED) );
		}
		
		/**
		 * 安定への Timer を決定するタイマー処理.
		 * @param event
		 */	
		private function _onTimerComplete(event:TimerEvent):void{
			
			trace( name + " Checking IP List... COMPLETE");
			
			_activateTimer.removeEventListener( TimerEvent.TIMER,_onTimer );
			_activateTimer.removeEventListener( TimerEvent.TIMER_COMPLETE, _onTimerComplete );
			
			// --- Decide Host IP. ---
			
			if( !_hostIP ){
				var lastIP:int;
				var minLastIP:int = 255;
				for( var ip:String in _clients ){
					lastIP = int( ip.substring( ip.lastIndexOf(".")+1, ip.length ) );
					if( lastIP < minLastIP ){
						_hostIP = ip;
						minLastIP = lastIP;
					}
				}
			}
			trace( name + " Host IP : " + _hostIP );
			
			// --- Last Checking. ---
			
			trace( name + " Activating...");
			
			_activateTimer.repeatCount = 1;
			_activateTimer.delay = 30000;
			_activateTimer.reset();
			_activateTimer.addEventListener( TimerEvent.TIMER_COMPLETE, _onTimerCompleteCompletely );
			_activateTimer.start();
			
		}
		
		/**
		 * 本当に同期完了を決定した際の処理.
		 * @param event
		 */
		private function _onTimerCompleteCompletely(event:TimerEvent):void{
			
			trace( name + " Activating... COMPLETE");
			
			dispatchEvent( new Event(Event.CLEAR) );
			
		}
		
	}
	
}