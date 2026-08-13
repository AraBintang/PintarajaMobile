import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TurnstileScreen extends StatefulWidget {
  final String siteKey;

  const TurnstileScreen({
    super.key,
    required this.siteKey,
  });

  @override
  State<TurnstileScreen> createState() =>
      _TurnstileScreenState();
}

class _TurnstileScreenState
    extends State<TurnstileScreen> {
  late final WebViewController _controller;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(
        JavaScriptMode.unrestricted,
      )
      ..setBackgroundColor(
        Colors.transparent,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) {
              return;
            }

            setState(() {
              _loading = true;
              _error = null;
            });
          },
          onPageFinished: (_) {
            if (!mounted) {
              return;
            }

            setState(() {
              _loading = false;
            });
          },
          onWebResourceError: (error) {
            if (!mounted) {
              return;
            }

            setState(() {
              _loading = false;
              _error =
                  'Turnstile gagal dimuat. '
                  'Periksa koneksi internet.';
            });
          },
        ),
      )
      ..addJavaScriptChannel(
        'Turnstile',
        onMessageReceived: (
          JavaScriptMessage message,
        ) {
          final value =
              message.message.trim();

          if (value.isEmpty) {
            return;
          }

          if (value.startsWith('ERROR:')) {
            if (!mounted) {
              return;
            }

            setState(() {
              _loading = false;
              _error = value
                  .substring(6)
                  .trim();
            });

            return;
          }

          if (value == 'EXPIRED') {
            if (!mounted) {
              return;
            }

            setState(() {
              _error =
                  'Verifikasi kedaluwarsa. Silakan ulangi.';
            });

            return;
          }

          // Token Turnstile berhasil.
          if (!value.contains(':') &&
              value.length > 20) {
            Navigator.of(
              context,
            ).pop(value);
          }
        },
      );

    _loadTurnstile();
  }

  // ==========================================================
  // LOAD TURNSTILE
  // ==========================================================

  Future<void> _loadTurnstile() async {
    final siteKey =
        jsonEncode(widget.siteKey);

    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta
    name="viewport"
    content="width=device-width, initial-scale=1.0"
  />

  <meta
    http-equiv="Content-Security-Policy"
    content="
      default-src 'self';
      script-src 'self' https://challenges.cloudflare.com 'unsafe-inline';
      connect-src 'self' https://challenges.cloudflare.com;
      frame-src 'self' https://challenges.cloudflare.com;
      style-src 'self' 'unsafe-inline';
    "
  />

  <style>
    html, body {
      margin: 0;
      padding: 0;
      width: 100%;
      height: 100%;
      background: transparent;
      overflow: hidden;
      font-family: Arial, sans-serif;
    }

    body {
      display: flex;
      align-items: center;
      justify-content: center;
    }

    #turnstile-container {
      width: 100%;
      min-height: 70px;
      display: flex;
      align-items: center;
      justify-content: center;
    }
  </style>

  <script
    src="https://challenges.cloudflare.com/turnstile/v0/api.js"
    async
    defer
    onload="initializeTurnstile()">
  </script>
</head>

<body>
  <div id="turnstile-container"></div>

  <script>
    function sendMessage(value) {
      try {
        Turnstile.postMessage(value);
      } catch (e) {
        console.log(e);
      }
    }

    function initializeTurnstile() {
      if (!window.turnstile) {
        setTimeout(initializeTurnstile, 300);
        return;
      }

      try {
        window.turnstile.render(
          '#turnstile-container',
          {
            sitekey: $siteKey,
            theme: 'light',
            size: 'normal',

            callback: function(token) {
              sendMessage(token);
            },

            'expired-callback': function() {
              sendMessage('EXPIRED');
            },

            'error-callback': function(error) {
              sendMessage(
                'ERROR: Cloudflare Turnstile error'
              );
            }
          }
        );
      } catch (e) {
        sendMessage(
          'ERROR: Gagal menjalankan Turnstile'
        );
      }
    }
  </script>
</body>
</html>
''';

    await _controller.loadHtmlString(
      html,
      baseUrl: 'https://pintaraja.com/',
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Security verification',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: Container(
              margin:
                  const EdgeInsets.all(24),
              padding:
                  const EdgeInsets.all(24),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(
                      alpha: 0.06,
                    ),
                    blurRadius: 24,
                    offset:
                        const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  const Text(
                    'Verifikasi keamanan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w700,
                      color:
                          Color(0xFF1F2937),
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  const Text(
                    'Selesaikan verifikasi untuk membuat akun PintarAja.',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color:
                          Color(0xFF6B7280),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  SizedBox(
                    height: 90,
                    child:
                        WebViewWidget(
                      controller:
                          _controller,
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      _error!,
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        color:
                            Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (_loading)
            const Center(
              child:
                  CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}