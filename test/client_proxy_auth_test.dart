import 'dart:convert';
import 'dart:io';

import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';
import 'package:flutter_ali_http_dns/flutter_ali_http_dns_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

class _LocalPlatform extends FlutterAliHttpDnsPlatform {
  @override
  Future<bool> initializeDns(DnsConfig config) async => true;

  @override
  Future<String?> resolveDomain(String domain) async => '127.0.0.1';
}

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterAliHttpDnsPlatform.instance = _LocalPlatform();
  final dns = FlutterAliHttpDns.instance;

  setUp(() async {
    FlutterAliHttpDns.setLogEnabled(false);
    expect(
        await dns.initialize(const DnsConfig(
          accountId: 'local-test',
          accessKeyId: 'unused',
          accessKeySecret: 'unused',
        )),
        isTrue);
    final reservation =
        await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = reservation.port;
    await reservation.close();
    expect(await dns.startProxy(config: ProxyConfig(portPool: [port])), isTrue);
  });

  tearDown(() async => dns.dispose());

  test('Dio config documents the actual credential fields', () async {
    final config = (await dns.getDioProxyConfig())!;
    final credentials = (await dns.getProxyCredentials())!;
    expect(config.keys,
        unorderedEquals(['host', 'port', 'username', 'token', 'auth']));
    expect(config['username'], credentials.username);
    expect(config['token'], credentials.token);
    expect(config['auth'], credentials.basicAuthValue());
    expect(config['auth'],
        'Basic ${base64Encode(utf8.encode('${config['username']}:${config['token']}'))}');
  });

  for (final secure in [false, true]) {
    test(
        'configureHttpClient authenticates ${secure ? 'HTTPS CONNECT (records SDK credential leak)' : 'HTTP without leaking credentials'}',
        () async {
      // Test-only self-signed certificate. No Internet, platform SDK or device.
      final context = secure
          ? (SecurityContext()
            ..useCertificateChainBytes(utf8.encode(_certificate))
            ..usePrivateKeyBytes(utf8.encode(_privateKey)))
          : null;
      final target = secure
          ? await HttpServer.bindSecure(
              InternetAddress.loopbackIPv4, 0, context!)
          : await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => target.close(force: true));
      var requests = 0;
      String? upstreamProxyAuthorization;
      String? upstreamAuthorization;
      target.listen((request) async {
        requests++;
        upstreamProxyAuthorization =
            request.headers.value('proxy-authorization');
        upstreamAuthorization = request.headers.value('authorization');
        request.response.write('authenticated');
        await request.response.close();
      });
      await HttpOverrides.runZoned(() async {
        final client = HttpClient();
        addTearDown(() => client.close(force: true));
        // Only trust this test's local TLS endpoint; production must keep normal validation.
        client.badCertificateCallback = (cert, host, port) =>
            secure && host == '127.0.0.1' && port == target.port;
        expect(await dns.configureHttpClient(client), isTrue);
        final request = await client.getUrl(Uri.parse(
            '${secure ? 'https' : 'http'}://127.0.0.1:${target.port}/check'));
        request.headers.set('Authorization', 'Bearer business-token');
        final response =
            await request.close().timeout(const Duration(seconds: 5));
        expect(response.statusCode, HttpStatus.ok);
        expect(await utf8.decoder.bind(response).join(), 'authenticated');
        expect(requests, 1);
        expect(upstreamAuthorization, 'Bearer business-token');
        if (secure) {
          // Known Dart 3.11.5 limitation: _HttpClientConnection.send adds proxy
          // credentials again inside the TLS tunnel. Record the actual leak;
          // this is NOT a no-leak acceptance test for HTTPS.
          expect(upstreamProxyAuthorization,
              (await dns.getProxyCredentials())!.basicAuthValue());
        } else {
          expect(upstreamProxyAuthorization, isNull);
        }
      }, createHttpClient: _RealHttpOverrides().createHttpClient);
    });
  }

  test('stopped proxy cannot configure a client', () async {
    await dns.stopProxy();
    await HttpOverrides.runZoned(() async {
      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      expect(await dns.configureHttpClient(client), isFalse);
      expect(await dns.getDioProxyConfig(), isNull);
    }, createHttpClient: _RealHttpOverrides().createHttpClient);
  });
}

// Public, disposable fixture key, never used outside these loopback tests.
const _privateKey = '''-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDC6SHkAF2v9mzW
WPCwCSBkkVfHCBK2mhPApyHDenbgH6ocF9JjC0n8KdVWFATq0igEQJPcwDTOGFdc
XnsRiv+8W8w8odFMraG5DsDMHeUof+pDB44d38fEA1rW0V2juwdb6sKEcsC6lXIS
btlPYnBecmCvwuOJ4mo/LCEYk5Hdh2M5QQxxSW1Aqdn3L+SFAnQWYq+vMTeizwoR
IYNaFIr1jf3pZ/h9COWbgdVKoEYtfAveue00l6J+IuUXqVX5dyvQT1MSSkCoB/ej
n7HUMOZTDu9qLtHnOBGIE4TKncAJh8mMHyrIoxCm5E+bU/sAYyXd08KlpbQtMg2O
3Qi0KT27AgMBAAECggEALtCKGFZSKlp4577zCIUYp68VMzPoMr2tMt+xx17ZwJk6
ZYb/PFTQz2VI3WTvjWsuu167ZRExXbMRAJmc26jUJeyykHmZaN5ncqhtfFlN2j1n
CfR9mQVP2O+pWOFuqU3ZxaUMVX2uduJARNclEOEm9jhoqq6Xsl2UgVnbFSkUpu1b
WKARx50Dc5rXETPW3oYlIla7oT65Ec32Di6rDO4KrgJdZ39VLQGyYKietd4a5JBJ
D34suaPt1MgvDiHULPSN/LSn35XbAu/GbZB7G9COhT11Weqx4XkWr5oy/9prAel0
PeU2akFS/jeFGSlQ0Hf+/nu+izZklsudfRBvCJfpKQKBgQDsYoa6ZnYy03rqt/Kt
/XYtj8ghtD9KxPskDZwuaPUR+nzjxYNq2IMePMw65YXGzZIpz/XZJc9eoR/W/4Tm
20MYcbR5V+Y8f2EZyZLGTzAX4Y+6j/mqcOwdemGAhUPXBV2f9yHuGPYVB3Fz6oMR
po8SvXmPI4Yt2vs5P57druBJzQKBgQDTFZQcipOOdwi8zDXo3dMGt5dA8Qjy7JP4
SpRa8xbcAcQ8NsdZi8F1bgux3wQTDOtWKiprZPuyt+pJ6/T5DNrbOXtOfpAD0hYA
+ZH1c5td9CPYmd6SY+txzloSSfq9aLqs3p8ypOnmqr5INFBmThbkluIc4wVLl2k5
fQ7GexB9pwKBgBtA8M+k6JPLlixhsPUmd+2g2i4onfN86oepmgwvxbGg860/JHu5
IsTltZZEyDu3j9aKR4oVtebvJMChDS2gsgerdGdZHw5ykTtr5iQ/FQhr1SppVxuz
kUWEyqEKvFuaHsVGtP7CmfyqswXuT9ZFIdHDTrSWH+5BhR2AnExq0SkxAoGBAJNp
Vm44OKQdbPSsiFl/0Ie4XuDzc5Rys0OKkeCSMzyh3zFN8BoRB6HCoFgvruC+/PrH
p6godb5xwiStq/7hg1Xl5r8ClACXDtbPc6c+fRo4DXCOxGjnbt2jhjOPhpQQN43S
SstLcC2uwAQcxKktj79Dv9T8lg4cR1fmhhMGjpWxAoGBAINUsxqCIsed34ka5cbK
Wavs+9/390Y/3SxeJ5pKHN7si4MYbBLRwUdiE9mmTrmMnjoLZSzxdsZlZ849YR9r
d3pQDhAjlMR6vpcPesO70LQxHn8ElZ1XrajezrDLh5q/TxnV2SxT7I1RSWvwVeSG
f0dQbCUTwvnU2yOi/YaHGxoZ
-----END PRIVATE KEY-----''';
const _certificate = '''-----BEGIN CERTIFICATE-----
MIIC6DCCAdCgAwIBAgIUae3R42Xuj0fljZ6srsLZ9nniSXUwDQYJKoZIhvcNAQEL
BQAwFDESMBAGA1UEAwwJbG9jYWxob3N0MB4XDTI2MTEwOTAzMDEyOVoXDTM2MTEw
NjAzMDEyOVowFDESMBAGA1UEAwwJbG9jYWxob3N0MIIBIjANBgkqhkiG9w0BAQEF
AAOCAQ8AMIIBCgKCAQEAwukh5ABdr/Zs1ljwsAkgZJFXxwgStpoTwKchw3p24B+q
HBfSYwtJ/CnVVhQE6tIoBECT3MA0zhhXXF57EYr/vFvMPKHRTK2huQ7AzB3lKH/q
QweOHd/HxANa1tFdo7sHW+rChHLAupVyEm7ZT2JwXnJgr8LjieJqPywhGJOR3Ydj
OUEMcUltQKnZ9y/khQJ0FmKvrzE3os8KESGDWhSK9Y396Wf4fQjlm4HVSqBGLXwL
3rntNJeifiLlF6lV+Xcr0E9TEkpAqAf3o5+x1DDmUw7vai7R5zgRiBOEyp3ACYfJ
jB8qyKMQpuRPm1P7AGMl3dPCpaW0LTINjt0ItCk9uwIDAQABozIwMDAdBgNVHQ4E
FgQUiAS9MoQ2v4+lTpU+al+Sin8fCL8wDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG
9w0BAQsFAAOCAQEAj13icmAWo4hBtw7GKLQKnTljvW+UvsUuv8XdidNDj71xnk3u
lLKH73tJcPilZN2vlOYJfjxf3Nf66iXLN6rj8AYvWq+UxiNWWGL5GUdl5+Imt7nw
mrhmYTZ7RV8kyQuwiFWQVTZyQMEdCcYMQvb3mOXfFX03AuF/A/j6DMfSQ7S0g6Rv
7ZfyzJYQdreoDohPaI8lQyvj0qjoQQPqlaD2NAkcqgWsv1vNW/XX4oF0fXd645DH
VFVwPV3I7fSURd4dipg4JdxnQs8R6MaYlf/dKD8gRLA+ejLIjowMdZwEYgtpr5/C
36r5kuz5Kcxuwfu4yvlt6TNdKAyU0tkjkGIK0Q==
-----END CERTIFICATE-----''';
