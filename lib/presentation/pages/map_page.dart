import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../../main.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  static WebViewController? globalController;

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
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            MapPage.globalController = controller;
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          // Qui ricevi le coordinate "lat,lng" ogni volta che l'utente tocca la mappa
          debugPrint("Coordinate ricevute: ${message.message}");
        },
      )
      ..loadHtmlString(_buildHtml());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebViewWidget(
        controller: controller,
        gestureRecognizers: {
          Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
        },
      ),
    );
  }

  String _buildHtml() {
    return '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
          <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
          <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
          <style>
            body { margin: 0; padding: 0; overflow: hidden; }
            #map { height: 100vh; width: 100vw; touch-action: none !important; }
            .parking-marker {
              background-color: black;
              border: 2px solid white;
              border-radius: 50%;
              color: white;
              font-weight: bold;
              text-align: center;
              line-height: 30px;
              font-size: 16px;
              z-index: 9999 !important;
            }
            .leaflet-control-zoom, .leaflet-control-attribution { display: none; }
          </style>
        </head>
        <body>
          <div id="map"></div>
          <script>
            var map = L.map('map', { zoomControl: false, tap: false }).setView([40.7725, 14.7915], 16);
            L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png').addTo(map);

            var userMarker = null;
            var isSelectionMode = false; // Ritorna a false di default

            // Attivata dal MainWrapper quando si preme "ESCO"
            window.setSelectionMode = function(active) {
                isSelectionMode = active;
            };

            // Chiamata se l'utente annulla o chiude lo sheet
            window.removeParkingMarker = function() {
              if (userMarker) {
                map.removeLayer(userMarker);
                userMarker = null;
              }
            };

            function placeMarker(lat, lng) {
              if (userMarker) map.removeLayer(userMarker);
              userMarker = L.marker([lat, lng], {
                icon: L.divIcon({
                  className: 'parking-marker',
                  html: 'P',
                  iconSize: [30, 30],
                  iconAnchor: [15, 15]
                })
              }).addTo(map);
            }

            map.on('mousedown', function(e) {
              if (!isSelectionMode) return;
              
              placeMarker(e.latlng.lat, e.latlng.lng);
              
              if (window.FlutterChannel) {
                window.FlutterChannel.postMessage(e.latlng.lat + "," + e.latlng.lng);
              }
            });

            // POLIGONI TRASPARENTI AI CLICK (interactive: false)
            var polyStyle = { fillOpacity: 0.35, weight: 2, interactive: false };

            L.polygon([[40.77511, 14.79032], [40.77502, 14.79030], [40.77498, 14.79046], [40.77481, 14.79040], [40.77464, 14.79054], [40.77503, 14.79068]], { ...polyStyle, color: '#4A7D91' }).addTo(map);
            L.polygon([[40.77580, 14.78744], [40.77460, 14.78833], [40.77410, 14.78710], [40.77463, 14.78675], [40.77481, 14.78711]], { ...polyStyle, color: '#34495e' }).addTo(map);
            L.polygon([[40.77386, 14.79081], [40.77396, 14.79115], [40.77419, 14.79103], [40.77446, 14.79156], [40.77368, 14.79216]], { ...polyStyle, color: '#e67e22' }).addTo(map);
            L.polygon([[40.76741, 14.79274], [40.76769, 14.79372], [40.76792, 14.79371], [40.76687, 14.79391]], { ...polyStyle, color: '#9b59b6' }).addTo(map);
            L.polygon([[40.77256, 14.79279], [40.77268, 14.79308], [40.77124, 14.79413], [40.77111, 14.79382]], { ...polyStyle, color: '#27ae60' }).addTo(map);
            L.polygon([[40.77001, 14.79382], [40.76993, 14.79372], [40.76931, 14.79369], [40.76951, 14.79419]], { ...polyStyle, color: '#c0392b' }).addTo(map);
          </script>
        </body>
        </html>
    ''';
  }
}
