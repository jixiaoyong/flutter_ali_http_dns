import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../utils/proxy_auth.dart';

/// Isolates CONNECT credentials from the business HttpClient.
Future<ConnectionTask<Socket>> connectThroughProxy(
  Uri target, {
  required String proxyHost,
  required int proxyPort,
  required ProxyCredentials credentials,
  SecurityContext? context,
  Duration timeout = const Duration(seconds: 30),
}) async {
  if (target.scheme != 'http' && target.scheme != 'https') {
    throw UnsupportedError('Only HTTP and HTTPS tunnels are supported');
  }
  final result = Completer<Socket>();
  ConnectionTask<Socket>? pending;
  Socket? active;
  var finished = false;
  void fail(Object error, [StackTrace? stack]) {
    if (finished) return;
    finished = true;
    pending?.cancel();
    active?.destroy();
    result.completeError(error, stack);
  }

  final timer = Timer(timeout, () {
    fail(TimeoutException('Proxy tunnel connection timed out', timeout));
  });
  Future<void> establish() async {
    try {
      if (target.scheme == 'http') {
        final connector = HttpClient()
          ..findProxy = (_) => 'PROXY $proxyHost:$proxyPort';
        connector.addProxyCredentials(
            proxyHost,
            proxyPort,
            ProxyCredentials.realm,
            HttpClientBasicCredentials(
                credentials.username, credentials.token));
        // Closing this dedicated connector cancels its pending CONNECT.
        final original = result.future;
        unawaited(original.then<void>((_) => connector.close(force: true),
            onError: (Object _) => connector.close(force: true)));
        final request = await connector.openUrl(
            'CONNECT', Uri(host: target.host, port: target.port));
        request.followRedirects = false;
        final response = await request.close();
        if (response.statusCode != HttpStatus.ok) {
          throw const HttpException('Proxy CONNECT rejected');
        }
        active = await response.detachSocket();
        if (finished) {
          active!.destroy();
          return;
        }
        finished = true;
        result.complete(active!);
        return;
      }
      pending = await Socket.startConnect(proxyHost, proxyPort);
      if (finished) pending!.cancel();
      final socket = await pending!.socket;
      active = socket;
      if (finished) {
        socket.destroy();
        return;
      }
      final header = Completer<void>();
      final bytes = <int>[];
      final subscription = socket.listen((data) {
        if (header.isCompleted) return;
        for (var index = 0; index < data.length; index++) {
          bytes.add(data[index]);
          final n = bytes.length;
          if (n > 16384) {
            header.completeError(
                const HttpException('CONNECT headers exceed 16 KiB'));
            return;
          }
          if (n >= 4 &&
              bytes[n - 4] == 13 &&
              bytes[n - 3] == 10 &&
              bytes[n - 2] == 13 &&
              bytes[n - 1] == 10) {
            // A CONNECT target cannot send application data before this client
            // sends HTTP or the TLS ClientHello. Reject unexpected early bytes.
            if (index != data.length - 1) {
              header.completeError(
                  const HttpException('Unexpected data after CONNECT headers'));
              return;
            }
            header.complete();
            return;
          }
        }
      }, onError: (Object error, StackTrace stack) {
        if (!header.isCompleted) header.completeError(error, stack);
      }, onDone: () {
        if (!header.isCompleted) {
          header.completeError(
              const HttpException('Proxy closed during CONNECT'));
        }
      });
      final host = target.host.contains(':') ? '[${target.host}]' : target.host;
      final authority = '$host:${target.port}';
      socket.write('CONNECT $authority HTTP/1.1\r\n'
          'Host: $authority\r\n'
          'Proxy-Authorization: ${credentials.basicAuthValue()}\r\n\r\n');
      await header.future;
      subscription.pause();
      final status = latin1.decode(bytes).split('\r\n').first;
      if (!RegExp(r'^HTTP/1\.[01] 200(?: |$)').hasMatch(status)) {
        throw const HttpException('Proxy CONNECT rejected or malformed');
      }
      if (finished) return;
      if (target.scheme == 'https') {
        // 已知上游限制：SecureSocket.secure() 在握手期间接管底层连接，
        // 外层超时或取消不保证终止底层握手或立即释放连接。
        // 详见：https://github.com/dart-lang/sdk/issues/64143
        active = await SecureSocket.secure(socket,
            host: target.host, context: context);
      }
      if (finished) {
        active?.destroy();
        return;
      }
      finished = true;
      timer.cancel();
      result.complete(active!);
    } catch (error, stack) {
      fail(error, stack);
    } finally {
      timer.cancel();
    }
  }

  unawaited(establish());
  return ConnectionTask.fromSocket(result.future, () {
    timer.cancel();
    fail(const SocketException('Proxy tunnel connection cancelled'));
  });
}
