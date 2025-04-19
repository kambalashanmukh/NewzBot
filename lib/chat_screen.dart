import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  static const String _apiKey = 'AIzaSyBWRr305KeB6DbCmhvhCRIuTuIwkJm1zvw'; // Replace this!

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=$_apiKey"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": text}
              ]
            }
          ],
          "systemInstruction": {
            "parts": [
              {"text": "You are a helpful assistant focused only on news topics not outside news topics."}
            ]
          }
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final content = data['candidates'][0]['content']['parts'][0]['text'];
          setState(() => _messages.add({'role': 'assistant', 'content': content}));
        } else {
          throw Exception('No valid response from API');
        }
      } else {
        throw Exception('API Error: ${data['error']['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant', 
          'content': 'Error: ${e.toString().replaceAll(RegExp(r'^Exception: '), '')}'
        });
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat with NewzBot")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              reverse: true, // New messages at bottom
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages.reversed.toList()[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Align(
                    alignment: message['role'] == 'user' 
                        ? Alignment.centerRight 
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: message['role'] == 'user'
                            ? Colors.blue
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message['content']!,
                        style: TextStyle(
                          color: message['role'] == 'user'
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Ask about news...',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                      ),
                      onSubmitted: (value) => _sendMessageIfValid(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: _isLoading
                        ? const CircularProgressIndicator()
                        : const Icon(Icons.send_rounded),
                    onPressed: _sendMessageIfValid,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessageIfValid() {
    if (_controller.text.trim().isNotEmpty && !_isLoading) {
      sendMessage(_controller.text.trim());
      _controller.clear();
    }
  }
}