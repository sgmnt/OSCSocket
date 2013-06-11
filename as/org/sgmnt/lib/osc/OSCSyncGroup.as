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
	
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	/**
	 * 同期処理時に OSCSyncProcess が自らの挙動を決定する上での情報を提供するためのクラスです.
	 * 同期対象となる各々の PC の IP をリスト化し, Timer クラスを用いて生存監視を行います.
	 * 
	 * TODO Activate 後に追加があった場合は、再度アクティベートフローに入る.
	 * その際現在実行中の同期処理があった場合はその同期処理完了後にフローに入る.
	 * 
	 * やる事
	 * 
	 * - STABLE 状態と PENDING 状態、など状態をグループ側で制御する
	 * - UNSTABLE = 実行不可能 ではなく STABLE 時に実行していたものは引き続き完了まで面倒をみる.
	 * - activate の完了を保証する（今はちょっとずれる事がありそう OSC でしっかり監視）
	 *   この完了タイミングで _clients を全て stable にするのが良さそう.
	 *   _clients の stable = 現在実行可能な IP という設計.
	 * 
	 * @author sgmnt.org
	 */
	internal class OSCSyncGroup extends EventDispatcher{
		
		// ------- MEMBER -----------------------------------------------
		
		/** OSCSyncManager への参照. */
		private var _mngr:OSCSyncManager;
		
		/** このグループがアクティベートされているか. */
		private var _activated:Boolean;
		
		/** グループ名 */
		private var _name:String;
		
		/** インスタンスが作られた時間. */
		private var _createdTime:Number;
		
		/** Hostとして把握しているクライアントのIP */
		private var _hostIP:String;
		
		/** 自身のグループに所属しているクライアントのリスト. */
		private var _clients:Vector.<OSCSyncGroupClient>;
		
		/** 自身がアクティベートされるまでにIPを監視するためのタイマー */
		private var _activateTimer:Timer;
		private var _activateTimerDelay:Number;
		private var _activateTimerCount:int;
		
		/** このグループの自身の更新をするタイマー. */
		private var _updateTimer:Timer;
		
		/** 新規プロセスの開始を受け付けるかどうか. */
		private var _newProcessRunnable:Boolean;
		
		/** このグループで実行中の同期プロセス数. */
		private var _numProcess:int;
		
		// ------- PUBLIC -----------------------------------------------
		
		/**
		 * Constructor.
		 * 
		 * @param name グループ名
		 * @param activateTimerDelay アクティベート用タイマーのディレイ. ここで指定された秒数 x activateTimerCount の回数だけ実行される.
		 * @param activateTimerCount アクティベート用タイマーのカウント.
		 * 
		 */
		public function OSCSyncGroup( manager:OSCSyncManager, name:String, activateTimerDelay:Number = 1000, activateTimerCount:int = 10 ){
			
			// --- Init properties. ---
			_mngr = manager;
			_name = name;
			
			_activateTimerDelay = activateTimerDelay;
			_activateTimerCount = activateTimerCount;
			
			_createdTime = new Date().time;
			
			_hostIP  = null;
			_clients = new Vector.<OSCSyncGroupClient>();
			
			_activated  = false;
			_numProcess = 0;
			_newProcessRunnable  = false;
			
			// --- Broadcast Group Create Message. ---
			var msg:OSCMessage = new OSCMessage();
			msg.address = "/group/"+_name+"/create";
			_mngr.broadcast( msg );
			
			// --- Add EventLisnters to OSCSyncManager. ---
			_mngr.socket.addEventListener( "/group/" + _name + "/create", _onCreateMessageReceived );
			_mngr.socket.addEventListener( "/group/" + _name + "/join"  , _onJoinMessageReceived );
			_mngr.socket.addEventListener( "/group/" + _name + "/pend"  , _onPendMessageReceived );
			_mngr.socket.addEventListener( "/group/" + _name + "/lostip", _onLostIPMessageReceived );
			_mngr.socket.addEventListener( "/group/" + _name + "/stable", _onStableMessageReceived );
			
			// --- Setup Timers. ---
			_activateTimer = new Timer( _activateTimerDelay, _activateTimerCount );
			
			_updateTimer = new Timer( 3000 );
			_updateTimer.addEventListener( TimerEvent.TIMER, _onUpdateTimer );
			_updateTimer.start();
			
		}
		
		/**
		 * 新規の同期プロセス開始を受け付けているか.
		 * @return 
		 */
		public function get canNewProcessBegin():Boolean{
			return _newProcessRunnable;
		}
		
		/**
		 * このグループ間で実行されている同期プロセスがあるかどうか.
		 * @return
		 */
		public function get hasRunningProcesses():Boolean{
			return 0 < _numRunningProcess;
		}
		
		/**
		 * HostとなるIPアドレスを設定します.
		 * 設定処理は OSCSyncManager から行われます.
		 * @return
		 */
		public function get hostIP():String{
			return _hostIP;
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
			return _clients.length;
		}
		
		/**
		 * このグループが現在安定しており同期処理が実行可能な状態であるか.
		 * @return 
		 */
		public function get stable():Boolean{
			return _activated == true && _newProcessRunnable == true;
		}
		
		/**
		 * グループに所属しているクライアントのIPの配列を生成し取得します.
		 * 仮登録 (unstable client) の IP は除外されます.
		 * @return
		 */
		public function createClientIPArray():Array{
			var arr:Array = [];
			for( var i:int = 0; i < _clients.length; i++ ){
				if( _clients[i].stable == true ){
					arr.push( _clients[i].ip );
				}
			}
			return arr;
		}
		
		/**
		 * このグループインスタンスの破棄を申し出ます.
		 * 破棄の処理は OSC メッセージ通知後に行われます.
		 */
		public function destroy():void{
			var msg:OSCMessage = new OSCMessage();
			msg.address = "/group/"+_name+"/destroy";
			_mngr.broadcast(msg);
		}
		
		/**
		 * 保持しているクライアントの IP アドレスの一覧を出力します.
		 * Host として認識している IP には * が追加されます.
		 * 仮登録している IP には ! が追加されます.
		 * @return
		 */
		override public function toString():String{
			var i:int, c:OSCSyncGroupClient,
				str:String = name + ":\n";
			for( i = 0; i < _clients.length; i++ ){
				c = _clients[i];
				if( _hostIP == c.ip ){
					str += " *" + c.ip　+"\n";
				}else if( c.stable == false ){
					str += " !" + c.ip + "\n";
				}else{
					str += "  " + c.ip　+"\n";
				}
			}
			return str;
		}
		
		// ------- INTERNAL ----------------------------------------------
		
		/**
		 * 現在実行中のプロセス数.
		 * @param value
		 */		
		internal function set _numRunningProcess( value:int ):void{
			if( value < 0 ){ value = 0; }
			if( _numProcess == value ){ return; }
			_numProcess = value;
		}
		internal function get _numRunningProcess():int{
			return _numProcess;
		}
		
		// ------- PRIVATE ----------------------------------------------
		
		/**
		 * 複数 PC 間での同期処理の確立のために
		 * グループ作成のメッセージをブロードキャストします.
		 * 
		 * このメッセージ処理が定期的に通知しあう事でグループは各 PC の死活を管理しているため
		 * 各クライアントは定期的にこのメッセージを通知し続ける事となります.
		 * 
		 * @param name
		 */
		private function _broadcastJoinMessage():void{
			//trace("_broadcastJoinMessage");
			var msg:OSCMessage = new OSCMessage();
			msg.address = "/group/"+_name+"/join";
			msg.addArgument("f",_createdTime);
			_mngr.broadcast(msg);
		}
		
		/**
		 * 自身の生存確認用タイマーの実行処理.
		 * 各 PC の OSCSyncGroup インスタンスがこのタイマーを一定時間ごとに実行する事で
		 * 全体のグループの生存状態を保つ.
		 * @param event
		 */
		private function _onUpdateTimer(event:TimerEvent):void{
			//trace("_onUpdateTimer");
			_broadcastJoinMessage();
			if( _updateTimer.delay == 3000 ){
				_updateTimer.delay = 10000 * 0.4649;
				_updateTimer.reset();
				_updateTimer.start();
			}
		}
		
		// ================================
		// === Add flow.
		
		/**
		 * グループ生成のメッセージが来た際の処理.グループへクライアントを登録します.
		 * 
		 * 各クライアントはTimerで死活管理されており,
		 * Timer が完了したタイミングで期限が切れたとみなすようになっています.
		 * 登録済みのクライアントが、再度メッセージを送信してきた時に Timer をリセットし保持期間を延長します.
		 * 
		 * @param event
		 */
		private function _onJoinMessageReceived(event:OSCSocketEvent):void{
			
			//trace("_onJoinMessageReceived");
			
			var ip:String   = event.srcAddress,
				time:Number = event.args[0];
			
			// --- find client if already exists.
			
			var i:int, len:int = _clients.length,
				client:OSCSyncGroupClient, ipTimer:Timer;
			
			for( i = 0; i < len; i++ ){
				if( _clients[i].ip == ip ){
					client = _clients[i];
					break;
				}
			}
			
			// --- Add to IP List.
			
			if( !client ){
				
				_newProcessRunnable = false;
				
				// 処理中のプロセスがある場合は一旦待ってもらう.
				if( hasRunningProcesses == true ){
					if( _mngr.isHost( _name ) ){
						var msg:OSCMessage = new OSCMessage();
						msg.address = "/group/"+_name+"/pend";
						_mngr.broadcast(msg);
					}
					return;
				}
				
				// 処理中のプロセスが無い場合は追加処理を行い再度 activate する.
				
				client = new OSCSyncGroupClient( ip, time );
				client.timer.addEventListener( TimerEvent.TIMER_COMPLETE, _onClientTimerComplete );
				_clients.push( client );
				
				trace( "[" + name + "] IP added to client list.");
				trace( "--------------------\n" + toString() + "\n--------------------" );
				
				_activate();
				
			}else{
				// --- 保持していた場合 _createdTime を更新する. ---
				client._createdTime = time;
			}
			
			ipTimer = client.timer;
			ipTimer.reset();
			ipTimer.start();
			
		}
		
		/**
		 * グループへの追加保留が通達された際の処理.
		 * もし hasRunningProcesses が false の場合は,自身が弾かれた可能性が高いので
		 * 再度 activate 処理を行う.
		 * @param event
		 */
		private function _onPendMessageReceived(event:OSCSocketEvent):void{
			if( hasRunningProcesses == false ){
				trace("_onPendMessageReceived");
				_activate();
			}
		}
		
		// ================================
		// === Remove flow.
		
		/**
		 * グループ生成の通知が来た際の処理.
		 * 再起動した可能性があるため対象となる IP をリストから一度外す.
		 * @param event
		 */
		private function _onCreateMessageReceived(event:OSCSocketEvent):void{
			var ip:String = event.srcAddress;
			_removeClientByIP(ip);
		}
		
		/**
		 * 管理されている IP の期限が切れた際の処理.
		 * @param event
		 */
		private function _onClientTimerComplete(event:TimerEvent):void{
			
			//trace("_onClientTimerComplete");
			
			var timer:Timer = event.target as Timer;
			var i:int, len:int = _clients.length, ip:String = null;
			
			// --- 期限切れとなった IP を調べ通知する. ---
			for( i = 0; i < len; i++ ){
				if( _clients[i].timer == timer ){
					ip = _clients[i].ip;
					break;
				}
			}
			
			// --- IPが存在した場合削除する. ---
			if( ip != null ){
				var msg:OSCMessage = new OSCMessage();
				msg.address = "/group/"+_name+"/lostip";
				msg.addArgument( "s", ip );
				_mngr.broadcast(msg);
			}
			
		}
		
		/**
		 * IP の保持期限が来た際の処理.
		 * グループからIPを削除する.
		 * @param event
		 */
		private function _onLostIPMessageReceived(event:OSCSocketEvent):void{
			var ip:String = event.args[0];
			_removeClientByIP(ip);
		}
		
		/**
		 * クライアントリストから引数で指定した IP を持つ要素を削除します.
		 * @param ip
		 */		
		private function _removeClientByIP( ip:String ):void{
			var i:int, len:int = _clients.length;
			for( i = 0; i < len; i++ ){
				if( _clients[i].ip == ip ){
					// --- Delete from _clients if ip exists. ---
					_clients[i].timer.removeEventListener( TimerEvent.TIMER_COMPLETE, _onClientTimerComplete );
					_clients.splice(i,1);
					// --- 
					_decideHostIP();
					trace( "[" + name + "] IP removed from client list.");
					trace( "--------------------\n" + toString() + "\n--------------------" );
					// ---
					dispatchEvent( new OSCSyncGroupEvent( OSCSyncGroupEvent.REMOVED ) );
					break;
				}
			}
		}
		
		// ====================================================================
		// === Activation Flow.
		
		/**
		 * アクティベートフローを実行します.
		 * グループに所属しているクライアントの状態の同期をとる目的で実行されます.
		 * 
		 * @param activateTimerDelay
		 * @param repeatCount
		 */
		private function _activate( activateTimerDelay:Number = -1, repeatCount:int = -1 ):void{
			_activated = false;
			_activateTimer.delay       = ( activateTimerDelay < 0 ) ? _activateTimerDelay: activateTimerDelay;
			_activateTimer.repeatCount = ( repeatCount < 0 ) ? _activateTimerCount: repeatCount;
			_activateTimer.reset();
			_activateTimer.addEventListener(TimerEvent.TIMER, _onActivateTimer );
			_activateTimer.addEventListener(TimerEvent.TIMER_COMPLETE, _onActivateTimerComplete );
			_activateTimer.removeEventListener( TimerEvent.TIMER_COMPLETE, _onStableTimerComplete );
			_activateTimer.start();
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
			trace( "[" + name + "] Checking IP List... " + _activateTimer.currentCount);
			_broadcastJoinMessage();
		}
		
		/**
		 * グループを構成するIPのリストが安定し,これ以上更新が無いと判断し
		 * 安定への Timer を決定するタイマー処理.
		 * 
		 * @param event
		 */	
		private function _onActivateTimerComplete(event:TimerEvent):void{
			
			_activateTimer.removeEventListener( TimerEvent.TIMER,_onActivateTimer );
			
			if( hasRunningProcesses == false ){
				
				// --- Decide Host IP. ---
				_decideHostIP( true );
				
				if( _mngr.isHost( _name ) ){
					var msg:OSCMessage = new OSCMessage();
					msg.address = "/group/" + _name + "/stable";
					_mngr.broadcast( msg );
				}
				
			}else{
				// --- プロセスの実行中であった場合それらが終了するまで待つ. ---
				_activateTimer.repeatCount = 1;
				_activateTimer.reset();
				_activateTimer.start();
			}
			
		}
		
		/**
		 * 
		 * @param event
		 */		
		private function _onStableMessageReceived(event:OSCSocketEvent):void{
			
			// --- removeEventListeners. ---
			_activateTimer.stop();
			_activateTimer.removeEventListener( TimerEvent.TIMER,_onActivateTimer );
			_activateTimer.removeEventListener( TimerEvent.TIMER_COMPLETE, _onActivateTimerComplete );
			
			// --- Activate Complete. ---
			_activated = true;
			_newProcessRunnable = true;
			
			// --- Decide Host IP. ---
			_decideHostIP( true );
			
			trace( "[" + name + "] Checking IP List... COMPLETE");
			trace( "--------------------\n" + toString() + "\n--------------------" );
			
			if( _mngr.isHost( _name ) ){
				// --- Host だった場合 STABLE 確認のための同期処理を 3 秒後に実行する.
				_activateTimer.delay = 3000;
				_activateTimer.repeatCount = 1;
				_activateTimer.addEventListener( TimerEvent.TIMER_COMPLETE, _onStableTimerComplete );
				_activateTimer.reset();
				_activateTimer.start();
			}
			
		}
		
		/**
		 * STABLE 確認の同期処理を開始します.
		 * @param event
		 */
		private function _onStableTimerComplete(event:TimerEvent):void{
			_activateTimer.stop();
			_activateTimer.removeEventListener( TimerEvent.TIMER_COMPLETE, _onStableTimerComplete );
			dispatchEvent( new OSCSyncGroupEvent( OSCSyncGroupEvent.STABLED ) );
		}
		
		// ====================================================================
		// === Update Host IP Flow.
		
		/**
		 * Host となる IP を決定します.
		 * IP List に変化が会った際に実行されます.
		 * Host は常に IP の Host Address の数値が最も小さいものになります.
		 * @param stableAll 全てのクライアントを stable にするか.
		 */
		private function _decideHostIP( stableAll:Boolean = false ):void{
			
			var ip:String, newHostIP:String, lastIP:int, minLastIP:int = 255;
			var i:int, len:int = _clients.length, c:OSCSyncGroupClient;
			
			for( i = 0; i < len; i++ ){
				c = _clients[i];
				if( stableAll || c._stable == true ){
					c._stable = true;
					ip = c.ip;
					lastIP = int( ip.substring( ip.lastIndexOf(".")+1, ip.length ) );
					if( lastIP < minLastIP ){
						newHostIP = ip;
						minLastIP = lastIP;
					}
				}
			}
			
			if( newHostIP != _hostIP ){
				_hostIP = newHostIP;
				dispatchEvent( new OSCSyncGroupEvent( OSCSyncGroupEvent.HOST_CHANGED ) );
			}
			
		}
		
	}
	
}