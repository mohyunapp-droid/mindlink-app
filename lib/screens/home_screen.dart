import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
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

  const _FileCard({
    required this.file,
    required this.formatDate,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
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
