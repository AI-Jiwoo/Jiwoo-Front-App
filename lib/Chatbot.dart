import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChatbotWidget extends StatefulWidget {
  @override
  _ChatbotWidgetState createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _getToken();
  }

  Future<void> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('access_token') ?? '';
    });
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getString('chat_messages');
    if (messagesJson != null) {
      final List<dynamic> decodedMessages = json.decode(messagesJson);
      setState(() {
        _messages.addAll(decodedMessages.map((msg) => ChatMessage.fromJson(msg)).toList().reversed);
      });
    }
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = json.encode(_messages.map((msg) => msg.toJson()).toList());
    await prefs.setString('chat_messages', messagesJson);
  }

  void _handleSubmitted(String text) async {
    _textController.clear();
    ChatMessage message = ChatMessage(
      text: text,
      isUserMessage: true,
    );
    setState(() {
      _messages.insert(0, message);
      _isLoading = true;
    });
    _saveMessages();

    try {
      final response = await http.post(
        Uri.parse('http://13.124.128.228:8001/chat'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({'message': text}),
      );

      if (response.statusCode == 200) {
        final decodedResponse = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedResponse);
        ChatMessage botMessage = ChatMessage(
          text: data['message'],
          isUserMessage: false,
        );
        setState(() {
          _messages.insert(0, botMessage);
        });
        _saveMessages();
      } else {
        throw Exception('Failed to load response');
      }
    } catch (e) {
      print('Error: $e');
      ChatMessage errorMessage = ChatMessage(
        text: '죄송합니다. 오류가 발생했습니다.',
        isUserMessage: false,
      );
      setState(() {
        _messages.insert(0, errorMessage);
      });
      _saveMessages();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTextComposer() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: <Widget>[
          Flexible(
            child: TextField(
              controller: _textController,
              onSubmitted: _handleSubmitted,
              decoration: InputDecoration.collapsed(hintText: "메시지를 입력하세요..."),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () => _handleSubmitted(_textController.text),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('지우 AI 챗봇'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        children: <Widget>[
          Flexible(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(8.0),
              reverse: true,
              itemBuilder: (_, int index) => _messages[index],
              itemCount: _messages.length,
            ),
          ),
          Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  ChatMessage({required this.text, required this.isUserMessage});

  final String text;
  final bool isUserMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isUserMessage: json['isUserMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUserMessage': isUserMessage,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
        isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: <Widget>[
          if (!isUserMessage)
            Container(
              margin: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(child: Text('AI')),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: isUserMessage
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: <Widget>[
                Text(isUserMessage ? '사용자' : 'AI 챗봇',
                    style: Theme.of(context).textTheme.titleMedium),
                Container(
                  margin: EdgeInsets.only(top: 5.0),
                  child: Text(text),
                ),
              ],
            ),
          ),
          if (isUserMessage)
            Container(
              margin: const EdgeInsets.only(left: 16.0),
              child: CircleAvatar(child: Text('사용자'[0])),
            ),
        ],
      ),
    );
  }
}