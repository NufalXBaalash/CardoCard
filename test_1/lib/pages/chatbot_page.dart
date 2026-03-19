import 'package:flutter/material.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get RTL information
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.isRTL;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          context.translate('AI Health Assistant'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 1, // Added slight elevation for better visual separation
      ),
      body: Column(
        children: [
          // Selected Content Display Area (when content is selected)
          if (_selectedContent != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                border: Border(
                  bottom: BorderSide(
                    color: isDarkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade300,
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
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "التخصص: ${_selectedContent!['specialty']} • النوع: ${_selectedContent!['dataType']}",
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedContent = null;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.grey.shade700
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      "${_selectedContent!['content']}",
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.health_and_safety_outlined,
                          size: 80,
                          color: colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "👨‍⚕️ مرحبًا بك في نظام رفع بيانات العيادة",
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    reverse: false,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      if (message.isOption) {
                        return _buildOptionButton(message);
                      } else if (message.isFileRequest) {
                        return _buildFileRequestMessage(message);
                      } else {
                        return _buildChatMessage(message);
                      }
                    },
                  ),
          ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.grey.shade800.withOpacity(0.7)
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
                          "الذكاء الاصطناعي يكتب...",
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
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: "اكتب رسالتك هنا...",
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
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.attachment_outlined,
                          color: isDarkMode ? Colors.white60 : Colors.black45,
                        ),
                        onPressed: () {
                          _addUserMessage("رفع بيانات");
                        },
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  mini: true,
                  backgroundColor: colorScheme.primary,
                  elevation: 2,
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                    textDirection: TextDirection.ltr, // Force LTR for send icon
                  ),
                ),
              ],
            ),
          ),
          // Added bottom padding for nav bar
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _buildOptionButton(Message message) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: InkWell(
          onTap: () => _addUserMessage(message.text),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Text(
              message.text,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileRequestMessage(Message message) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primary,
            radius: 16,
            child: const Icon(
              Icons.health_and_safety,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (message.fileName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "الملف: ${message.fileName}",
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(Message message) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            CircleAvatar(
              backgroundColor: colorScheme.primary,
              radius: 16,
              child: const Icon(
                Icons.health_and_safety,
                size: 16,
                color: Colors.white,
              ),
            ),
          if (!message.isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: message.isUser
                    ? colorScheme.primary
                    : isDarkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.text,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: message.isUser
                      ? Colors.white
                      : isDarkMode
                          ? Colors.white
                          : Colors.black87,
                ),
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
          if (message.isUser)
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
