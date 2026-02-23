import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../../main.dart';

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
      ..setBackgroundColor(const Color(0xFFFFFFFF)) // Sempre bianco
      ..enableZoom(true)
      ..loadHtmlString(_buildHtml());
  }

  @override
  Widget build(BuildContext context) {
    // Ascoltiamo il tema solo per il box del titolo "Mappa Campus"
    final isDark = Provider.of<ThemeService>(context).isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          WebViewWidget(
            controller: controller,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: IgnorePointer(
              child: Container(
                height: 55,
                decoration: BoxDecoration(
                  // Il box del titolo si adatta al tema dell'app per coerenza
                  color: isDark
                      ? Colors.black.withOpacity(0.8)
                      : Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(15),
                  border: isDark ? Border.all(color: Colors.white12) : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    "Mappa Campus",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF333333),
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildHtml() {
    // Usiamo solo i Tiles chiari (Positron)
    const String mapTiles =
        'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';

    return '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=10.0, user-scalable=yes">
          <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
          <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
          <style>
            body { margin: 0; padding: 0; overflow: hidden; background-color: #ffffff; }
            #map { height: 100vh; width: 100vw; touch-action: pan-x pan-y pinch-zoom !important; }
            .leaflet-control-zoom, .leaflet-control-attribution { display: none; }
          </style>
        </head>
        <body>
          <div id="map"></div>
          <script>
            var map = L.map('map', { 
              zoomControl: false, tap: false, touchZoom: true, dragging: true, bounceAtZoomLimits: false
            }).setView([40.7725, 14.7915], 15);

            L.tileLayer('$mapTiles', { maxZoom: 20, subdomains: 'abcd' }).addTo(map);

            var informaticaCoords = [[40.775111182255706, 14.790328502322696], [40.77502326028438, 14.790307020066566], [40.77498503522413, 14.79046373098474], [40.774815974909636, 14.790405464542195], [40.77464540381218, 14.790544277754915], [40.77503761327039, 14.790681028251193], [40.77511838249426, 14.79033655601146]];
            var farmaciaCoords = [[40.775801639439464, 14.787444097646938], [40.774608000918406, 14.788330685317158], [40.774103325477064, 14.78710644418101], [40.77463400483788, 14.78675442031313], [40.774818929304026, 14.787115186152993], [40.775355397245384, 14.786785258596431], [40.77548008425473, 14.787115461476095], [40.775640409111276, 14.787012198738978]];
            var ingegneriaCoords = [[40.77386050058257, 14.790816693894728], [40.77396854738768, 14.791154426413488], [40.774192022872825, 14.79103932193692], [40.7744617348546, 14.791569934969134], [40.77368815651624, 14.792160469517992], [40.7738465028323, 14.792410176525575], [40.773227578504304, 14.792887501318642], [40.77266860001853, 14.791546848801483], [40.77325478607766, 14.791093071251362], [40.77331241131183, 14.791197512482372]];
            var multipianoCoords = [[40.76741065702939, 14.792740959501169], [40.767699013949546, 14.793722778738237], [40.76792386431746, 14.793717532003221], [40.76791920632912, 14.793837247340944], [40.76687549551982, 14.793917881482214], [40.7668317635251, 14.793357804996816]];
            var mensaCoords = [[40.77256559534837, 14.79279232925913], [40.77268265711835, 14.79308664929488], [40.771247254167506, 14.79413935165044], [40.77111684712297, 14.793821519101828]];
            var giurisprudenzaCoords = [[40.77001082779702, 14.793828764032058], [40.76993706514013, 14.793728542314502], [40.76992097733611, 14.793769025816005], [40.76985494381797, 14.793678741565385], [40.76970864081819, 14.793795988912004], [40.76960172767767, 14.79355467124717], [40.769319032682176, 14.793699089469412], [40.76951016139194, 14.794197599362867]];

            L.polygon(informaticaCoords, { color: '#4A7D91', fillColor: '#4A7D91', fillOpacity: 0.35, weight: 2 }).addTo(map).bindPopup("Informatica");
            L.polygon(farmaciaCoords, { color: '#34495e', fillColor: '#34495e', fillOpacity: 0.35, weight: 2 }).addTo(map).bindPopup("Farmacia");
            L.polygon(ingegneriaCoords, { color: '#e67e22', fillColor: '#e67e22', fillOpacity: 0.35, weight: 2 }).addTo(map).bindPopup("Ingegneria");
            L.polygon(multipianoCoords, { color: '#9b59b6', fillColor: '#9b59b6', fillOpacity: 0.35, weight: 2 }).addTo(map).bindPopup("Multipiano");
            L.polygon(mensaCoords, { color: '#27ae60', fillColor: '#27ae60', fillOpacity: 0.35, weight: 2 }).addTo(map).bindPopup("Mensa");
            L.polygon(giurisprudenzaCoords, { color: '#c0392b', fillColor: '#c0392b', fillOpacity: 0.35, weight: 2 }).addTo(map).bindPopup("Giurisprudenza");
          </script>
        </body>
        </html>
    ''';
  }
}
