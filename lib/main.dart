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
  // final String _serverUrl = 'http://127.0.0.1:5000/api/messages';
  final String _serverUrl = 'http://10.0.2.2:5000/api/messages';

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
              "intent": messageJson['intent'],
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
        title: Text("Hey, 오은영"),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
                itemCount: _messages.length,
                controller: _scrollController,
                itemBuilder: (context, index) {
                  return chatWidget(context, index);
                }),
          ),
          typeWidget(),
        ],
      ),
    );
  }

  Widget _oeyProfile(context, index) {
    if (_messages[index]['intent'] == "긍정")
      return Image.asset("assets/images/oey_positive.png",
          width: 60.0, height: 60.0, fit: BoxFit.cover);
    else if (_messages[index]['intent'] == "경청")
      return Image.asset("assets/images/oey_listening.png",
          width: 60.0, height: 60.0, fit: BoxFit.cover);
    else if (_messages[index]['intent'] == "공감")
      return Image.asset("assets/images/oey_sympathy.png",
          width: 60.0, height: 60.0, fit: BoxFit.cover);
    else {
      return SizedBox();
    }
  }

  Widget chatWidget(context, index) {
    return Container(
      padding: EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 10),
      child: Align(
          alignment: (_messages[index]['user'] == "OEY"
              ? Alignment.topLeft
              : Alignment.topRight),
          child: Row(
            mainAxisAlignment: _messages[index]['user'] == "OEY"
                ? MainAxisAlignment.start
                : MainAxisAlignment.end,
            children: [
              if (_messages[index]['user'] == "OEY")
                _oeyProfile(context, index),
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: (_messages[index]['user'] == "OEY"
                        ? Colors.grey.shade200
                        : Colors.blue[200]),
                  ),
                  padding: EdgeInsets.all(16),
                  child: Text(_messages[index]['message'],
                      style: TextStyle(fontSize: 15),
                      softWrap: true,
                      overflow: TextOverflow.visible),
                ),
              ),
              if (_messages[index]['user'] != "OEY")
                Icon(Icons.face, size: 60.0),
            ],
          )),
    );
  }

  Widget typeWidget() {
    void _sendMessageHandler() {
      if (_controller.text.isNotEmpty) {
        _sendMessage(_controller.text);
        _controller.clear();
      }
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(hintText: "Type a message..."),
              onSubmitted: (text) {
                _sendMessageHandler();
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              _sendMessageHandler();
            },
          ),
        ],
      ),
    );
  }
}
