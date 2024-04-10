// ignore_for_file: unused_field, use_key_in_widget_constructors, avoid_print, prefer_const_constructors, use_super_parameters

import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_application_1/controller/scan_controller.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';

late List<CameraDescription> cameras;

Future<Null> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error: $e.code\nError Message: $e.message');
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Home Automation',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(backgroundColor: Colors.blue),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<Map<String, dynamic>>> futureValue;
  late Future<List<Map<String, dynamic>>> futureServoValue;
  late Timer timer;
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool switchValue = false;
  double sliderValue = 5;

  @override
  void initState() {
    super.initState();
    futureValue = fetchValue();
    timer = Timer.periodic(const Duration(seconds: 3), (Timer t) {
      setState(() {
        futureValue = fetchValue();
      });
    });
    _initializeCamera();
  }

  void _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    _controller = CameraController(firstCamera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }

  Future<List<Map<String, dynamic>>> fetchValue() async {
    final response =
        await http.get(Uri.parse('http://192.168.15.140/getValues'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      final List<Map<String, dynamic>> dataList =
          jsonData.cast<Map<String, dynamic>>();
      return dataList;
    } else {
      throw Exception('Failed to load value');
    }
  }


  Future<void> setFanStatus() async {
    final url = Uri.parse('http://192.168.15.140/setStatus');
    final headers = {'Content-Type': 'application/json'};
    String state = "";
    if (switchValue) {
      state = '1';
    } else {
      state = '0';
    }
    final body = json
        .encode({'fanStatus': state, 'servoStatus': sliderValue.toString()});

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      // Handle success
      print('Fan status set successfully');
    } else {
      // Handle error
      throw Exception('Failed to set fan status');
    }
  }

  Icon getWifiIcon(int wifiStrength) {
    if (wifiStrength < 60) {
      return const Icon(Icons.wifi);
    } else if (wifiStrength >= 60 && wifiStrength < 80) {
      return const Icon(Icons.wifi_2_bar);
    } else {
      return const Icon(Icons.wifi_1_bar);
    }
  }

  @override
  void dispose() {
    timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IOT Control'),
      ),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.blue,width: 4
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: SizedBox(
                    height: 200,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            'Living Room',
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: futureValue,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final List<Map<String, dynamic>> dataList =
                                  snapshot.data!;
                              if (dataList.isNotEmpty) {
                                final Map<String, dynamic> jsonData =
                                    dataList[0];
                                final Map<String, dynamic> jsonData1 =
                                    dataList[1];
                                final temperature = jsonData['value'];
                                final humidity = jsonData1['value'];
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.thermostat_outlined),
                                        Text(
                                          "Temperature ${temperature.toStringAsFixed(2)} °C",
                                          style:
                                              const TextStyle(fontSize: 10.0),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Icon(Icons.water_drop_outlined),
                                        Text(
                                          "Humidity ${humidity.toStringAsFixed(2)} %",
                                          style:
                                              const TextStyle(fontSize: 10.0),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row()
                                  ],
                                );
                              } else {
                                return const Text('');
                              }
                            } else {
                              return const Text('');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue,width: 4),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: SizedBox(
                    height: 200,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            'Kitchen',
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: futureValue,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final List<Map<String, dynamic>> dataList =
                                  snapshot.data!;
                              if (dataList.isNotEmpty) {
                                final Map<String, dynamic> jsonData =
                                    dataList[0];
                                final Map<String, dynamic> jsonData1 =
                                    dataList[1];
                                final Map<String, dynamic> jsonData5 =
                                    dataList[5];
                                final Map<String, dynamic> jsonData7 =
                                    dataList[6];
                                final temperature = jsonData['value'];
                                final humidity = jsonData1['value'];
                                final waterLevel = jsonData5['value'];
                                final gasLevel = jsonData7['value'];
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.thermostat_outlined),
                                        Text(
                                          "Temperature ${temperature.toStringAsFixed(2)} °C",
                                          style:
                                              const TextStyle(fontSize: 10.0),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Icon(Icons.water_drop_outlined),
                                        Text(
                                          "Humidity ${humidity.toStringAsFixed(2)} %",
                                          style:
                                              const TextStyle(fontSize: 10.0),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Icon(Icons.wb_cloudy_outlined),
                                        Text(
                                          "Gas Level:${gasLevel.toStringAsFixed(2)}",
                                          style:
                                              const TextStyle(fontSize: 10.0),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Icon(Icons.water_drop_outlined),
                                        Text(
                                          "Water Level:${waterLevel.toStringAsFixed(2)}",
                                          style:
                                              const TextStyle(fontSize: 10.0),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row()
                                  ],
                                );
                              } else {
                                return const Text('');
                              }
                            } else {
                              return const Text('');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue,width: 4),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Miscellaneous',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: futureValue,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final List<Map<String, dynamic>> dataList =
                            snapshot.data!;
                        if (dataList.isNotEmpty) {
                          final Map<String, dynamic> jsonData3 = dataList[3];
                          final Map<String, dynamic> jsonData4 = dataList[4];
                          final Map<String, dynamic> jsonData6 = dataList[6];
                          final wifiStrength = jsonData3['value'];
                          final distance = jsonData4['value'];
                          final occupiedRoom = jsonData6['value'];
                          String message = '';
                          switch (occupiedRoom) {
                            case 0:
                              message = 'No Rooms Occupied';
                              break;
                            case 1:
                              message = 'Kitchen is Occupied';
                              break;
                            case 2:
                              message = 'Living Room is Occupied';
                              break;
                            case 3:
                              message = 'Both are Occupied';
                              break;
                            default:
                              message = 'Unknown Status';
                              break;
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  getWifiIcon(wifiStrength.abs()),
                                  Text(
                                    "WiFi Strength:${wifiStrength.abs()}",
                                    style: const TextStyle(fontSize: 10.0),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.straighten_outlined),
                                  Text(
                                    "Distance:${distance.toStringAsFixed(2)} cm",
                                    style: const TextStyle(fontSize: 10.0),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.home),
                                  Text(
                                    message,
                                    style: const TextStyle(fontSize: 10.0),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row()
                            ],
                          );
                        } else {
                          return const Text('');
                        }
                      } else {
                        return const Text('');
                      }
                    },
                  ),
                ]),
          ),
        ]),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.air_outlined),
                Text(
                  "",
                  style: TextStyle(fontSize: 18.0),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: switchValue,
                  onChanged: (value) {
                    setState(() {
                      switchValue = value;
                      setFanStatus();
                    });
                  },
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CameraView(
                      key: UniqueKey(),
                      controller: _controller,
                    ),
                  ),
                );
              },
              child: const Text('Open Camera'),
            ),
          ],
        ),
      ),
    );
  }
}

class CameraView extends StatelessWidget {
  const CameraView({Key? key, required this.controller}) : super(key: key);

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera View'),
      ),
      body: GetBuilder<ScanController>(
        init: ScanController(),
        builder: (controller) {
          return Stack(
            children: [
              // Camera Preview
              controller.isCameraInitialized.value
                  ? CameraPreview(controller.cameraController)
                  : const Center(child: Text("Loading")),
              // Detected Object Text Overlay
              Positioned(
                bottom: 16,
                left: 16,
                child: Obx(() => Text(
                      controller.detectedObject.value,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
              ),
            ],
          );
        },
      ),
    );
  }
}
