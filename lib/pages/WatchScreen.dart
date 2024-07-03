import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:wear/wear.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wear ControLED',
      theme: ThemeData(
        visualDensity: VisualDensity.compact,
      ),
      home: const WatchScreen(),
    );
  }
}

class WatchScreen extends StatelessWidget {
  const WatchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WatchShape(
      builder: (context, shape, child) {
        return AmbientMode(
          builder: (context, mode, child) {
            return LEDScreen(mode);
          },
        );
      },
    );
  }
}

class LEDScreen extends StatefulWidget {
  final WearMode mode;

  const LEDScreen(this.mode, {Key? key}) : super(key: key);

  @override
  State<LEDScreen> createState() => _LEDScreenState();
}

class _LEDScreenState extends State<LEDScreen> {
  bool _isLEDon = false;
  Color _ledColor = Colors.grey;
  String _message = '';
  bool _showColorIcon = false; // Flag to show color icon

  // List of colors to cycle through
  List<Color> _colorCycle = [
    Color.fromARGB(255, 27, 255, 35),
    Color.fromARGB(255, 33, 215, 243),
    Color.fromARGB(255, 198, 38, 226),
    Color.fromARGB(255, 255, 25, 9),
    Color.fromARGB(255, 255, 199, 29),
  ];
  int _currentColorIndex = 0;

  // Bluetooth
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _characteristic;

  void _toggleLED() {
    setState(() {
      _isLEDon = !_isLEDon;
      if (_isLEDon) {
        _ledColor = _colorCycle[_currentColorIndex];
        _message = 'LED encendido';
        _showColorIcon = false; // Hide color icon when LED is on
      } else {
        _ledColor = Colors.grey;
        _message = 'LED apagado';
        _showColorIcon = false; // Hide color icon when LED is off
      }
      _showUpdateMessage();
    });
  }

  void _showUpdateMessage() {
    Timer(Duration(milliseconds: 1500), () {
      setState(() {
        _message = '';
        _showColorIcon = false; // Hide color icon after message disappears
      });
    });
  }

  void _changeColor() {
    setState(() {
      _currentColorIndex = (_currentColorIndex + 1) % _colorCycle.length;
      _ledColor = _colorCycle[_currentColorIndex];
      _message = 'Se actualizó el color a';
      _showColorIcon = true; // Show color icon when color changes
      _showUpdateMessage();
    });
  }

  void _startScan() async {
    try {
      await flutterBlue.startScan(timeout: const Duration(seconds: 4));

      flutterBlue.scanResults.listen((results) {
        for (ScanResult r in results) {
          if (r.device.name == 'YourDeviceName') {
            _connectToDevice(r.device);
            break;
          }
        }
      });

      flutterBlue.stopScan();
    } catch (e) {
      print('Error starting scan: $e');
      // Handle error starting scan (e.g., show error message)
    }
  }

  void _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        _connectedDevice = device;
      });

      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.notify) {
            _characteristic = characteristic;
            _characteristic!.setNotifyValue(true);
            _characteristic!.value.listen((value) {
              _handleReceivedData(value);
            });
          }
        }
      }
    } catch (e) {
      print('Error connecting to device: $e');
      // Handle error connecting to device (e.g., show error message)
    }
  }

  void _handleReceivedData(List<int> value) {
    setState(() {
      // Assuming received data represents RGB color values
      _ledColor = Color.fromRGBO(value[0], value[1], value[2], 1.0);
      _message = 'LED actualizado a';
      _showColorIcon = true; // Show color icon when LED is updated
      _showUpdateMessage();
    });
  }

  void _disconnectDevice() {
    if (_connectedDevice != null) {
      _connectedDevice!.disconnect();
      setState(() {
        _connectedDevice = null;
        _ledColor = Colors.grey; // Reset LED color to default when disconnected
        _isLEDon = false; // Turn off LED when disconnected
        _message = '';
        _showColorIcon = false; // Hide color icon when LED is disconnected
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _changeColor, // Call _changeColor on tap anywhere
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 19, 19, 19),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 35,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Text(
                      'Wear ControLED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold, // Bold font weight
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ), // Adjust this height to move the icon down
                  ],
                ),
              ),
              Center(
                child: GestureDetector(
                  onTap: _isLEDon ? _changeColor : null,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: _isLEDon
                          ? [
                              BoxShadow(
                                color: _ledColor.withOpacity(0.3),
                                blurRadius: 30.0,
                                spreadRadius: 2.0,
                              ),
                            ]
                          : [],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: _ledColor,
                          size: 70.0,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: _message.isNotEmpty ? 1.0 : 0.0,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16.0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_message ',
                          style: TextStyle(color: Colors.white),
                        ),
                        if (_showColorIcon &&
                            _message.startsWith('Se actualizó el color a'))
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _ledColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 10,
                right: 10,
                child: GestureDetector(
                  onTap: _toggleLED,
                  child: Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.power_settings_new,
                        color: _isLEDon ? _ledColor : Colors.white,
                        size: 20.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
