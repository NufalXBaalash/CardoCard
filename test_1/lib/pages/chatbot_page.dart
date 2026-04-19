import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:test_1/utils/theme_provider.dart';
import 'package:test_1/utils/language_provider.dart';
import 'package:test_1/utils/app_localizations.dart';
import 'package:file_picker/file_picker.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  final List<Map<String, String>> _uploadedData = [];
  final ScrollController _scrollController = ScrollController();
  String? _currentSpecialty;
  String? _currentDataType;
  bool _isTyping = false;
  Map<String, dynamic>? _selectedContent;

  final _specialties = const [
    "جلدية",
    "باطنة",
    "أطفال",
    "عيون",
    "أسنان",
    "عظام",
    "أعصاب",
    "نساء وتوليد",
    "أنف وأذن وحنجرة",
    "جراحة عامة"
  ];

  final _dataTypes = const [
    "تقارير طبية",
    "أشعة",
    "تحاليل",
    "روشتات",
    "فواتير",
    "بيانات المرضى"
  ];

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    _addBotMessage(
      "👨‍⚕️ مرحبًا بك في نظام رفع بيانات العيادة\nكيف يمكنني مساعدتك اليوم؟",
    );
    _addOptions(["رفع بيانات", "عرض البيانات"]);
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(Message(
        text: text,
        specialty: _currentSpecialty,
        dataType: _currentDataType,
      ));
      _scrollToBottom();
    });
  }

  void _addOptions(List<String> options) {
    setState(() {
      for (var option in options) {
        _messages.add(Message(
          text: option,
          isOption: true,
          specialty: _currentSpecialty,
          dataType: _currentDataType,
        ));
      }
      _scrollToBottom();
    });
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(Message(
        text: text,
        isUser: true,
        specialty: _currentSpecialty,
        dataType: _currentDataType,
      ));
      _scrollToBottom();
    });
    _processUserInput(text);
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

  void _processUserInput(String input) {
    setState(() {
      _isTyping = true;
    });

    // Simulate AI typing delay for more natural interaction
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _isTyping = false;
      });

      switch (input) {
        case "رفع بيانات":
          _showSpecialties();
          break;
        case "عرض البيانات":
          _showUploadedData();
          break;
        case "نعم":
          _requestFileUpload();
          break;
        case "لا":
          _addBotMessage("حسنًا، يمكنك رفع البيانات لاحقًا إذا أردت.");
          _showMainOptions();
          break;
        case "عرض المحتوى":
          _showSelectedContent();
          break;
        default:
          if (_specialties.contains(input)) {
            _handleSpecialtySelection(input);
          } else if (_dataTypes.contains(input)) {
            _handleDataTypeSelection(input);
          } else if (input.startsWith("عرض:")) {
            _viewSelectedData(input.substring(5).trim());
          } else {
            // Handle custom user text
            _addBotMessage("هل ترغب في رفع بيانات أو عرض البيانات المرفوعة؟");
            _showMainOptions();
          }
      }
    });
  }

  void _handleSpecialtySelection(String specialty) {
    _currentSpecialty = specialty;
    _addBotMessage("✅ تم اختيار تخصص: $specialty");
    _showDataTypes();
  }

  void _showSpecialties() {
    _addBotMessage("👨‍⚕️ من فضلك اختر التخصص الطبي:");
    _addOptions(_specialties);
  }

  void _showDataTypes() {
    _addBotMessage("📂 اختر نوع البيانات المطلوب رفعها:");
    _addOptions(_dataTypes);
  }

  void _handleDataTypeSelection(String dataType) {
    _currentDataType = dataType;
    _addBotMessage(
      "✔️ تم اختيار: $dataType للتخصص: $_currentSpecialty\nهل تريد رفع الملفات الآن؟",
    );
    _addOptions(["نعم", "لا"]);
  }

  void _requestFileUpload() {
    _addBotMessage("📤 من فضلك اختر الملفات لرفعها");
    _simulateFileUpload();
  }

  Future<void> _simulateFileUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png', 'dicom'],
      );

      if (result == null || result.files.isEmpty) {
        _addBotMessage("⚠️ لم يتم اختيار أي ملف");
        _showMainOptions();
        return;
      }

      setState(() {
        for (final file in result.files) {
          _uploadedData.add({
            'specialty': _currentSpecialty ?? 'غير محدد',
            'dataType': _currentDataType ?? 'غير محدد',
            'fileName': file.name,
            'date': DateTime.now().toString(),
          });
        }
      });

      final fileNames = result.files.map((file) => file.name).join('\n');
      _addBotMessage("✅ تم رفع ${result.files.length} ملف بنجاح:\n$fileNames");
      _showMainOptions();
    } catch (e) {
      _addBotMessage("❌ حدث خطأ أثناء محاولة رفع الملف: ${e.toString()}");
      _showMainOptions();
    }
  }

  void _showUploadedData() {
    if (_uploadedData.isEmpty) {
      _addBotMessage("لا توجد بيانات مرفوعة حتى الآن");
      _showMainOptions();
      return;
    }

    String dataText = "📋 البيانات المرفوعة:\n";
    List<String> viewOptions = [];

    for (var i = 0; i < _uploadedData.length; i++) {
      final data = _uploadedData[i];
      dataText +=
          "${i + 1}. ${data['fileName']} - ${data['specialty']} (${data['dataType']})\n";

      // Add view option for each file
      viewOptions.add("عرض: ${data['fileName']}");
    }

    _addBotMessage(dataText);
    _addBotMessage("يمكنك اختيار أحد الملفات لعرض محتواه:");
    _addOptions(viewOptions);
    _addOptions(["العودة للقائمة الرئيسية"]);
  }

  void _viewSelectedData(String fileName) {
    final selectedData = _uploadedData.firstWhere(
      (data) => data['fileName'] == fileName,
      orElse: () => {},
    );

    if (selectedData.isEmpty) {
      _addBotMessage("⚠️ لم يتم العثور على الملف المطلوب");
      _showMainOptions();
      return;
    }

    setState(() {
      _selectedContent = {
        'fileName': selectedData['fileName'],
        'specialty': selectedData['specialty'],
        'dataType': selectedData['dataType'],
        'date': selectedData['date'],
        'content': "محتوى ملف ${selectedData['fileName']} سيظهر هنا",
      };
    });

    _addBotMessage(
        "تم تحديد ${selectedData['fileName']} للعرض. يمكنك الآن عرض المحتوى.");
    _addOptions(["عرض المحتوى", "العودة للقائمة الرئيسية"]);
  }

  void _showSelectedContent() {
    if (_selectedContent == null) {
      _addBotMessage("⚠️ لم يتم تحديد أي محتوى للعرض");
      _showMainOptions();
      return;
    }

    _addBotMessage("📄 جاري عرض محتوى الملف: ${_selectedContent!['fileName']}");
    // Content will be displayed in the ContentDisplayArea which is rendered in the build method
  }

  void _showMainOptions() {
    _addOptions(["رفع بيانات", "عرض البيانات"]);
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    _addUserMessage(_messageController.text);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Bio-Tech Colors
    final biotechCyan = const Color(0xFF00E5FF);
    final biotechCyanDeep = const Color(0xFF00B8D4);
    final primaryCyan = isDarkMode ? biotechCyan : biotechCyanDeep;

    final biotechBlack = const Color(0xFF0F0F0F);
    final backgroundColor = isDarkMode ? biotechBlack : const Color(0xFFF5F7FA);
    final cardColor = isDarkMode
        ? Colors.white.withOpacity(0.03)
        : Colors.white.withOpacity(0.7);
    final onSurfaceColor = isDarkMode ? Colors.white : biotechBlack;
    final subTextColor = isDarkMode ? Colors.white70 : Colors.black54;

    // Get RTL information
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.isRTL;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          context.translate('AI Health Assistant').toUpperCase(),
          style: GoogleFonts.orbitron(
            color: onSurfaceColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryCyan, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded, color: primaryCyan),
            onPressed: () {
              // History logic
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Glows
          if (isDarkMode) ...[
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryCyan.withOpacity(0.05),
                ),
              ),
            ),
          ],

          Column(
            children: [
              // Selected Content Display Area
              if (_selectedContent != null)
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primaryCyan.withOpacity(0.05),
                        border: Border(
                          bottom: BorderSide(
                            color: primaryCyan.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${_selectedContent!['fileName']}",
                                      style: GoogleFonts.orbitron(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: primaryCyan,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "PROTOCOL: ${_selectedContent!['dataType']}",
                                      style: GoogleFonts.orbitron(
                                        fontSize: 10,
                                        color: subTextColor.withOpacity(0.5),
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close_fullscreen_rounded,
                                    color: onSurfaceColor, size: 20),
                                onPressed: () => setState(() => _selectedContent = null),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: primaryCyan.withOpacity(0.1)),
                            ),
                            child: Text(
                              "${_selectedContent!['content']}",
                              style: GoogleFonts.poppins(
                                color: subTextColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: primaryCyan.withOpacity(0.2)),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryCyan.withOpacity(0.1),
                                    blurRadius: 30,
                                  )
                                ],
                              ),
                              child: Icon(
                                Icons.shield_moon_outlined,
                                size: 60,
                                color: primaryCyan,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "CORE INTELLIGENCE ACTIVE",
                              style: GoogleFonts.orbitron(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: primaryCyan,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          if (message.isOption) {
                            return _buildOptionButton(message, primaryCyan, cardColor);
                          } else {
                            return _buildChatMessage(message, primaryCyan, cardColor, onSurfaceColor, subTextColor);
                          }
                        },
                      ),
              ),

              // Typing Indicator
              if (_isTyping)
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: primaryCyan,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "ANALYZING PROTOCOLS...",
                        style: GoogleFonts.orbitron(
                          color: primaryCyan.withOpacity(0.5),
                          fontSize: 8,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),

              // Input Area
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: MediaQuery.of(context).padding.bottom + 10,
                      top: 10,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      border: Border(top: BorderSide(color: primaryCyan.withOpacity(0.1))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: primaryCyan.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 15),
                                Expanded(
                                  child: TextField(
                                    controller: _messageController,
                                    style: GoogleFonts.poppins(color: onSurfaceColor, fontSize: 14),
                                    decoration: InputDecoration(
                                      hintText: "Enter protocol command...",
                                      hintStyle: GoogleFonts.orbitron(
                                        color: subTextColor.withOpacity(0.3),
                                        fontSize: 10,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    onSubmitted: (_) => _sendMessage(),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.attach_file_rounded,
                                      color: primaryCyan.withOpacity(0.5), size: 20),
                                  onPressed: () => _addUserMessage("رفع بيانات"),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _sendMessage,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primaryCyan,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryCyan.withOpacity(0.3),
                                  blurRadius: 10,
                                )
                              ],
                            ),
                            child: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(Message message, Color primaryCyan, Color cardColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: () => _addUserMessage(message.text),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: primaryCyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryCyan.withOpacity(0.3)),
            ),
            child: Text(
              message.text,
              style: GoogleFonts.orbitron(
                color: primaryCyan,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatMessage(Message message, Color primaryCyan, Color cardColor, Color onSurfaceColor, Color subTextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryCyan.withOpacity(0.3)),
              ),
              child: Icon(Icons.hub_outlined, size: 16, color: primaryCyan),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser
                    ? primaryCyan.withOpacity(0.15)
                    : cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 0),
                  bottomRight: Radius.circular(message.isUser ? 0 : 20),
                ),
                border: Border.all(
                  color: message.isUser
                      ? primaryCyan.withOpacity(0.4)
                      : primaryCyan.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!message.isUser)
                    Text(
                      "SYSTEM",
                      style: GoogleFonts.orbitron(
                        fontSize: 8,
                        color: primaryCyan,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  if (!message.isUser) const SizedBox(height: 4),
                  Text(
                    message.text,
                    style: GoogleFonts.poppins(
                      color: onSurfaceColor.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser)
            Container(
              margin: const EdgeInsets.only(left: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryCyan,
              ),
              child: const Icon(Icons.person_outline_rounded, size: 16, color: Colors.black),
            ),
        ],
      ),
    );
  }

}

class Message {
  final String text;
  final bool isUser;
  final bool isOption;
  final bool isFileRequest;
  final String? fileName;
  final String? specialty;
  final String? dataType;

  const Message({
    required this.text,
    this.isUser = false,
    this.isOption = false,
    this.isFileRequest = false,
    this.fileName,
    this.specialty,
    this.dataType,
  });
}
