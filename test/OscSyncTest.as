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
				trace(e);
				trace(OSCSyncManager.getInstance().status);
				_process.begin();
			});
			
			trace('Test Start.');
			
		}
		
		function process1(args:*=null){
			trace('process1');
			var timer:Timer = new Timer(3000,1);
			timer.addEventListener(TimerEvent.TIMER_COMPLETE,function(){
				_process.complete( process1 );
			});
			timer.start();
		}
		
		function process2(args:*=null){
			trace('process2');
			_process.complete( process2 );
		}
		
	}
}