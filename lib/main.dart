import 'package:flutter/material.dart';
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
  final List<String> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final String _serverUrl = 'http://127.0.0.1:5000/messages';

  @override
  void initState() {
    super.initState();
    Timer.periodic(Duration(seconds: 2), (timer) {
      _fetchMessages();
    });
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await http.get(Uri.parse(_serverUrl));
      if (response.statusCode == 200) {
        setState(() {
          _messages.clear();
          List<dynamic> messagesJson = json.decode(response.body);
          messagesJson.forEach((messageJson) {
            _messages.add("${messageJson['user']}: ${messageJson['message']}");
          });
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
      final response = await http.post(
        Uri.parse(_serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user': 'User', 'message': message}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to send message');
      }
      _controller.clear();
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
              itemBuilder: (context, index) => ListTile(
                title: Text(_messages[index]),
              ),
            ),
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
