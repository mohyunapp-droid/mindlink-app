import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class LinkedFile {
  final String id;
  final String name;
  final String path;
  final String extension;
  final Uint8List? bytes;

  LinkedFile({
    required this.id,
    required this.name,
    required this.path,
    required this.extension,
    this.bytes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'path': path,
        'extension': extension,
        // bytes는 저장 안 함 — 대용량 데이터가 SharedPreferences에 쌓이면 iOS 재시작 시 크래시
      };

  factory LinkedFile.fromJson(Map<String, dynamic> json) => LinkedFile(
        id: json['id'] as String,
        name: json['name'] as String,
        path: json['path'] as String,
        extension: json['extension'] as String,
        bytes: null, // 저장하지 않으므로 항상 null
      );
}

class Stroke {
  final Color color;
  final double width;
  final List<Offset> points;

  Stroke({required this.color, required this.width, List<Offset>? points})
      : points = points ?? [];

  Map<String, dynamic> toJson() => {
        'color': color.toARGB32(),
        'width': width,
        'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      };

  factory Stroke.fromJson(Map<String, dynamic> json) => Stroke(
        color: Color(json['color'] as int),
        width: (json['width'] as num).toDouble(),
        points: (json['points'] as List)
            .map((p) => Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble()))
            .toList(),
      );
}

class NoteImage {
  Uint8List bytes;
  Rect rect;

  NoteImage({required this.bytes, required this.rect});

  Map<String, dynamic> toJson() => {
        'bytes': base64Encode(bytes),
        'rect': {'l': rect.left, 't': rect.top, 'w': rect.width, 'h': rect.height},
      };

  factory NoteImage.fromJson(Map<String, dynamic> json) {
    final r = json['rect'] as Map<String, dynamic>;
    return NoteImage(
      bytes: base64Decode(json['bytes'] as String),
      rect: Rect.fromLTWH(
        (r['l'] as num).toDouble(),
        (r['t'] as num).toDouble(),
        (r['w'] as num).toDouble(),
        (r['h'] as num).toDouble(),
      ),
    );
  }
}

class HandwrittenNote {
  final String id;
  String name;
  final List<Stroke> strokes;
  final List<NoteImage> images;

  HandwrittenNote({
    required this.id,
    this.name = '메모',
    List<Stroke>? strokes,
    List<NoteImage>? images,
    Uint8List? backgroundImage,
    Rect? backgroundImageRect,
  })  : strokes = strokes ?? [],
        images = images ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'strokes': strokes.map((s) => s.toJson()).toList(),
        'images': images.map((i) => i.toJson()).toList(),
      };

  factory HandwrittenNote.fromJson(Map<String, dynamic> json) => HandwrittenNote(
        id: json['id'] as String,
        name: json['name'] as String? ?? '메모',
        strokes: (json['strokes'] as List? ?? [])
            .map((s) => Stroke.fromJson(s as Map<String, dynamic>))
            .toList(),
        images: (json['images'] as List? ?? [])
            .map((i) => NoteImage.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
}

class MindNode {
  final String id;
  Offset position;
  String category;
  String? parentId;
  final List<LinkedFile> linkedFiles;
  final List<HandwrittenNote> notes;
  final List<String> connectedNodeIds;
  bool collapsed;
  final List<String> crossLinks;

  MindNode({
    required this.id,
    required this.position,
    this.category = '',
    this.parentId,
    this.collapsed = false,
    List<LinkedFile>? linkedFiles,
    List<HandwrittenNote>? notes,
    List<String>? connectedNodeIds,
    List<String>? crossLinks,
  })  : linkedFiles = linkedFiles ?? [],
        notes = notes ?? [],
        connectedNodeIds = connectedNodeIds ?? [],
        crossLinks = crossLinks ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'x': position.dx,
        'y': position.dy,
        'category': category,
        'parentId': parentId,
        'collapsed': collapsed,
        'linkedFiles': linkedFiles.map((f) => f.toJson()).toList(),
        'notes': notes.map((n) => n.toJson()).toList(),
        'connectedNodeIds': connectedNodeIds,
        'crossLinks': crossLinks,
      };

  factory MindNode.fromJson(Map<String, dynamic> json) => MindNode(
        id: json['id'] as String,
        position: Offset(
          (json['x'] as num).toDouble(),
          (json['y'] as num).toDouble(),
        ),
        category: json['category'] as String? ?? '',
        parentId: json['parentId'] as String?,
        collapsed: json['collapsed'] as bool? ?? false,
        linkedFiles: (json['linkedFiles'] as List? ?? [])
            .map((f) => LinkedFile.fromJson(f as Map<String, dynamic>))
            .toList(),
        notes: (json['notes'] as List? ?? [])
            .map((n) => HandwrittenNote.fromJson(n as Map<String, dynamic>))
            .toList(),
        connectedNodeIds: (json['connectedNodeIds'] as List? ?? [])
            .map((e) => e as String)
            .toList(),
        crossLinks: (json['crossLinks'] as List? ?? [])
            .map((e) => e as String)
            .toList(),
      );
}
