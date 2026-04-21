import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/language_provider.dart';
import 'package:test_1/utils/app_localizations.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  String get _apiUrl =>
      dotenv.env['AI_API_URL'] ?? 'http://10.0.2.2:8000';

  @override
  void initState() {
    super.initState();
    _addBotMessage(
      "Hello! I'm your CardoCard AI Health Assistant.\n\nI can help you with:\n- Analyzing medical reports\n- Answering health questions\n- Booking appointments\n- General health advice\n\nHow can I help you today?",
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addBotMessage(String text, {Map<String, dynamic>? payload, String? action}) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: false,
        payload: payload,
        action: action,
      ));
      _scrollToBottom();
    });
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _scrollToBottom();
    });
    _sendToApi(text);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendToApi(String message) async {
    setState(() => _isTyping = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final history = _messages
          .where((m) => !m.isOption)
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.text,
              })
          .toList();

      final response = await http.post(
        Uri.parse('$_apiUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': uid,
          'message': message,
          'history': history,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['reply'] ?? 'I couldn\'t process that request.';
        final action = data['action'] ?? 'none';
        final payload = data['payload'] ?? {};

        _addBotMessage(reply, payload: payload, action: action);
      } else {
        _addBotMessage(
          "Sorry, I'm having trouble connecting right now. Please try again.",
        );
      }
    } catch (e) {
      if (!mounted) return;
      _addBotMessage(
        "Connection error: Unable to reach the AI service. Make sure the server is running.\n\nError: ${e.toString()}",
      );
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'doc', 'docx'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      _addUserMessage("Upload file: ${file.name}");

      setState(() => _isTyping = true);

      // For now, send the file name to the chat API as context
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final response = await http.post(
        Uri.parse('$_apiUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': uid,
          'message': 'I uploaded a file named "${file.name}". Please help me with it.',
          'history': [],
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _addBotMessage(
          data['reply'] ?? 'File received. How else can I help?',
          payload: data['payload'],
          action: data['action'],
        );
      } else {
        _addBotMessage("File uploaded but I couldn't process it. Please try again.");
      }
    } catch (e) {
      if (!mounted) return;
      _addBotMessage("Error uploading file: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    _addUserMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.isRTL;
    final colorScheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            context.translate('AI Health Assistant'),
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: colorScheme.surface,
          elevation: 1,
        ),
        body: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.health_and_safety_outlined,
                            size: 80,
                            color: colorScheme.primary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Ask me anything about your health",
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return _buildMessage(msg, isDarkMode, colorScheme);
                      },
                    ),
            ),
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.grey.shade800.withValues(alpha: 0.7)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "AI is typing...",
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.attach_file,
                      color: isDarkMode ? Colors.white60 : Colors.black45,
                    ),
                    onPressed: _pickAndUploadFile,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Type your message...",
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.white60 : Colors.black45,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDarkMode
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    mini: true,
                    backgroundColor: colorScheme.primary,
                    elevation: 2,
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage msg, bool isDarkMode, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isUser)
            CircleAvatar(
              backgroundColor: colorScheme.primary,
              radius: 16,
              child: const Icon(Icons.smart_toy, size: 16, color: Colors.white),
            ),
          if (!msg.isUser) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: msg.isUser
                        ? colorScheme.primary
                        : isDarkMode
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: msg.isUser
                          ? Colors.white
                          : isDarkMode
                              ? Colors.white
                              : Colors.black87,
                    ),
                  ),
                ),
                if (msg.payload != null && msg.payload!.isNotEmpty)
                  _buildPayloadCard(msg.payload!, msg.action, isDarkMode, colorScheme),
              ],
            ),
          ),
          if (msg.isUser) const SizedBox(width: 8),
          if (msg.isUser)
            CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              radius: 16,
              child: Icon(
                Icons.person,
                size: 16,
                color: isDarkMode ? Colors.black87 : Colors.grey.shade700,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPayloadCard(
    Map<String, dynamic> payload,
    String? action,
    bool isDarkMode,
    ColorScheme colorScheme,
  ) {
    if (action == 'show_doctors' && payload.containsKey('doctors')) {
      final doctors = payload['doctors'] as List<dynamic>? ?? [];
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Available Doctors:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            ...doctors.map<Widget>((doc) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 16, color: colorScheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "${doc['name'] ?? 'Unknown'} - ${doc['specialty'] ?? ''}",
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      );
    }

    if (action == 'show_slots' && payload.containsKey('slots')) {
      final slots = payload['slots'] as List<dynamic>? ?? [];
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Available Slots:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: slots.map<Widget>((slot) {
                final start = slot['start_time'] ?? '';
                final end = slot['end_time'] ?? '';
                return Chip(
                  label: Text('$start - $end'),
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(fontSize: 12, color: colorScheme.primary),
                );
              }).toList(),
            ),
          ],
        ),
      );
    }

    if (action == 'show_analysis') {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (payload.containsKey('abnormal_values'))
              _buildAnalysisRow("Abnormal Values", payload['abnormal_values'], isDarkMode),
            if (payload.containsKey('risks'))
              _buildAnalysisRow("Risks", payload['risks'], isDarkMode),
            if (payload.containsKey('summary'))
              _buildAnalysisRow("Summary", payload['summary'], isDarkMode),
            if (payload.containsKey('recommendation'))
              _buildAnalysisRow("Recommendation", payload['recommendation'], isDarkMode),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildAnalysisRow(String label, dynamic value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.cardoBlue,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isOption;
  final Map<String, dynamic>? payload;
  final String? action;

  const ChatMessage({
    required this.text,
    this.isUser = false,
    this.isOption = false,
    this.payload,
    this.action,
  });
}
