import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:clinic_management/app/core/session.dart';
import 'package:clinic_management/app/core/theme_notifier.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

const String _kBaseUrl = 'http://10.0.2.2:8093';

enum _Role { user, assistant }

class _ChatMessage {
  final _Role role;
  final String text;
  _ChatMessage(this.role, this.text);
}

// ─── Strip markdown symbols from AI response ────────────────
String _cleanMarkdown(String text) {
  text = text.replaceAll(RegExp(r'\*{1,3}(.*?)\*{1,3}'), r'$1');
  text = text.replaceAll(RegExp(r'#{1,6}\s*'), '');
  text = text.replaceAll(RegExp(r'`{1,3}(.*?)`{1,3}', dotAll: true), r'$1');
  text = text.replaceAll(RegExp(r'^[-*_]{3,}\s*$', multiLine: true), '');
  text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return text.trim();
}

// ─── Main overlay widget ──────────────────────────────────────
// NOTE: This widget is intentionally NOT a Positioned widget.
// Positioning is handled entirely by main.dart's global builder.
class ClinicChatbotOverlay extends StatefulWidget {
  const ClinicChatbotOverlay({super.key});

  @override
  State<ClinicChatbotOverlay> createState() => _ClinicChatbotOverlayState();
}

class _ClinicChatbotOverlayState extends State<ClinicChatbotOverlay>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _animCtrl.forward() : _animCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScaleTransition(
          scale: _scaleAnim,
          alignment: Alignment.bottomLeft,
          child: _open ? _ChatPanel(onClose: _toggle) : const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        _ChatFab(open: _open, onTap: _toggle),
      ],
    );
  }
}

// ─── Enhanced Blue FAB ───────────────────────────────────────
class _ChatFab extends StatelessWidget {
  final bool open;
  final VoidCallback onTap;
  const _ChatFab({required this.open, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          gradient: open
              ? const LinearGradient(
            colors: [Color(0xFF1E40AF), Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(29),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(open ? 0.55 : 0.40),
              blurRadius: open ? 28 : 20,
              spreadRadius: open ? 2 : 0,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Subtle inner ring for depth
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1,
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: open
                  ? const Icon(Icons.close_rounded,
                  key: ValueKey('close'),
                  color: Colors.white,
                  size: 24)
                  : const Icon(Icons.chat_bubble_rounded,
                  key: ValueKey('chat'),
                  color: Colors.white,
                  size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CHAT PANEL ──────────────────────────────────────────────
class _ChatPanel extends StatefulWidget {
  final VoidCallback onClose;
  const _ChatPanel({required this.onClose});

  @override
  State<_ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<_ChatPanel> {
  String get _welcome =>
      '👋 Hello${AppSession.patientName != null ? ', ${AppSession.patientName}' : ''}!\n\n'
          'I\'m your Clinic Assistant.\n\n'
          'I can help you:\n'
          '📅 Book an appointment\n'
          '📋 View your appointment records\n'
          '🕐 Check doctor availability\n'
          '🌙 Switch dark / light mode\n\n'
          'Try: "Book me with Dr. Ahmed tomorrow at 10 AM"';

  late final List<_ChatMessage> _messages;
  final List<Map<String, String>> _history = [];
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _loading = false;

  // ── Speech-to-text ─────────────────────────────────────────
  late stt.SpeechToText _speech;
  bool _isListening = false;

  // Three-state: null = not yet checked, true = available, false = unavailable
  bool? _speechAvailable;

  @override
  void initState() {
    super.initState();
    _messages = [_ChatMessage(_Role.assistant, _welcome)];
    _speech = stt.SpeechToText();
    // Don't block UI — init in background
    _initSpeech();
  }

  // ── Speech init ─────────────────────────────────────────────
  Future<void> _initSpeech() async {
    try {
      // Check and request permission
      var micStatus = await Permission.microphone.status;
      debugPrint('Microphone status: $micStatus');

      if (!micStatus.isGranted) {
        micStatus = await Permission.microphone.request();
        debugPrint('Microphone request result: $micStatus');
      }

      if (!micStatus.isGranted) {
        if (mounted) setState(() => _speechAvailable = false);
        return;
      }

      // Initialize with proper error handling
      final available = await _speech.initialize(
        onError: (e) {
          debugPrint('STT error: ${e.errorMsg}');
          if (mounted) {
            setState(() {
              _isListening = false;
              _speechAvailable = false;
            });
          }
        },
        onStatus: (s) {
          debugPrint('STT status: $s');
          if ((s == 'done' || s == 'notListening') && mounted) {
            setState(() => _isListening = false);
          }
        },
        debugLogging: true,
      );

      if (mounted) setState(() => _speechAvailable = available);
      debugPrint('STT init result: $available');

      // If initialization failed, try once more with default options
      if (!available) {
        debugPrint('Retrying STT initialization...');
        final retryAvailable = await _speech.initialize();
        if (mounted) setState(() => _speechAvailable = retryAvailable);
        debugPrint('STT retry result: $retryAvailable');
      }
    } catch (e) {
      debugPrint('STT init exception: $e');
      if (mounted) setState(() => _speechAvailable = false);
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    if (_isListening) _speech.stop();
    super.dispose();
  }

  // ── Toggle mic ──────────────────────────────────────────────
  Future<void> _toggleListening() async {
    // If currently listening, stop
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    // Re-check permission before listening
    final micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '🎙 Microphone permission required.\n'
                  'Please grant permission in Settings.',
            ),
            backgroundColor: const Color(0xFF1D4ED8),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: openAppSettings,
            ),
          ),
        );
        return;
      }
    }

    // If init hasn't finished yet, wait for it
    if (_speechAvailable == null) {
      await _initSpeech();
    }

    // If still not available, try to reinitialize
    if (_speechAvailable == false) {
      debugPrint('Attempting to reinitialize speech...');
      await _initSpeech();
    }

    // If init confirmed unavailable, show a helpful message
    if (_speechAvailable != true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '🎙 Speech recognition not available.\n'
                'This may happen on emulators without Google Services.',
          ),
          backgroundColor: const Color(0xFF1D4ED8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Start listening
    if (mounted) setState(() => _isListening = true);

    try {
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() {
            _input.text = result.recognizedWords;
            _input.selection = TextSelection.fromPosition(
              TextPosition(offset: _input.text.length),
            );
          });
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            _speech.stop();
            if (mounted) setState(() => _isListening = false);
            _send();
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        cancelOnError: false,
        partialResults: true,
      );
    } catch (e) {
      debugPrint('STT listen error: $e');
      if (mounted) setState(() => _isListening = false);

      // Show error but don't mark as permanently unavailable
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not start listening: ${e.toString()}'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Dark / light mode local commands ─────────────────────
  bool _handleLocalCommand(String text) {
    final lower = text.toLowerCase().trim();
    if (lower.contains('dark mode') ||
        lower.contains('turn dark') ||
        lower == 'dark' ||
        lower.contains('switch to dark')) {
      themeNotifier.toggleDark(true);
      setState(() {
        _messages.add(_ChatMessage(_Role.user, text));
        _messages.add(_ChatMessage(_Role.assistant, '🌙 Dark mode enabled!'));
        _history.add({'role': 'user', 'content': text});
        _history.add({'role': 'assistant', 'content': '🌙 Dark mode enabled!'});
      });
      _input.clear();
      _scrollToBottom();
      return true;
    }
    if (lower.contains('light mode') ||
        lower.contains('turn light') ||
        lower == 'light' ||
        lower.contains('switch to light')) {
      themeNotifier.toggleDark(false);
      setState(() {
        _messages.add(_ChatMessage(_Role.user, text));
        _messages.add(_ChatMessage(_Role.assistant, '☀️ Light mode enabled!'));
        _history.add({'role': 'user', 'content': text});
        _history
            .add({'role': 'assistant', 'content': '☀️ Light mode enabled!'});
      });
      _input.clear();
      _scrollToBottom();
      return true;
    }
    return false;
  }

  Future<void> _send([String? quickText]) async {
    final text = (quickText ?? _input.text).trim();
    if (text.isEmpty || _loading) return;

    if (_handleLocalCommand(text)) return;

    setState(() {
      _messages.add(_ChatMessage(_Role.user, text));
      _history.add({'role': 'user', 'content': text});
      _input.clear();
      _loading = true;
    });
    _scrollToBottom();

    try {
      const tzName = 'Asia/Kolkata';
      final patientId = AppSession.patientId;

      final uri = Uri.parse('$_kBaseUrl/api/v19/chatbot/mobile/message');
      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (AppSession.sessionToken != null)
            'X-Session-Token': AppSession.sessionToken!,
        },
        body: jsonEncode({
          'message': text,
          'history': _history.length > 12
              ? _history.sublist(_history.length - 12)
              : _history,
          'tz_name': tzName,
          if (patientId != 0) 'patient_id': patientId,
        }),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final rawReply =
            data?['data']?['reply'] ?? 'Sorry, I could not process that.';
        final reply = _cleanMarkdown(rawReply.toString());
        setState(() {
          _messages.add(_ChatMessage(_Role.assistant, reply));
          _history.add({'role': 'assistant', 'content': reply});
        });
      } else {
        throw Exception('HTTP ${resp.statusCode}');
      }
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          _Role.assistant,
          '⚠️ Connection error. Make sure you\'re on the same network as the server.',
        ));
      });
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _clearChat() {
    setState(() {
      _messages
        ..clear()
        ..add(_ChatMessage(_Role.assistant, _welcome));
      _history.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 340,
        height: 520,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFBFDBFE)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.15),
              blurRadius: 40,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildMessages()),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withOpacity(0.35), width: 1.5),
            ),
            child: const Center(
              child: Text('🩺', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Clinic Assistant',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      AppSession.patientName != null
                          ? 'Hi, ${AppSession.patientName}'
                          : 'Always here to help',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _headerBtn(Icons.delete_outline_rounded, _clearChat),
          const SizedBox(width: 6),
          _headerBtn(Icons.close_rounded, widget.onClose),
        ],
      ),
    );
  }

  Widget _headerBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(icon, color: Colors.white, size: 16),
        ),
      ),
    );
  }

  // ── Messages area ─────────────────────────────────────────
  Widget _buildMessages() {
    return Container(
      color: const Color(0xFFF0F9FF),
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.all(12),
        itemCount: _messages.length +
            (_loading ? 1 : 0) +
            (_messages.length <= 1 ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (_messages.length <= 1 && i == 0) return _buildChips();
          final msgIndex = _messages.length <= 1 ? i - 1 : i;
          if (msgIndex < _messages.length) {
            return _buildBubble(_messages[msgIndex]);
          }
          return _buildTyping();
        },
      ),
    );
  }

  Widget _buildChips() {
    final chips = [
      ('📅 Book Appointment', 'I want to book an appointment'),
      ('📋 View My Records', 'Show me my appointment records'),
      ('🕐 Check Availability', 'Check doctor availability'),
      ('🌙 Dark Mode', 'dark mode'),
      ('☀️ Light Mode', 'light mode'),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: chips.map((c) {
          return GestureDetector(
            onTap: () => _send(c.$2),
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(c.$1,
                  style: const TextStyle(
                      color: Color(0xFF1D4ED8), fontSize: 12)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    final isUser = msg.role == _Role.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) _avatar('🩺', const Color(0xFF2563EB)),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: isUser ? null : Colors.white,
                gradient: isUser
                    ? const LinearGradient(
                  colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isUser ? 14 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 14),
                ),
                border: isUser
                    ? null
                    : Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: isUser ? Colors.white : const Color(0xFF1E3A5F),
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            _avatar('👤', const Color(0xFFDBEAFE),
                textColor: const Color(0xFF2563EB)),
        ],
      ),
    );
  }

  Widget _avatar(String emoji, Color bg, {Color? textColor}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: textColor != null
            ? Border.all(color: const Color(0xFF93C5FD), width: 1.5)
            : null,
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 13))),
    );
  }

  Widget _buildTyping() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _avatar('🩺', const Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomRight: Radius.circular(14),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  // ── Input bar ─────────────────────────────────────────────
  Widget _buildInputBar() {
    // Mic icon state:
    // - null  (not checked yet) → blue mic outline
    // - true  (available)       → blue mic, red when listening
    // - false (unavailable)     → grey mic with slash
    final micAvailable = _speechAvailable != false;
    final micColor = _isListening
        ? Colors.white
        : micAvailable
        ? const Color(0xFF2563EB)
        : Colors.grey.shade400;
    final micBg = _isListening
        ? const Color(0xFFEF4444)
        : const Color(0xFFEFF6FF);
    final micBorder = _isListening
        ? const Color(0xFFEF4444)
        : micAvailable
        ? const Color(0xFFDBEAFE)
        : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFDBEAFE))),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          // ── Mic button ──────────────────────────────────
          GestureDetector(
            onTap: _toggleListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: micBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: micBorder),
              ),
              child: Center(
                child: Icon(
                  _isListening
                      ? Icons.mic
                      : micAvailable
                      ? Icons.mic_none
                      : Icons.mic_off,
                  color: micColor,
                  size: 18,
                ),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _input,
              onSubmitted: (_) => _send(),
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF1E3A5F)),
              decoration: InputDecoration(
                hintText: _isListening
                    ? '🎙 Listening...'
                    : 'Type your request...',
                hintStyle: TextStyle(
                    color: _isListening
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF93C5FD),
                    fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFEFF6FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  const BorderSide(color: Color(0xFFDBEAFE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  const BorderSide(color: Color(0xFFDBEAFE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF2563EB), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 13, vertical: 9),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child:
                Icon(Icons.send_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TYPING DOTS ─────────────────────────────────────────────
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = (_ctrl.value - i * 0.18).clamp(0.0, 1.0);
            final scale = (t < 0.4
                ? t / 0.4
                : t < 0.8
                ? 1.0
                : 1.0 - (t - 0.8) / 0.2);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Color.lerp(const Color(0xFFBFDBFE),
                    const Color(0xFF2563EB), scale.clamp(0.0, 1.0)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}