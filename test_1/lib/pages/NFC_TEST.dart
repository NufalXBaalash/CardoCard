// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'dart:convert';
import 'dart:typed_data';

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
    NfcAvailability availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) {
      setState(() {
        _nfcData = "NFC is not available on this device.";
      });
      return;
    }

    NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
      },
      onDiscovered: (NfcTag tag) async {
        setState(() {
          // In nfc_manager 4.x, we access tech-specific data through their respective classes
          // tag.data is protected, so we use NdefAndroid.from(tag) (or NdefIos for iOS)
          final ndef = NdefAndroid.from(tag);
          
          if (ndef != null && ndef.cachedNdefMessage != null) {
            final records = ndef.cachedNdefMessage!.records;
            if (records.isNotEmpty) {
              _nfcData = "NDEF Record found";
            } else {
              _nfcData = "No NDEF records";
            }
          } else {
            // Fallback to raw data if needed, but handled via tech classes
            _nfcData = "Tag discovered";
          }
        });

        NfcManager.instance.stopSession();
      },
    );
  }
// ----------------------------------------------------------------

  Future<void> _writeNfc() async {
    NfcAvailability availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) {
      return;
    }

    NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
      },
      onDiscovered: (NfcTag tag) async {
        final ndef = NdefAndroid.from(tag);
        if (ndef == null || !ndef.isWritable) {
          setState(() {
            _nfcData = "This tag is not writable.";
          });
          return;
        }

        NdefMessage message = NdefMessage(records: [
          NdefRecord.text(text: 'Hello NFC!'),
        ]);

        await ndef.writeNdefMessage(message);
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
