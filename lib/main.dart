import 'package:flutter/material.dart';
import 'screens/mindmap_screen.dart';

void main() {
  runApp(const MindLinkApp());
}

class MindLinkApp extends StatelessWidget {
  const MindLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindLink',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const MindMapScreen(),
    );
  }
}
