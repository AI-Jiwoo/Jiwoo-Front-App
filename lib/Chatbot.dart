import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
  String? _selectedResearch;
  List<String> _researchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _getToken();
    _loadResearchHistory();
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

  Future<void> _loadResearchHistory() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8001/market-research/history'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> decodedResponse = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _researchHistory = decodedResponse.map((item) => item['title'] as String).toList();
        });
      } else {
        throw Exception('Failed to load research history');
      }
    } catch (e) {
      print('Error loading research history: $e');
      // 에러 처리 (예: 사용자에게 알림)
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
        Uri.parse('http://loaclhost:8001/chat'),
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
          parsedResponse: _parseResponse(data['message']),
          webResults: data['web_results'],
          imageUrl: data['image_url'],
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
        text: '죄송합니다. 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
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

  List<Map<String, dynamic>> _parseResponse(String text) {
    final lines = text.split('\n');
    final categories = <Map<String, dynamic>>[];
    Map<String, dynamic>? currentCategory;

    for (final line in lines) {
      if (RegExp(r'^\d+\.').hasMatch(line)) {
        if (currentCategory != null) {
          categories.add(currentCategory);
        }
        currentCategory = {
          'title': line.replaceFirst(RegExp(r'^\d+\.\s*'), '').split(':')[0].trim(),
          'examples': <String>[],
          'source': '',
          'date': '',
        };
      } else if (currentCategory != null) {
        if (line.startsWith('- 예시:')) {
          currentCategory['examples'] = line.replaceFirst('- 예시:', '').split(',').map((e) => e.trim()).toList();
        } else if (line.startsWith('- 출처:')) {
          currentCategory['source'] = line.replaceFirst('- 출처:', '').trim();
        } else if (line.startsWith('- 날짜:')) {
          currentCategory['date'] = line.replaceFirst('- 날짜:', '').trim();
        }
      }
    }

    if (currentCategory != null) {
      categories.add(currentCategory);
    }

    return categories;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jiwoo AI 챗봇'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String research) {
              setState(() {
                _selectedResearch = research;
              });
            },
            itemBuilder: (BuildContext context) {
              return _researchHistory.map((String research) {
                return PopupMenuItem<String>(
                  value: research,
                  child: Text(research),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(8.0),
              reverse: true,
              itemBuilder: (_, int index) => _buildMessage(_messages[index]),
              itemCount: _messages.length,
            ),
          ),
          Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              child: Text(message.isUserMessage ? '사용자' : 'AI'),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(message.isUserMessage ? '사용자' : 'Jiwoo AI',
                    style: Theme.of(context).textTheme.titleMedium),
                Container(
                  margin: EdgeInsets.only(top: 5.0),
                  child: Text(message.text),
                ),
                if (!message.isUserMessage) ...[
                  SizedBox(height: 10),
                  _buildParsedResponse(message),
                  _buildWebResults(message),
                  if (message.imageUrl != null) _buildImage(message.imageUrl!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParsedResponse(ChatMessage message) {
    if (message.parsedResponse == null || message.parsedResponse!.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: message.parsedResponse!.map((category) {
        return Card(
          margin: EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category['title'], style: TextStyle(fontWeight: FontWeight.bold)),
                if (category['examples'].isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Text('예시: ${category['examples'].join(', ')}'),
                  ),
                if (category['source'].isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Text('출처: ${category['source']}'),
                  ),
                if (category['date'].isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Text('날짜: ${category['date']}'),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWebResults(ChatMessage message) {
    if (message.webResults == null || message.webResults!.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('웹 검색 결과:', style: TextStyle(fontWeight: FontWeight.bold)),
        ...message.webResults!.map((result) {
          return Card(
            margin: EdgeInsets.only(top: 5, bottom: 5),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result['title'], style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text(result['snippet']),
                  SizedBox(height: 5),
                  Text(result['link'], style: TextStyle(color: Colors.blue)),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildImage(String imageUrl) {
    return Container(
      margin: EdgeInsets.only(top: 10),
      child: Image.network(imageUrl),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: Container(
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
            Container(
              margin: EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: Icon(Icons.send),
                onPressed: () => _handleSubmitted(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUserMessage;
  final List<Map<String, dynamic>>? parsedResponse;
  final List<Map<String, dynamic>>? webResults;
  final String? imageUrl;

  ChatMessage({
    required this.text,
    required this.isUserMessage,
    this.parsedResponse,
    this.webResults,
    this.imageUrl,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isUserMessage: json['isUserMessage'],
      parsedResponse: json['parsedResponse'],
      webResults: json['webResults'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUserMessage': isUserMessage,
      'parsedResponse': parsedResponse,
      'webResults': webResults,
      'imageUrl': imageUrl,
    };
  }
}