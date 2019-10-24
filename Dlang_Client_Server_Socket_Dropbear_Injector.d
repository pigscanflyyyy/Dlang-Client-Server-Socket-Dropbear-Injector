/*
    Direct DropBear Dlang Injector.
    Created by Marcone (thegrapevine@email.com) in 2019.
*/

import std;
import core.thread;
import core.stdc.stdlib;

// Configuracoes.
string LISTEN_PORT = "127.0.0.1:8088";
string PAYLOAD = "GET / HTTP/1.1\r\nhost: www.bing.com\r\n\r\n";

void conecta(Socket c, int conn_number){

    writeln("\nConnection #", conn_number);
	writeln("[#] Received Client.");

    char[8192] request;
    auto rq = c.receive(request);

    string host = to!string(request)[to!string(request).indexOf("CONNECT")+7..to!string(request).indexOf(":")].strip();
    ushort port = to!ushort(to!string(request)[to!string(request).indexOf(":")+1..to!string(request).indexOf("HTTP/")].strip());

    writeln("[-] Real request: \"", to!string(request[0..rq]).replace("\r\n", r"\r\n"), "\"");
    writeln("[#] Payload: \"", PAYLOAD.replace("\r\n", r"\r\n"), "\"");

    auto s = new Socket(AddressFamily.INET, SocketType.STREAM);
    s.blocking = true;
    writeln("[-] Direct connection to server: ", host, ":", port);
    try{
        s.connect(new InternetAddress(host, port));
    }catch(Exception){
        writeln("[!] Error when try to connect to server: ", host, ":", port);
    }
    
    s.send(PAYLOAD); // Payload.
    c.send("HTTP/1.1 200 Established\r\n\r\n");

    auto set = new SocketSet();
    char[8192] data;

    while(true){
        set.reset();
        set.add(s);
        set.add(c);
        Socket.select(set, null, null, null); 
        
        if (set.isSet(s)){
            // Download
            auto got = s.receive(data);
            if (got == 0){break;}
            c.send(data[0 .. got]);
        } else {
            // Upload
            auto got = c.receive(data);
            if (got == 0){break;}
            s.send(data[0 .. got]);
        }
    }
    writeln("[!] Client Disconnected!");
    writeln("[!] Connection #%d Closed!".format(conn_number));
}

void main(){
    spawnShell("title Direct DropBear Dlang Injector && color 47");
	writeln("-*-*-*- Direct DropBear Dlang Injector -*-*-*-\nCreated by Marcone (thegrapevine@email.com) in 2019\n");

    int conn_number = 0;

	// Listen
	auto l = new Socket(AddressFamily.INET, SocketType.STREAM);
    try {
        l.bind(new InternetAddress(LISTEN_PORT[0..LISTEN_PORT.indexOf(":")], to!ushort(LISTEN_PORT[LISTEN_PORT.indexOf(":")+1..LISTEN_PORT.length])));
        l.blocking = true;
    } catch(Exception){
        writeln("[!] Listen Error! Listen Port ", LISTEN_PORT, " is alread in Use!" );
        readln();
        exit(1);
    } 
    l.listen(1);
    writeln("[-] Listening on IP and Port: ", LISTEN_PORT[0..LISTEN_PORT.indexOf(":")], ":", LISTEN_PORT[LISTEN_PORT.indexOf(":")+1..LISTEN_PORT.length], "\n");

    while(true){
        conn_number += 1;
        task!conecta(l.accept(), conn_number).executeInNewThread();
    }
}