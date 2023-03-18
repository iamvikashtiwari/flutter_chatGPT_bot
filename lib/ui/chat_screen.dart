import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_chatgpt_bot/model/model.dart';
import 'package:flutter_chatgpt_bot/ui/chat_message_widget.dart';
import 'package:flutter_chatgpt_bot/utils/constant.dart';
import 'package:http/http.dart' as http;

const backgroundColor = Color(0xff343541);
const botBackgroundColor = Color(0xff444654);

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late bool isLoading;
  final TextEditingController _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    isLoading = false;
  }

  Future<String> generateResponse(String prompt) async {
    const apiKey = apiSecretKey;

    var url = Uri.https(baseUrl, urlEndPoint);
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        "Authorization": "Bearer $apiKey"
      },
      body: json.encode({
        "model": "text-davinci-003",
        "prompt": prompt,
        'temperature': 0,
        'max_tokens': 2000,
        'top_p': 1,
        'frequency_penalty': 0.0,
        'presence_penalty': 0.0,
      }),
    );

    ///decode the respone
    Map<String, dynamic> newResponse = jsonDecode(response.body);
    return newResponse['choices'][0]['text'];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 100,
          centerTitle: true,
          title: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              appBarText,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
          backgroundColor: botBackgroundColor,
        ),
        backgroundColor: backgroundColor,
        body: Column(
          children: [
            ///Chat body
            Expanded(
              child: _buildList(),
            ),
            Visibility(
              visible: isLoading,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
            Row(
              children: [
                //input field
                _buildInput(),

                //submit button
                _buildSubmit(),
              ],
            )
          ],
        ),
      ),
    );
  }

  Expanded _buildInput() {
    return Expanded(
        child: TextField(
      controller: _textController,
      decoration: const InputDecoration(
        fillColor: botBackgroundColor,
        filled: true,
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
      ),
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(
        color: Colors.white,
      ),
    ));
  }

  Widget _buildSubmit() {
    return Visibility(
      visible: !isLoading,
      child: Container(
        color: botBackgroundColor,
        child: IconButton(
          icon: const Icon(
            Icons.send_rounded,
            color: Color.fromRGBO(142, 142, 160, 1),
          ),
          onPressed: () {
            // display user input
            setState(() {
              _messages.add(ChatMessage(
                  text: _textController.text,
                  chatMessageType: ChatMessageType.user));
              isLoading = true;
            });
            var input = _textController.text;
            _textController.clear();
            Future.delayed(const Duration(milliseconds: 50))
                .then((value) => _scrollDown());
            // call chatbot api
            generateResponse(input).then((value) {
              setState(() {
                isLoading = false;
                _messages.add(ChatMessage(
                    text: value, chatMessageType: ChatMessageType.bot));
              });
            });
            // display chatbot response
            _textController.clear();
            Future.delayed(const Duration(milliseconds: 50))
                .then((value) => _scrollDown());
          },
        ),
      ),
    );
  }

  void _scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  ListView _buildList() {
    return ListView.builder(
      itemCount: _messages.length,
      controller: _scrollController,
      itemBuilder: ((context, index) {
        var message = _messages[index];
        return ChatMessageWidget(
          text: message.text,
          chatMessageType: message.chatMessageType,
        );
      }),
    );
  }
}
