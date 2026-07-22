import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mindmap_file.dart';
import 'mindmap_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<MindMapFile> _files = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final files = await MindMapFile.loadAll();
    if (mounted) {
      setState(() {
        _files = files;
        _loading = false;
      });
    }
  }

  Future<void> _createFile() async {
    final nameController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('새 마인드맵'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '파일 이름 입력',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => Navigator.pop(ctx, true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    final now = DateTime.now();
    final file = MindMapFile(
      id: const Uuid().v4(),
      name: name,
      createdAt: now,
      updatedAt: now,
    );

    setState(() => _files.add(file));
    await MindMapFile.saveAll(_files);

    if (!mounted) return;
    _openFile(file);
  }

  void _openFile(MindMapFile file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MindMapScreen(storageKey: file.storageKey),
      ),
    ).then((_) {
      // 돌아왔을 때 수정일 갱신
      setState(() {
        file.updatedAt = DateTime.now();
      });
      MindMapFile.saveAll(_files);
    });
  }

  Future<void> _renameFile(MindMapFile file) async {
    final nameController = TextEditingController(text: file.name);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('이름 변경'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          onSubmitted: (_) => Navigator.pop(ctx, true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => file.name = name);
    await MindMapFile.saveAll(_files);
  }

  Future<void> _exportFile(MindMapFile file) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nodesJson = prefs.getString(file.storageKey) ?? '[]';

      final export = jsonEncode({
        'version': 1,
        'file': file.toJson(),
        'nodes': jsonDecode(nodesJson),
      });

      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('내보내기는 앱에서만 지원됩니다')),
        );
        return;
      }

      final dir = await getTemporaryDirectory();
      final safeName = file.name.replaceAll(RegExp(r'[^\w가-힣]'), '_');
      final path = '${dir.path}/$safeName.mindlink';
      await File(path).writeAsString(export);

      await Share.shareXFiles(
        [XFile(path, mimeType: 'application/json')],
        subject: '${file.name}.mindlink',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('내보내기 실패: $e')),
        );
      }
    }
  }

  Future<void> _importFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mindlink', 'json'],
      );
      if (result == null || result.files.isEmpty) return;

      final bytes = result.files.first.bytes;
      String raw;
      if (bytes != null) {
        raw = utf8.decode(bytes);
      } else {
        final path = result.files.first.path;
        if (path == null) return;
        raw = await File(path).readAsString();
      }

      final data = jsonDecode(raw) as Map<String, dynamic>;
      final fileData = data['file'] as Map<String, dynamic>;
      final nodesData = data['nodes'];

      final now = DateTime.now();
      final newFile = MindMapFile(
        id: const Uuid().v4(),
        name: '${fileData['name']} (가져옴)',
        createdAt: now,
        updatedAt: now,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(newFile.storageKey, jsonEncode(nodesData));

      setState(() => _files.add(newFile));
      await MindMapFile.saveAll(_files);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${newFile.name}" 가져오기 완료')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('가져오기 실패: $e')),
        );
      }
    }
  }

  Future<void> _deleteFile(MindMapFile file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제'),
        content: Text('"${file.name}" 을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await MindMapFile.deleteFile(file);
    setState(() => _files.removeWhere((f) => f.id == file.id));
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: isLight ? const Color(0xFFF3F4F8) : cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'MindLink',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 26,
            color: cs.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: '파일 가져오기',
            onPressed: _importFile,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_tree_outlined,
                          size: 72, color: cs.primary.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        '마인드맵을 만들어보세요',
                        style: TextStyle(
                          fontSize: 17,
                          color: cs.onSurface.withValues(alpha: 0.45),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '아래 + 버튼을 눌러 시작하세요',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _files.length,
                  itemBuilder: (ctx, i) => _FileCard(
                    file: _files[i],
                    formatDate: _formatDate,
                    onTap: () => _openFile(_files[i]),
                    onRename: () => _renameFile(_files[i]),
                    onDelete: () => _deleteFile(_files[i]),
                    onExport: () => _exportFile(_files[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: _createFile,
        child: const Icon(Icons.add_rounded, size: 36),
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  final MindMapFile file;
  final String Function(DateTime) formatDate;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onExport;

  const _FileCard({
    required this.file,
    required this.formatDate,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showOptions(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isLight ? Colors.white : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 컬러 바
            Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [cs.primary, cs.tertiary]),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            // 아이콘 영역
            Expanded(
              child: Center(
                child: Icon(
                  Icons.account_tree_rounded,
                  size: 52,
                  color: cs.primary.withValues(alpha: 0.25),
                ),
              ),
            ),
            // 하단 정보
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    formatDate(file.updatedAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('공유 / 내보내기'),
              subtitle: const Text('Google Drive, Dropbox 등에 저장'),
              onTap: () {
                Navigator.pop(ctx);
                onExport();
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline_rounded),
              title: const Text('이름 변경'),
              onTap: () {
                Navigator.pop(ctx);
                onRename();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('삭제', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
