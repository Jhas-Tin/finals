import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';

void main(){
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<void> getCoordinates() async{
    await Geolocator.requestPermission();
    Position position = await Geolocator.getCurrentPosition();
    print(position.latitude);
    print(position.longitude);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      home: CupertinoPageScaffold(child: Stack(
        children: [
          Text("Hello world")
        ],
      )),
    );
  }
}
