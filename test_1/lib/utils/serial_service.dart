import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:url_launcher/url_launcher.dart';

class SerialService {
  static final SerialService _instance = SerialService._internal();
  factory SerialService() => _instance;
  SerialService._internal();

  UsbPort? _port;
  StreamSubscription<Uint8List>? _subscription;
  StreamSubscription<UsbEvent>? _eventSubscription;
  String _buffer = "";
  bool _isConnecting = false;
  
  Function(String)? onTagReceived;
  Function(String)? onDebugMessage;

  void init({Function(String)? onTag, Function(String)? onDebug}) {
    if (onTag != null) onTagReceived = onTag;
    if (onDebug != null) onDebugMessage = onDebug;
    
    // Prevent multiple listeners
    _eventSubscription?.cancel();
    
    debugPrint("SERIAL_SYSTEM: Initializing Service...");
    _logDebug("Serial Service Started");

    _eventSubscription = UsbSerial.usbEventStream?.listen((UsbEvent event) {
      if (event.event == UsbEvent.ACTION_USB_ATTACHED) {
        if (event.device != null) {
          // Add a small delay for Android to stabilize the connection
          Future.delayed(const Duration(milliseconds: 500), () {
            _connectToDevice(event.device!);
          });
        }
      } else if (event.event == UsbEvent.ACTION_USB_DETACHED) {
        _logDebug("Device Unplugged");
        _disposeConnection();
      }
    });

    _checkForExistingDevices();
  }

  Future<void> _checkForExistingDevices() async {
    try {
      List<UsbDevice> devices = await UsbSerial.listDevices();
      if (devices.isNotEmpty) {
        _connectToDevice(devices.first);
      }
    } catch (e) {
      _logDebug("Scan Error: $e");
    }
  }

  Future<void> _connectToDevice(UsbDevice device) async {
    if (_isConnecting) return;
    
    // If a port exists, check if it's still healthy, otherwise dispose it
    if (_port != null) {
      _disposeConnection();
    }
    
    _isConnecting = true;

    try {
      _logDebug("Connecting to Arduino...");
      _port = await UsbSerial.createFromDeviceId(device.deviceId);
      
      if (_port == null) {
        _logDebug("Permission required or device busy");
        _isConnecting = false;
        return;
      }

      bool openResult = await _port!.open();
      if (openResult) {
        _logDebug("CONNECTED!");
        
        await _port!.setPortParameters(9600, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);
        await _port!.setDTR(true);
        await _port!.setRTS(true);

        _subscription = _port!.inputStream?.listen(
          (Uint8List data) => _handleRawData(data),
          onError: (e) {
            _logDebug("Connection lost: $e");
            _disposeConnection();
          },
          onDone: () {
            _logDebug("Device disconnected");
            _disposeConnection();
          },
        );
      } else {
        _logDebug("Failed to open port. Re-plug cable.");
      }
    } catch (e) {
      _logDebug("Connection Error. Please re-plug.");
      debugPrint("SERIAL_ERROR: $e");
      _disposeConnection();
    } finally {
      _isConnecting = false;
    }
  }

  void _handleRawData(Uint8List data) {
    String text = utf8.decode(data, allowMalformed: true);
    debugPrint("SERIAL_IN: $text");
    
    _buffer += text;
    if (_buffer.contains('\n')) {
      List<String> lines = _buffer.split('\n');
      _buffer = lines.removeLast();
      for (String line in lines) {
        String id = line.trim();
        if (id.isNotEmpty && onTagReceived != null) onTagReceived!(id);
      }
    }
  }

  void _logDebug(String msg) {
    debugPrint("SERIAL_LOG: $msg");
    if (onDebugMessage != null) onDebugMessage!(msg);
  }

  void _disposeConnection() {
    _subscription?.cancel();
    _subscription = null;
    _port?.close();
    _port = null;
    _isConnecting = false;
    _buffer = "";
  }
}
