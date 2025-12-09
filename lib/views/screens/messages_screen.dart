import 'package:flutter/material.dart';
import 'package:tiktok_tutorial/constants.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text(
          'Messages',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.message_outlined,
              size: 100,
              color: Colors.white54,
            ),
            SizedBox(height: 20),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white54,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Start chatting with your friends!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
