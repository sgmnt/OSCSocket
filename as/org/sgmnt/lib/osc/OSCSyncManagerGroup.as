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
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	/**
	 * 同期処理時に OSCSyncProcess が自らの挙動を決定する上での情報を提供するためのクラスです.
	 * 同期対象となる各々の PC の IP をリスト化し, Timer クラスを用いて生存監視を行います.
	 * 
	 * TODO Activate 後に追加が会った場合は、再度アクティベートフローに入る.
	 * その際現在実行中の同期処理が会った場合はその同期処理完了後にフローに入る.
	 * 
	 * @author sgmnt.org
	 */
	internal class OSCSyncManagerGroup extends EventDispatcher{
		
		// ------- MEMBER -----------------------------------------------
		
		/** OSCSyncManager への参照. */
		private var _mngr:OSCSyncManager;
		
		/** グループ名 */
		private var _name:String;
		
		/** 生存時間. */
		private var _life:Number;
		
		/** 自身のグループに所属しているクライアント数. */
		private var _length:uint;
		
		/** インスタンスが作られた時間. */
		private var _createTime:Number;
		
		/** ホストとして把握しているクライアントのIP */
		private var _hostIP:String;
		
		/** 自身のグループに所属しているクライアントのリスト. */
		private var _clients:Array;
		
		/** 自身がアクティベートされるまでにIPを監視するためのタイマー */
		private var _activateTimer:Timer;
		private var _activateTimerDelay:Number;
		private var _activateTimerCount:int;
		
		/** このグループの自身の所属期限を定義するタイマー. */
		private var _expireTimer:Timer;
		
		/** このグループがアクティベートされているか. */
		internal var _activated:Boolean;
		
		/** このグループの同期プロセスが実行中であるか. */
		internal var _processRunning:Boolean;
		
		// ------- PUBLIC -----------------------------------------------
		
		/**
		 * Constructor.
		 * 
		 * @param name グループ名
		 * @param activateTimerDelay アクティベート用タイマーのディレイ. ここで指定された秒数 x activateTimerCount の回数だけ実行される.
		 * @param activateTimerCount アクティベート用タイマーのカウント.
		 * 
		 */
		public function OSCSyncManagerGroup( manager:OSCSyncManager, name:String, life:Number, activateTimerDelay:Number = 1000, activateTimerCount:int = 10 ){
			
			_mngr = manager;
			_name = name;
			_life = life;
			_activateTimerDelay = activateTimerDelay;
			_activateTimerCount = activateTimerCount;
			
			_createTime     = new Date().time;
			
			_hostIP         = null;
			_clients        = new Array();
			_length         = 0;
			
			_activated      = false;
			_processRunning = false;
			
			// --- Setup Manager.
			_mngr.socket.addEventListener( "/group/" + _name + "/create", _onCreate );
			_mngr.socket.addEventListener( "/group/" + _name + "/pending", _onPending );
			_mngr.socket.addEventListener( "/group/" + _name + "/lostip", _onLostIP );
			
			// --- Setup Timer. ---
			_activateTimer = new Timer( _activateTimerDelay, _activateTimerCount );
			_expireTimer   = new Timer( 1000 );
			_expireTimer.addEventListener( TimerEvent.TIMER, _onExpireTimer );
			
			// --- Start Activate.
			
			_activate();
			
		}
		
		/**
		 * このグループがアクティベートされているか.
		 * @return 
		 */		
		public function get activated():Boolean{
			return _activated;
		}
		
		/**
		 * グループ名.
		 * @return 
		 */		
		public function get name():String{
			return _name;
		}
		
		/**
		 * グループに所属しているクライアント数.
		 * @return
		 */
		public function get numClients():int{
			return _length;
		}
		
		/**
		 * ホストとなるIPアドレスを設定します.
		 * 設定処理は OSCSyncManager から行われます.
		 * @return
		 */
		public function get hostIP():String{ return _hostIP; }
		
		/**
		 * グループに所属しているクライアントのIPの配列を生成し取得します.
		 * @return
		 */
		public function createClientIPArray():Array{
			var arr:Array = [];
			for( var ip:String in _clients ){ arr.push(ip); }
			return arr;
		}
		
		public function destroy():void{
			_mngr.broadcast( new OSCMessage("/group/"+_name+"/destroy") );
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
		 * アクティベートフローを実行します.
		 * グループに所属しているクライアントの状態の同期をとる目的で実行されます.
		 * 
		 * @param activateTimerDelay
		 * @param repeatCount
		 */
		internal function _activate( activateTimerDelay:Number = -1, repeatCount:int = -1 ):void{
			if( _activated == true ){
				return;
			}
			_activateTimer.delay       = ( activateTimerDelay < 0 ) ? _activateTimerDelay: activateTimerDelay;
			_activateTimer.repeatCount = ( repeatCount < 0 ) ? _activateTimerCount: repeatCount;
			_activateTimer.reset();
			_activateTimer.addEventListener(TimerEvent.TIMER, _onActivateTimer );
			_activateTimer.addEventListener(TimerEvent.TIMER_COMPLETE, _onActivateTimerComplete );
			_activateTimer.start();
			_broadcastCreateGroupMessage();
		}
		
		/**
		 * ActivateTimer が実行される度に自分のIPを通知し直す事を試みる.
		 * ADDED イベントを通知して OSCSyncManager に追加処理を通知する.
		 * 
		 * この処理を activateTimerCount で指定した回数繰り返す.
		 * その過程でグループを構成するIPのリストに変化が無かった場合、初めて Activate されたと見なされる.
		 * @param event
		 */
		private function _onActivateTimer(event:TimerEvent):void{
			trace( name + " Checking IP List... " + _activateTimer.currentCount);
			_broadcastCreateGroupMessage();
		}
		
		/**
		 * グループを構成するIPのリストが安定し,これ以上更新が無いと判断し
		 * 安定への Timer を決定するタイマー処理.
		 * 
		 * @param event
		 */	
		private function _onActivateTimerComplete(event:TimerEvent):void{
			
			trace( name + " Checking IP List... COMPLETE");
			
			// --- removeEventListeners.
			_activateTimer.removeEventListener( TimerEvent.TIMER,_onActivateTimer );
			_activateTimer.removeEventListener( TimerEvent.TIMER_COMPLETE, _onActivateTimerComplete );
			
			// --- Decide Host IP.
			_decideHostIP();
			
			// --- Activate Complete.
			_activated = true;
			
			// --- Dispatch Activate Event.
			dispatchEvent( new OSCSyncManagerGroupEvent( OSCSyncManagerGroupEvent.ACTIVATED ) );
			
		}
		
		/**
		 * 自身の生存確認用タイマーの実行処理.
		 * @param event
		 */		
		private function _onExpireTimer(event:TimerEvent):void{
			trace("_onExpireTimer");
			_broadcastCreateGroupMessage();
		}
		
		/**
		 * 複数 PC 間での同期処理の確立のために
		 * グループ作成のメッセージをブロードキャストします.
		 * @param name
		 */
		private function _broadcastCreateGroupMessage():void{
			trace("_broadcastCreateGroupMessage");
			var msg:OSCMessage = new OSCMessage();
			msg.address = "/group/"+_name+"/create";
			msg.addArgument("f",_createTime);
			_mngr.broadcast( msg );
		}
		
		/**
		 * グループ生成のメッセージが来た際の処理.グループへIPを登録します.
		 * 
		 * グループ内のIPは IP : Timer の関係で管理され
		 * Timer が完了したタイミングでその IP の期限が切れたとみなすようになっています.
		 * 既に登録されている IP が、再度登録された場合にはその Timer がリセットされ期限もリセットされます.
		 * 
		 * この追加処理が定期的に実行される事でグループは IP の死活を管理しているため
		 * 各クライアントは定期的にこのメッセージを通知し続ける事となります.
		 * 
		 * @param event
		 */
		private function _onCreate(event:OSCSocketEvent):void{
			
			trace("_onCreate");
			
			var ip:String   = event.srcAddress;
			var time:Number = event.args[0];
			
			// --- Add to IP List.
			
			var ipTimer:Timer;
			if( !_clients[ip] ){
				
				// --- 自身が保持していないIP場合は追加処理を行う.
				
				if( _processRunning == true ){
					// --- 既にプロセスが実行中であった場合,IPの追加を保留する.
					_mngr.broadcast( new OSCMessage("/group/"+_name+"/pending") );
					return;
				}
				
				var client:Client = new Client( time );
				client.timer.addEventListener( TimerEvent.TIMER_COMPLETE, _onClientTimerComplete );
				_clients[ip] = client;
				_length++;
				
				// --- restart Timer. ---
				_activated = false;
				_activate();
				
				// グループに登録されたIPが追加された際の処理.
				dispatchEvent( new OSCSyncManagerGroupEvent( OSCSyncManagerGroupEvent.ADDED ) );
				
			}
			
			ipTimer = _clients[ip].timer;
			ipTimer.reset();
			ipTimer.start();
			
			// --- Update Expire Timer.
			
			_expireTimer.delay = Math.floor( _life * 0.4649 );
			_expireTimer.reset();
			_expireTimer.start();
			
		}
		
		/**
		 * グループへの追加保留が通達された際の処理.
		 * もし _processRunning が false の場合は,自身が弾かれた可能性が高いので
		 * 再度 activate 処理を行う.
		 * @param event
		 */
		private function _onPending(event:OSCSocketEvent):void{
			trace("_onPending");
			if( _processRunning == false ){
				_activated = false;
				_activate();
				dispatchEvent( new OSCSyncManagerGroupEvent( OSCSyncManagerGroupEvent.ADD_PENDING ) );				
			}
		}
		
		/**
		 * 管理されている IP の期限が切れた際の処理.
		 * @param event
		 */
		private function _onClientTimerComplete(event:TimerEvent):void{
			trace("_onClientTimerComplete");
			var timer:Timer = event.target as Timer;
			var ip:String = null;
			// 期限切れとなった IP を調べ通知する.
			for( var key:String in _clients ){
				if( _clients[key].timer == timer ){
					ip = key;
					break;
				}
			}
			if( ip != null ){
				var msg:OSCMessage = new OSCMessage();
				msg.address = "/group/"+_name+"/lostip";
				msg.addArgument( "s", ip );
				_mngr.broadcast( msg );
			}
		}
		
		/**
		 * IP の保持期限が来た際の処理.
		 * グループからIPを削除する.
		 * @param event
		 */
		private function _onLostIP(event:OSCSocketEvent):void{
			
			var ip:String = event.args[0];
			var client:Client = _clients[ip];
			
			if( client ){
				
				// IP が存在する場合リストから削除する.
				
				// --- Clear Timer.
				client.timer.removeEventListener( TimerEvent.TIMER_COMPLETE, _onClientTimerComplete );
				client = null;
				
				// --- Remove from _clients.
				
				_clients[ip] = null;
				delete _clients[ip];
				_length--;
				
				// --- 
				
				_decideHostIP();
				
				// ---
				
				dispatchEvent( new OSCSyncManagerGroupEvent( OSCSyncManagerGroupEvent.REMOVED ) );
				
			}
			
		}
		
		/**
		 * Host となる IP を決定します.
		 * IP List に変化が会った際に実行されます.
		 */
		private function _decideHostIP():void{
			var newHostIP:String;
			var lastIP:int;
			var minLastIP:int = 255;
			for( var ip:String in _clients ){
				lastIP = int( ip.substring( ip.lastIndexOf(".")+1, ip.length ) );
				if( lastIP < minLastIP ){
					newHostIP = ip;
					minLastIP = lastIP;
				}
			}
			if( newHostIP != _hostIP ){
				_hostIP = newHostIP;
				dispatchEvent( new OSCSyncManagerGroupEvent( OSCSyncManagerGroupEvent.HOST_CHANGED ) );
			}
			trace( name + " Host IP : " + _hostIP );
		}
		
	}
	
}

// ===

import flash.utils.Timer;

/**
 * グループ内でクライアント一覧を管理する際に扱う１クライアント分のデータを扱うためのクラス.
 * @author sgmnt.org
 */
class Client{
	
	// ------ MEMBER -----------------------------------------
	
	private var _timer:Timer;
	private var _createTime:Number;
	
	// ------ PUBLIC -----------------------------------------
	
	/**
	 * Constructor.
	 * @param time グループの生成時刻.
	 */	
	public function Client( time:Number ):void{
		// その IP をキーに、100秒を寿命としたタイマーを生成する.
		_timer      = new Timer( 100000, 1 );
		_createTime = time;
	}
	
	/** 生存時間を司るタイマー. */
	public function get timer():Timer{ return _timer; }
	
	/** グループの生成時刻. */
	public function get createTime():Number{ return _createTime; }
	
}