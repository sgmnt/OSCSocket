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
package org.sgmnt.lib.osc
{
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	/**
     * OSCメッセージをブロードキャストするためのクラスです.
	 * AIR 単体でのブロードキャスト機能は存在しないため UDPBroadcaster.jar を通じて行われます.
	 * そのため UDPBroadcaster.jar が起動していない場合は機能しません.
	 * 
     * @author  sgmnt.org
     * @version 0.1.1
	 */
	public class OSCBroadcastSocket extends OSCSocket
	{
		
		// ------- PRIVATE ----------------------------------------------
		
		private static var _INSTANCE:OSCBroadcastSocket;
		
		private var _initialized:Boolean;
		
		private var _address:String;
		private var _port:int;
		
		private var _checkTimer:Timer;
		private var _checkToken:String;
		
		// ------- PUBLIC -----------------------------------------------
		
		/**
		 * 
		 * @param pvt
		 */
		public function OSCBroadcastSocket( pvt:PrivateClass ):void
		{
			super();
		}
		
		/**
		 * Get Singleton Instance.
		 * @return 
		 */
		static public function getInstance():OSCBroadcastSocket{
			if( !_INSTANCE ){
				_INSTANCE = new OSCBroadcastSocket( new PrivateClass() );
			}
			return _INSTANCE;
		}
		
		/**
		 * Initialize OSCSocket for UDPBroadcaster.jar.
		 * @param broadcastListenPort
		 * @param udpBroadcasterAddress
		 * @param udpBroadcasterPort
		 */
		public function initialize( broadcastListenPort:int = 57577, udpBroadcasterPort:int = 57578,
									udpBroadcasterAddress:String = "127.0.0.1" ):void{
			
			if( _initialized ) throw new ReferenceError("OSCBroadcastSocket can't be initialized twice.");
			
			this._address = udpBroadcasterAddress;
			this._port    = udpBroadcasterPort;
			
			this.bind( broadcastListenPort );
			this.receive();
			
			this.addEventListener( "/__check__", _onChecked );
			
			// --- 動作チェック. ---
			
			this._checkToken = ":" + ( new Date().time ) + ":";
			
			this._checkTimer = new Timer( 1000, 10 );
			this._checkTimer.addEventListener( TimerEvent.TIMER_COMPLETE, _onTimerComplete );
			this._checkTimer.addEventListener( TimerEvent.TIMER, _onTimer );
			this._checkTimer.start();
			
			broadcast( new OSCMessage( "/__check__ ,s " + this._checkToken ) );
			
		}
		
		/**
		 * 初期化が完了しているか.
		 * @return 
		 */
		public function get initialized():Boolean{
			return this._initialized;
		}
		
		/**
		 * メッセージをブロードキャストします.
		 * AIR 単体でのブロードキャスト機能は存在しないため UDPBroadcaster.jar を通じて行われます.
		 * そのため UDPBroadcaster.jar が起動していない場合は機能しません.
		 * @param packet
		 */
		public function broadcast( packet:OSCPacket, timetagOffset:Number = 0 ):void{
			if( 0 < timetagOffset ){
				var bundle:OSCBundle = new OSCBundle();
				bundle.setTimeTagOffset( 100 );
				bundle.addPacket( packet );
				send( bundle, _address, _port );
			}else{
				send( packet, _address, _port );
			}
		}
		
		// ------- PROTECTED ---------------------------------------------
		
		/**
		 * 一定間隔ごとにチェック用メッセージを送信する.
		 * @param event
		 */
		protected function _onTimer(event:TimerEvent):void{
			trace("Send Check Broadcast Message.");
			broadcast( new OSCMessage( "/__check__ ,s " + this._checkToken ) );
		}
		
		/**
		 * チェックトークンが Broadcast で返って来た際の処理.
		 * チェックを終了し、初期化完了を通知する.
		 * @param event
		 */
		protected function _onChecked(event:OSCSocketEvent):void
		{
			
			if( event.args[0] == this._checkToken ){
				
				this._checkTimer.stop();
				this._checkTimer.removeEventListener( TimerEvent.TIMER, _onTimer );
				this._checkTimer = null;
				
				this.removeEventListener( "/__check__", _onChecked );
				
				this._initialized = true;
				
				this.dispatchEvent( new OSCSocketEvent( OSCSocketEvent.INITIALIZE ) );
				
			}
			
		}
		
		/**
		 * Timer Complete
		 * @param event
		 */		
		protected function _onTimerComplete(event:TimerEvent):void{
			
			// TODO Auto-generated method stub
			
			this._checkTimer.stop();
			this._checkTimer.removeEventListener( TimerEvent.TIMER, _onTimer );
			this._checkTimer = null;
			
			this.removeEventListener( "/__check__", _onChecked );
			
			this.dispatchEvent( new OSCSocketEvent( OSCSocketEvent.ERROR ) );
			
		}
		
	}
	
}

class PrivateClass{}