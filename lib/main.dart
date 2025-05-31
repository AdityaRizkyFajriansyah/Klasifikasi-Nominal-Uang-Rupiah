import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image/image.dart' as img;
import 'dart:math';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp(camera: cameras.first));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;
  const MyApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TFLite Kamera',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(camera: camera),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final CameraDescription camera;
  const MyHomePage({super.key, required this.camera});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late CameraController _controller;
  late Interpreter _interpreter;
  final FlutterTts _flutterTts = FlutterTts();
  bool _isCameraInitialized = false;
  String _output = '';

  final Map<int, String> labels = {
    0: 'Seribu',
    1: 'Seribu',
    2: 'Dua Ribu',
    3: 'Dua Ribu',
    4: 'Lima Ribu',
    5: 'Lima Ribu',
    6: 'Sepuluh Ribu',
    7: 'Sepuluh Ribu',
    8: 'Dua Puluh Ribu',
    9: 'Dua Puluh Ribu',
    10: 'Lima Puluh Ribu',
    11: 'Lima Puluh Ribu',
    12: 'Seratus Ribu',
    13: 'Seratus Ribu'
  };

  @override
  void initState() {
    super.initState();
    _initCameraAndModel();
  }

  Future<void> _initCameraAndModel() async {
    _controller = CameraController(widget.camera, ResolutionPreset.medium, enableAudio: false);
    await _controller.initialize();
    await _controller.setFlashMode(FlashMode.off); // 🔕 Matikan flash

    _interpreter = await Interpreter.fromAsset('assets/model.tflite');

    setState(() => _isCameraInitialized = true);

    await _flutterTts.speak("Kamera siap digunakan");
    await _flutterTts.speak("Silakan tekan tombol untuk klasifikasi");
  }

  Future<void> _classifyImage() async {
    final image = await _controller.takePicture();
    final bytes = await File(image.path).readAsBytes();
    final decodedImage = img.decodeImage(bytes)!;
    final resizedImage = img.copyResize(decodedImage, width: 224, height: 224);

    var input = List.generate(1, (_) => List.generate(224, (_) => List.generate(224, (_) => List.filled(3, 0.0))));
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = resizedImage.getPixel(x, y);
        input[0][y][x][0] = pixel.r / 255.0;
        input[0][y][x][1] = pixel.g / 255.0;
        input[0][y][x][2] = pixel.b / 255.0;
      }
    }

    var output = List.filled(1 * 14, 0.0).reshape([1, 14]);
    _interpreter.run(input, output);

    List<double> prediction = List<double>.from(output[0]);
    int predictedIndex = prediction.indexOf(prediction.reduce(max));

    setState(() {
      _output = labels[predictedIndex]!;
    });
    await _flutterTts.speak(_output);
  }

  @override
  void dispose() {
    _controller.dispose();
    _interpreter.close();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("TFLite Kamera")),
      body: Column(
        children: [
          AspectRatio(aspectRatio: _controller.value.aspectRatio, child: CameraPreview(_controller)),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
            onPressed: _classifyImage,
            child: const Text("Ambil Gambar & Klasifikasi"),
          ),
          const SizedBox(height: 20),
          Text(_output, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
