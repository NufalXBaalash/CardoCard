// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

void main() {
  runApp(const NfcTest());
}

class NfcTest extends StatelessWidget {
  const NfcTest({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NFCReader(),
    );
  }
}

// ignore: use_key_in_widget_constructors
class NFCReader extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _NFCReaderState createState() => _NFCReaderState();
}

class _NFCReaderState extends State<NFCReader> {
  String _nfcData = "Scan an NFC tag...";

  Future<void> _readNfc() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      setState(() {
        _nfcData = "NFC is not available on this device.";
      });
      return;
    }

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        setState(() {
          _nfcData = tag.data.toString();
        });

        NfcManager.instance.stopSession();
      },
    );
  }
// ----------------------------------------------------------------

  Future<void> _writeNfc() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      return;
    }

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        Ndef? ndef = Ndef.from(tag);
        if (ndef == null || !ndef.isWritable) {
          setState(() {
            _nfcData = "This tag is not writable.";
          });
          return;
        }

        NdefMessage message = NdefMessage([
          NdefRecord.createText("Hello NFC!"),
        ]);

        await ndef.write(message);
        setState(() {
          _nfcData = "Successfully written!";
        });

        NfcManager.instance.stopSession();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NFC Reader')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_nfcData),
            ElevatedButton(
              onPressed: _readNfc,
              child: const Text("Scan NFC"),
            ),
            SizedBox(
              height: 10,
            ),
            ElevatedButton(
              onPressed: _writeNfc,
              child: const Text("Write NFC"),
            ),
          ],
        ),
      ),
    );
  }
}
