import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  MapController controller = MapController();

  bool cameraLock = false;
  bool finished = false;

  List<LatLng> temp = [];
  List<LatLng> route = [];
  List<LatLng> fullRoute = [];

  double totalDistance = 0;

  int seconds = 0;

  Timer? timeTracker;

  final Distance distance = const Distance();

  double speedKmh = 20;

  Future<void> getCoordinates() async {

    await Geolocator.requestPermission();

    Position position = await Geolocator.getCurrentPosition();

    String uri =
        "https://router.project-osrm.org/route/v1/driving/${position.longitude},${position.latitude};120.743728,15.073296?overview=full&geometries=geojson";

    final response = await http.get(Uri.parse(uri));

    final data = jsonDecode(response.body);

    List<dynamic> tempRoute = data["routes"][0]["geometry"]["coordinates"];

    for (int i = 0; i < tempRoute.length; i++) {
      temp.add(LatLng(tempRoute[i][1], tempRoute[i][0]));
    }

    setState(() {
      route = List.from(temp);
      fullRoute = List.from(temp);
    });

    startTimer();
    simulatedDelivery();
  }

  void startTimer() {
    timeTracker = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        seconds++;
      });
    });
  }

  void calculateDistance() {

    if (route.length > 1) {

      double d = distance(route.last, route[route.length - 2]);
      totalDistance += d;

    }
  }

  double remainingDistance() {

    double total = 0;

    for (int i = 1; i < route.length; i++) {
      total += distance(route[i - 1], route[i]);
    }

    return total; // meters
  }

  String calculateETA() {

    double remainingMeters = remainingDistance();

    double km = remainingMeters / 1000;

    double hours = km / speedKmh;

    int secondsETA = (hours * 3600).round();

    int h = secondsETA ~/ 3600;
    int m = (secondsETA % 3600) ~/ 60;
    int s = secondsETA % 60;

    return "${h.toString().padLeft(2,"0")}:${m.toString().padLeft(2,"0")}:${s.toString().padLeft(2,"0")}";
  }

  void move() {
    if (route.isNotEmpty) {
      controller.move(route.last, 16);
    }
  }

  void cameraLockLocation() {

    setState(() {
      cameraLock = !cameraLock;
    });

    if (cameraLock) {

      Timer.periodic(const Duration(milliseconds: 300), (timer) {

        if (route.isNotEmpty) {
          controller.move(route.last, 16);
        }

        if (!cameraLock) {
          timer.cancel();
        }

      });

    }
  }

  void simulatedDelivery() {

    Timer.periodic(const Duration(milliseconds: 300), (timer) {

      if (route.length <= 1) {

        timer.cancel();
        timeTracker?.cancel();

        setState(() {
          finished = true;
        });

        return;
      }

      calculateDistance();

      setState(() {
        route.removeLast();
      });

    });

  }

  String formatTime() {

    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;

    return "${h.toString().padLeft(2,"0")}:${m.toString().padLeft(2,"0")}:${s.toString().padLeft(2,"0")}";
  }

  @override
  void initState() {
    getCoordinates();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      home: CupertinoPageScaffold(
          child: SafeArea(

            child: (route.isNotEmpty)

                ? Stack(
              children: [

                FlutterMap(
                    mapController: controller,
                    options: MapOptions(
                      initialCenter: route.last,
                      initialZoom: 16,
                    ),
                    children: [

                      TileLayer(
                        urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                        userAgentPackageName: "com.xyna.delivery",
                      ),

                      PolylineLayer(
                          polylines: [
                            Polyline(
                                points: route,
                                color: CupertinoColors.systemBlue,
                                strokeWidth: 4
                            )
                          ]),

                      MarkerLayer(markers: [

                        Marker(
                            point: route.last,
                            child: const Icon(
                              CupertinoIcons.car,
                              color: CupertinoColors.white,
                            )),

                        Marker(
                            point: route.first,
                            child: const Icon(
                              CupertinoIcons.location_solid,
                              color: CupertinoColors.systemRed,
                            ))

                      ])
                    ]),

                Positioned(
                    bottom: 20,
                    right: 10,
                    child: Column(
                      children: [

                        CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: const Icon(CupertinoIcons.location_fill),
                            onPressed: () {
                              move();
                            }),

                        CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: Icon((cameraLock)
                                ? CupertinoIcons.lock_open_fill
                                : CupertinoIcons.padlock_solid),
                            onPressed: () {
                              cameraLockLocation();
                            })

                      ],
                    )
                ),

                if (finished)
                  Positioned(
                      top: 40,
                      left: 20,
                      right: 20,
                      child: Container(

                        padding: const EdgeInsets.all(20),

                        decoration: BoxDecoration(
                            color: CupertinoColors.black.withOpacity(.75),
                            borderRadius: BorderRadius.circular(16)
                        ),

                        child: Column(
                          children: [

                            const Text(
                              "Activity Summary",
                              style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold),
                            ),

                            const SizedBox(height: 20),

                            Container(
                              height: 120,
                              width: 200,
                              decoration: BoxDecoration(
                                color: CupertinoColors.black,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: CustomPaint(
                                painter: RoutePainter(fullRoute),
                              ),
                            ),

                            const SizedBox(height: 20),

                            Text(
                              "Distance ${(totalDistance / 1000).toStringAsFixed(2)} km",
                              style: const TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 20),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              "Time ${formatTime()}",
                              style: const TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 20),
                            ),

                            const SizedBox(height: 10),

                          ],
                        ),
                      )
                  )

              ],
            )

                : const Center(child: CupertinoActivityIndicator()),

          )),
    );
  }
}

class RoutePainter extends CustomPainter {

  final List<LatLng> route;

  RoutePainter(this.route);

  @override
  void paint(Canvas canvas, Size size) {

    if (route.isEmpty) return;

    final paint = Paint()
      ..color = CupertinoColors.systemOrange
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    double minLat = route.first.latitude;
    double maxLat = route.first.latitude;
    double minLng = route.first.longitude;
    double maxLng = route.first.longitude;

    for (var p in route) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    double latRange = maxLat - minLat;
    double lngRange = maxLng - minLng;

    ui.Path path = ui.Path();

    for (int i = 0; i < route.length; i++) {

      double x = ((route[i].longitude - minLng) / lngRange) * size.width;
      double y = ((route[i].latitude - minLat) / latRange) * size.height;

      y = size.height - y;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}