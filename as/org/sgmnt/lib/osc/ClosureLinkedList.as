package org.sgmnt.lib.osc{
	
	/**
	 * OSCSyncProcess で用いるプロセス同士のつながりを定義する Closure のラッパクラス.
	 * @author sgmnt.org
	 */
	internal class ClosureLinkedList{
		
		// ------- MEMBER ---------------------------------------------
		
		private var _index:int;
		private var _closure:Function;
		private var _next:ClosureLinkedList;
		private var _prev:ClosureLinkedList;
		
		// ------- PUBLIC ---------------------------------------------
		
		/**
		 * Constructor.
		 * @param index
		 * @param closure
		 */	
		public function ClosureLinkedList( index:int, closure:Function ){
			_index   = index;
			_closure = closure;
		}
		
		/** Closure の実行順 index. */
		public function get index():int{ return _index }
		
		/** 実行すべき Closure への参照. */
		public function get closure():Function{ return _closure; }
		
		/** 次に実行すべき ClosureLinkedList への参照. */
		public function get next():ClosureLinkedList{ return _next; }
		public function set next(value:ClosureLinkedList):void{
			_next = value;
		}
		
		/** 前に実行すべき ClosureLinkedList への参照. */
		public function get prev():ClosureLinkedList{ return _prev; }
		public function set prev(value:ClosureLinkedList):void{
			_prev = value;
		}
		
		// ------- PROTECTED ------------------------------------------
		// ------- PRIVATE --------------------------------------------
		// ------- INTERNAL -------------------------------------------
		
	}
}