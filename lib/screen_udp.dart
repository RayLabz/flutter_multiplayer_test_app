import 'dart:convert';
import 'dart:io';

import 'package:athlos/athlos.dart';
import 'package:flutter/material.dart';

class UDPScreen extends StatefulWidget {
  const UDPScreen({super.key});

  @override
  State<UDPScreen> createState() => _UDPScreenState();
}

class _UDPScreenState extends State<UDPScreen> {

  late UdpClient client;

  @override
  void initState() {
    super.initState();
    client = UdpClient(

      serverAddress: InternetAddress(Platform.isWindows ? "127.0.0.1" : '10.0.2.2'),
      serverPort: 9000,

      onMessage: (msg) {
        print(utf8.decode(msg));
      },
      tickRate: Duration(seconds: 2),

      onTick: (client) {
        final data = utf8.encode("Hello from UDP client!");
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
                  client.disconnect();
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
