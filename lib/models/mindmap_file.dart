import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MindMapFile {
  final String id;
  String name;
  final DateTime createdAt;
  DateTime updatedAt;

  MindMapFile({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  String get storageKey => 'mindlink_nodes_$id';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory MindMapFile.fromJson(Map<String, dynamic> json) => MindMapFile(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  static const _filesKey = 'mindlink_files_v1';

  static Future<List<MindMapFile>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_filesKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => MindMapFile.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAll(List<MindMapFile> files) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_filesKey, jsonEncode(files.map((f) => f.toJson()).toList()));
  }

  static Future<void> deleteFile(MindMapFile file) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(file.storageKey);
    final files = await loadAll();
    files.removeWhere((f) => f.id == file.id);
    await saveAll(files);
  }
}
