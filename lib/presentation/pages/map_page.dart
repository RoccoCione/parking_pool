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
      body: Stack(
        children: [
          // La mappa Webview
          WebViewWidget(
            controller: controller,
            gestureRecognizers: {
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
          ),

          // Pulsante per centrare la mappa (Piccolo e in alto a destra)
          Positioned(
            top:
                60, // Distanza dal bordo superiore per evitare la barra di stato
            right: 20,
            child: SizedBox(
              width: 40, // Dimensione ridotta
              height: 40,
              child: FloatingActionButton(
                heroTag: "center_map",
                elevation: 4,
                backgroundColor: const Color(0xFF4A7D91),
                child: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: 20, // Icona proporzionata
                ),
                onPressed: () {
                  controller.runJavaScript(
                    "map.flyTo([40.7725, 14.7915], 16, {animate: true, duration: 1.5});",
                  );
                },
              ),
            ),
          ),
        ],
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
          body { margin: 0; padding: 0; overflow: hidden; background: #f8f9fa; }
          #map { height: 100vh; width: 100vw; }
          
          .parking-marker { 
            background-color: #2d3436; 
            border: 3px solid white; 
            border-radius: 50%; 
            color: white; 
            font-weight: bold; 
            text-align: center; 
            line-height: 30px; 
            font-size: 14px; 
            box-shadow: 0 4px 15px rgba(0,0,0,0.3);
          }

          .external-marker { 
            background-color: #4A7D91; 
            border: 2px solid white; 
            border-radius: 50% 50% 50% 0;
            transform: rotate(-45deg);
            color: white; 
            text-align: center; 
            box-shadow: 0 4px 10px rgba(0,0,0,0.2);
          }
          
          .marker-text { transform: rotate(45deg); display: block; line-height: 30px; font-weight: bold; font-size: 14px; }

          .pulse {
            display: block; width: 30px; height: 30px; border-radius: 50%;
            background: rgba(74, 125, 145, 0.4);
            animation: pulse 2s infinite; position: absolute; top: -2px; left: -2px;
          }

          @keyframes pulse {
            0% { box-shadow: 0 0 0 0 rgba(74, 125, 145, 0.7); }
            70% { box-shadow: 0 0 0 15px rgba(74, 125, 145, 0); }
            100% { box-shadow: 0 0 0 0 rgba(74, 125, 145, 0); }
          }

          .leaflet-popup-content-wrapper { border-radius: 8px; padding: 2px; }
          .leaflet-popup-tip-container { display: none; }
          .leaflet-control-zoom, .leaflet-control-attribution { display: none; }
        </style>
      </head>
      <body>
        <div id="map"></div>
        <script>
          var map = L.map('map', { 
              zoomControl: false, 
              tap: true,
              inertia: true,
              preferCanvas: true 
          }).setView([40.7725, 14.7915], 16);

          L.tileLayer('https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png').addTo(map);

          var userMarker = null;
          var externalMarkers = {};
          var isSelectionMode = false;

          window.setSelectionMode = function(active) { 
            isSelectionMode = active; 
            if (!active) window.removeParkingMarker();
            map.closePopup();
          };

          window.removeParkingMarker = function() { if (userMarker) { map.removeLayer(userMarker); userMarker = null; } };

          window.updateExternalMarkers = function(slots) {
              var currentIds = slots.map(function(s) { return s.id; });
              for (var id in externalMarkers) {
                  if (currentIds.indexOf(id) === -1) {
                      map.removeLayer(externalMarkers[id]);
                      delete externalMarkers[id];
                  }
              }
              slots.forEach(function(slot) {
                  if (!externalMarkers[slot.id]) {
                      var m = L.marker([slot.lat, slot.lng], {
                          icon: L.divIcon({
                              className: 'custom-div-icon',
                              html: '<div class="pulse"></div><div class="external-marker"><span class="marker-text">P</span></div>',
                              iconSize: [30, 30], iconAnchor: [15, 15]
                          })
                      }).addTo(map);
                      
                      m.on('click', function(e) {
                          L.DomEvent.stopPropagation(e);
                          map.closePopup();
                          if (window.FlutterChannel) window.FlutterChannel.postMessage("OPEN_SHEET:" + slot.id);
                      });
                      externalMarkers[slot.id] = m;
                  }
              });
          };

          map.on('click', function(e) {
            if (!isSelectionMode) return;
            
            map.closePopup();
            
            if (userMarker) map.removeLayer(userMarker);
            userMarker = L.marker([e.latlng.lat, e.latlng.lng], {
              icon: L.divIcon({ className: 'parking-marker', html: 'P', iconSize: [30, 30], iconAnchor: [15, 15] })
            }).addTo(map);
            if (window.FlutterChannel) window.FlutterChannel.postMessage(e.latlng.lat + "," + e.latlng.lng);
          });

          var polyStyle = { fillOpacity: 0.2, weight: 2, color: '#4A7D91', dashArray: '5, 10' };

          function addParkingArea(coords, name) {
              var poly = L.polygon(coords, polyStyle).addTo(map);
              
              poly.on('click', function(e) {
                  if (isSelectionMode) {
                      // TRUCCO: Se siamo in selezione, simuliamo un click sulla mappa 
                      // nelle stesse coordinate per far apparire il marker nero
                      map.fire('click', e); 
                      return; 
                  }
                  
                  L.popup()
                    .setLatLng(e.latlng)
                    .setContent('<b style="color: #4A7D91; font-family: sans-serif; font-size: 13px;">' + name + '</b>')
                    .openOn(map);
              });
          }

          // Aggiunta aree con coordinate complete
          addParkingArea([
              [40.77256559534837, 14.79279232925913],
              [40.77268265711835, 14.79308664929488],
              [40.771247254167506, 14.79413935165044],
              [40.77111684712297, 14.793821519101828]
          ], "Parcheggio Mensa");

          addParkingArea([
              [40.77001082779702, 14.793828764032058],
              [40.76993706514013, 14.793728542314502],
              [40.76992097733611, 14.793769025816005],
              [40.76985494381797, 14.793678741565385],
              [40.76970864081819, 14.793795988912004],
              [40.76960172767767, 14.79355467124717],
              [40.769319032682176, 14.793699089469412],
              [40.76951016139194, 14.794197599362867]
          ], "Parcheggio Giurisprudenza");

          addParkingArea([
              [40.77579849920218, 14.787436659636995],
              [40.77548990027803, 14.787105055977753],
              [40.77535092764958, 14.786786354063453],
              [40.774853502300196, 14.787061051951705],
              [40.77462979433082, 14.78674893127272],
              [40.77396476289088, 14.78716338144754],
              [40.77440855548802, 14.788468882628743]
          ], "Informatica / Farmacia");

          addParkingArea([
              [40.775103608888045, 14.790326110396503],
              [40.774799276843076, 14.790410969771425],
              [40.77464777867754, 14.7905320706851],
              [40.77503573507723, 14.79067465964113]
          ], "Parcheggio Nord");

          addParkingArea([
              [40.77429906441958, 14.791164360020788],
              [40.77443367843061, 14.791580313185591],
              [40.7736688949185, 14.792163748245015],
              [40.77377844052101, 14.792471654122853],
              [40.7732185592747, 14.792872682366902],
              [40.77268130765263, 14.79152093587828],
              [40.77323573303127, 14.79112901798461],
              [40.77330223606627, 14.791194631295951],
              [40.773836776146894, 14.79082462280933],
              [40.77401160194669, 14.791175590460112],
              [40.77418424555364, 14.791087994389574]
          ], "Parcheggio Ingegneria");

          addParkingArea([
              [40.76739897953872, 14.792665641419934],
              [40.766796570547704, 14.793335022071188],
              [40.76690812443376, 14.793986924101949],
              [40.76796456658152, 14.79384424908399],
              [40.767700536953285, 14.793638076411009]
          ], "Complesso Multi-Piano");

        </script>
      </body>
      </html>
  ''';
  }
}
