import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/voice_assistant_provider.dart';
import '../../services/voice_assistant_service.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Waveform animation
  late AnimationController _waveController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initialize the voice assistant provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VoiceAssistantProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceAssistantProvider>(
      builder: (context, provider, child) {
        // Auto-scroll when new messages arrive
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return Scaffold(
          backgroundColor: const Color(0xFF1A1A2E),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1A1A2E),
            elevation: 0,
            foregroundColor: Colors.white,
            title: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: provider.isSessionActive
                        ? AppColors.success
                        : AppColors.grey500,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Voice Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            actions: [
              // Language toggle
              Container(
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: InkWell(
                  onTap: () => provider.toggleLanguage(),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      provider.currentLanguage == 'en' ? 'EN' : 'বাং',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              // Text/Voice toggle
              IconButton(
                icon: Icon(
                  provider.isTextMode ? Icons.mic : Icons.keyboard,
                  color: Colors.white,
                ),
                onPressed: () => provider.toggleInputMode(),
                tooltip: provider.isTextMode
                    ? 'Switch to Voice'
                    : 'Switch to Text',
              ),
              // Clear chat
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white70),
                onPressed: () => provider.clearMessages(),
                tooltip: 'Clear Chat',
              ),
            ],
          ),
          body: Column(
            children: [
              // Status bar
              _buildStatusBar(provider),

              // Chat messages
              Expanded(
                child: provider.messages.isEmpty
                    ? _buildEmptyState(provider)
                    : _buildMessageList(provider),
              ),

              // Partial recognition text
              if (provider.partialText.isNotEmpty &&
                  provider.isListening)
                _buildPartialText(provider),

              // Waveform or input area
              if (!provider.isTextMode)
                _buildVoiceInput(provider)
              else
                _buildTextInput(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBar(VoiceAssistantProvider provider) {
    String statusText;
    Color statusColor;

    switch (provider.state) {
      case VoiceAssistantState.listening:
        statusText = provider.currentLanguage == 'en'
            ? '🎤 Listening...'
            : '🎤 শুনছি...';
        statusColor = AppColors.success;
        break;
      case VoiceAssistantState.processing:
        statusText = provider.currentLanguage == 'en'
            ? '⚡ Processing...'
            : '⚡ প্রক্রিয়াকরণ...';
        statusColor = AppColors.warning;
        break;
      case VoiceAssistantState.speaking:
        statusText = provider.currentLanguage == 'en'
            ? '🔊 Speaking...'
            : '🔊 বলছি...';
        statusColor = AppColors.info;
        break;
      case VoiceAssistantState.error:
        statusText = provider.currentLanguage == 'en'
            ? '⚠️ Error occurred'
            : '⚠️ ত্রুটি হয়েছে';
        statusColor = AppColors.error;
        break;
      default:
        statusText = provider.currentLanguage == 'en'
            ? 'Ready'
            : 'প্রস্তুত';
        statusColor = AppColors.grey500;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: statusColor.withOpacity(0.15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (provider.state == VoiceAssistantState.processing ||
              provider.state == VoiceAssistantState.speaking)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: statusColor,
              ),
            ),
          if (provider.state == VoiceAssistantState.processing ||
              provider.state == VoiceAssistantState.speaking)
            const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(VoiceAssistantProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryOrange.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.assistant,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              provider.currentLanguage == 'en'
                  ? 'VALESCO Voice Assistant'
                  : 'ভ্যালেস্কো ভয়েস সহকারী',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              provider.currentLanguage == 'en'
                  ? 'Tap the microphone to start speaking\nor switch to text input mode'
                  : 'কথা বলতে মাইক্রোফোনে ট্যাপ করুন\nবা টেক্সট ইনপুট মোডে যান',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            // Example prompts
            _buildExamplePrompt(
              provider.currentLanguage == 'en'
                  ? '"Show my blood sugar readings"'
                  : '"আমার ব্লাড সুগার দেখাও"',
            ),
            const SizedBox(height: 8),
            _buildExamplePrompt(
              provider.currentLanguage == 'en'
                  ? '"What medications do I have today?"'
                  : '"আজ আমার কী ওষুধ আছে?"',
            ),
            const SizedBox(height: 8),
            _buildExamplePrompt(
              provider.currentLanguage == 'en'
                  ? '"Open my diet plan"'
                  : '"আমার ডায়েট প্ল্যান খোলো"',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamplePrompt(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildMessageList(VoiceAssistantProvider provider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: provider.messages.length,
      itemBuilder: (context, index) {
        final message = provider.messages[index];
        return _buildMessageBubble(message, provider);
      },
    );
  }

  Widget _buildMessageBubble(
      ChatMessage message, VoiceAssistantProvider provider) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assistant,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primaryOrange.withOpacity(0.85)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.white.withOpacity(0.9),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: isUser
                              ? Colors.white.withOpacity(0.6)
                              : Colors.white.withOpacity(0.4),
                          fontSize: 11,
                        ),
                      ),
                      if (!isUser && message.intentName != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryViolet.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            message.intentName!,
                            style: TextStyle(
                              color: AppColors.primaryVioletLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Navigation action button
                  if (!isUser && message.navigationRoute != null) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, message.navigationRoute!);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.open_in_new,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              provider.currentLanguage == 'en'
                                  ? 'Go to Screen'
                                  : 'স্ক্রিনে যান',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: AppColors.primaryOrange,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPartialText(VoiceAssistantProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.white.withOpacity(0.05),
      child: Text(
        provider.partialText,
        style: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 15,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildVoiceInput(VoiceAssistantProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Waveform animation
          if (provider.isListening) _buildWaveformAnimation(provider),

          const SizedBox(height: 16),

          // Mic button
          Center(
            child: ScaleTransition(
              scale: provider.isListening
                  ? _pulseAnimation
                  : const AlwaysStoppedAnimation(1.0),
              child: GestureDetector(
                onTap: () => provider.toggleListening(),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: provider.isListening
                        ? LinearGradient(
                            colors: [
                              AppColors.error,
                              AppColors.error.withOpacity(0.8),
                            ],
                          )
                        : AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (provider.isListening
                                ? AppColors.error
                                : AppColors.primaryOrange)
                            .withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Icon(
                    provider.isListening ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          Text(
            provider.isListening
                ? (provider.currentLanguage == 'en'
                    ? 'Tap to stop'
                    : 'থামাতে ট্যাপ করুন')
                : (provider.currentLanguage == 'en'
                    ? 'Tap to speak'
                    : 'কথা বলতে ট্যাপ করুন'),
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformAnimation(VoiceAssistantProvider provider) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(20, (index) {
              final normalizedLevel =
                  ((provider.soundLevel + 10) / 20).clamp(0.1, 1.0);
              final phase = (index / 20) * 2 * pi;
              final animValue =
                  sin(_waveController.value * 2 * pi + phase).abs();
              final height =
                  8 + (animValue * 40 * normalizedLevel);

              return Container(
                width: 3,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppColors.primaryOrange,
                      AppColors.primaryViolet,
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildTextInput(VoiceAssistantProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: provider.currentLanguage == 'en'
                    ? 'Type your message...'
                    : 'আপনার বার্তা লিখুন...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onSubmitted: (text) {
                if (text.isNotEmpty) {
                  provider.sendTextInput(text);
                  _textController.clear();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () {
                final text = _textController.text;
                if (text.isNotEmpty) {
                  provider.sendTextInput(text);
                  _textController.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
