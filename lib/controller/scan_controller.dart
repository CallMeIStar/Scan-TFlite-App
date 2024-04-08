import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanController extends GetxController {
  late CameraController cameraController;
  late List<CameraDescription> cameras;
  var isCameraInitialized = false.obs;
  var detectedObject = ''.obs;
  var cameraCount = 0;

  @override
  void onInit() {
    super.onInit();
    initCamera();
    initTFlite();
  }

  @override
  void dispose() {
    super.dispose();
    cameraController.dispose();
  }

  initCamera() async {
    if (await Permission.camera.request().isGranted) {
      cameras = await availableCameras();
      cameraController = CameraController(
        cameras[0],
        ResolutionPreset.max,
      );
      await cameraController.initialize().then((value) {
        cameraController.startImageStream((image) {
          cameraCount++;
          if (cameraCount % 10 == 0) {
            cameraCount = 0;
            objectDetector(image);
          }
          update();
        });
      });
      isCameraInitialized(true);
      update();
    } else {
      print("Permission Denied");
    }
  }

  initTFlite() async {
    await Tflite.loadModel(
      model: "assets/model_unquant.tflite",
      labels: "assets/labels.txt",
      isAsset: true,
      numThreads: 1,
      useGpuDelegate: false,
    );
  }

  objectDetector(CameraImage image) async {
    var detector = await Tflite.runModelOnFrame(
      bytesList: image.planes.map((e) {
        return e.bytes;
      }).toList(),
      asynch: true,
      imageHeight: image.height,
      imageWidth: image.width,
      imageMean: 127.5,
      imageStd: 127.5,
      numResults: 1,
      rotation: 90,
      threshold: 0.4,
    );

    if (detector != null && detector.isNotEmpty) {
      String objectLabel = detector[0]['label'] ?? '';
      double confidence = detector[0]['confidence'] ?? 0.0;

      detectedObject('$objectLabel\n(Confidence: ${(confidence * 100).toStringAsFixed(2)}%)');

      // Check if the detected object is "open"
      if (objectLabel.toLowerCase() == 'open') {
        // Send data (setLedStatus=1) to the API
        await sendLEDStatus(1);
      } else {
        // Send data (setLedStatus=0) to the API
        await sendLEDStatus(0);
      }
    }
  }

  Future<void> sendLEDStatus(int status) async {
    final url = Uri.parse('http://192.168.15.140/setLEDStatus');
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode({'setLedStatus': status});

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      print('LED status set successfully');
    } else {
      throw Exception('Failed to set LED status');
    }
  }
}
