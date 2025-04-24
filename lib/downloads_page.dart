import 'package:flutter/material.dart';

class DownloadsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
      ),
      body: const Center(
        child: Text(
          'No downloads yet!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}