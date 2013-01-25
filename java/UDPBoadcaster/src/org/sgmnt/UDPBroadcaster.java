package org.sgmnt;

import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.InterfaceAddress;
import java.net.NetworkInterface;
import java.util.Enumeration;

public class UDPBroadcaster {
	
	public static void main( String[] args ) throws Exception{
		
		int fromPort = 57578;
		int toPort = 57577;
		
        String broadcastAddr = "255.255.255.255";
        
		DatagramSocket sock;
		DatagramPacket packet;
        InetSocketAddress remoteAddr;
        byte receiveBuffer[];
        
		for ( int i = 0; i < args.length; i++ ) {
			if ("-from".equals(args[i])) {
				fromPort = Integer.parseInt(args[++i]);
			} else if ("-to".equals(args[i])) {
				toPort = Integer.parseInt(args[++i]);
			} else if( "-broadcast".equals(args[i]) ){
				broadcastAddr = args[++i];
			}
		}
		
        // --- Check Broadcast Address. ---
        
        if( broadcastAddr.equals("255.255.255.255") ){
            Enumeration<NetworkInterface> interfaces = NetworkInterface.getNetworkInterfaces();
    		while (interfaces.hasMoreElements()) {
        		NetworkInterface networkInterface = interfaces.nextElement();
        		if ( networkInterface.isLoopback() ){
        			continue; // Don't want to broadcast to the loopback interface
        		}
        		for (InterfaceAddress interfaceAddress : networkInterface.getInterfaceAddresses()) {
        			InetAddress broadcast = interfaceAddress.getBroadcast();
        			if (broadcast == null) continue;
        			broadcastAddr = broadcast.getHostAddress();
        		}
    		}
        }
		
        // --- Create Socket. ---
		
		sock = new DatagramSocket( fromPort );
		
        // 受け付けるデータバッファとUDPパケットを作成
        receiveBuffer = new byte[512];
        packet = new DatagramPacket( receiveBuffer, receiveBuffer.length );
        
        remoteAddr = new InetSocketAddress( broadcastAddr, toPort );
        
		System.out.println( "Broadcast " + broadcastAddr + " from " + fromPort + " to " + toPort );
		
        while (true) {
        	
            sock.receive(packet);
            
            byte[] buf = packet.getData();
            int len    = packet.getLength();
            
            /*
            // 受信したデータを標準出力へ出力
            System.out.println(
            	new String( buf, 0, len )
            );
            //*/
            
            sock.send( new DatagramPacket(buf, len, remoteAddr ) );
            
        }
        
	}
	
}
