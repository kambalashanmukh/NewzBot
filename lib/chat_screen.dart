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
  final ScrollController _scrollController = ScrollController();

  static const String _apiKey = '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';
  static const String _apiUrl = 'https://api.groq.com/openai/v1/chat/completions';

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "compound-beta",
          "messages": [
            {
              "role": "system",
              "content": "you are a newzbot that provides current news updates only not other information and give summarized answers in 2-3 lines"
            },
            {"role": "user", "content": text}
          ],
          "temperature": 0.7,
          "max_tokens": 1024,
          "stop": null,
          "stream": false
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('choices')) {
          final choices = data['choices'] as List;
          if (choices.isNotEmpty) {
            final firstChoice = choices[0];
            final message = firstChoice['message'] as Map<String, dynamic>;
            final content = message['content'] as String;
            setState(() => _messages.add({
                  'role': 'assistant',
                  'content': content
                }));
          } else {
            throw Exception('No choices available in response');
          }
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('API Error ${response.statusCode}: ${response.body}');
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
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat with NewzBot"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.transparent,
                                child: Image.asset(
                                  'lib/Icons/bot.png',
                                  width: 80,
                                  height: 80,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? const Color.fromARGB(226, 222, 221, 221)
                                      : const Color.fromARGB(223, 46, 46, 46),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Welcome to NewzBot!',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ask me about the latest news topics, and I\'ll provide you with quick and summarized updates.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    reverse: true,
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0 && _isLoading) {
                        return _buildTypingIndicator();
                      }
                      final message = _messages.reversed.toList()[index - (_isLoading ? 1 : 0)];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, String> message) {
    final isUser = message['role'] == 'user';
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.transparent,
                child: Image.asset(
                  'lib/Icons/bot.png',
                  width: 32,
                  height: 32,
                  color: theme.brightness == Brightness.dark
                      ? const Color.fromARGB(226, 222, 221, 221)
                      : const Color.fromARGB(223, 46, 46, 46),
                ),
              ),
            ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? (theme.brightness == Brightness.dark
                        ? Colors.deepPurple[400] // User bubble color in dark mode
                        : theme.primaryColor) // User bubble color in light mode
                    : (theme.brightness == Brightness.dark
                        ? Colors.grey[800] // Assistant bubble color in dark mode
                        : Colors.grey[200]), // Assistant bubble color in light mode
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Text(
                message['content']!,
                style: TextStyle(
                  color: isUser
                      ? Colors.white // User text color
                      : (theme.brightness == Brightness.dark ? Colors.white : Colors.black), // Assistant text color
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.transparent,
              child: Image.asset(
                'lib/Icons/bot.png',
                width: 32,
                height: 32,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color.fromARGB(226, 222, 221, 221)
                    : const Color.fromARGB(223, 46, 46, 46),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ask about current news...',
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  suffixIcon: _isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.primaryColor,
                          ),
                        )
                      : null,
                ),
                onSubmitted: (value) => _sendMessageIfValid(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.brightness == Brightness.dark
                  ? Colors.deepPurple[400] 
                  : Colors.deepPurple[400], 
              child: IconButton(
                icon: Icon(
                  Icons.send_rounded,
                  color: Colors.white, 
                ),
                onPressed: _sendMessageIfValid,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessageIfValid() {
    if (_controller.text.trim().isNotEmpty && !_isLoading) {
      sendMessage(_controller.text.trim());
      _controller.clear();
      _scrollToBottom();
    }
  }
}