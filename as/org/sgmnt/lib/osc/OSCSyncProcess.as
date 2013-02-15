﻿/** *  * Copyright (c) 2010 - 2012, http://sgmnt.org/ *  * Permission is hereby granted, free of charge, to any person obtaining * a copy of this software and associated documentation files (the * "Software"), to deal in the Software without restriction, including * without limitation the rights to use, copy, modify, merge, publish, * distribute, sublicense, and/or sell copies of the Software, and to * permit persons to whom the Software is furnished to do so, subject to * the following conditions: *  * The above copyright notice and this permission notice shall be * included in all copies or substantial portions of the Software. *  * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. * */package org.sgmnt.lib.osc {		import flash.events.Event;	import flash.events.EventDispatcher;	import flash.events.TimerEvent;	import flash.utils.Dictionary;	import flash.utils.Timer;	    /**     * OscSyncManager で管理される処理同期プロセス.	 * @author  sgmnt.org     * @version 0.1     */    public class OSCSyncProcess extends EventDispatcher{                //------- CONSTS ----------------------------------------------------------------------- */				//------- MEMBER ----------------------------------------------------------------------- */				static private var _INSTANCE_DICTIONARY:Dictionary;		static private var _PROCESS_TARGET_INSTANCE_LIST:Dictionary;		static private var _PROCESS_INSTANCE_LIST:Dictionary;				/** OSCSyncManager */		private var _mngr:OSCSyncManager;				/** 同期のグループ名. */		private var _group:String;		/** 同期のキー. */		private var _key:String;		/** 同期通知を行う OSC のアドレス. */		private var _address:String;		/** 同期処理が実行可能な状態であるか. */		private var _enable:Boolean;		/** 同期処理にタイムアウトが存在する場合のタイムアウト用タイマー. */		private var _timeoutTimer:Timer;				/** 同期処理が実行中であるか. */		private var _running:Boolean;		/** 同期処理実行時の時刻. */		private var _timestamp:Number;				/** 現在何番目の同期処理を行っているかのポインタ. */		private var _pointer:int;		/** 同期実行する関数を格納する Vector クラス. */		private var _closureVec:Vector.<ClosureLinkedList>;		/** closure 用辞書クラス. */		private var _closureDict:Dictionary;				private var _args:Array;				private var _numGroupMember:int;		private var _completeCount:int;		        //------- PUBLIC ----------------------------------------------------------------------- */                /**         * Constructor.		 * 		 * TODO このプロセスのグループ単位で、同期完了を一定時間待つようにする		 * そうする事で、 このクラスインスタンスをソースコード内に分散させても大幅に問題発生がしにくくなる。		 * 		 * @param group   同期グループ名.		 * @param key     同期処理を一意に定めるためのユニークキー.		 * @param timeout 同期処理のタイムアウト時間.         */        public function OSCSyncProcess( group:String, key:String, timeout:Number = 0 ) {			            super();						// --- Setup Member Properties. ---						_group   = group;			_key     = key;			_address = "/sync/" + _group + "/" + _key;			_enable = false;						_running       = false;						_pointer = 0;			_closureVec  = new Vector.<ClosureLinkedList>();			_closureDict = new Dictionary();						// --- Create timeout timer. If needed. ---			if( 0 < timeout ){				_timeoutTimer = new Timer( timeout, 1 );				_timeoutTimer.addEventListener( TimerEvent.TIMER_COMPLETE, _onTimeoutTimerComplete );			}						// --- Create Static Properties. ----						if( _PROCESS_INSTANCE_LIST == null ){				_PROCESS_INSTANCE_LIST = new Dictionary();			}						if( _PROCESS_TARGET_INSTANCE_LIST == null ){				_PROCESS_TARGET_INSTANCE_LIST = new Dictionary();			}						if( _INSTANCE_DICTIONARY == null ){				_INSTANCE_DICTIONARY = new Dictionary();			}			if( _INSTANCE_DICTIONARY[_address] == null ){				_INSTANCE_DICTIONARY[_address] = new Vector.<OSCSyncProcess>();			}			_INSTANCE_DICTIONARY[_address].push(this);						// --- Setup OSCSocket. ---						_mngr = OSCSyncManager.getInstance();						_mngr.addEventListener( _address + "/begin"           , _onBegin          );			_mngr.addEventListener( _address + "/begin_"          , _onBeginInquiry   );			_mngr.addEventListener( _address + "/execute"         , _onExecute        );			_mngr.addEventListener( _address + "/complete"        , _onComplete       );			_mngr.addEventListener( _address + "/end"             , _onEnd            );			_mngr.addEventListener( _address + "/cancel"          , _onCancel         );			_mngr.addEventListener( _address + "/cancel_"         , _onCancelInquiry  );			_mngr.addEventListener( _address + "/cancel/start"    , _onCancelStart    );			_mngr.addEventListener( _address + "/canceled"        , _onCanceled       );			_mngr.addEventListener( _address + "/cancel/complete" , _onCancelComplete );			_mngr.addEventListener( _address + "/error"           , _onError          );						// TODO グループを作成し、グルーピングが完了するまで begin が実行されてもペンドするようにする.			_mngr.addEventListener( OSCSyncManagerEvent.GROUP_CREATED, _onGroupCreated );						_mngr.createGroup( this );			        }				/** 同期グループ. */		public function get group():String{ return _group; }				/** 同期キー */		public function get key():String{ return _key; }				/** 同期プロセスの名称 (group:key) */		public function get name():String{ return _group + ":" + _key; }				/** 同期開始時刻. */		public function get timestamp():Number{ return _timestamp; }				// --- Activity Information. ---				/** 同期処理が実行中であるか. */		public function get running():Boolean{ return _running; }				/**		 * グループ登録が受け付けられ,実行可能な状態にあるか.		 * これが false の状況で begin 等を実行した場合は true になるまで実行を延期する.		 */		public function get enable():Boolean{ return _enable; }				// --- Host Information. ---				/** 自分がこのグループのホストであるかを調べる. */		public function get isHost():Boolean{			return isLocalLeader && OSCSyncManager.getInstance().isHost( group );		}				/** ローカルグループ内のリーダーであるかを調べる. */		public function get isLocalLeader():Boolean{			return _INSTANCE_DICTIONARY != null && _INSTANCE_DICTIONARY[_address] != null && _INSTANCE_DICTIONARY[_address][0] == this;		}				// --- Process Settings. ---				/**		 * 実行する関数を追加します.		 * @param closure		 */		public function addProcess( closure:Function ):void{			// ClosureLinkedList にラップして扱いやすくします.			var c:ClosureLinkedList = new ClosureLinkedList( _closureVec.length, closure );			_closureDict[closure] = c;			if( 1 < _closureVec.length ){				var tail:ClosureLinkedList = _closureVec[_closureVec.length-1];				tail.next = c;				c.prev = tail;			}			_closureVec.push( c );		}								// =============================================================		// === SYNC BEGIN		/**		 * 処理を開始します.		 * ホストでない場合は何も行いません.		 * @param args		 */		public function begin( ...args ):void{						// 既に実行中の場合は Error を throw する.			if( _running ){				throw new Error("OSCSyncProcess [" + name + "] is already running.");				return;			}						//trace( this, "begin", args );						// 同期処理が activate されていない場合には			// 実行を activate のタイミングまで遅らせる.			if( !_enable ){				addEventListener( OSCSyncProcessEvent.ACTIVATE, _onActivate );				return;			}						var msg:OSCMessage = new OSCMessage();						// 自分がホストの場合同期開始を通知する.			if( isHost  == true ){				msg.address = _address + "/begin";			}else{				msg.address = _address + "/begin_";			}						msg.addArgument("d", new Date().time);			if( args != null ){				for( var i:int = 0; i < args.length; i++ ){					if( args[i] is int || _args[i] is uint ){						msg.addArgument("i",args[i]);					}else if( _args[i] is Number ){						msg.addArgument("d",args[i]);					}else if( _args[i] is String ){						msg.addArgument("s",args[i]);					}				}			}						_mngr.broadcast( msg );					}				/**		 * 同期処理が activate されていない場合に		 * 実行を activate のタイミングまで遅らせるためのハンドラ.		 * @param event		 */		private function _onActivate(event:OSCSyncProcessEvent):void{						//trace( this, "_onActivate" );						removeEventListener( OSCSyncProcessEvent.ACTIVATE, _onActivate );			begin.apply(null, _args);		}				/**		 * 同期開始の申請が来た際の処理.		 * @param event		 */		private function _onBeginInquiry(event:OSCSocketEvent):void{			//trace( this, "_onBeginInquiry" );			if( isHost && !running ){				begin.apply(null,event.args);			}		}				/**		 * 同期処理の開始が通知された際の処理.		 * @param event		 */				private function _onBegin(event:OSCSocketEvent):void{						//trace( this, "_onBegin" );						// --- If running process already.			if( _running == true ){				return;			}						var i:int;						// --- Init Properties.			_running        = true;			_pointer        = 0;			_timestamp      = Number( event.args[0] );			_numGroupMember = _mngr.numGroupMember( group );						_args = new Array();			for( i = 1; i < event.args.length; i++ ){				_args.push( event.args[i] );			}						// --- ローカル内の親が代表して OSC を送信するために.			// --- インスタンスの一覧を保持し,内部のコンプリートを監視する.			if( isLocalLeader == true ){				var v:Vector.<OSCSyncProcess>  = _INSTANCE_DICTIONARY[_address];				var v2:Vector.<OSCSyncProcess> = new Vector.<OSCSyncProcess>();				var v3:Vector.<OSCSyncProcess> = new Vector.<OSCSyncProcess>();				for( i = 0; i < v.length; i++ ){					v[i].addEventListener( "_complete", _onExecuteComplete );					v2.push(v[i]);					v3.push(v[i]);				}				_PROCESS_TARGET_INSTANCE_LIST[_address] = v2;				_PROCESS_INSTANCE_LIST[_address]        = v3;			}						// --- If timeout timer exists. Start timer.			if(_timeoutTimer != null ){				_timeoutTimer.reset();				_timeoutTimer.start();			}						// --- Dispatch Begin Event.			dispatchEvent( new OSCSyncProcessEvent( OSCSyncProcessEvent.BEGIN ) );						if( isHost ){				var msg:OSCMessage = new OSCMessage();				msg.address = _address + "/execute";				msg.addArgument( "i", _pointer );				msg.addArgument( "d", timestamp);				_mngr.broadcast( msg );			}					}				/**		 * 実行を通知された際の処理.		 * @param event		 */		private function _onExecute(event:OSCSocketEvent):void{						// begin を受け取っていない場合は無条件で完了.			if( _running == false ){				dispatchEvent( new Event("_complete") );				return;			}						// --- complete を受け取った数.			// --- 次のプロセスに進むかを判断するのに使う.			_completeCount = 0;						// Timeout の Timer が設定されている場合は処理が実行されたのでリセットする.			if( _timeoutTimer != null ){				_timeoutTimer.reset();				_timeoutTimer.start();			}						_pointer   = event.args[0];			_timestamp = Number(event.args[1]);						_closureVec[_pointer].closure(_args);					}				/**		 * 処理シーケンスの完了通知を行います.		 * @param pointer		 */		public function complete( closure:Function ):void{			//trace( this, "complete", closure );			if( _running && _pointer == ClosureLinkedList( _closureDict[closure] ).index ){				//trace("OscSyncProcess.complete("+_pointer+")");				dispatchEvent( new Event("_complete") );			}		}				/**		 * 処理完了時の処理.		 * 内部にインスタンスが複数存在した場合に対応するための処理.		 * 内部的に作成された OscSyncProcess の数に応じて、処理内容を決定する.		 * @param	event		 */		private function _onExecuteComplete(event:Event):void{						// trace( this, "_onExecuteComplete" );						// ローカル内の親が代表して OSC を送信するために.			// インスタンスの一覧を保持し,内部のコンプリートを監視する.						if( isLocalLeader == true ){								var i:int, v:Vector.<OSCSyncProcess>;								// 保持しているインスタンスを照合し、存在すれば完了とみなす.				v = _PROCESS_INSTANCE_LIST[_address];				for( i = 0; i < v.length; i++ ){					if( v[i] == event.target ){						v[i].removeEventListener( "_complete", _onExecuteComplete );						v.splice(i--,1);					}				}								// 監視すべきインスタンスが、リストからなくなった場合に完了を通知する.				if( v.length == 0 ){										v = _PROCESS_TARGET_INSTANCE_LIST[_address];					var v2:Vector.<OSCSyncProcess> = new Vector.<OSCSyncProcess>();					for( i = 0; i < v.length; i++ ){						v[i].addEventListener( "_complete", _onExecuteComplete );						v[i].dispatchEvent(	new OSCSyncProcessEvent( OSCSyncProcessEvent.COMPLETE ) );						v2.push(v[i]);					}					_PROCESS_INSTANCE_LIST[_address] = v2;										var msg:OSCMessage = new OSCMessage();					msg.address = _address + "/complete";					msg.addArgument("i", _pointer );					_mngr.broadcast( msg );									}							}					}				/**		 * 処理完了時の処理.		 * @param event		 */		private function _onComplete(event:OSCSocketEvent):void{						//trace( this, "_onComplete" );						var pointer:int = int(event.args[0]);			if( _pointer == pointer && isHost ){				if( _numGroupMember <= ++_completeCount ){					var msg:OSCMessage = new OSCMessage();					if( ++_pointer == _closureVec.length ){						msg.address = _address + "/end";					}else{						msg.address = _address + "/execute";						msg.addArgument( "i", _pointer );						msg.addArgument( "d", timestamp);					}					_mngr.broadcast( msg );				}			}		}				/**		 * 完了を通知された際の処理.		 * @param event		 */		private function _onEnd(event:OSCSocketEvent):void{			//trace(this,'_onEnd');			_running = false;			if(_timeoutTimer != null){				_timeoutTimer.stop();				_timeoutTimer.reset();			}			dispatchEvent( new OSCSyncProcessEvent( OSCSyncProcessEvent.END ) );		}						// TODO 全クライアントがどこをホストだと思ってるかを調べて整合性を取る.				// =============================================================		// === SYNC CANCEL				/**		 * キャンセル処理を行います.		 */		public function cancel():void{			//(this,'cancel');			if( _running ){				var msg:OSCMessage = new OSCMessage();				if( isHost ){					// ホストの場合はキャンセルを通知します.					//trace("OscSyncProcess.cancel()");					msg.address = _address + "/cancel";				}else{					// ホストでない場合はキャンセルを要請します.					//trace("OscSyncProcess.cancel()");					msg.address = _address + "/cancel_";				}				_mngr.broadcast( msg );			}		}				/**		 * キャンセル処理をクライアントからホストに対して要請した際の処理.		 * ホストであればキャンセルを行う.		 * @param event		 */		private function _onCancelInquiry(event:OSCSocketEvent):void{			//trace(this,'_onCancelInquiry');			if( isHost && running ){				//trace("OscSyncProcess.cancel()");				var msg:OSCMessage = new OSCMessage();				msg.address = _address + "/cancel";				_mngr.broadcast( msg );			}		}				/**		 * キャンセル処理を通知された際の処理.		 * Host であった場合はキャンセルプロセスを開始します.		 * @param event		 */		private function _onCancel(event:OSCSocketEvent):void{			// trace(this,'_onCancel');			if( isHost ){				// --- キャンセル完了を通知する.				_completeCount = 0;				var msg:OSCMessage = new OSCMessage();				msg.address = _address + "/cancel/start";				_mngr.broadcast( msg );			}		}				/**		 * キャンセル処理の開始が通達された際の処理.		 * キャンセルを行います.		 * @param event		 */		private function _onCancelStart(event:OSCSocketEvent):void{			//(this,'_onCancelStart');			_cancel();			var msg:OSCMessage = new OSCMessage();			msg.address = _address + "/canceled";			_mngr.broadcast( msg );		}				/**		 * クライアントからのキャンセル完了通知を取得し.		 * 全クライアントがキャンセルされたタイミングでメッセージを通達する.		 * @param event		 */				private function _onCanceled(event:OSCSocketEvent):void{			//trace(this,'_onCanceled');			if( isHost && _numGroupMember <= ++_completeCount ){				var msg:OSCMessage = new OSCMessage();				msg.address = _address + "/cancel/complete";				_mngr.broadcast( msg );			}		}				/**		 * 全てのキャンセル処理が完了した際の処理.		 * CANCEL イベントを通知します.		 * @param event		 */				private function _onCancelComplete(event:OSCSocketEvent):void{			//trace(this,'_onCancelComplete');			_running = false;			dispatchEvent( new OSCSyncProcessEvent( OSCSyncProcessEvent.CANCEL ) );		}				/**		 * キャンセルの実処理.		 * タイムアウト用タイマーの停止や、インスタンスの監視をすべてキャンセルする.		 */		private function _cancel():void{						// trace(this,'_cancel');						// --- タイムアウト用のタイマーを停止する.						if( _timeoutTimer != null ){				_timeoutTimer.removeEventListener( TimerEvent.TIMER_COMPLETE, _onTimeoutTimerComplete );				_timeoutTimer.stop();				_timeoutTimer = null;			}						// --- 保持しているインスタンスの監視を全てキャンセルする.						var i:int, v:Vector.<OSCSyncProcess>;						v = _PROCESS_INSTANCE_LIST[_address];			if( v ){				for( i = 0; i < v.length; i++ ){					v[i].removeEventListener( "_complete", _onExecuteComplete );				}			}						_PROCESS_TARGET_INSTANCE_LIST[_address] = null;			delete _PROCESS_TARGET_INSTANCE_LIST[_address];						_PROCESS_INSTANCE_LIST[_address] = null;			delete _PROCESS_INSTANCE_LIST[_address];					}				// =============================================================		// === SYNC ERROR				/**		 * エラー発生を通知します.		 */		public function error():void{			//trace(this,'error');			if( _running ){				var msg:OSCMessage = new OSCMessage();				msg.address = _address + "/error";				_mngr.broadcast( msg );			}		}				private function _onError(event:OSCSocketEvent):void{			//trace(this,'_onError');			//trace("OscSyncProcess.error()");			dispatchEvent( new OSCSyncProcessEvent( OSCSyncProcessEvent.ERROR ) );		}				/**		 * インスタンスを破棄します.		 * 不要になったインスタンスは必ずこの関数を実行し破棄してください.		 */		public function destroy():void{						//trace("OscSyncProcess.destory()");						_mngr.removeEventListener( _address + "/begin"           , _onBegin          );			_mngr.removeEventListener( _address + "/begin_"          , _onBeginInquiry   );			_mngr.removeEventListener( _address + "/execute"         , _onExecute        );			_mngr.removeEventListener( _address + "/complete"        , _onComplete       );			_mngr.removeEventListener( _address + "/end"             , _onEnd            );			_mngr.removeEventListener( _address + "/cancel"          , _onCancel         );			_mngr.removeEventListener( _address + "/cancel_"         , _onCancelInquiry  );			_mngr.removeEventListener( _address + "/cancel/start"    , _onCancelStart    );			_mngr.removeEventListener( _address + "/canceled"        , _onCanceled       );			_mngr.removeEventListener( _address + "/cancel/complete" , _onCancelComplete );			_mngr.removeEventListener( _address + "/error"           , _onError          );			_mngr.removeEventListener( OSCSyncManagerEvent.GROUP_CREATED, _onGroupCreated );			_mngr = null;						// --- タイムアウトのタイマーが存在する場合停止しておく.						if(_timeoutTimer != null){				_timeoutTimer.removeEventListener( TimerEvent.TIMER_COMPLETE, _onTimeoutTimerComplete );				_timeoutTimer.stop();				_timeoutTimer = null;			}						// --- 自分が抜けるにあたり,必要な処理群から外れる.						var i:int,				v:Vector.<OSCSyncProcess>;						v = _INSTANCE_DICTIONARY[_address] as Vector.<OSCSyncProcess>;			for( i = 0; i < v.length; i++ ){				if( v[i] == this ){					v.splice( i--, 1 );				}			}						v = _PROCESS_TARGET_INSTANCE_LIST[_address] as Vector.<OSCSyncProcess>;			for( i = 0; i < v.length; i++ ){				if( v[i] == this ){					v.splice( i--, 1 );				}			}						dispatchEvent( new Event( "_complete" ) );						// --- 破棄された事を通知.						dispatchEvent( new OSCSyncProcessEvent( OSCSyncProcessEvent.DESTROY ) );					}						        //------- PRIVATE ----------------------------------------------------------------------- */				/**		 * タイムアウト発生時の処理.		 * キャンセル処理を行います.		 * @param event		 */		private function _onTimeoutTimerComplete(event:TimerEvent):void{			//trace(this,'_onTimeoutTimerComplete');			//trace(event);			cancel();		}				/**		 * グループへの参加が完了した際の処理.		 * @param event		 */		private function _onGroupCreated(event:OSCSyncManagerEvent):void{			//trace(this,'_onGroupCreated');			if( event.groupName == group ){				_enable = true;				dispatchEvent( new OSCSyncProcessEvent( OSCSyncProcessEvent.ACTIVATE ) );			}		}				//------- PROTECTED ---------------------------------------------------------------------- */                //------- INTERNAL ----------------------------------------------------------------------- */		    }	}class PrivateClass{}/** * OSCSyncProcess で用いるプロセス同士のつながりを定義する Closure のラッパクラス. * @author sgmnt.org */class ClosureLinkedList{		// ------- MEMBER ---------------------------------------------		private var _index:int;	private var _closure:Function;	private var _next:ClosureLinkedList;	private var _prev:ClosureLinkedList;		// ------- PUBLIC ---------------------------------------------		/**	 * Constructor.	 * @param index	 * @param closure	 */		public function ClosureLinkedList( index:int, closure:Function ){		_index   = index;		_closure = closure;	}		/** Closure の実行順 index. */	public function get index():int{ return _index }		/** 実行すべき Closure への参照. */	public function get closure():Function{ return _closure; }		/** 次に実行すべき ClosureLinkedList への参照. */	public function get next():ClosureLinkedList{ return _next; }	public function set next(value:ClosureLinkedList):void{		_next = value;	}		/** 前に実行すべき ClosureLinkedList への参照. */	public function get prev():ClosureLinkedList{ return _prev; }	public function set prev(value:ClosureLinkedList):void{		_prev = value;	}	}