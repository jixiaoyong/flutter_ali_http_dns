import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_ali_http_dns/src/models/proxy_config.dart';
import 'package:flutter_ali_http_dns/src/services/dns_resolver.dart';
import 'package:flutter_ali_http_dns/src/services/proxy_server.dart';
import 'package:flutter_ali_http_dns/src/utils/proxy_auth.dart';
import 'package:flutter_test/flutter_test.dart';

/// 通过原始 Socket 发送请求到代理端口，返回完整响应字节。
Future<Uint8List> _sendRawRequest(int proxyPort, String request) async {
  final socket = await Socket.connect(InternetAddress.loopbackIPv4, proxyPort);
  final completer = Completer<Uint8List>();
  final received = <int>[];
  socket.listen(
    (data) => received.addAll(data),
    onDone: () {
      if (!completer.isCompleted) {
        completer.complete(Uint8List.fromList(received));
      }
    },
    onError: (e) {
      if (!completer.isCompleted) {
        if (received.isNotEmpty) {
          completer.complete(Uint8List.fromList(received));
        } else {
          completer.completeError(e);
        }
      }
    },
  );
  socket.add(utf8.encode(request));
  await socket.flush();
  try {
    return await completer.future.timeout(const Duration(seconds: 3));
  } finally {
    socket.destroy();
  }
}

/// 解析响应：返回状态行与响应头。
(String, Map<String, String>) _parseRawResponse(Uint8List bytes) {
  final text = utf8.decode(bytes, allowMalformed: true);
  final headerEnd = text.indexOf('\r\n\r\n');
  final headerPart = headerEnd == -1 ? text : text.substring(0, headerEnd);
  final lines = headerPart.split('\r\n');
  final status = lines.isEmpty ? '' : lines.first;
  final headers = <String, String>{};
  for (final line in lines.skip(1)) {
    final idx = line.indexOf(':');
    if (idx > 0) {
      headers[line.substring(0, idx).trim().toLowerCase()] =
          line.substring(idx + 1).trim();
    }
  }
  return (status, headers);
}

/// 断言代理返回 407 且携带 Proxy-Authenticate 挑战头。
Future<void> _expect407(int proxyPort, String request) async {
  final response = await _sendRawRequest(proxyPort, request);
  final (status, headers) = _parseRawResponse(response);
  expect(status, contains('407'));
  final challenge = headers['proxy-authenticate'] ?? '';
  expect(challenge.startsWith('Basic realm='), isTrue,
      reason: '407 响应应携带 Proxy-Authenticate: Basic realm="..."');
}

/// 启动代理并返回 (proxy, proxyPort, credentials)。
Future<(ProxyServer, int, ProxyCredentials)> _startProxy() async {
  final reservation = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = reservation.port;
  await reservation.close();
  final proxy = await ProxyServer.start(
    ProxyConfig(portPool: [port]),
    DnsResolver(),
  );
  expect(proxy, isNotNull);
  return (proxy!, proxy.allocatedPorts.first, proxy.credentials);
}

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final chunked in [false, true]) {
    test('streams large fragmented body chunked=$chunked and drops pipeline',
        () async {
      final target = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => target.close(force: true));
      final firstBytes = Completer<void>();
      final completeBody = Completer<int>();
      var requests = 0;
      target.listen((request) async {
        requests++;
        var count = 0;
        await for (final data in request) {
          count += data.length;
          if (!firstBytes.isCompleted) firstBytes.complete();
        }
        completeBody.complete(count);
        request.response.write('ok');
        await request.response.close();
      });
      final (proxy, port, credentials) = await _startProxy();
      addTearDown(proxy.stop);
      final socket = await Socket.connect(InternetAddress.loopbackIPv4, port);
      addTearDown(socket.destroy);
      final responseDone = Completer<void>();
      socket.listen((_) {}, onDone: responseDone.complete);
      const size = 2 * 1024 * 1024;
      socket.add(utf8.encode(
          'POST http://127.0.0.1:${target.port}/ HTTP/1.1\r\n'
          'Host: 127.0.0.1\r\nProxy-Authorization: ${credentials.basicAuthValue()}\r\n'
          '${chunked ? 'Transfer-Encoding: chunked' : 'Content-Length: $size'}\r\n\r\n'));
      for (var offset = 0; offset < size; offset += 16384) {
        final body = 'a' * 16384;
        if (chunked) {
          // 大小行、body、结束符可分别跨 socket 事件。
          socket.add(utf8.encode('4000;test=yes\r'));
          await socket.flush();
          socket.add(utf8.encode('\n$body\r\n'));
        } else {
          socket.add(utf8.encode(body));
        }
        await socket.flush();
        if (offset == 0) {
          await firstBytes.future.timeout(const Duration(seconds: 3));
        }
      }
      socket.add(utf8.encode('${chunked ? '0\r\n\r\n' : ''}'
          'GET http://127.0.0.1:${target.port}/pipeline HTTP/1.1\r\nHost: 127.0.0.1\r\n\r\n'));
      await socket.flush();
      expect(
          await completeBody.future.timeout(const Duration(seconds: 5)), size);
      await responseDone.future.timeout(const Duration(seconds: 3));
      expect(requests, 1);
    });
  }

  for (final framing in [
    'Content-Length: -1',
    'Content-Length: +1',
    'Content-Length: 1, 1',
    'Content-Length: 1\r\nContent-Length: 1',
    'Content-Length: 1\r\nTransfer-Encoding: chunked',
    'Transfer-Encoding: gzip, chunked',
    'Transfer-Encoding: chunked\r\nTransfer-Encoding: chunked',
  ]) {
    test('rejects ambiguous request framing $framing', () async {
      final (proxy, port, credentials) = await _startProxy();
      addTearDown(proxy.stop);
      final response = await _sendRawRequest(
          port,
          'POST http://127.0.0.1:1/ HTTP/1.1\r\n'
          'Proxy-Authorization: ${credentials.basicAuthValue()}\r\n$framing\r\n\r\n');
      expect(_parseRawResponse(response).$1, contains('400'));
    });
  }

  test('incomplete body times out and releases authenticated slot', () async {
    final target = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final peers = <Socket>[];
    target.listen((peer) {
      peers.add(peer);
      peer.listen((_) {});
    });
    addTearDown(() async {
      for (final peer in peers) {
        peer.destroy();
      }
      await target.close();
    });
    final (proxy, port, credentials) = await _startProxy();
    addTearDown(proxy.stop);
    final socket = await Socket.connect(InternetAddress.loopbackIPv4, port);
    addTearDown(socket.destroy);
    final response = Completer<String>();
    final bytes = <int>[];
    socket.listen(bytes.addAll,
        onDone: () => response.complete(utf8.decode(bytes)));
    socket.add(utf8.encode('POST http://127.0.0.1:${target.port}/ HTTP/1.1\r\n'
        'Proxy-Authorization: ${credentials.basicAuthValue()}\r\nContent-Length: 100\r\n\r\nx'));
    expect(await response.future.timeout(const Duration(seconds: 12)),
        contains('408'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(proxy.authenticatedClientCount, 0);
  });

  test('client close during incomplete body releases upstream and slot',
      () async {
    final target = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(target.close);
    final upstreamClosed = Completer<void>();
    target.listen((peer) {
      addTearDown(peer.destroy);
      peer.listen((_) {}, onDone: upstreamClosed.complete);
    });
    final (proxy, port, credentials) = await _startProxy();
    addTearDown(proxy.stop);
    final socket = await Socket.connect(InternetAddress.loopbackIPv4, port);
    socket.add(utf8.encode('POST http://127.0.0.1:${target.port}/ HTTP/1.1\r\n'
        'Proxy-Authorization: ${credentials.basicAuthValue()}\r\nContent-Length: 100\r\n\r\nx'));
    await socket.flush();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    socket.destroy();
    await upstreamClosed.future.timeout(const Duration(seconds: 3));
    expect(proxy.authenticatedClientCount, 0);
  });

  test('HTTP response larger than 1MiB is not truncated', () async {
    final payload = 'z' * (2 * 1024 * 1024);
    final target = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => target.close(force: true));
    target.listen((request) async {
      request.response.contentLength = payload.length;
      request.response.write(payload);
      await request.response.close();
    });
    final (proxy, port, credentials) = await _startProxy();
    addTearDown(proxy.stop);
    final response = await _sendRawRequest(
        port,
        'GET http://127.0.0.1:${target.port}/ HTTP/1.1\r\n'
        'Proxy-Authorization: ${credentials.basicAuthValue()}\r\n\r\n');
    final text = utf8.decode(response);
    expect(text.substring(text.indexOf('\r\n\r\n') + 4), payload);
  });

  test('raw HTTP2 direct cannot bypass proxy authentication', () async {
    final (proxy, port, _) = await _startProxy();
    addTearDown(proxy.stop);
    await _expect407(port, 'PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n');
  });

  test('CONNECT preserves coalesced HTTP2 preface and binary frames', () async {
    final target = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final peers = <Socket>[];
    addTearDown(() async {
      for (final peer in peers) {
        peer.destroy();
      }
      await target.close();
    });
    target.listen((peer) {
      peers.add(peer);
      peer.listen(peer.add);
    });
    final (proxy, port, credentials) = await _startProxy();
    addTearDown(proxy.stop);
    final socket = await Socket.connect(InternetAddress.loopbackIPv4, port);
    addTearDown(socket.destroy);
    final payload = <int>[
      ...utf8.encode('PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n'),
      0, 0, 0, 4, 0, 0, 0, 0, 0, // SETTINGS
      0, 0, 5, 0, 0, 0, 0, 0, 1, 0, 255, 13, 10, 128,
      ...utf8.encode('Proxy-Authorization: not-a-proxy-header\r\n\r\n'),
    ];
    final received = <int>[];
    final done = Completer<void>();
    socket.listen((data) {
      received.addAll(data);
      final end = latin1.decode(received).indexOf('\r\n\r\n');
      if (end >= 0 &&
          received.length == end + 4 + payload.length &&
          !done.isCompleted) done.complete();
    });
    socket.add([
      ...utf8.encode('CONNECT 127.0.0.1:${target.port} HTTP/1.1\r\n'
          'Proxy-Authorization: ${credentials.basicAuthValue()}\r\n\r\n'),
      ...payload,
    ]);
    await socket.flush();
    await done.future.timeout(const Duration(seconds: 3));
    final end = latin1.decode(received).indexOf('\r\n\r\n');
    expect(latin1.decode(received.sublist(0, end)), contains('200'));
    expect(received.sublist(end + 4), payload);
  });

  test('CONNECT continuously echoes more than 1MiB', () async {
    final target = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final peers = <Socket>[];
    addTearDown(() async {
      for (final peer in peers) {
        peer.destroy();
      }
      await target.close();
    });
    target.listen((peer) {
      peers.add(peer);
      peer.listen(peer.add);
    });
    final (proxy, port, credentials) = await _startProxy();
    addTearDown(proxy.stop);
    final socket = await Socket.connect(InternetAddress.loopbackIPv4, port);
    addTearDown(socket.destroy);
    final ready = Completer<void>();
    final done = Completer<void>();
    final bytes = <int>[];
    final payload = List<int>.generate(2 * 1024 * 1024, (i) => i % 256);
    var headerDone = false;
    socket.listen((data) {
      bytes.addAll(data);
      if (!headerDone) {
        final end = latin1.decode(bytes).indexOf('\r\n\r\n');
        if (end < 0) return;
        expect(latin1.decode(bytes.sublist(0, end)), contains('200'));
        bytes.removeRange(0, end + 4);
        headerDone = true;
        ready.complete();
      }
      if (bytes.length == payload.length && !done.isCompleted) done.complete();
    });
    socket.add(utf8.encode('CONNECT 127.0.0.1:${target.port} HTTP/1.1\r\n'
        'Proxy-Authorization: ${credentials.basicAuthValue()}\r\n\r\n'));
    await ready.future.timeout(const Duration(seconds: 3));
    for (var offset = 0; offset < payload.length; offset += 16384) {
      socket.add(payload.sublist(offset, offset + 16384));
      await socket.flush();
    }
    await done.future.timeout(const Duration(seconds: 5));
    expect(bytes, payload);
  });

  test('stopAll safely stops multiple instances and multiple ports', () async {
    final (first, _, _) = await _startProxy();
    final (second, _, _) = await _startProxy();
    addTearDown(first.stop);
    addTearDown(second.stop);
    final reservation =
        await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final extraPort = reservation.port;
    await reservation.close();
    expect(await first.registerPort(extraPort), isTrue);
    await ProxyServer.stopAll();
    expect(first.isRunning, isFalse);
    expect(second.isRunning, isFalse);
    expect(ProxyServer.getRunningPorts(), isEmpty);
  });

  test('registerPort preserves credentials for existing clients', () async {
    final (proxy, port, credentials) = await _startProxy();
    addTearDown(proxy.stop);
    final reservation =
        await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final extraPort = reservation.port;
    await reservation.close();
    expect(await proxy.registerPort(extraPort), isTrue);
    expect(proxy.credentials.basicAuthValue(), credentials.basicAuthValue());
    for (final listeningPort in [port, extraPort]) {
      final response = await _sendRawRequest(
          listeningPort,
          'GET http://127.0.0.1:1/ HTTP/1.1\r\n'
          'Proxy-Authorization: ${credentials.basicAuthValue()}\r\n\r\n');
      expect(_parseRawResponse(response).$1, isNot(contains('407')));
    }
  });

  test('forwards POST body arriving with request headers (with auth)',
      () async {
    final body = Completer<String>();
    final proxyAuthHeader = Completer<String?>();
    final target = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    target.listen((request) async {
      proxyAuthHeader.complete(request.headers.value('proxy-authorization'));
      body.complete(await utf8.decoder.bind(request).join());
      request.response
        ..statusCode = HttpStatus.ok
        ..write('ok');
      await request.response.close();
    });

    final (proxy, proxyPort, credentials) = await _startProxy();
    const payload = '{"message":"header-and-body-in-one-write"}';
    final request = 'POST http://127.0.0.1:${target.port}/echo HTTP/1.1\r\n'
        'Host: 127.0.0.1:${target.port}\r\n'
        'Proxy-Authorization: ${credentials.basicAuthValue()}\r\n'
        'Content-Type: application/json\r\n'
        'Content-Length: ${utf8.encode(payload).length}\r\n'
        'Connection: close\r\n'
        '\r\n'
        '$payload';

    final response = await _sendRawRequest(proxyPort, request);
    final (status, _) = _parseRawResponse(response);
    expect(status, contains('200'));

    expect(
      await body.future.timeout(const Duration(seconds: 3)),
      equals(payload),
    );
    // 上游绝不能收到 Proxy-Authorization 头。
    expect(
      await proxyAuthHeader.future.timeout(const Duration(seconds: 3)),
      isNull,
    );

    await proxy.stop();
    await target.close(force: true);
  });

  for (final fragmented in [false, true]) {
    test('large same-event body excludes header limit fragmented=$fragmented',
        () async {
      final target = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => target.close(force: true));
      final received = Completer<int>();
      target.listen((request) async {
        received.complete(
            await request.fold<int>(0, (sum, data) => sum + data.length));
        await request.response.close();
      });
      final (proxy, port, credentials) = await _startProxy();
      addTearDown(proxy.stop);
      final socket = await Socket.connect(InternetAddress.loopbackIPv4, port);
      addTearDown(socket.destroy);
      socket.listen((_) {});
      final header = 'POST http://127.0.0.1:${target.port}/ HTTP/1.1\r\n'
          'Host: 127.0.0.1\r\nProxy-Authorization: ${credentials.basicAuthValue()}\r\n'
          'Content-Length: 131072\r\n\r\n';
      if (fragmented) {
        socket.add(utf8.encode(header.substring(0, 20)));
        await socket.flush();
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      socket.add(utf8.encode(
          '${fragmented ? header.substring(20) : header}${'x' * 131072}'));
      await socket.flush();
      expect(await received.future.timeout(const Duration(seconds: 3)), 131072);
    });
  }

  test('rejects request without Proxy-Authorization with 407', () async {
    final target = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final (proxy, proxyPort, _) = await _startProxy();

    final request = 'GET http://127.0.0.1:${target.port}/ HTTP/1.1\r\n'
        'Host: 127.0.0.1:${target.port}\r\n'
        'Connection: close\r\n'
        '\r\n';
    await _expect407(proxyPort, request);

    await proxy.stop();
    await target.close(force: true);
  });

  test('rejects request with wrong credentials with 407', () async {
    final target = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final (proxy, proxyPort, _) = await _startProxy();

    final wrongCredentials = ProxyCredentials(
      username: ProxyCredentials.defaultUsername,
      token: '0' * 64,
    );
    final request = 'GET http://127.0.0.1:${target.port}/ HTTP/1.1\r\n'
        'Host: 127.0.0.1:${target.port}\r\n'
        'Proxy-Authorization: ${wrongCredentials.basicAuthValue()}\r\n'
        'Connection: close\r\n'
        '\r\n';
    await _expect407(proxyPort, request);

    await proxy.stop();
    await target.close(force: true);
  });

  test('forwards request with correct credentials (no Proxy-Auth leak)',
      () async {
    final proxyAuthHeader = Completer<String?>();
    final target = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    target.listen((request) async {
      proxyAuthHeader.complete(request.headers.value('proxy-authorization'));
      request.response
        ..statusCode = HttpStatus.ok
        ..write('ok');
      await request.response.close();
    });

    final (proxy, proxyPort, credentials) = await _startProxy();
    final request = 'GET http://127.0.0.1:${target.port}/ HTTP/1.1\r\n'
        'Host: 127.0.0.1:${target.port}\r\n'
        'Proxy-Authorization: ${credentials.basicAuthValue()}\r\n'
        'Connection: close\r\n'
        '\r\n';
    final response = await _sendRawRequest(proxyPort, request);
    final (status, _) = _parseRawResponse(response);
    expect(status, contains('200'));
    expect(
      await proxyAuthHeader.future.timeout(const Duration(seconds: 3)),
      isNull,
    );

    await proxy.stop();
    await target.close(force: true);
  });

  test('proxy binds to loopback only', () async {
    final (proxy, proxyPort, _) = await _startProxy();
    final bindAddress = proxy.bindAddress;
    expect(bindAddress, isNotNull);
    expect(bindAddress!.isLoopback, isTrue,
        reason: '代理必须绑定 loopback，禁止 anyIPv4 开放代理');
    expect(bindAddress.type, InternetAddressType.IPv4);

    // loopback 可达：无凭据请求应得到 407。
    await _expect407(
      proxyPort,
      'GET http://127.0.0.1:1/ HTTP/1.1\r\n'
      'Host: 127.0.0.1:1\r\n'
      'Connection: close\r\n'
      '\r\n',
    );

    await proxy.stop();
  });

  test('rejects oversized request headers (>64KiB) with 431', () async {
    final (proxy, proxyPort, credentials) = await _startProxy();

    // ignore: prefer_const_declarations
    final bigHeaderValue = 'x' * (64 * 1024);
    final request = 'GET http://127.0.0.1:1/ HTTP/1.1\r\n'
        'Host: 127.0.0.1:1\r\n'
        'Proxy-Authorization: ${credentials.basicAuthValue()}\r\n'
        'X-Big: $bigHeaderValue\r\n'
        'Connection: close\r\n'
        '\r\n';
    final response = await _sendRawRequest(proxyPort, request);
    final (status, _) = _parseRawResponse(response);
    expect(status, contains('431'));

    await proxy.stop();
  });

  test('rejects CONNECT without Proxy-Authorization with 407', () async {
    final (proxy, proxyPort, _) = await _startProxy();

    const request = 'CONNECT example.com:443 HTTP/1.1\r\n'
        'Host: example.com:443\r\n'
        'Connection: close\r\n'
        '\r\n';
    await _expect407(proxyPort, request);

    await proxy.stop();
  });

  test('HttpClient completes automatic proxy authentication challenge',
      () async {
    final target = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    target.listen((request) async {
      request.response.write('automatic-auth-ok');
      await request.response.close();
    });
    final (proxy, proxyPort, credentials) = await _startProxy();
    late HttpClient client;
    HttpOverrides.runWithHttpOverrides(
      () => client = HttpClient(),
      _RealHttpOverrides(),
    );
    client.findProxy = (_) => 'PROXY 127.0.0.1:$proxyPort';
    client.addProxyCredentials(
      '127.0.0.1',
      proxyPort,
      ProxyCredentials.realm,
      HttpClientBasicCredentials(credentials.username, credentials.token),
    );
    client.authenticateProxy = (host, port, scheme, realm) async =>
        host == '127.0.0.1' &&
        port == proxyPort &&
        scheme.toLowerCase() == 'basic' &&
        realm == ProxyCredentials.realm;
    final request = await client.getUrl(
      Uri.parse('http://127.0.0.1:${target.port}/auto'),
    );
    final response = await request.close();
    expect(await utf8.decoder.bind(response).join(), 'automatic-auth-ok');
    client.close(force: true);
    await proxy.stop();
    await target.close(force: true);
  });

  test('drops pipelined and subsequent HTTP requests on one socket', () async {
    final paths = <String>[];
    final target = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    target.listen((request) async {
      paths.add(request.uri.path);
      request.response.write('ok');
      await request.response.close();
    });
    final (proxy, proxyPort, credentials) = await _startProxy();
    String request(String path, {String extra = ''}) =>
        'GET http://127.0.0.1:${target.port}$path HTTP/1.1\r\n'
        'Host: 127.0.0.1:${target.port}\r\n'
        'Proxy-Authorization: ${credentials.basicAuthValue()}\r\n'
        '$extra'
        'Connection: keep-alive\r\n\r\n';
    await _sendRawRequest(
      proxyPort,
      '${request('/first')}${request('/pipeline', extra: 'X-Token: secret\r\n')}',
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(paths, ['/first']);

    final socket =
        await Socket.connect(InternetAddress.loopbackIPv4, proxyPort);
    socket.add(utf8.encode(request('/sequential')));
    await socket.flush();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    socket.add(utf8.encode(request('/must-not-arrive')));
    await socket.flush();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(paths, ['/first', '/sequential']);
    socket.destroy();
    await proxy.stop();
    await target.close(force: true);
  });

  test('forwards fragmented POST body completely', () async {
    final receivedBody = Completer<String>();
    final target = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    target.listen((request) async {
      receivedBody.complete(await utf8.decoder.bind(request).join());
      request.response.write('ok');
      await request.response.close();
    });
    final (proxy, proxyPort, credentials) = await _startProxy();
    const payload = 'fragmented-request-body';
    final socket =
        await Socket.connect(InternetAddress.loopbackIPv4, proxyPort);
    socket.add(utf8.encode(
      'POST http://127.0.0.1:${target.port}/body HTTP/1.1\r\n'
      'Host: 127.0.0.1:${target.port}\r\n'
      'Proxy-Authorization: ${credentials.basicAuthValue()}\r\n'
      'Content-Length: ${payload.length}\r\n\r\nfrag',
    ));
    await socket.flush();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    socket.add(utf8.encode('mented-request-body'));
    await socket.flush();
    expect(
        await receivedBody.future.timeout(const Duration(seconds: 3)), payload);
    socket.destroy();
    await proxy.stop();
    await target.close(force: true);
  });

  test('limits pending auth per instance and releases slots after timeout',
      () async {
    final (proxy, proxyPort, credentials) = await _startProxy();
    final silent = <Socket>[];
    for (var i = 0; i < 16; i++) {
      silent.add(await Socket.connect(InternetAddress.loopbackIPv4, proxyPort));
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(proxy.pendingAuthClientCount, 16);
    final rejected = await _sendRawRequest(
      proxyPort,
      'GET http://127.0.0.1:1/ HTTP/1.1\r\nHost: 127.0.0.1\r\n\r\n',
    );
    expect(_parseRawResponse(rejected).$1, contains('503'));
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    expect(proxy.pendingAuthClientCount, 0);
    final authenticated = await _sendRawRequest(
      proxyPort,
      'GET http://127.0.0.1:1/ HTTP/1.1\r\n'
      'Host: 127.0.0.1\r\n'
      'Proxy-Authorization: ${credentials.basicAuthValue()}\r\n\r\n',
    );
    expect(_parseRawResponse(authenticated).$1, isNot(contains('503')));
    for (final socket in silent) {
      socket.destroy();
    }
    await proxy.stop();
  });

  test('keeps pending and authenticated counts isolated across proxy instances',
      () async {
    ProxyServer? firstProxy;
    ProxyServer? secondProxy;
    HttpServer? httpTarget;
    ServerSocket? tunnelTarget;
    Socket? pendingSocket;
    Socket? authenticatedSocket;
    StreamSubscription<Uint8List>? authenticatedSubscription;
    final acceptedTunnelSockets = <Socket>[];

    try {
      final first = await _startProxy();
      firstProxy = first.$1;
      final firstPort = first.$2;
      final firstCredentials = first.$3;
      final second = await _startProxy();
      secondProxy = second.$1;

      expect(firstPort, isNot(second.$2));
      expect(firstProxy.pendingAuthClientCount, 0);
      expect(firstProxy.authenticatedClientCount, 0);
      expect(secondProxy.pendingAuthClientCount, 0);
      expect(secondProxy.authenticatedClientCount, 0);

      pendingSocket =
          await Socket.connect(InternetAddress.loopbackIPv4, firstPort);

      tunnelTarget = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      tunnelTarget.listen(acceptedTunnelSockets.add);
      authenticatedSocket =
          await Socket.connect(InternetAddress.loopbackIPv4, firstPort);
      final connectResponse = Completer<String>();
      final connectBytes = <int>[];
      authenticatedSubscription = authenticatedSocket.listen((data) {
        connectBytes.addAll(data);
        final response = utf8.decode(connectBytes, allowMalformed: true);
        if (!connectResponse.isCompleted && response.contains('\r\n\r\n')) {
          connectResponse.complete(response);
        }
      });
      authenticatedSocket.add(utf8.encode(
        'CONNECT 127.0.0.1:${tunnelTarget.port} HTTP/1.1\r\n'
        'Host: 127.0.0.1:${tunnelTarget.port}\r\n'
        'Proxy-Authorization: ${firstCredentials.basicAuthValue()}\r\n\r\n',
      ));
      await authenticatedSocket.flush();
      expect(
        await connectResponse.future.timeout(const Duration(seconds: 3)),
        startsWith('HTTP/1.1 200'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(firstProxy.pendingAuthClientCount, 1);
      expect(firstProxy.authenticatedClientCount, 1);
      expect(secondProxy.pendingAuthClientCount, 0);
      expect(secondProxy.authenticatedClientCount, 0);

      await secondProxy.stop();
      expect(secondProxy.pendingAuthClientCount, 0);
      expect(secondProxy.authenticatedClientCount, 0);
      expect(firstProxy.pendingAuthClientCount, 1);
      expect(firstProxy.authenticatedClientCount, 1);

      httpTarget = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      httpTarget.listen((request) async {
        request.response.write('first-proxy-still-available');
        await request.response.close();
      });
      final response = await _sendRawRequest(
        firstPort,
        'GET http://127.0.0.1:${httpTarget.port}/health HTTP/1.1\r\n'
        'Host: 127.0.0.1:${httpTarget.port}\r\n'
        'Proxy-Authorization: ${firstCredentials.basicAuthValue()}\r\n\r\n',
      );
      expect(utf8.decode(response), contains('first-proxy-still-available'));
      expect(firstProxy.pendingAuthClientCount, 1);
      expect(firstProxy.authenticatedClientCount, 1);
    } finally {
      pendingSocket?.destroy();
      await authenticatedSubscription?.cancel();
      authenticatedSocket?.destroy();
      for (final socket in acceptedTunnelSockets) {
        socket.destroy();
      }
      await firstProxy?.stop();
      await secondProxy?.stop();
      await httpTarget?.close(force: true);
      await tunnelTarget?.close();
    }
  });
}
