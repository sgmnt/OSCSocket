package org.sgmnt.lib.osc{
	
	/**
	 * OSCSyncProcess で用いるプロセス同士のつながりを定義する Closure のラッパクラス.
	 * @author sgmnt.org
	 */
	internal class OSCSyncProcessClosureLinkedList{
		
		// ------- MEMBER ---------------------------------------------
		
		private var _index:int;
		private var _closure:Function;
		private var _next:OSCSyncProcessClosureLinkedList;
		private var _prev:OSCSyncProcessClosureLinkedList;
		
		// ------- PUBLIC ---------------------------------------------
		
		/**
		 * Constructor.
		 * @param index
		 * @param closure
		 */	
		public function OSCSyncProcessClosureLinkedList( index:int, closure:Function ){
			_index   = index;
			_closure = closure;
		}
		
		/** Closure の実行順 index. */
		public function get index():int{ return _index }
		
		/** 実行すべき Closure への参照. */
		public function get closure():Function{ return _closure; }
		
		/** 次に実行すべき ClosureLinkedList への参照. */
		public function get next():OSCSyncProcessClosureLinkedList{ return _next; }
		public function set next(value:OSCSyncProcessClosureLinkedList):void{
			_next = value;
		}
		
		/** 前に実行すべき ClosureLinkedList への参照. */
		public function get prev():OSCSyncProcessClosureLinkedList{ return _prev; }
		public function set prev(value:OSCSyncProcessClosureLinkedList):void{
			_prev = value;
		}
		
		// ------- PROTECTED ------------------------------------------
		// ------- PRIVATE --------------------------------------------
		// ------- INTERNAL -------------------------------------------
		
	}
}