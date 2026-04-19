import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nfc_writer/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NFC Auth Writer',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const UserListScreen(),
    );
  }
}

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _startNfcReader();
  }

  Future<void> _startNfcReader() async {
    try {
      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onDiscovered: (NfcTag tag) async {
          final androidTag = NfcTagAndroid.from(tag);
          final identifier = androidTag?.id;

          if (identifier != null) {
            String hexId = identifier.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
            debugPrint("Scanned Tag UID: $hexId");

            final doc = await _firestore.collection('users').doc(hexId).get();

            if (doc.exists && doc.data()?['type'] == 'nfc_mapping') {
              final userId = doc.data()?['linkedUser'];
              final userDoc = await _firestore.collection('users').doc(userId).get();
              if (userDoc.exists && mounted) {
                _showUserDetails(userDoc.data() as Map<String, dynamic>);
              }
            }
          }
        },
      );
    } catch (e) {
      debugPrint("NFC Reader Error: $e");
    }
  }

  void _showUserDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['fullName'] ?? "User Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Email: ${data['email'] ?? 'N/A'}"),
            Text("Phone: ${data['phoneNumber'] ?? 'N/A'}"),
            const SizedBox(height: 10),
            const Text("This card is successfully linked!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select User to Link Card")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter documents manually to avoid index issues with 'where'
          final users = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['type'] != 'nfc_mapping';
          }).toList();

          if (users.isEmpty) {
            return const Center(
              child: Text("No users found in Firestore.\nMake sure you have users in the 'users' collection."),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id;
              final fullName = userData['fullName'] ?? userData['name'] ?? "Unknown User";
              final email = userData['email'] ?? "No Email";

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(fullName),
                subtitle: Text(email),
                trailing: const Icon(Icons.nfc),
                onTap: () => _showWriteDialog(context, userId, fullName),
              );
            },
          );
        },
      ),
    );
  }

  void _showWriteDialog(BuildContext context, String userId, String userName) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      builder: (context) => WriteNfcDialog(userId: userId, userName: userName),
    );
  }
}

class WriteNfcDialog extends StatefulWidget {
  final String userId;
  final String userName;

  const WriteNfcDialog({super.key, required this.userId, required this.userName});

  @override
  State<WriteNfcDialog> createState() => _WriteNfcDialogState();
}

class _WriteNfcDialogState extends State<WriteNfcDialog> {
  String _status = "Ready to write...";
  bool _isWriting = false;

  @override
  void initState() {
    super.initState();
    _startNfcWrite();
  }

  Future<void> _startNfcWrite() async {
    setState(() {
      _isWriting = true;
      _status = "Tap the NFC card to write ${widget.userName}'s ID";
    });

    try {
      NfcAvailability availability = await NfcManager.instance.checkAvailability();
      if (availability != NfcAvailability.enabled) {
        setState(() {
          _isWriting = false;
          _status = "NFC is ${availability.name}";
        });
        return;
      }

      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onDiscovered: (NfcTag tag) async {
          try {
            NdefAndroid? ndef = NdefAndroid.from(tag);
            NdefFormatableAndroid? formatable = NdefFormatableAndroid.from(tag);

            // تحضير البيانات للكتابة
            const languageCode = 'en';
            final languageCodeBytes = ascii.encode(languageCode);
            final textBytes = utf8.encode(widget.userId);
            final payload = Uint8List.fromList([
              languageCodeBytes.length,
              ...languageCodeBytes,
              ...textBytes,
            ]);

            String webUrl = "https://osamakemekem.github.io/cardo?id=${widget.userId}";
            final uriPayload = Uint8List.fromList([0x04, ...utf8.encode(webUrl.replaceFirst("https://", ""))]);

            NdefMessage message = NdefMessage(records: [
              NdefRecord(
                typeNameFormat: TypeNameFormat.wellKnown,
                type: Uint8List.fromList([0x55]), // 'U' for URI record
                identifier: Uint8List.fromList([]),
                payload: uriPayload,
              ),
              NdefRecord(
                typeNameFormat: TypeNameFormat.wellKnown,
                type: Uint8List.fromList([0x54]), // 'T' for Text record
                identifier: Uint8List.fromList([]),
                payload: payload,
              ),
            ]);

            if (ndef != null) {
              // الكارت مهيأ مسبقاً، نكتفي بالكتابة
              if (!ndef.isWritable) {
                setState(() { _isWriting = false; _status = "Tag is Read-Only"; });
                await NfcManager.instance.stopSession();
                return;
              }
              await ndef.writeNdefMessage(message);
            } else if (formatable != null) {
              // الكارت غير مهيأ، نقوم بتهيئته وكتابة البيانات
              setState(() { _status = "Formatting and writing..."; });
              await formatable.format(message);
            } else {
              // الكارت غير متوافق نهائياً
              setState(() { _isWriting = false; _status = "Tag not supported or not NDEF formatable"; });
              await NfcManager.instance.stopSession();
              return;
            }

            // تسجيل الـ UID في Firestore للاحتياط
            final androidTag = NfcTagAndroid.from(tag);
            final identifier = androidTag?.id;

            if (identifier != null) {
              String hexId = identifier.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
              await FirebaseFirestore.instance.collection('users').doc(hexId).set({
                'linkedUser': widget.userId,
                'type': 'nfc_mapping'
              }, SetOptions(merge: true));
            }

            setState(() {
              _isWriting = false;
              _status = "SUCCESS! Card linked to ${widget.userName}";
            });

            await Future.delayed(const Duration(seconds: 2));
            if (mounted) Navigator.pop(context);

          } catch (e) {
            setState(() {
              _isWriting = false;
              _status = "Write Error: $e";
            });
          } finally {
            await NfcManager.instance.stopSession();
          }
        },
      );
    } catch (e) {
      setState(() {
        _isWriting = false;
        _status = "Session Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isWriting
                ? const Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            )
                : Icon(Icons.nfc, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              widget.userName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _status.contains("Error") ? Colors.red : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  NfcManager.instance.stopSession();
                  Navigator.pop(context);
                },
                child: const Text("Cancel"),
              ),
            ),
            const SizedBox(height: 16), // مساحة إضافية لتجنب الحواف
          ],
        ),
      ),
    );
  }
}
