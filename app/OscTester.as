﻿/** * * Copyright (c) 2010 - 2012, http://sgmnt.org/ *  * Permission is hereby granted, free of charge, to any person obtaining * a copy of this software and associated documentation files (the * "Software"), to deal in the Software without restriction, including * without limitation the rights to use, copy, modify, merge, publish, * distribute, sublicense, and/or sell copies of the Software, and to * permit persons to whom the Software is furnished to do so, subject to * the following conditions: *  * The above copyright notice and this permission notice shall be * included in all copies or substantial portions of the Software. *  * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. * */package  {		import flash.display.MovieClip;	import flash.text.TextField;	import flash.display.SimpleButton;	import flash.events.MouseEvent;	import org.sgmnt.lib.osc.OSCSocket;	import flash.events.Event;	import flash.display.StageAlign;	import flash.display.StageScaleMode;	import org.sgmnt.lib.osc.OSCMessage;	import flash.events.KeyboardEvent;	import flash.ui.Keyboard;	import flash.text.TextFormat;	import flash.display.Screen;		/**	 * Application for OSCTest.	 * @author hrfm	 */	public class OscTester extends MovieClip {				// ------- MEMBER --------------------------------------------------------------				private var _socket:OSCSocket;		private var _receiverWindows:Vector.<OscTesterReceiverWindow>;				public var sendMsgTF:TextField;		public var sendAddrTF:TextField;		public var sendPortTF:TextField;		public var sendBtn:SimpleButton;				public var receiverAddrTF:TextField;		public var receiverPortTF:TextField;		public var receiverBtn:SimpleButton;				// ------- PUBLIC --------------------------------------------------------------				public function OscTester() {						this.stage.align     = StageAlign.TOP_LEFT;			this.stage.scaleMode = StageScaleMode.NO_SCALE;						_socket = new OSCSocket();						_receiverWindows = new Vector.<OscTesterReceiverWindow>();						var fmt:TextFormat = new TextFormat();			fmt.color = 0xffffff;						sendMsgTF.borderColor     = 0x666666;			sendMsgTF.backgroundColor = 0x202020;			sendMsgTF.addEventListener(KeyboardEvent.KEY_DOWN, _onKeyDown );						sendAddrTF.borderColor     = 0x666666;			sendAddrTF.backgroundColor = 0x202020;						sendPortTF.borderColor     = 0x666666;			sendPortTF.backgroundColor = 0x202020;						receiverAddrTF.borderColor     = 0x666666;			receiverAddrTF.backgroundColor = 0x202020;						receiverPortTF.borderColor     = 0x666666;			receiverPortTF.backgroundColor = 0x202020;						sendBtn.addEventListener(MouseEvent.CLICK, _sendMessage );			receiverBtn.addEventListener(MouseEvent.CLICK, _onReceiverBtnClick );						this.stage.nativeWindow.addEventListener(Event.CLOSING, _onWindowClosing );					}				// ------- PRIVATE -------------------------------------------------------				private function _onKeyDown( event:KeyboardEvent ):void{			if( event.keyCode == Keyboard.ENTER ){				_sendMessage();			}		}				private function _sendMessage(event:MouseEvent = null):void{			_socket.send( new OSCMessage( sendMsgTF.text ), sendAddrTF.text, int( sendPortTF.text ) );		}				private var _recentWindow:OscTesterReceiverWindow;				private function _onReceiverBtnClick(event:MouseEvent):void{			try{				var win:OscTesterReceiverWindow = new OscTesterReceiverWindow( receiverAddrTF.text, int( receiverPortTF.text ) );				win.x = 30 * _receiverWindows.length;				win.y = 30 * _receiverWindows.length;				_receiverWindows.push( win );				_recentWindow = win;			}catch(e){				trace(e);			}		}				private function _onWindowClosing(event:Event){						for( var i:int = 0; i < _receiverWindows.length; i++ ){				try{					_receiverWindows[i].nativeWindow.close();				}catch(e){}			}						_socket.close();			_socket = null;					}			}	}