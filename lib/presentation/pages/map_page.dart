import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..enableZoom(true) // Fondamentale per il pinch-to-zoom a livello di browser
      ..loadHtmlString('''
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=10.0, user-scalable=yes">
          <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
          <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
          <style>
            body { margin: 0; padding: 0; overflow: hidden; }
            #map { 
              height: 100vh; 
              width: 100vw; 
              /* Questo comando dice a iOS: "Passa il pinch-zoom direttamente al web" */
              touch-action: pan-x pan-y pinch-zoom !important; 
            }
            .leaflet-control-zoom { display: none; } /* Rimuoviamo i tasti come chiesto */
            .leaflet-control-attribution { display: none; }
          </style>
        </head>
        <body>
          <div id="map"></div>
          <script>
            var map = L.map('map', { 
              zoomControl: false, // Niente tasti
              tap: false,
              touchZoom: true, // Abilita esplicitamente il pinch
              dragging: true,
              bounceAtZoomLimits: false
            }).setView([40.7751, 14.7892], 16);

            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { 
              maxZoom: 20, 
              maxNativeZoom: 19 
            }).addTo(map);

            // FIX: Ripristina il focus ad ogni singolo tocco
            window.addEventListener('touchstart', function() {
              window.focus();
            }, {passive: true});

            // Poligoni UNISA
            L.polygon([[40.7735, 14.7885], [40.7745, 14.7885], [40.7745, 14.7900], [40.7735, 14.7900]], {color: '#2ecc71', fillOpacity: 0.5, weight: 0}).addTo(map);
            L.polygon([[40.7770, 14.7905], [40.7780, 14.7905], [40.7780, 14.7920], [40.7770, 14.7920]], {color: '#e74c3c', fillOpacity: 0.5, weight: 0}).addTo(map);
          </script>
        </body>
        </html>
      ''');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // La WebView deve avere la priorità assoluta sui gesti
          WebViewWidget(
            controller: controller,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              // EagerGestureRecognizer intercetta il pinch prima di Flutter
              Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
            },
          ),
          // Titolo "trasparente" ai tocchi
          Positioned(
            top: 60, left: 0, right: 0,
            child: IgnorePointer(
              child: Center(
                child: Text(
                  "Mappa dei parcheggi", 
                  style: TextStyle(
                    fontSize: 26, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.black,
                    shadows: [Shadow(color: Colors.white, blurRadius: 4)]
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}