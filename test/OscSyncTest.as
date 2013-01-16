package
{
	
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import org.sgmnt.lib.osc.OSCSyncManager;
	import org.sgmnt.lib.osc.OSCSyncManagerConfigure;
	import org.sgmnt.lib.osc.OSCSyncProcess;
	
	public class OscSyncTest extends Sprite
	{
		
		private var _process:OSCSyncProcess;
		
		public function OscSyncTest(){
			
			OSCSyncManager.getInstance().initialize( new OSCSyncManagerConfigure() );
			
			_process = new OSCSyncProcess('hoge','fuga');
			_process.addProcess(process1);
			_process.addProcess(process2);
			
			stage.addEventListener(MouseEvent.CLICK,function(e){
				_process.begin( 0xff0000, 0x00ff00 );
			});
			
			trace('Test Start.');
			
		}
		
		function process1(args:*=null){
			
			trace(OSCSyncManager.getInstance().status);
			
			trace('process1');
			
			var color:uint = uint( args[0] );
			trace(color);
			
			graphics.clear();
			graphics.beginFill( color, 1.0 );
			graphics.drawRect( 0,0, stage.stageWidth, stage.stageHeight );
			
			var timer:Timer = new Timer(3000,1);
			timer.addEventListener(TimerEvent.TIMER_COMPLETE,function(){
				_process.complete( process1 );
			});
			timer.start();
		}
		
		function process2(args:*=null){
			trace('process2');
			
			var color:uint = uint( args[1] );
			
			trace(color);
			
			graphics.clear();
			graphics.beginFill( color, 1.0 );
			graphics.drawRect( 0,0, stage.stageWidth, stage.stageHeight );
			
			_process.complete( process2 );
		}
		
	}
}