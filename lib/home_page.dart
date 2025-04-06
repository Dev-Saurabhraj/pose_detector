import 'package:flutter/material.dart';
import 'package:pose_detector/pose_detection.dart';
import 'package:pose_detector/pose_detector_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('pose detector'),
      ),
      body: Center(
        child: MaterialButton(
            color: Colors.greenAccent,
            elevation: 5,
            child: Text("Go"),
            onPressed: (){Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PoseDetectorView()),
            );},),
      ),
    );
  }
}
