// lib/main.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // timestamps 사용 (pubspec.yaml에 intl 추가되어 있지 않으면 자동으로 추가하거나 주석 처리)

void main() {
  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      ),
      home: const ChatScreen(),
    );
  }
}

class Message {
  final String text;
  final bool isUser;
  final DateTime time;
  Message({required this.text, required this.isUser, DateTime? time})
      : time = time ?? DateTime.now();
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false; // 전송 중 상태 (버튼 비활성화 / 타이핑 인디케이터 등)

  // TODO: 실제 서버(예: FastAPI) 연동 시 이 함수를 수정하세요.
  Future<String> _fetchAiReply(String userMessage) async {
    // 예: http 패키지로 POST 요청 보내고 응답 본문 반환
    // final res = await http.post(Uri.parse('https://your-api/chat'),
    //     body: jsonEncode({'message': userMessage}), headers: {'Content-Type':'application/json'});
    // return jsonDecode(res.body)['reply'];
    await Future.delayed(const Duration(milliseconds: 700)); // 모의 지연
    if (userMessage.contains('안녕')) return '안녕하세요! 무엇을 도와드릴까요?';
    if (userMessage.contains('이름')) return '저는 Flutter로 만든 데모 봇이에요 🤖';
    return '재밌는 질문이네요. 조금 더 자세히 말씀해 주시겠어요?';
  }

  void _sendMessageFromInput() {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    _sendMessage(text);
  }

  Future<void> _sendMessage(String text) async {
    setState(() {
      _messages.add(Message(text: text, isUser: true));
      _isSending = true;
    });
    _controller.clear();
    _scrollToBottom();

    // AI 응답 처리
    final replyText = await _fetchAiReply(text);

    setState(() {
      _messages.add(Message(text: replyText, isUser: false));
      _isSending = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 60,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatTime(DateTime t) {
    try {
      return DateFormat('HH:mm').format(t);
    } catch (_) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildMessageTile(Message m) {
    final alignment = m.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = m.isUser ? Colors.blueAccent : Colors.grey.shade200;
    final textColor = m.isUser ? Colors.white : Colors.black87;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: Radius.circular(m.isUser ? 14 : 4),
      bottomRight: Radius.circular(m.isUser ? 4 : 14),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisAlignment: m.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!m.isUser) const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: radius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      )
                    ],
                  ),
                  child: Text(
                    m.text,
                    style: TextStyle(color: textColor, fontSize: 16),
                  ),
                ),
              ),
              if (m.isUser) const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(left: m.isUser ? 0 : 6, right: m.isUser ? 6 : 0),
            child: Text(
              _formatTime(m.time),
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
        centerTitle: true,
        elevation: 1,
        actions: [
          IconButton(
            tooltip: '대화 초기화',
            icon: Image.asset(
              'assets/rotate.png', // 이미지 경로
              width: 30,
              height: 30,
              color: Colors.blueAccent, // 아이콘처럼 색을 바꾸고 싶으면
              colorBlendMode: BlendMode.srcIn,
            ),
            onPressed: () {
              setState(() {
                _messages.clear();
              });
            },
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (context, idx) {
                  return _buildMessageTile(_messages[idx]);
                },
              ),
            ),
            _buildInputArea(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/log.png', // 이미지 경로
            width: 72,
            height: 72,
            color: Colors.blueAccent, // 아이콘처럼 색을 바꾸고 싶으면
            colorBlendMode: BlendMode.srcIn,
          ),
          const SizedBox(height: 12),
          const Text(
            '새 대화를 시작해보세요',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 6),
          const Text(
            '메시지를 입력하고 전송 버튼을 눌러보세요',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }


  Widget _buildInputArea(ThemeData theme) {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessageFromInput(),
                decoration: InputDecoration(
                  hintText: _isSending ? '응답을 기다리는 중...' : '메시지를 입력하세요...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                enabled: !_isSending,
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 22,
              backgroundColor: _isSending ? Colors.grey : Colors.blueAccent,
              child: IconButton(
                icon: _isSending
                    ? Image.asset(
                  'assets/sandclock.png',
                  width: 24,
                  height: 24,
                  color: Colors.white, // 색을 바꾸고 싶으면
                  colorBlendMode: BlendMode.srcIn,
                )
                    : Image.asset(
                  'assets/airplane.png',
                  width: 24,
                  height: 24,
                  color: Colors.white,
                  colorBlendMode: BlendMode.srcIn,
                ),
                color: Colors.white,
                onPressed: _isSending ? null : _sendMessageFromInput,
              ),
            )
          ],
        ),
      ),
    );
  }
}