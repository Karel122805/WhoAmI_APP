// lib/src/ui/screens/game_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class GamePage extends StatefulWidget {
  static const route = '/game';
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  InAppWebViewController? _controller;
  bool _loading = true;
  String? _html; // contenido del index.html

  // Ruta base a assets en Android:
  static const String _androidAssetsBase =
      'file:///android_asset/flutter_assets/assets/gdevelop_game/';

  @override
  void initState() {
    super.initState();
    _loadHtml();
  }

  Future<void> _loadHtml() async {
    try {
      final html = await rootBundle.loadString('assets/gdevelop_game/index.html');
      setState(() {
        _html = html;
      });
    } catch (e) {
      setState(() {
        _html = '<h2 style="color:white;background:#000;'
            'text-align:center;margin-top:30vh">'
            'No se pudo leer index.html<br>${e.toString()}</h2>';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Neurorama – Mini juego')),
      body: _html == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SafeArea(
                  child: InAppWebView(
                    // 👇 Cargamos el HTML como string y fijamos un baseUrl
                    initialData: InAppWebViewInitialData(
                      data: _html!,
                      baseUrl: WebUri(_androidAssetsBase),
                      // historyUrl opcional:
                      // historyUrl: WebUri('about:blank'),
                    ),
                    initialSettings: InAppWebViewSettings(
                      allowFileAccessFromFileURLs: true,
                      allowUniversalAccessFromFileURLs: true,
                      mediaPlaybackRequiresUserGesture: false,
                      useHybridComposition: true,
                      javaScriptEnabled: true,
                    ),
                    onWebViewCreated: (c) => _controller = c,
                    onLoadStop: (c, url) {
                      setState(() => _loading = false);
                    },
                    onLoadError: (c, url, code, message) {
                      setState(() {
                        _loading = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error cargando juego: $message')),
                      );
                    },
                  ),
                ),
                if (_loading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
    );
  }
}
