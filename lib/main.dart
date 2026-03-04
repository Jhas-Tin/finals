import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;

void main(){
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  MapController controller = MapController();
  bool cameraLock = false;
  List<LatLng> temp = [
    // LatLng(15.103053108325737, 120.7676060510483),
    // LatLng(15.095942157468778, 120.76677780833406),
    // LatLng(15.094188681645957, 120.76962541469615),
  ];
  List<LatLng> route = [];

  Future<void> getCoordinates() async{
    await Geolocator.requestPermission();
    Position position = await Geolocator.getCurrentPosition();
    print("${position.longitude}, ${position.latitude}");
    String uri = "https://router.project-osrm.org/route/v1/driving/${position.longitude},${position.latitude};120.743728,15.073296?overview=full&geometries=geojson";
    final response =  await http.get(
      Uri.parse(uri)
    );
    final data = jsonDecode(response.body);
    //print(data["routes"][0]["geometry"]["coordinates"]);
    List<dynamic> tempRoute = data["routes"][0]["geometry"]["coordinates"];
    for (int i = 0; i < tempRoute.length; i++){
      temp.add(LatLng(tempRoute[i][1], tempRoute[i][0]));
    }
    setState(() {
      route = temp;
    });
    simulatedDelivery();
  }

  void move(){
    controller.move(route.last, 16);
  }

  void cameraLockLocation(){

    setState(() {
      cameraLock = ! cameraLock;
    });
    if (cameraLock) {
      Timer.periodic(Duration(milliseconds: 300), (timer){
        controller.move(route.last, 16);
        if (!cameraLock) {
          timer.cancel();
        }
      });
    }
  }

  void simulatedDelivery() {
    Timer.periodic(Duration(milliseconds: 300), (timer){
      setState(() {
        route.removeLast();
      });
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    getCoordinates();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      home: CupertinoPageScaffold(child: SafeArea(
        child: (route.isNotEmpty) ? Stack(
          children: [
            FlutterMap(
              mapController: controller,
                options: MapOptions(
                  initialCenter: route.last,
                  initialZoom: 16,
                ),
                children: [
                  TileLayer(
                    //https://tile.opentopomap.org/{z}/{x}/{y}.png
                    //https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/
                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.pmg',
                    userAgentPackageName: "com.xyna.delivery",
                  ),
                  PolylineLayer(polylines: [
                    Polyline(points: route, color: CupertinoColors.systemBlue, strokeWidth: 3)
                  ]),
                  MarkerLayer(markers: [
                    Marker(point: route.last, child: Icon(CupertinoIcons.car, color: CupertinoColors.white,)),
                    Marker(point: route.first, child: Icon(CupertinoIcons.location_solid, color: CupertinoColors.white,))
                  ])
                ]),
            Positioned(
                bottom: 0,
                right: 0,
                child: Column(
              children: [
                CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Icon(CupertinoIcons.location_fill), onPressed: (){
                  move();
                }),
                CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Icon((cameraLock) ? CupertinoIcons.lock_open_fill : CupertinoIcons.padlock_solid), onPressed: (){
                      cameraLockLocation();
                })
              ],
            ))
          ],
        ) : Center(child: CupertinoActivityIndicator(),),
      )),
    );
  }
}
