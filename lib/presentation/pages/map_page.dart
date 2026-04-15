import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'enter_parking_sheet.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  static WebViewController? globalController;
  static double? lastLat;
  static double? lastLng;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final WebViewController controller;
  StreamSubscription? _slotsSubscription;
  bool _isMapReady = false;

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
            setState(() => _isMapReady = true);
            _setupFirestoreListener();
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message.startsWith("OPEN_SHEET:")) {
            String slotId = message.message.split(":")[1];
            _showEnterSheet(slotId);
          } else {
            try {
              List<String> coords = message.message.split(',');
              MapPage.lastLat = double.parse(coords[0]);
              MapPage.lastLng = double.parse(coords[1]);
            } catch (e) {
              debugPrint("Errore coordinate: $e");
            }
          }
        },
      )
      ..loadHtmlString(_buildHtml());
  }

  void _setupFirestoreListener() {
    _slotsSubscription = FirebaseFirestore.instance
        .collection('active_slots')
        .where('status', isEqualTo: 'available')
        .snapshots()
        .listen((snapshot) {
          if (!_isMapReady) return;

          List<Map<String, dynamic>> slots = snapshot.docs.map((doc) {
            var data = doc.data();
            return {
              'id': doc.id,
              'lat': data['lat'],
              'lng': data['lng'],
              'veicolo': data['nome_veicolo'] ?? 'Veicolo',
              'timer': data['timer_iniziale'] ?? 5,
            };
          }).toList();

          final jsonSlots = jsonEncode(slots);

          controller.runJavaScript(
            "if(window.updateExternalMarkers) { window.updateExternalMarkers($jsonSlots); }",
          );
        });
  }

  @override
  void dispose() {
    _slotsSubscription?.cancel();
    super.dispose();
  }

  void _showEnterSheet(String slotId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnterParkingSheet(slotId: slotId),
    );
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

  // ... (tutti gli import restano uguali)

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
            #map { height: 100vh; width: 100vw; }
            .parking-marker { background-color: black; border: 2px solid white; border-radius: 50%; color: white; font-weight: bold; text-align: center; line-height: 30px; font-size: 16px; z-index: 1000 !important; }
            .external-marker { background-color: #4A7D91; border: 2px solid white; border-radius: 50%; color: white; text-align: center; line-height: 30px; font-weight: bold; box-shadow: 0 0 8px rgba(0,0,0,0.4); z-index: 1000 !important; }
            .leaflet-control-zoom, .leaflet-control-attribution { display: none; }
          </style>
        </head>
        <body>
          <div id="map"></div>
          <script>
            // MODIFICATO: tap: true per migliorare la risposta su mobile
            var map = L.map('map', { zoomControl: false, tap: true }).setView([40.7725, 14.7915], 16);
            L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png').addTo(map);

            var userMarker = null;
            var externalMarkers = {};
            var isSelectionMode = false;

            window.setSelectionMode = function(active) {
                isSelectionMode = active;
                // Quando usciamo dalla selezione, forziamo un refresh dei marker esterni
                if (!active) {
                    window.removeParkingMarker();
                    map.invalidateSize(); // Forza la mappa a ricalcolare i listener
                }
            };

            window.removeParkingMarker = function() {
              if (userMarker) { map.removeLayer(userMarker); userMarker = null; }
            };

            window.updateExternalMarkers = function(slots) {
                var currentIds = slots.map(function(s) { return s.id; });

                // Rimuovi marker obsoleti
                for (var id in externalMarkers) {
                    if (currentIds.indexOf(id) === -1) {
                        map.removeLayer(externalMarkers[id]);
                        delete externalMarkers[id];
                    }
                }

                // Aggiungi o aggiorna marker
                slots.forEach(function(slot) {
                    if (!externalMarkers[slot.id]) {
                        var m = L.marker([slot.lat, slot.lng], {
                            icon: L.divIcon({
                                className: 'external-marker',
                                html: 'P',
                                iconSize: [30, 30],
                                iconAnchor: [15, 15]
                            })
                        }).addTo(map);

                        // MODIFICATO: Usiamo 'mousedown' o 'click' con stopPropagation
                        m.on('click mousedown', function(e) {
                            L.DomEvent.stopPropagation(e); // Impedisce alla mappa di ricevere il click
                            if (window.FlutterChannel) {
                                window.FlutterChannel.postMessage("OPEN_SHEET:" + slot.id);
                            }
                        });

                        externalMarkers[slot.id] = m;
                    }
                });
            };

            // MODIFICATO: Gestione click mappa più pulita
            map.on('click', function(e) {
              if (!isSelectionMode) return;

              if (userMarker) map.removeLayer(userMarker);
              userMarker = L.marker([e.latlng.lat, e.latlng.lng], {
                icon: L.divIcon({ className: 'parking-marker', html: 'P', iconSize: [30, 30], iconAnchor: [15, 15] })
              }).addTo(map);
              
              if (window.FlutterChannel) {
                window.FlutterChannel.postMessage(e.latlng.lat + "," + e.latlng.lng);
              }
            });

            var polyStyle = { fillOpacity: 0.3, weight: 1, interactive: false };
            L.polygon([[40.77511, 14.79032], [40.77502, 14.79030], [40.77498, 14.79046], [40.77481, 14.79040], [40.77464, 14.79054], [40.77503, 14.79068]], { ...polyStyle, color: '#4A7D91' }).addTo(map);
            L.polygon([[40.77580, 14.78744], [40.77460, 14.78833], [40.77410, 14.78710], [40.77463, 14.78675], [40.77481, 14.78711]], { ...polyStyle, color: '#34495e' }).addTo(map);
          </script>
        </body>
        </html>
    ''';
  }
}
