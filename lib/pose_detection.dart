import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseDetectionPage extends StatefulWidget {
  const PoseDetectionPage({super.key});

  @override
  State<PoseDetectionPage> createState() => _PoseDetectionPageState();
}

class _PoseDetectionPageState extends State<PoseDetectionPage> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  List<PoseLandmark> _landmarks = [];

  Future<void> _getImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      _imageFile = File(image.path);
      await _detectPose(_imageFile!);
      setState(() {});
    }
  }

  Future<void> _detectPose(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final poseDetector = PoseDetector(
      options: PoseDetectorOptions(mode: PoseDetectionMode.single),
    );
    final poses = await poseDetector.processImage(inputImage);
    if (poses.isNotEmpty) {
      _landmarks = poses.first.landmarks.values.toList();
    }
    poseDetector.close();
  }

  Future<ui.Image> _loadUiImage(File file) async {
    final data = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(data);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pose Detection'),
        backgroundColor: Colors.green.shade800,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 400,
            child: _imageFile == null
              ? const Icon(Icons.camera_alt_outlined, size: 100)
              : FutureBuilder<ui.Image>(
            future: _loadUiImage(_imageFile!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                return CustomPaint(
                  size: Size(
                    snapshot.data!.width.toDouble(),
                    snapshot.data!.height.toDouble(),
                  ),
                  painter: PosePainter1(snapshot.data!, _landmarks),
                );
              } else {
                return const CircularProgressIndicator();
              }
            },
          ),),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MaterialButtonWidget(
                label: "Upload from Gallery",
                onPressed: () => _getImage(ImageSource.gallery),
              ),
              const SizedBox(width: 16),
              MaterialButtonWidget(
                label: "Capture with Camera",
                onPressed: () => _getImage(ImageSource.camera),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class MaterialButtonWidget extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const MaterialButtonWidget({super.key, required this.onPressed, required this.label});

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onPressed,
      elevation: 4,
      height: 45,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.green),
      ),
      splashColor: Colors.greenAccent,
      child: Text(
        label,
        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class PosePainter1 extends CustomPainter {
  final ui.Image image;
  final List<PoseLandmark> landmarks;

  PosePainter1(this.image, this.landmarks);

  @override
  void paint(Canvas canvas, Size size) {
    final pointPaint = Paint()
      ..strokeWidth = 4.0
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..strokeWidth = 3.0
      ..color = Colors.green.withOpacity(0.8)
      ..strokeCap = StrokeCap.round;

    // Scale factors to map landmark positions to canvas
    double scaleX = size.width / image.width;
    double scaleY = size.height / image.height;

    // Draw image
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()), rect, Paint());

    Offset scaledOffset(PoseLandmark landmark) =>
        Offset(landmark.x * scaleX, landmark.y * scaleY);

    // Draw joint circles
    for (final landmark in landmarks) {
      final offset = scaledOffset(landmark);
      canvas.drawCircle(offset, 6, pointPaint);
    }

    // Helper to draw lines
    void drawLine(PoseLandmarkType type1, PoseLandmarkType type2) {
      try {
        final p1 = landmarks.firstWhere((l) => l.type == type1);
        final p2 = landmarks.firstWhere((l) => l.type == type2);
        canvas.drawLine(scaledOffset(p1), scaledOffset(p2), linePaint);
      } catch (_) {
        // Skip if landmarks not found
      }
    }

    // Skeleton lines
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
    drawLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
    drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
    drawLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);
    drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
    drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
    drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
    drawLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
    drawLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
    drawLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);
  }

  @override
  bool shouldRepaint(covariant PosePainter1 oldDelegate) =>
      image != oldDelegate.image || landmarks != oldDelegate.landmarks;
}
