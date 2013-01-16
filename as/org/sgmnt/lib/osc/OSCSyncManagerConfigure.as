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
	
	import flash.net.InterfaceAddress;
	import flash.net.NetworkInfo;
	import flash.net.NetworkInterface;
	
	public class OSCSyncManagerConfigure{
		
		// ------- MEMBER ----------------------------------------------------------
		
		private var _localAddress:String;
		private var _broadcastAddress:String;
		private var _syncPort:int;
		private var _hostHash:Array;
		
		// ------- PUBLIC ----------------------------------------------------------
		
		/**
		 * Constructor.
		 * @param localAddress
		 * @param syncPort
		 * @param broadcastPort
		 */		
		public function OSCSyncManagerConfigure( localAddress:* = null, broadcastAddress:* = null, syncPort:int = 57577 ){
			
			// --- Setup Local Address. ---
			
			_localAddress     = localAddress;
			_broadcastAddress = broadcastAddress;
			
			var found:Boolean = false;
			var ifaces:Vector.<NetworkInterface> = NetworkInfo.networkInfo.findInterfaces();
			for each (var iface : NetworkInterface in ifaces){
				var listInterfaces : Vector.<InterfaceAddress> = iface.addresses;
				for each(var interfaceAddress : InterfaceAddress in listInterfaces){
					if( interfaceAddress.address == "127.0.0.1" || interfaceAddress.address.indexOf("::") == 0 ){
						continue;
					}
					if( !_localAddress ){
						_localAddress     = interfaceAddress.address;
					}
					if( !_broadcastAddress ){
						_broadcastAddress = interfaceAddress.broadcast;
					}
					found = true;
					break;
				}
				if( found ) break;
			}
			
			// --- Setup for Broadcast. ---
			
			_syncPort      = syncPort;
			
		}
		
		/**
		 * 
		 * @return 
		 */
		public function get localAddress():String{ return _localAddress; }
		
		/**
		 * 
		 * @return 
		 */
		public function get broadcastAddress():String{ return _broadcastAddress; }
		
		/**
		 * 
		 * @return 
		 */
		public function get syncPort():int{ return _syncPort; }
		
		/**
		 * ホストのIPアドレス情報を追加する.
		 * @param name
		 * @param address
		 */
		public function addHostIP( name:String, ip:String ):void{
			if( !_hostHash ) _hostHash = new Array();
			_hostHash[name] = ip;
		}
		
		/**
		 * ホストのアドレス情報をグループ名から解決します.
		 * @param name
		 */
		public function getHostIPByName( name:String ):String{
			return _hostHash[name];
		}
		
		/**
		 * addHostAddress を用いて Host 情報の設定を行い
		 * ホスト情報を持っているか.
		 * @return 
		 */		
		public function get hasHostIPSettigs():Boolean{
			return _hostHash != null;
		}
		
		// ------- PUBLIC ----------------------------------------------------------

	}
	
}