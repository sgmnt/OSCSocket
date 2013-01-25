﻿/** * * Copyright (c) 2010 - 2012, http://sgmnt.org/ *  * Permission is hereby granted, free of charge, to any person obtaining * a copy of this software and associated documentation files (the * "Software"), to deal in the Software without restriction, including * without limitation the rights to use, copy, modify, merge, publish, * distribute, sublicense, and/or sell copies of the Software, and to * permit persons to whom the Software is furnished to do so, subject to * the following conditions: *  * The above copyright notice and this permission notice shall be * included in all copies or substantial portions of the Software. *  * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. * */package org.sgmnt.lib.osc {        import flash.events.Event;    import flash.events.EventDispatcher;    import flash.events.TimerEvent;    import flash.net.InterfaceAddress;    import flash.net.NetworkInfo;    import flash.net.NetworkInterface;    import flash.utils.Dictionary;    import flash.utils.Timer;        /**     * .     * Singleton Class.     * @author  sgmnt.org     * @version 0.1     */    public class OSCSyncManager extends EventDispatcher{                //------- CONSTS ----------------------------------------------------------------------- */		        //------- MEMBER ----------------------------------------------------------------------- */                /** Singleton Instance. */        static private var _instance:OSCSyncManager;        		private var _enabled:Boolean;				private var _socket:OSCBroadcastSocket;				private var _localAddress:String;				private var _basetime:Number;		private var _basetimeTimer:Timer;				private var _groups:Dictionary;		private var _life:Number;		        private var _createGroupTimerDictionary:Dictionary;				//------- PUBLIC ----------------------------------------------------------------------- */                /**         * Private Constructor.         */        public function OSCSyncManager( pvtClass:PrivateClass ) {                        super();						_enabled       = false;						_groups = new Dictionary();			_life   = 100000.0;						_createGroupTimerDictionary = new Dictionary();			        }		        /**         * Get Singleton Instance.         * @return         */        static public function getInstance():OSCSyncManager{            if( _instance == null ){                _instance = new OSCSyncManager( new PrivateClass() );            }            return _instance;        }        		/**		 * 初期化処理です.必ず同期を開始する前に、始めに一回実行してください.		 * broadcast の方法などの Manager の基本的な挙動を設定します.		 * @param localAddress  自分のマシンのアドレス.		 * @param syncPort      同期処理を受信するポート.		 * @param broadcastPort ブロードキャストを通知するポート. 未指定の場合 ブロードキャストはしない.		 */		public function initialize( configure:OSCSyncManagerConfigure ):void{						// --- Setup Local Address. ---						_localAddress  = configure.localAddress;						// --- Create OSCSocket. ---						_socket = configure.broadcastSocket;			_socket.addEventListener( "/basetime"      , _onBasetimeMessageReceived     );			_socket.addEventListener( "/group/create"  , _onGroupCreateMessageReceived  );			_socket.addEventListener( "/group/destroy" , _onGroupDestoryMessageReceived );			_socket.addEventListener( OSCSocketEvent.CLOSE, _onSocketClose );			_socket.addEventListener( OSCSocketEvent.ERROR, _onSocketError );						// --- Setup Basetime. ---						_basetime = new Date().time;			_basetimeTimer = new Timer( 10000 );			_basetimeTimer.addEventListener( TimerEvent.TIMER, _onBasetimeUpdateTimer );			_basetimeTimer.start();						// --- Setup Basetime. ---						_socket.broadcast( new OSCMessage("/basetime ,d "+basetime) );					}				public function enable():void{			if( _enabled ) return;			_enabled = true;			dispatchEvent( new OSCSyncManagerEvent( OSCSyncManagerEvent.ENABLED ) );		}				public function disable():void{			if( !_enabled ) return;			_enabled = false;			dispatchEvent( new OSCSyncManagerEvent( OSCSyncManagerEvent.DISABLED ) );		}				/**		 * メッセージのブロードキャストを行います.		 * @param msg		 */				public function broadcast( msg:OSCPacket ):void{			_socket.broadcast( msg, 100 );		}				// --- Override EventDispatcher Interfaces. ---				/**		 * 		 * @param type		 * @param listener		 * @param useCapture		 * @param priority		 * @param useWeakReference		 */		override public function addEventListener( type:String, listener:Function,												   useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false ):void{			switch( type ){				case OSCSyncManagerEvent.SOCKET_ERROR :				case OSCSyncManagerEvent.ENABLED :				case OSCSyncManagerEvent.DISABLED :				case OSCSyncManagerEvent.GROUP_CREATED :					super.addEventListener( type, listener, useCapture, priority, useWeakReference );					break;				default :					_socket.addEventListener( type, listener, useCapture, priority, useWeakReference );			}		}				/**		 * 		 * @param type		 * @param listener		 * @param useCapture		 * 		 */		override public function removeEventListener( type:String, listener:Function, useCapture:Boolean = false ):void{			switch( type ){				case OSCSyncManagerEvent.SOCKET_ERROR :				case OSCSyncManagerEvent.ENABLED :				case OSCSyncManagerEvent.DISABLED :				case OSCSyncManagerEvent.GROUP_CREATED :					super.removeEventListener( type, listener, useCapture );					break;				default :					_socket.removeEventListener( type, listener, useCapture );			}		}				/**		 * 		 * @param type		 * @return 		 */		override public function hasEventListener( type:String ):Boolean{			switch( type ){				case OSCSyncManagerEvent.SOCKET_ERROR :				case OSCSyncManagerEvent.ENABLED :				case OSCSyncManagerEvent.DISABLED :				case OSCSyncManagerEvent.GROUP_CREATED :					return super.hasEventListener( type );					break;				default :					return _socket.hasEventListener( type );			}		}				/** 同期の基点なる時間を取得します. */				public function get basetime():Number{ return _basetime; }				/**		 * 指定した名称のグループにいくつのクライアントが存在するかを取得します.		 * @param name		 * @return 		 */		public function numGroupMember(name:String):int{			return _groups[name] ? _groups[name].numClients : 0;		}		        /** 指定したグループに対して自分がホストであるか否か. */        public function isHost( groupName:String ):Boolean{ return _groups[groupName] && _groups[groupName].hostIP == _localAddress; }                // --- Control.                /**         * grouping の設定をサーバに要請します.         * 実際の要請処理は Timer で一定時間ごとに行われます.         * @param group グループ名.         */        public function createGroup( process:OSCSyncProcess ):void{						// TODO 1 Group の入れ物を作る.			// TODO 2 メッセージを受信し、登録していなければ実行する.			// TODO 3 登録されたタイミングで待ち時間を更新する.			// TODO 4 待ち時間が終了したらグループが制作作成されたことを伝え activate する.						var groupName:String = process.group;						if( _groups[groupName] == null ){								var group:OSCSyncManagerGroup = new OSCSyncManagerGroup(groupName);				_groups[groupName] = group;								group.addEventListener( Event.ADDED , _onGroupAdded );				group.addEventListener( Event.CHANGE, _onGroupAdded );				group.addEventListener( Event.CLEAR , _onGroupActivate );								_broadcastCreateGroupMessage( group );								group.timer.addEventListener( TimerEvent.TIMER, function(e:TimerEvent):void{					_broadcastCreateGroupMessage( group );				});				group.timer.start();							}                    }				/**		 * グループ作成のメッセージをブロードキャストします.		 * @param name		 */		private function _broadcastCreateGroupMessage( group:OSCSyncManagerGroup ):void{			var msg:OSCMessage = new OSCMessage();			msg.address = "/group/create";			msg.addArgument( "s", group.name );			if( group.hostIP && group.hostIP != "" ){				msg.addArgument( "s", group.hostIP );			}			_socket.broadcast( msg );		}				/**		 * グループにメンバーが追加された際の処理.		 * 自分のIPをもう一度 broadcast する.		 * @param event		 */		private function _onGroupAdded(event:Event):void{			var group:OSCSyncManagerGroup = event.target as OSCSyncManagerGroup;			if( group ){				_broadcastCreateGroupMessage( group );			}		}				/**		 * onGroupActivate.		 * @param event		 */		private function _onGroupActivate(event:Event):void{			//trace("_onGroupActivate");			var group:OSCSyncManagerGroup = event.target as OSCSyncManagerGroup;			if( group ){				var evt:OSCSyncManagerEvent = new OSCSyncManagerEvent( OSCSyncManagerEvent.GROUP_CREATED );				evt._groupName = group.name;				dispatchEvent( evt );			}		}				/**		 * グループ生成のメッセージが来た際の処理.		 * 生成を確認したグループは通知の頻度を遅くする.		 * @param event		 */		private function _onGroupCreateMessageReceived(event:OSCSocketEvent):void{			var groupName:String = event.args[0];			var hostIP:*         = ( 1 < event.args.length ) ? event.args[1] : null;			var group:OSCSyncManagerGroup = _groups[groupName];			if( group ){				group.add( event.srcAddress );				// ホストの IP の通知がある場合.				if( hostIP ){					group.hostIP = hostIP;				}				var timer:Timer = group.timer;				timer.delay = Math.floor( _life * 0.4649 );				timer.reset();				timer.start();			}		}		        /**         * grouping の破棄をサーバに要請します.         * @param group グループ名.         */        public function destroyGroup( process:OSCSyncProcess ):void{            			var group:String = process.group;			            var timer:Timer = _createGroupTimerDictionary[group];            if( timer != null ){                timer.stop();                _createGroupTimerDictionary[group] = null;                delete _createGroupTimerDictionary[group];            }                        var msg:OSCMessage = new OSCMessage();            	msg.address = "/group/destroy";            	msg.addArgument("s",group);            _socket.broadcast( msg );                    }				/**		 * グループ生成のメッセージが来た際の処理.		 * 生成を確認したグループは通知の頻度を遅くする.		 * @param event		 */		private function _onGroupDestoryMessageReceived(event:OSCSocketEvent):void{			var group:String = event.args[0];						// need to development.		}				/**		 * OSCSocket の接続を切断します.		 */				public function close():void{			_socket.close();		}				/**		 * 同期グループの状況を取得します.		 */		public function get status():String{			var str:String = "-------------------------\n";			for( var key:String in _groups ){				str += _groups[key].toString();			}			str += "-------------------------\n";			return str;		}		        //------- PRIVATE ----------------------------------------------------------------------- */				// ===============================================================		// === basetime の設定				/**		 * 自分の basetime を通知し、他のマシンとの整合性を取る.		 * @param event		 */		private function _onBasetimeUpdateTimer(event:TimerEvent):void{			_socket.broadcast( new OSCMessage("/basetime ,d " + basetime) );		}				/**		 * 送られてきた basetime と自分のベースタイムを比べ、より早いベースタイムであった場合そちらにあわせる.		 * @param event		 */		private function _onBasetimeMessageReceived(event:OSCSocketEvent):void{			var time:Number = Number( event.args[0] );			//trace("_onBasetimeMessageReceived", time, _basetime);			if( time < _basetime ){				_basetime = time;			}else if( _basetime < time ){				// 自分よりも遅い時刻が送られてきた場合、自分の時間を通知しかえす.				_socket.broadcast( new OSCMessage("/basetime ,d " + basetime) );			}		}		        /**         * OSCSocket の接続が閉じられた際に実行されます.         * @param event         */        private function _onSocketClose(event:Event):void{            dispatchEvent( new OSCSyncManagerEvent( OSCSyncManagerEvent.SOCKET_ERROR ) );        }                /**         * OSCSocket の接続でエラーが発生した際に実行されます.         * エラー発生の旨を通知します.         * @param event         */        private function _onSocketError(event:Event):void{            dispatchEvent( new OSCSyncManagerEvent( OSCSyncManagerEvent.SOCKET_ERROR ) );        }		        //------- PROTECTED ---------------------------------------------------------------------- */                //------- INTERNAL ----------------------------------------------------------------------- */        	}    }class PrivateClass{}