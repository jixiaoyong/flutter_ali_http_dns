import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_ali_http_dns/src/models/proxy_config.dart';
import 'package:flutter_ali_http_dns/src/services/dns_resolver.dart';
import 'package:flutter_ali_http_dns/src/services/proxy_server.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('forwards POST body arriving with request headers', () async {
    final receivedBody = Completer<String>();
    final target = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    target.listen((request) async {
      receivedBody.complete(await utf8.decoder.bind(request).join());
      request.response
        ..statusCode = HttpStatus.ok
        ..write('ok');
      await request.response.close();
    });

    final portProbe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final proxyPort = portProbe.port;
    await portProbe.close();

    final proxy = await ProxyServer.start(
      ProxyConfig(portPool: [proxyPort]),
      DnsResolver(),
    );
    expect(proxy, isNotNull);

    const body = '{"message":"header-and-body-in-one-write"}';
    final socket = await Socket.connect(InternetAddress.loopbackIPv4, proxyPort);
    final request = 'POST http://127.0.0.1:${target.port}/echo HTTP/1.1\r\n'
        'Host: 127.0.0.1:${target.port}\r\n'
        'Content-Type: application/json\r\n'
        'Content-Length: ${utf8.encode(body).length}\r\n'
        'Connection: close\r\n'
        '\r\n'
        '$body';

    // 单次写入稳定覆盖 Header 与 Body 同包到达的缺陷场景。
    socket.add(utf8.encode(request));
    await socket.flush();

    expect(
      await receivedBody.future.timeout(const Duration(seconds: 3)),
      body,
    );

    socket.destroy();
    await proxy!.stop();
    await target.close(force: true);
  });
}
