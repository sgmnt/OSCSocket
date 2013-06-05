﻿/** *  * Copyright (c) 2010 - 2013, http://sgmnt.org/ *  * Permission is hereby granted, free of charge, to any person obtaining * a copy of this software and associated documentation files (the * "Software"), to deal in the Software without restriction, including * without limitation the rights to use, copy, modify, merge, publish, * distribute, sublicense, and/or sell copies of the Software, and to * permit persons to whom the Software is furnished to do so, subject to * the following conditions: *  * The above copyright notice and this permission notice shall be * included in all copies or substantial portions of the Software. *  * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. * */package org.sgmnt.lib.osc {		import flash.events.Event;	import flash.events.EventDispatcher;	import flash.events.TimerEvent;	import flash.utils.Dictionary;	import flash.utils.Timer;		import org.sgmnt.lib.debug.DebugTrace;
	    /**     * OscSyncManager で管理される処理同期プロセスです.	 * このクラスを使う事で同期処理を簡潔に記述する事が出来ます.	 * 	 * @author  sgmnt.org     * @version 0.1     */    public class OSCSyncProcessSimulator extends EventDispatcher implements IOSCSyncProcess{                //------- CONSTS ----------------------------------------------------------------------- */				//------- MEMBER ----------------------------------------------------------------------- */				static private var _INSTANCE_DICTIONARY:Dictionary;		static private var _PROCESS_TARGET_INSTANCE_LIST:Dictionary;		static private var _PROCESS_INSTANCE_LIST:Dictionary;		static private var _EVENT_DISPATCHER:EventDispatcher;				private var _uniqueKey:String;				/** 同期のグループ名. */		private var _groupName:String;		/** 同期のキー. */		private var _key:String;		/** 同期通知を行う OSC のアドレス. */		private var _address:String;		/** 同期処理にタイムアウトが存在する場合のタイムアウト用タイマー. */		private var _timeoutTimer:Timer;				/** 同期処理が実行中であるか. */		private var _running:Boolean;		/** 同期処理実行時の時刻. */		private var _timestamp:Number;				/** 現在何番目の同期処理を行っているかのポインタ. */		private var _pointer:int;		/** 同期実行する関数を格納する Vector クラス. */		private var _closureVec:Vector.<ClosureLinkedList>;		/** closure 用辞書クラス. */		private var _closureDict:Dictionary;				/** 同期時に受け渡しされる引数. */		private var _args:Array;		        //------- PUBLIC ----------------------------------------------------------------------- */                /**         * Constructor.		 * 		 * OSCSyncProcess を AIR ではなく FlashPlayer 上でシミュレートするためのクラス.		 * 		 * @param group   同期グループ名.		 * @param key     同期処理を一意に定めるためのユニークキー.		 * @param timeout 同期処理のタイムアウト時間.         */        public function OSCSyncProcessSimulator( group:String, key:String, timeout:Number = 0 ) {			            super();						// --- Setup Member Properties. ---						_uniqueKey = "_" + group + "_" + key + "_" + ( new Date().time );						_groupName = group;			_key       = key;			_address   = "/sync/" + _groupName + "/" + _key;						_running = false;						_pointer = 0;			_closureVec  = new Vector.<ClosureLinkedList>();			_closureDict = new Dictionary();						// --- Create timeout timer. If needed. ---			if( 0 < timeout ){				_timeoutTimer = new Timer( timeout, 1 );				_timeoutTimer.addEventListener( TimerEvent.TIMER_COMPLETE, _onTimeoutTimerComplete );			}						// --- Create Static Properties. ----						if( _PROCESS_INSTANCE_LIST == null ){				_PROCESS_INSTANCE_LIST = new Dictionary();			}						if( _PROCESS_TARGET_INSTANCE_LIST == null ){				_PROCESS_TARGET_INSTANCE_LIST = new Dictionary();			}						if( _INSTANCE_DICTIONARY == null ){				_INSTANCE_DICTIONARY = new Dictionary();			}			if( _INSTANCE_DICTIONARY[_address] == null ){				_INSTANCE_DICTIONARY[_address] = new Vector.<IOSCSyncProcess>();			}			_INSTANCE_DICTIONARY[_address].push(this);						// --- Setup OSCSocket. ---						if( _EVENT_DISPATCHER == null ){				_EVENT_DISPATCHER = new EventDispatcher(this);			}						_EVENT_DISPATCHER.addEventListener( _address + "/begin"           , _onBegin          );			_EVENT_DISPATCHER.addEventListener( _address + "/begin_"          , _onBeginInquiry   );			_EVENT_DISPATCHER.addEventListener( _address + "/execute"         , _onExecute        );			_EVENT_DISPATCHER.addEventListener( _address + "/complete"        , _onComplete       );			_EVENT_DISPATCHER.addEventListener( _address + "/end"             , _onEnd            );			_EVENT_DISPATCHER.addEventListener( _address + "/cancel"          , _onCancel         );			_EVENT_DISPATCHER.addEventListener( _address + "/cancel_"         , _onCancelInquiry  );			_EVENT_DISPATCHER.addEventListener( _address + "/cancel/start"    , _onCancelStart    );			_EVENT_DISPATCHER.addEventListener( _address + "/canceled"        , _onCanceled       );			_EVENT_DISPATCHER.addEventListener( _address + "/cancel/complete" , _onCancelComplete );			_EVENT_DISPATCHER.addEventListener( _address + "/error"           , _onError          );						dispatchEvent( new OSCSyncProcessEvent( OSCSyncProcessEvent.ACTIVATE ) );			        }				/** 同期グループ. */		public function get group():String{			return _groupName;		}				/** 同期キー */		public function get key():String{			return _key;		}				/** 同期プロセスの名称 (group:key) */		public function get name():String{			return _groupName + ":" + _key;		}				/** 同期開始時刻. */		public function get timestamp():Number{			return _timestamp;		}				// --- Activity Information. ---				/** 同期処理が実行中であるか. */		public function get running():Boolean{			return _running;		}				/**		 * グループ登録が受け付けられ,実行可能な状態にあるか.		 * これが false の状況で begin 等を実行した場合は true になるまで実行を延期する.		 */		public function get enable():Boolean{			return true;		}				// --- Host Information. ---				/** 自分がこのグループのホストであるかを調べる. */		public function get isHost():Boolean{			return isLocalLeader;		}				/** ローカルグループ内のリーダーであるかを調べる. */		public function get isLocalLeader():Boolean{			return _INSTANCE_DICTIONARY != null && _INSTANCE_DICTIONARY[_address] != null && _INSTANCE_DICTIONARY[_address][0] == this;		}				// --- Process Settings. ---				/**		 * 実行する関数を追加します.		 * @param closure		 */		public function addProcess( closure:Function ):void{			// ClosureLinkedList にラップして扱いやすくします.			var c:ClosureLinkedList = new ClosureLinkedList( _closureVec.length, closure );			_closureDict[closure] = c;			if( 1 < _closureVec.length ){				var tail:ClosureLinkedList = _closureVec[_closureVec.length-1];				tail.next = c;				c.prev = tail;			}			_closureVec.push( c );		}								// =============================================================		// === SYNC BEGIN		/**		 * 処理を開始します.		 * ホストでない場合は何も行いません.		 * @param args		 */		public function begin( ...args ):void{						// 既に実行中の場合は Error を throw する.			if( _running ){				DebugTrace.debug("OSCSyncProcessSimulator [" + name + "] is already running.");				//throw new Error("OSCSyncProcessSimulator [" + name + "] is already running.");				return;			}						var eventType:String;			// 自分がホストの場合同期開始を通知する.			if( isHost  == true ){				eventType = _address + "/begin";				var arr:Array = [ new Date().time ];				if( args != null ){					for( var i:int = 0; i < args.length; i++ ){						arr.push( args[i] );					}				}				_EVENT_DISPATCHER.dispatchEvent( new OSCSocketEvent( eventType, null, -1, eventType, arr ) );			}					}				/**		 * 同期開始の申請が来た際の処理.		 * @param event		 */		private function _onBeginInquiry(event:OSCSocketEvent):void{			//trace( this, "_onBeginInquiry" );			if( isHost && !running ){				begin.apply(null,event.args);			}		}				/**		 * 同期処理の開始が通知された際の処理.		 * @param event		 */				private function _onBegin(event:OSCSocketEvent):void{						trace(_uniqueKey, "_onBegin")						// --- If running process already.			if( _running == true ){				return;			}						// --- Init Properties.						var i:int;						_running        = true;			_pointer        = 0;			_timestamp      = Number( event.args[0] );						_args = new Array();			for( i = 1; i < event.args.length; i++ ){				_args.push( event.args[i] );			}						trace(_uniqueKey,"args",_args);						// --- ローカル内の親が代表して OSC を送信するために.			// --- インスタンスの一覧を保持し,内部のコンプリートを監視する.			if( isLocalLeader == true ){				var v:Vector.<IOSCSyncProcess>  = _INSTANCE_DICTIONARY[_address];				var v2:Vector.<IOSCSyncProcess> = new Vector.<IOSCSyncProcess>();				var v3:Vector.<IOSCSyncProcess> = new Vector.<IOSCSyncProcess>();				for( i = 0; i < v.length; i++ ){					v[i].addEventListener( "_complete", _onExecuteComplete );					v2.push(v[i]);					v3.push(v[i]);				}				_PROCESS_TARGET_INSTANCE_LIST[_address] = v2;				_PROCESS_INSTANCE_LIST[_address]        = v3;							}						// --- If timeout timer exists. Start timer.			if(_timeoutTimer != null ){				_timeoutTimer.reset();				_timeoutTimer.start();			}						// --- Dispatch Begin Event.			dispatchEvent( new OSCSyncProcessEvent( OSCSyncProcessEvent.BEGIN ) );						if( isHost ){				trace(_pointer);				var timer:Timer = new Timer(100,1);				timer.addEventListener(TimerEvent.TIMER_COMPLETE, function(event):void{					_EVENT_DISPATCHER.dispatchEvent(						new OSCSocketEvent(							_address + "/execute", null, -1, _address + "/execute", [_pointer,timestamp]						)					);				});				timer.start();			}					}				/**		 * 実行を通知された際の処理.		 * @param event		 */		private function _onExecute(event:OSCSocketEvent):void{						trace(_uniqueKey, "_onExecute", _args)						// begin を受け取っていない場合は無条件で完了.			if( _running == false ){				dispatchEvent( new Event("_complete") );				return;			}						// Timeout の Timer が設定されている場合は処理が実行されたのでリセットする.			if( _timeoutTimer != null ){				_timeoutTimer.reset();				_timeoutTimer.start();			}						_pointer   = event.args[0];			_timestamp = Number(event.args[1]);						trace( _uniqueKey, "_pointer", _pointer );						_closureVec[_pointer].closure(_args);					}				/**		 * 処理シーケンスの完了通知を行います.		 * @param pointer		 */		public function complete( closure:Function ):void{			//trace( this, "complete", closure );			if( _running && _pointer == ClosureLinkedList( _closureDict[closure] ).index ){				//trace("OscSyncProcess.complete("+_pointer+")");				var timer:Timer = new Timer(100,1);				timer.addEventListener(TimerEvent.TIMER_COMPLETE, function(event){					dispatchEvent( new Event("_complete") );				});				timer.start();			}		}				/**		 * 処理完了時の処理.		 * 内部にインスタンスが複数存在した場合に対応するための処理.		 * 内部的に作成された OscSyncProcess の数に応じて、処理内容を決定する.		 * @param	event		 */		private function _onExecuteComplete(event:Event):void{						// trace( this, "_onExecuteComplete" );						// ローカル内の親が代表して OSC を送信するために.			// インスタンスの一覧を保持し,内部のコンプリートを監視する.						if( isLocalLeader == true ){								var i:int, v:Vector.<IOSCSyncProcess>;								// 保持しているインスタンスを照合し、存在すれば完了とみなす.				v = _PROCESS_INSTANCE_LIST[_address];								for( i = 0; i < v.length; i++ ){					if( v[i] == event.target ){						v[i].removeEventListener( "_complete", _onExecuteComplete );						v.splice(i--,1);					}				}								trace("vvvvvvvvvvvv", v.length);								// 監視すべきインスタンスが、リストからなくなった場合に完了を通知する.				if( v.length == 0 ){										v = _PROCESS_TARGET_INSTANCE_LIST[_address];					var v2:Vector.<IOSCSyncProcess> = new Vector.<IOSCSyncProcess>();					for( i = 0; i < v.length; i++ ){						v[i].addEventListener( "_complete", _onExecuteComplete );						v[i].dispatchEvent(	new OSCSyncProcessEvent( OSCSyncProcessEvent.COMPLETE ) );						v2.push(v[i]);					}					_PROCESS_INSTANCE_LIST[_address] = v2;										_EVENT_DISPATCHER.dispatchEvent(						new OSCSocketEvent( _address + "/complete", null, -1, _address + "/complete", [_pointer] )					);									}							}					}				/**		 * 処理完了時の処理.		 * @param event		 */		private function _onComplete(event:OSCSocketEvent):void{			//trace( this, "_onComplete" );			var pointer:int = int(event.args[0]);			if( _pointer == pointer && isHost ){				if( ++_pointer == _closureVec.length ){					_EVENT_DISPATCHER.dispatchEvent(						new OSCSocketEvent( _address + "/end", null, -1, _address + "/end" )					);				}else{					_EVENT_DISPATCHER.dispatchEvent(						new OSCSocketEvent( _address + "/execute", null, -1, _address + "/execute", [_pointer, timestamp] )					);				}			}		}				/**		 * 完了を通知された際の処理.		 * @param event		 */		private function _onEnd(event:OSCSocketEvent):void{			trace(_uniqueKey,'_onEnd');			_running = false;			if(_timeoutTimer != null){				_timeoutTimer.stop();				_timeoutTimer.reset();			}			var timer:Timer = new Timer(100,1);			timer.addEventListener(TimerEvent.TIMER_COMPLETE, function(event):void{				dispatchEvent( new OSCSyncProcessEvent( OSCSyncProcessEvent.END ) );			});			timer.start();		}						// TODO 全クライアントがどこをホストだと思ってるかを調べて整合性を取る.				// =============================================================		// === SYNC CANCEL				/**		 * キャンセル処理を行います.		 */		public function cancel():void{			//(this,'cancel');			if( _running ){				if( isHost ){					// ホストの場合はキャンセルを通知します.					_EVENT_DISPATCHER.dispatchEvent(						new OSCSocketEvent( _address + "/cancel", null, -1, _address + "/cancel" )					);				}else{					// ホストでない場合はキャンセルを要請します.					_EVENT_DISPATCHER.dispatchEvent(						new OSCSocketEvent( _address + "/cancel_", null, -1, _address + "/cancel_" )					);				}			}		}				/**		 * キャンセル処理をクライアントからホストに対して要請した際の処理.		 * ホストであればキャンセルを行う.		 * @param event		 */		private function _onCancelInquiry(event:OSCSocketEvent):void{			//trace(this,'_onCancelInquiry');			if( isHost && running ){				// ホストの場合はキャンセルを通知します.				_EVENT_DISPATCHER.dispatchEvent(					new OSCSocketEvent( _address + "/cancel", null, -1, _address + "/cancel" )				);			}		}				/**		 * キャンセル処理を通知された際の処理.		 * Host であった場合はキャンセルプロセスを開始します.		 * @param event		 */		private function _onCancel(event:OSCSocketEvent):void{			// trace(this,'_onCancel');			if( isHost ){				// --- キャンセル完了を通知する.				_EVENT_DISPATCHER.dispatchEvent(					new OSCSocketEvent( _address + "/start", null, -1, _address + "/start" )				);			}		}				/**		 * キャンセル処理の開始が通達された際の処理.		 * キャンセルを行います.		 * @param event		 */		private function _onCancelStart(event:OSCSocketEvent):void{			//(this,'_onCancelStart');			_cancel();			_EVENT_DISPATCHER.dispatchEvent(				new OSCSocketEvent( _address + "/canceled", null, -1, _address + "/canceled" )			);		}				/**		 * クライアントからのキャンセル完了通知を取得し.		 * 全クライアントがキャンセルされたタイミングでメッセージを通達する.		 * @param event		 */		private function _onCanceled(event:OSCSocketEvent):void{			//trace(this,'_onCanceled');			if( isHost ){				_EVENT_DISPATCHER.dispatchEvent(					new OSCSocketEvent( _address + "/cancel/complete", null, -1, _address + "/cancel/complete" )				);			}		}				/**		 * 全てのキャンセル処理が完了した際の処理.		 * CANCEL イベントを通知します.		 * @param event		 */				private function _onCancelComplete(event:OSCSocketEvent):void{			//trace(this,'_onCancelComplete');			_running = false;			dispatchEvent( new OSCSyncProcessEvent( OSCSyncProcessEvent.CANCEL ) );		}				/**		 * キャンセルの実処理.		 * タイムアウト用タイマーの停止や、インスタンスの監視をすべてキャンセルする.		 */		private function _cancel():void{						// trace(this,'_cancel');						// --- タイムアウト用のタイマーを停止する.						if( _timeoutTimer != null ){				_timeoutTimer.removeEventListener( TimerEvent.TIMER_COMPLETE, _onTimeoutTimerComplete );				_timeoutTimer.stop();				_timeoutTimer = null;			}						// --- 保持しているインスタンスの監視を全てキャンセルする.						var i:int, v:Vector.<IOSCSyncProcess>;						v = _PROCESS_INSTANCE_LIST[_address];			if( v ){				for( i = 0; i < v.length; i++ ){					v[i].removeEventListener( "_complete", _onExecuteComplete );				}			}						_PROCESS_TARGET_INSTANCE_LIST[_address] = null;			delete _PROCESS_TARGET_INSTANCE_LIST[_address];						_PROCESS_INSTANCE_LIST[_address] = null;			delete _PROCESS_INSTANCE_LIST[_address];					}				// =============================================================		// === SYNC ERROR				/**		 * エラー発生を通知します.		 */		public function error():void{			//trace(this,'error');			if( _running ){				_EVENT_DISPATCHER.dispatchEvent(					new OSCSocketEvent( _address + "/error", null, -1, _address + "/error" )				);			}		}				private function _onError(event:OSCSocketEvent):void{			//trace(this,'_onError');			//trace("OscSyncProcess.error()");			dispatchEvent( new OSCSyncProcessEvent( OSCSyncProcessEvent.ERROR ) );		}				/**		 * インスタンスを破棄します.		 * 不要になったインスタンスは必ずこの関数を実行し破棄してください.		 */		public function destroy():void{						//trace("OscSyncProcess.destory()");						_EVENT_DISPATCHER.removeEventListener( _address + "/begin"           , _onBegin          );			_EVENT_DISPATCHER.removeEventListener( _address + "/begin_"          , _onBeginInquiry   );			_EVENT_DISPATCHER.removeEventListener( _address + "/execute"         , _onExecute        );			_EVENT_DISPATCHER.removeEventListener( _address + "/complete"        , _onComplete       );			_EVENT_DISPATCHER.removeEventListener( _address + "/end"             , _onEnd            );			_EVENT_DISPATCHER.removeEventListener( _address + "/cancel"          , _onCancel         );			_EVENT_DISPATCHER.removeEventListener( _address + "/cancel_"         , _onCancelInquiry  );			_EVENT_DISPATCHER.removeEventListener( _address + "/cancel/start"    , _onCancelStart    );			_EVENT_DISPATCHER.removeEventListener( _address + "/canceled"        , _onCanceled       );			_EVENT_DISPATCHER.removeEventListener( _address + "/cancel/complete" , _onCancelComplete );			_EVENT_DISPATCHER.removeEventListener( _address + "/error"           , _onError          );						// --- タイムアウトのタイマーが存在する場合停止しておく.						if(_timeoutTimer != null){				_timeoutTimer.removeEventListener( TimerEvent.TIMER_COMPLETE, _onTimeoutTimerComplete );				_timeoutTimer.stop();				_timeoutTimer = null;			}						// --- 自分が抜けるにあたり,必要な処理群から外れる.						var i:int,				v:Vector.<IOSCSyncProcess>;						v = _INSTANCE_DICTIONARY[_address] as Vector.<IOSCSyncProcess>;			for( i = 0; i < v.length; i++ ){				if( v[i] == this ){					v.splice( i--, 1 );				}			}						v = _PROCESS_TARGET_INSTANCE_LIST[_address] as Vector.<IOSCSyncProcess>;			for( i = 0; i < v.length; i++ ){				if( v[i] == this ){					v.splice( i--, 1 );				}			}						dispatchEvent( new Event( "_complete" ) );						// --- 破棄された事を通知.						dispatchEvent( new OSCSyncProcessEvent( OSCSyncProcessEvent.DESTROY ) );					}						        //------- PRIVATE ----------------------------------------------------------------------- */				/**		 * タイムアウト発生時の処理.		 * キャンセル処理を行います.		 * @param event		 */		private function _onTimeoutTimerComplete(event:TimerEvent):void{			//trace(this,'_onTimeoutTimerComplete');			//trace(event);			cancel();		}				//------- PROTECTED ---------------------------------------------------------------------- */                //------- INTERNAL ----------------------------------------------------------------------- */		    }	}class PrivateClass{}