import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wear/wear.dart';
import 'package:flutter_blue/flutter_blue.dart';

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
  bool _showMessage = false;
  Timer? _messageTimer;

  // Bluetooth
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _characteristic;
  bool _isConnected = false;

  void _toggleLED() {
    setState(() {
      _isLEDon = !_isLEDon;
      _ledColor =
          _isLEDon ? const Color.fromARGB(255, 27, 255, 35) : Colors.grey;

      if (_isLEDon) {
        _showUpdateMessage();
      }
    });
  }

  void _showUpdateMessage() {
    setState(() {
      _showMessage = true;
    });

    _messageTimer?.cancel();
    _messageTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _showMessage = false;
      });
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
        _isConnected = true;
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
    });

    _showUpdateMessage();
  }

  void _disconnectDevice() {
    if (_connectedDevice != null) {
      _connectedDevice!.disconnect();
      setState(() {
        _connectedDevice = null;
        _isConnected = false;
        _ledColor = Colors.grey; // Reset LED color to default when disconnected
        _isLEDon = false; // Turn off LED when disconnected
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      height: 5), // Adjust this height to move the icon down
                ],
              ),
            ),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: _isLEDon
                      ? [
                          BoxShadow(
                            color: _ledColor.withOpacity(0.3), // Reduce opacity
                            blurRadius: 30.0, // Reduce blur radius
                            spreadRadius: 2.0, // Reduce spread radius
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  color: _ledColor,
                  size: 70.0,
                ),
              ),
            ),
            if (_showMessage)
              Center(
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'LED actualizado a ',
                        style: TextStyle(color: Colors.white),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        color: _ledColor,
                      ),
                    ],
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
    );
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }
}
