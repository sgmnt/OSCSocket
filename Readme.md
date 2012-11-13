#About

Use OSC protocol in your AIR Application.

OSC message **receive**, **send**, and use **#Bundle** available.

#Usage

##Adobe AIR

###Initializing.

    // import OSCSocket classes.
    import org.sgmnt.lib.osc.*;
    
    // Create OSCSocket instance.
    var socket:OSCSocket = new OSCSocket();
    
    // Use bind( port, address ) if need receiving messages.
    socket.bind( 10000, "127.0.0.1" );
    socket.receive();

###Receive messages.

You can use **addEventListener** method for receive OSC messages as usual.

    // ex) receive /message/1
    socket.addEventListener("/message/1", _onMessage);
    
    // You can get address and arguments from OSCSocketEvent.
    function _onMessage(e:OSCSocketEvent):void{
        trace( e.address, e.args );
    }

    // and, you can use * syntax in message address.
    // In the following syntax, it is possible to receive /message/1, /message/hoge, etc...
    socket.addEventListener("/message/*", _onMessage);

###Send messages.

You can send a message using **OSCMessage**.

    var message:OSCMessage = new OSCMessage();
    message.address = '/message/1';
    
    // add String arguments.
    message.addArgument('s','hogehoge');
    
    // add int32 arguments.
    message.addArgument('i',100);
    
    // add float arguments.
    message.addArgument('f',3.14);
    
    // add double arguments.
    message.addArgument('f',3.1415);
    
    // add blob arguments.
    message.addArgument('b',{type:'a'});
    
    // Sending message to 127.0.0.1:10001
    socket.send( message, '127.0.0.1', 10001 );

If You want to use bundle. Try to use **OSCBundle**.

    var bundle:OSCBundle = new OSCBundle();
    
    // Set timetag by elapsed time(milliseconds) from now timestamp;
    bundle.setTimeTagOffset(1000);
    
    // add OSCMassage to bundle.
    bundle.addPacket( message );
    
    // Sending bundle message to 127.0.0.1:10001
    socket.send( bundle, '127.0.0.1', 10001 );

#Lisence

Released under the MIT, and GPL Licenses.
