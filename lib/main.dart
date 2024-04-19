import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Chat App',
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String _serverUrl = 'http://127.0.0.1:5000/api/messages';

  @override
  void initState() {
    super.initState();
    Timer.periodic(Duration(seconds: 2), (timer) {
      _fetchMessages();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await http.get(Uri.parse(_serverUrl));
      if (response.statusCode == 200) {
        setState(() {
          // _messages.clear();
          dynamic messageJson = json.decode(response.body);
          print(messageJson);
          if (messageJson['user'] != "NO_MESSAGE") {
            _messages.add({
              "user": messageJson['user'],
              "message": messageJson['message'],
            });
            Future.delayed(Duration(milliseconds: 100), _scrollToBottom);
          }
        });
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _sendMessage(String message) async {
    try {
      setState(() {
        _messages.add({"user": 'User', "message": message}); // 메시지 추가
      });
      _controller.clear();
      Future.delayed(Duration(milliseconds: 100), _scrollToBottom);

      final response = await http.post(
        Uri.parse(_serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user': 'User', 'message': message}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Flutter Chat"),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
                itemCount: _messages.length,
                controller: _scrollController,
                itemBuilder: (context, index) {
                  return Container(
                    padding: EdgeInsets.only(
                        left: 14, right: 14, top: 10, bottom: 10),
                    child: Align(
                      alignment: (_messages[index]['user'] == "OEY"
                          ? Alignment.topLeft
                          : Alignment.topRight),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: (_messages[index]['user'] == "OEY"
                              ? Colors.grey.shade200
                              : Colors.blue[200]),
                        ),
                        padding: EdgeInsets.all(16),
                        child: Text(
                          _messages[index]['message'],
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  );
                }),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(hintText: "Type a message..."),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      _sendMessage(_controller.text);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
