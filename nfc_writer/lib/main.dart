import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:flutter/services.dart';

import 'package:nfc_writer/firebase_options.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print("Flutter binding initialized");

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");

    runApp(const MyApp());
    print("App started");
  } catch (e) {
    print("Error during initialization: $e");
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              "Error initializing app: $e",
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NFC Card Writer',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const NFCCardWriter(),
    );
  }
}

class NFCCardWriter extends StatefulWidget {
  const NFCCardWriter({Key? key}) : super(key: key);

  @override
  State<NFCCardWriter> createState() => _NFCCardWriterState();
}

class _NFCCardWriterState extends State<NFCCardWriter> {
  final _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isNfcAvailable = false;
  bool _isAuthenticating = false;
  bool _isWriting = false;
  bool _isReading = false;
  String _statusMessage = '';
  String _lastReadContent = '';
  bool _isSessionCancelled = false;
  bool _nfcBusy = false;

  // User info to display
  User? _currentUser;

  // Method to get dynamic URL based on current user's ID
  String _getCardoUrl() {
    if (_currentUser != null) {
      return "https://osamakemekem.github.io/cardo/?id=${_currentUser!.uid}";
    }
    return ""; // Return empty string if no user is signed in
  }

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
    _checkCurrentUser();
  }

  void _checkCurrentUser() {
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      setState(() {});
    }
  }

  Future<void> _checkNfcAvailability() async {
    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      setState(() {
        _isNfcAvailable = isAvailable;
        if (!isAvailable) {
          _statusMessage = 'NFC is not available on this device.';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error checking NFC: $e';
        _isNfcAvailable = false;
      });
    }
  }

  Future<void> _authenticate() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Email and password cannot be empty.';
      });
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _statusMessage = 'Authenticating...';
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      _currentUser = userCredential.user;

      setState(() {
        _statusMessage = 'Authentication successful! Ready to write to NFC.';
        _isAuthenticating = false;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _statusMessage = 'Authentication error: ${e.message}';
        _isAuthenticating = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isAuthenticating = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      setState(() {
        _statusMessage = 'Signed out successfully.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error signing out: $e';
      });
    }
  }

  Future<void> _writeToNfcCard() async {
    if (_currentUser == null) {
      setState(() {
        _statusMessage = 'Please authenticate first.';
      });
      return;
    }

    // Prevent multiple simultaneous NFC operations
    if (_nfcBusy) return;

    setState(() {
      _isWriting = true;
      _isSessionCancelled = false;
      _statusMessage = 'Ready to write CardoCare URL. Please tap NFC card...';
      _nfcBusy = true;
    });

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          print("NFC tag discovered");

          if (_isSessionCancelled) {
            NfcManager.instance.stopSession();
            _setNfcNotBusy();
            return;
          }

          String tagInfo = _getTagInfo(tag);
          print("Tag info: $tagInfo");

          final ndef = Ndef.from(tag);
          if (ndef == null || !ndef.isWritable) {
            setState(() {
              _statusMessage =
                  ndef == null
                      ? 'This tag does not support NDEF format.\n$tagInfo'
                      : 'Tag is read-only or write-protected.\n$tagInfo';
            });
            NfcManager.instance.stopSession();
            _setNfcNotBusy();
            return;
          }

          // Check capacity
          final maxSize = ndef.maxSize;
          final cardoUrl = _getCardoUrl();
          final urlSize = cardoUrl.length + 10; // Add overhead for NDEF format

          print("URL size: $urlSize bytes, Tag capacity: $maxSize bytes");

          if (maxSize < urlSize) {
            setState(() {
              _statusMessage =
                  'URL too large for this tag (${urlSize}b > ${maxSize}b).\n'
                  'Please use a tag with more capacity.';
            });
            NfcManager.instance.stopSession();
            _setNfcNotBusy();
            return;
          }

          try {
            // Create a URI record for the dynamic URL with current user's ID
            final uriRecord = NdefRecord.createUri(Uri.parse(cardoUrl));

            // Create a message with just the URI record
            final message = NdefMessage([uriRecord]);

            print("Writing URL to NFC tag: $cardoUrl");

            // Write with more detailed error handling
            try {
              await ndef
                  .write(message)
                  .timeout(
                    const Duration(seconds: 4),
                    onTimeout: () {
                      throw TimeoutException(
                        'Write operation timed out. Keep the card steady.',
                      );
                    },
                  );
              print("Write successful!");

              setState(() {
                _statusMessage =
                    'CardoCare URL successfully written to NFC card!\n$tagInfo\n'
                    'This card will now open the CardoCare web app when tapped.';
              });
            } catch (e) {
              if (e is PlatformException) {
                _handlePlatformException(e);
              } else {
                setState(() {
                  _statusMessage = 'Write error: $e\n$tagInfo';
                });
              }
            }
          } catch (e) {
            setState(() {
              _statusMessage = 'Failed to write to card: $e\n$tagInfo';
            });
          }

          _setNfcNotBusy();
          NfcManager.instance.stopSession();
        },
        onError: (error) async {
          setState(() {
            _statusMessage = 'NFC error: $error';
          });
          _setNfcNotBusy();
          NfcManager.instance.stopSession();
        },
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Error starting NFC: $e';
      });
      _setNfcNotBusy();
    }
  }

  void _setNfcNotBusy() {
    setState(() {
      _isWriting = false;
      _isReading = false;
      _nfcBusy = false;
    });
  }

  void _handlePlatformException(PlatformException e) {
    String errorMsg = 'NFC error';

    // Handle common platform exceptions with user-friendly messages
    if (e.code == 'io_exception') {
      errorMsg = 'NFC communication error. Make sure to:';
      errorMsg += '\n1. Keep the card steady during write';
      errorMsg += '\n2. Don\'t move the phone';
      errorMsg += '\n3. Try a different NFC tag if problem persists';
    } else if (e.code == 'tag_lost') {
      errorMsg = 'Tag connection lost. Keep the card steady against the phone.';
    } else if (e.code == 'tag_unavailable') {
      errorMsg = 'Tag is unavailable or may be incompatible.';
    } else if (e.code == 'permission_denied') {
      errorMsg = 'NFC permission denied. Check app permissions.';
    } else if (e.code == 'command_not_supported') {
      errorMsg = 'This NFC tag doesn\'t support the requested operation.';
    } else {
      errorMsg = 'NFC error: ${e.code} - ${e.message ?? "Unknown error"}';
    }

    print(errorMsg);
    setState(() {
      _statusMessage = errorMsg;
    });
  }

  Future<void> _readNfcTag() async {
    if (!_isNfcAvailable) {
      setState(() {
        _statusMessage = 'NFC is not available on this device.';
      });
      return;
    }

    // Prevent multiple simultaneous NFC operations
    if (_nfcBusy) return;

    setState(() {
      _isReading = true;
      _statusMessage = 'Ready to read. Please tap NFC card...';
      _nfcBusy = true;
    });

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          print("NFC tag discovered for reading");

          String tagInfo = _getTagInfo(tag);
          print("Tag info: $tagInfo");

          final ndef = Ndef.from(tag);
          if (ndef == null) {
            setState(() {
              _statusMessage =
                  'This tag does not support NDEF format.\n$tagInfo';
            });
            NfcManager.instance.stopSession();
            _setNfcNotBusy();
            return;
          }

          try {
            final message = await ndef.read();
            if (message != null && message.records.isNotEmpty) {
              StringBuffer readContent = StringBuffer();
              bool hasCardoUrl = false;

              for (var record in message.records) {
                String recordContent = '';

                if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown) {
                  var payload = record.payload;
                  var languageCodeLength = payload[0] & 0x3f;
                  recordContent = String.fromCharCodes(
                    payload.sublist(languageCodeLength + 1),
                  );
                } else if (record.typeNameFormat ==
                        NdefTypeNameFormat.nfcWellknown &&
                    record.type == 'U') {
                  // URI Record
                  if (record.payload != null && record.payload.isNotEmpty) {
                    int prefixByte = record.payload[0];
                    String prefix = _getUriPrefix(prefixByte) ?? '';

                    try {
                      String uriContent = String.fromCharCodes(
                        record.payload.sublist(1),
                      );
                      recordContent = prefix + uriContent;
                    } catch (e) {
                      print('Error decoding URI content: $e');
                    }
                  }
                } else {
                  recordContent = String.fromCharCodes(record.payload);
                }

                if (recordContent.contains("osamakemekem.github.io/cardo")) {
                  hasCardoUrl = true;
                }

                if (recordContent.isNotEmpty) {
                  readContent.writeln(recordContent);
                }
              }

              setState(() {
                _lastReadContent = readContent.toString().trim();

                if (hasCardoUrl) {
                  _statusMessage =
                      'Successfully read CardoCare URL!\n$tagInfo\n'
                      'This card will open the CardoCare web app when tapped.';
                } else {
                  _statusMessage =
                      'Read NFC tag, but no CardoCare URL found.\n$tagInfo';
                }
              });
            } else {
              setState(() {
                _statusMessage = 'No data found on NFC tag.\n$tagInfo';
              });
            }
          } catch (e) {
            setState(() {
              _statusMessage = 'Error reading NFC tag: $e\n$tagInfo';
            });
          }

          _setNfcNotBusy();
          NfcManager.instance.stopSession();
        },
        onError: (error) async {
          setState(() {
            _statusMessage = 'NFC read error: $error';
          });
          _setNfcNotBusy();
          NfcManager.instance.stopSession();
        },
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Error starting NFC read: $e';
      });
      _setNfcNotBusy();
    }
  }

  // Helper method to convert URI identifier code to prefix
  String _getUriPrefix(int identifierCode) {
    switch (identifierCode) {
      case 0x01:
        return "http://www.";
      case 0x02:
        return "https://www.";
      case 0x03:
        return "http://";
      case 0x04:
        return "https://";
      case 0x05:
        return "tel:";
      case 0x06:
        return "mailto:";
      case 0x07:
        return "ftp://anonymous:anonymous@";
      case 0x08:
        return "ftp://ftp.";
      case 0x09:
        return "ftps://";
      case 0x0A:
        return "sftp://";
      case 0x0B:
        return "smb://";
      case 0x0C:
        return "nfs://";
      case 0x0D:
        return "ftp://";
      case 0x0E:
        return "dav://";
      case 0x0F:
        return "news:";
      case 0x10:
        return "telnet://";
      case 0x11:
        return "imap:";
      case 0x12:
        return "rtsp://";
      case 0x13:
        return "urn:";
      case 0x14:
        return "pop:";
      case 0x15:
        return "sip:";
      case 0x16:
        return "sips:";
      case 0x17:
        return "tftp:";
      case 0x18:
        return "btspp://";
      case 0x19:
        return "btl2cap://";
      case 0x1A:
        return "btgoep://";
      case 0x1B:
        return "tcpobex://";
      case 0x1C:
        return "irdaobex://";
      case 0x1D:
        return "file://";
      case 0x1E:
        return "urn:epc:id:";
      case 0x1F:
        return "urn:epc:tag:";
      case 0x20:
        return "urn:epc:pat:";
      case 0x21:
        return "urn:epc:raw:";
      case 0x22:
        return "urn:epc:";
      case 0x23:
        return "urn:nfc:";
      default:
        return "";
    }
  }

  String _getTagInfo(NfcTag tag) {
    StringBuffer info = StringBuffer('Tag Type: ');

    if (tag.data.containsKey('ndef')) {
      info.write('NDEF');

      final ndef = Ndef.from(tag);
      if (ndef != null) {
        info.write('\nWritable: ${ndef.isWritable}');
        info.write('\nCapacity: ${ndef.maxSize} bytes');
        info.write(
          '\nType: ${ndef.cachedMessage?.records.firstOrNull?.typeNameFormat.toString() ?? "Unknown"}',
        );
      }
    } else if (tag.data.containsKey('mifare')) {
      info.write('MIFARE');
    } else if (tag.data.containsKey('iso7816')) {
      info.write('ISO7816');
    } else if (tag.data.containsKey('iso15693')) {
      info.write('ISO15693');
    } else if (tag.data.containsKey('felica')) {
      info.write('FeliCa');
    } else {
      info.write('Unknown');
    }

    info.write('\nTechnologies: ${tag.data.keys.join(", ")}');

    return info.toString();
  }

  void _cancelNfcSession() {
    if (_isWriting || _isReading) {
      setState(() {
        _isSessionCancelled = true;
        _statusMessage = 'NFC operation cancelled.';
      });
      _setNfcNotBusy();

      try {
        NfcManager.instance.stopSession();
      } catch (e) {
        print("Error stopping NFC session during cancellation: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current screen width to adjust UI
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'CardoCare NFC Writer',
          style: TextStyle(fontSize: isSmallScreen ? 16 : 20),
        ),
        actions: [
          if (_currentUser != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _signOut,
              tooltip: 'Sign Out',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isNfcAvailable)
                const Card(
                  color: Colors.red,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'NFC is not available on this device.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),

              // Show user info if signed in
              if (_currentUser != null)
                Card(
                  color: Colors.green.shade700,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Signed in as: ${_currentUser!.email}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 14 : 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'User ID: ${_currentUser!.uid}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

              if (_currentUser == null) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isAuthenticating && !_nfcBusy,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  enabled: !_isAuthenticating && !_nfcBusy,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed:
                      (_isNfcAvailable && !_isAuthenticating && !_nfcBusy)
                          ? _authenticate
                          : null,
                  child: Text(
                    _isAuthenticating ? 'Authenticating...' : 'Sign In',
                  ),
                ),
              ],

              if (_currentUser != null) ...[
                // Display the dynamic URL that will be written
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Card(
                    color: Colors.blue.shade800,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'URL to be written:',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getCardoUrl(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                isSmallScreen
                    ? Column(
                      children: [
                        _buildActionButton(
                          label:
                              _isWriting
                                  ? 'Writing...'
                                  : 'Write URL to NFC Card',
                          onPressed:
                              (_isNfcAvailable && !_nfcBusy)
                                  ? _writeToNfcCard
                                  : null,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 8),
                        _buildActionButton(
                          label: _isReading ? 'Reading...' : 'Read NFC Card',
                          onPressed:
                              (_isNfcAvailable && !_nfcBusy)
                                  ? _readNfcTag
                                  : null,
                          color: Colors.teal,
                        ),
                      ],
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            label:
                                _isWriting
                                    ? 'Writing...'
                                    : 'Write URL to NFC Card',
                            onPressed:
                                (_isNfcAvailable && !_nfcBusy)
                                    ? _writeToNfcCard
                                    : null,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionButton(
                            label: _isReading ? 'Reading...' : 'Read NFC Card',
                            onPressed:
                                (_isNfcAvailable && !_nfcBusy)
                                    ? _readNfcTag
                                    : null,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
              ],

              if (_isWriting || _isReading)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextButton(
                    onPressed: _cancelNfcSession,
                    child: const Text('Cancel NFC Operation'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ),

              const SizedBox(height: 16),

              if (_lastReadContent.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Card(
                    color: Colors.purple.shade700,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Card Content:',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _lastReadContent,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                          if (_lastReadContent.contains(
                            "osamakemekem.github.io/cardo",
                          ))
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade300,
                                    size: isSmallScreen ? 16 : 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Valid CardoCare URL found",
                                    style: TextStyle(
                                      color: Colors.green.shade300,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSmallScreen ? 12 : 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (_statusMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Card(
                    color:
                        _statusMessage.toLowerCase().contains('success')
                            ? Colors.green
                            : _statusMessage.toLowerCase().contains('error') ||
                                _statusMessage.toLowerCase().contains('fail')
                            ? Colors.red
                            : Colors.blue,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 13 : 15,
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

  Widget _buildActionButton({
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_isWriting || _isReading) {
      try {
        NfcManager.instance.stopSession();
      } catch (e) {
        print("Error stopping NFC session during dispose: $e");
      }
    }

    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
