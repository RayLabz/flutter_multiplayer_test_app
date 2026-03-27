import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:athlos/athlos.dart' show GatewayPacket, NetworkLogger, TcpClient, NetworkLogOutput, GatewayOpcode, GatewayOpcodeWire;

Future<void> main(List<String> args) async {
  final token = args.isNotEmpty ? args.first : 'dev-token-1';

  final authenticatedCompleter = Completer<void>();
  final routedCompleter = Completer<void>();

  late final TcpClient client;
  client = TcpClient(
    serverAddress: InternetAddress.loopbackIPv4,
    serverPort: 7777,
    logger: NetworkLogger(output: NetworkLogOutput.console),
    onMessage: (bytes) async {
      final packet = GatewayPacket.tryParse(bytes);

      if (packet == null) {
        stderr.writeln('Received invalid packet from gateway.');
        return;
      }

      switch (packet.opcode) {
        case GatewayOpcode.authenticated:
          stdout.writeln('Authenticated as: ${packet.data['playerId']}');
          if (!authenticatedCompleter.isCompleted) {
            authenticatedCompleter.complete();
          }
          break;

        case GatewayOpcode.routed:
          final backend =
          (packet.data['backend'] as Map?)?.cast<String, Object?>();

          if (backend == null) {
            stderr.writeln('Missing backend assignment in routed packet.');
            return;
          }

          stdout.writeln('Session ID: ${packet.data['sessionId']}');
          stdout.writeln('Player ID: ${packet.data['playerId']}');
          stdout.writeln(
            'Routed backend: ${backend['id']} @ ${backend['host']}:${backend['port']}',
          );

          //Connect to TCP Client:
          final tcpClient = TcpClient(
            serverAddress: InternetAddress(backend['host'] as String),
            serverPort: backend['port'] as int,
            logger: NetworkLogger(output: NetworkLogOutput.console),
            onMessage: (bytes) {
              print(utf8.decode(bytes));
            },
            tickRate: Duration(seconds: 2),
            onStart: () async {
              print("Started");
            },
          );

          await tcpClient.start();

          if (!routedCompleter.isCompleted) {
            routedCompleter.complete();
          }
          break;

        case GatewayOpcode.authenticationFailed:
        case GatewayOpcode.error:
          final message = packet.data['message'] ?? 'Unknown gateway error.';
          stderr.writeln('Gateway error: $message');
          if (!routedCompleter.isCompleted) {
            routedCompleter.completeError(Exception(message));
          }
          break;

        default:
          stdout.writeln('Gateway packet: ${packet.opcode.wireValue}');
      }
    },
  );

  try {
    await client.start();

    // 1) Authenticate
    client.send(
      GatewayPacket(
        opcode: GatewayOpcode.authenticate,
        data: {'token': token},
      ).toBytes(),
    );

    await authenticatedCompleter.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () => throw TimeoutException('Authentication timed out.'),
    );

    // 2) Ask for matchmaking / route assignment
    client.send(
      const GatewayPacket(opcode: GatewayOpcode.matchmakingRequest).toBytes(),
    );

    await routedCompleter.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () => throw TimeoutException('Routing response timed out.'),
    );
  } catch (error) {
    stderr.writeln('Smoke test failed: $error');
    exitCode = 1;
  } finally {
    await client.close();
  }
}