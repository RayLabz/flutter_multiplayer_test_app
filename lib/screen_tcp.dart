import 'dart:convert';
import 'dart:io';

import 'package:athlos/athlos.dart';
import 'package:flutter/material.dart';

class TCPScreen extends StatefulWidget {
  const TCPScreen({super.key});

  @override
  State<TCPScreen> createState() => _TCPScreenState();
}

class _TCPScreenState extends State<TCPScreen> {

  late TcpClient client;

  @override
  void initState() {
    super.initState();
    client = TcpClient(

      serverAddress: InternetAddress(Platform.isWindows ? "127.0.0.1" : '10.0.2.2'),
      serverPort: 9000,

      onMessage: (msg) {
        print(utf8.decode(msg));
      },
      tickRate: Duration(seconds: 2),

      onTick: (client) {
        final data = utf8.encode("Hello from TCP client!");
        client.send(data);
      },
    );

    clientStartFuture = client.start();
  }

  late Future clientStartFuture;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: clientStartFuture,
        builder: (context, asyncSnapshot) {
          if (asyncSnapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }
          if (asyncSnapshot.hasError) {
            return Text('Error: ${asyncSnapshot.error}');
          }

          return Column(
            children: [

              ElevatedButton(
                child: Text("Stop"),
                onPressed: () {
                  // client.disconnect(); //todo
                },
              )

            ],
          );
        }
      ),
    );
  }

  @override
  dispose() {
    client.close();
    super.dispose();
  }

}
