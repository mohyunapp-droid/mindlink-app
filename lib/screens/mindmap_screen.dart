import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/node_model.dart';

const _imageExtensions = {'png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'};

// ── 앱 연결 데이터 ──────────────────────────────────────────
class _AppInfo {
  final String name;
  final String scheme; // URL scheme to launch
  final String emoji;
  final String category;
  const _AppInfo(this.name, this.scheme, this.emoji, this.category);
}

const _kApps = [
  // SNS / 메신저
  _AppInfo('카카오톡', 'kakaotalk://', '💬', 'SNS'),
  _AppInfo('인스타그램', 'instagram://', '📸', 'SNS'),
  _AppInfo('네이버 밴드', 'bandapp://', '📣', 'SNS'),
  _AppInfo('트위터(X)', 'twitter://', '🐦', 'SNS'),
  _AppInfo('페이스북', 'fb://', '👤', 'SNS'),
  _AppInfo('라인', 'line://', '💚', 'SNS'),
  _AppInfo('텔레그램', 'tg://', '✈️', 'SNS'),
  _AppInfo('디스코드', 'discord://', '🎮', 'SNS'),
  _AppInfo('슬랙', 'slack://', '🔷', 'SNS'),
  // 생산성
  _AppInfo('Notion', 'notion://', '📝', '생산성'),
  _AppInfo('Obsidian', 'obsidian://', '🔮', '생산성'),
  _AppInfo('GoodNotes', 'goodnotes5://', '🖊️', '생산성'),
  _AppInfo('Notability', 'notability://', '📒', '생산성'),
  _AppInfo('Procreate', 'procreate://', '🎨', '생산성'),
  _AppInfo('Pages', 'ms-word://', '📄', '생산성'),
  _AppInfo('Numbers', 'ms-excel://', '📊', '생산성'),
  _AppInfo('Keynote', 'ms-powerpoint://', '📑', '생산성'),
  _AppInfo('Microsoft Word', 'ms-word://', '📘', '생산성'),
  _AppInfo('Microsoft Excel', 'ms-excel://', '📗', '생산성'),
  _AppInfo('Microsoft PowerPoint', 'ms-powerpoint://', '📙', '생산성'),
  _AppInfo('Google Drive', 'googledrive://', '☁️', '생산성'),
  _AppInfo('Google Docs', 'googledocs://', '📃', '생산성'),
  _AppInfo('Dropbox', 'dbapi-2://', '📦', '생산성'),
  _AppInfo('Bear', 'bear://', '🐻', '생산성'),
  _AppInfo('Evernote', 'evernote://', '🐘', '생산성'),
  _AppInfo('Things 3', 'things://', '✅', '생산성'),
  _AppInfo('Todoist', 'todoist://', '🔴', '생산성'),
  // 미디어
  _AppInfo('유튜브', 'youtube://', '▶️', '미디어'),
  _AppInfo('넷플릭스', 'nflx://', '🎬', '미디어'),
  _AppInfo('티빙', 'tving://', '📺', '미디어'),
  _AppInfo('웨이브', 'wavve://', '🌊', '미디어'),
  _AppInfo('왓챠', 'watcha://', '🎥', '미디어'),
  _AppInfo('멜론', 'melon://', '🍈', '미디어'),
  _AppInfo('지니뮤직', 'genie://', '🎵', '미디어'),
  _AppInfo('Spotify', 'spotify://', '🟢', '미디어'),
  _AppInfo('Apple Music', 'music://', '🎶', '미디어'),
  _AppInfo('팟캐스트', 'pcast://', '🎙️', '미디어'),
  _AppInfo('카카오TV', 'kakaolink://', '🟡', '미디어'),
  // 교육
  _AppInfo('클래스101', 'class101://', '🎓', '교육'),
  _AppInfo('강남인강', 'ebs://', '📚', '교육'),
  _AppInfo('Khan Academy', 'khanacademy://', '🏫', '교육'),
  _AppInfo('Duolingo', 'duolingo://', '🦜', '교육'),
  _AppInfo('Coursera', 'coursera://', '🎒', '교육'),
  // 쇼핑 / 금융
  _AppInfo('쿠팡', 'coupang://', '🛍️', '쇼핑/금융'),
  _AppInfo('네이버 쇼핑', 'navershopping://', '🏪', '쇼핑/금융'),
  _AppInfo('당근마켓', 'daangn://', '🥕', '쇼핑/금융'),
  _AppInfo('카카오페이', 'kakaopay://', '💳', '쇼핑/금융'),
  _AppInfo('토스', 'supertoss://', '💸', '쇼핑/금융'),
  _AppInfo('네이버페이', 'naverpay://', '💰', '쇼핑/금융'),
  // 지도 / 교통
  _AppInfo('카카오맵', 'kakaomap://', '🗺️', '지도/교통'),
  _AppInfo('네이버지도', 'nmap://', '📍', '지도/교통'),
  _AppInfo('구글맵', 'comgooglemaps://', '🌍', '지도/교통'),
  _AppInfo('카카오T', 'kakaot://', '🚖', '지도/교통'),
  _AppInfo('티맵', 'tmap://', '🚗', '지도/교통'),
  _AppInfo('국내 지하철', 'korail://', '🚇', '지도/교통'),
  // 건강
  _AppInfo('건강(Apple Health)', 'x-apple-health://', '❤️', '건강'),
  _AppInfo('나이키런', 'nikerunning://', '👟', '건강'),
  _AppInfo('눔(Noom)', 'noom://', '⚖️', '건강'),
  // 기타 / 시스템
  _AppInfo('사파리', 'https://', '🧭', '기타'),
  _AppInfo('앱스토어', 'itms-apps://', '🍎', '기타'),
  _AppInfo('설정', 'App-prefs://', '⚙️', '기타'),
  _AppInfo('카메라', 'camera://', '📷', '기타'),
  _AppInfo('계산기', 'calc://', '🔢', '기타'),
];

const _uuid = Uuid();

// Matches the node card's footprint (see _NodeWidget's 120-wide card) so the
// push-apart math below can compute exactly where its edge is.
const double _nodeHalfWidth = 60;
const double _nodeHalfHeight = 45;

// Desired gap between card edges after a newly-attached node is nudged away
// from the node it was dropped onto: half the node's width.
const double _nodeHalfSpacing = _nodeHalfWidth;

// Distance from a node's center to its rectangular edge along [direction]
// (must be a unit vector).
double _rectEdgeDistance(Offset direction) {
  final dx = direction.dx.abs();
  final dy = direction.dy.abs();
  if (dx < 1e-6) return _nodeHalfHeight;
  if (dy < 1e-6) return _nodeHalfWidth;
  return [_nodeHalfWidth / dx, _nodeHalfHeight / dy].reduce((a, b) => a < b ? a : b);
}

// Shared spacing used by both the per-node horizontal-tree alignment and the
// start button's top-level vertical alignment, so the two stay visually
// consistent and bands computed for one don't overlap layout from the other.
const double _treeColSpacing = 160.0;
// Spacing between sibling nodes that share the same top-level ancestor.
const double _treeRowSpacing = 140.0;
// Extra gap reserved between two different top-level branches, on top of
// each branch's own row spacing, so unrelated branches don't touch.
const double _treeBranchGap = 140.0;

const double _canvasExtent = 100000;
const Offset _canvasCenter = Offset(_canvasExtent / 2, _canvasExtent / 2);

class MindMapScreen extends StatefulWidget {
  final String storageKey;
  const MindMapScreen({super.key, this.storageKey = 'mindlink_nodes_v1'});

  @override
  State<MindMapScreen> createState() => _MindMapScreenState();
}

class _MindMapScreenState extends State<MindMapScreen> with SingleTickerProviderStateMixin {
  final List<MindNode> _nodes = [];
  final GlobalKey _canvasKey = GlobalKey();
  final TransformationController _transformController = TransformationController();
  bool _viewCentered = false;
  bool _canvasPanEnabled = true;
  Size _viewportSize = Size.zero;

  late final AnimationController _focusAnimController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  Animation<Matrix4>? _focusAnimation;

  // 노드 도착 강조 (펄스)
  String? _highlightedNodeId;
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  late final Animation<double> _pulseAnim = CurvedAnimation(
    parent: _pulseController,
    curve: Curves.easeInOut,
  );

  void _setCanvasPanEnabled(bool enabled) {
    if (_canvasPanEnabled == enabled) return;
    setState(() => _canvasPanEnabled = enabled);
  }

  void _focusOn(Offset canvasPoint) {
    if (_viewportSize.width == 0 || _viewportSize.height == 0) return;

    final tx = _viewportSize.width / 2 - canvasPoint.dx;
    final ty = _viewportSize.height / 2 - canvasPoint.dy;
    final targetMatrix = Matrix4.identity()..translateByDouble(tx, ty, 0, 1);

    _focusAnimation = Matrix4Tween(
      begin: _transformController.value.clone(),
      end: targetMatrix,
    ).animate(CurvedAnimation(parent: _focusAnimController, curve: Curves.easeInOutCubic))
      ..addListener(() {
        _transformController.value = _focusAnimation!.value;
      });

    _focusAnimController.forward(from: 0);
  }

  void _goHome() => _focusOn(_canvasCenter);

  void _focusOnNode(MindNode target) {
    _focusOn(target.position);
    // 이동 애니메이션 끝난 뒤 펄스 시작
    Future.delayed(const Duration(milliseconds: 480), () {
      if (!mounted) return;
      setState(() => _highlightedNodeId = target.id);
      _pulseController.forward(from: 0).then((_) {
        if (!mounted) return;
        // 한 번 더 역방향으로 fade out
        _pulseController.reverse().then((_) {
          if (!mounted) return;
          setState(() => _highlightedNodeId = null);
        });
      });
    });
  }

  void _zoomBy(double factor) {
    if (_viewportSize.width == 0 || _viewportSize.height == 0) return;
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    final newScale = (currentScale * factor).clamp(0.4, 2.5);
    final focal = Offset(_viewportSize.width / 2, _viewportSize.height / 2);
    final scenePoint = _transformController.toScene(focal);
    final targetMatrix = Matrix4.identity()
      ..translateByDouble(focal.dx, focal.dy, 0, 1)
      ..scaleByDouble(newScale, newScale, newScale, 1)
      ..translateByDouble(-scenePoint.dx, -scenePoint.dy, 0, 1);
    _focusAnimation = Matrix4Tween(
      begin: _transformController.value.clone(),
      end: targetMatrix,
    ).animate(CurvedAnimation(parent: _focusAnimController, curve: Curves.easeInOutCubic))
      ..addListener(() {
        _transformController.value = _focusAnimation!.value;
      });
    _focusAnimController.forward(from: 0);
  }

  Future<void> _openSearch() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('노드 검색'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '카테고리 이름으로 찾기'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('찾기'),
          ),
        ],
      ),
    );

    if (result == null || result.trim().isEmpty) return;

    final query = result.trim().toLowerCase();
    final matches = _nodes.where((n) => n.category.toLowerCase().contains(query));
    final match = matches.isEmpty ? null : matches.first;

    if (!mounted) return;
    if (match == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$result"와 일치하는 노드를 찾지 못했습니다')),
      );
      return;
    }

    _focusOn(match.position);
  }

  String get _kStorageKey => widget.storageKey;

  @override
  void initState() {
    super.initState();
    _loadNodes();
  }

  Future<void> _loadNodes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kStorageKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      final loaded = list.map((e) => MindNode.fromJson(e as Map<String, dynamic>)).toList();
      if (mounted) setState(() { _nodes.addAll(loaded); });
    } catch (e) {
      // 데이터 파싱 실패 시 초기화해서 무한 크래시 방지
      await prefs.remove(_kStorageKey);
    }
  }

  Future<void> _saveNodes() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_nodes.map((n) => n.toJson()).toList());
    await prefs.setString(_kStorageKey, encoded);
  }

  @override
  void dispose() {
    _saveNodes(); // 화면 나갈 때 안전망 저장
    _transformController.dispose();
    _focusAnimController.dispose();
    _pulseController.dispose();
    _hoverTimer?.cancel();
    super.dispose();
  }

  Offset _localFromGlobal(Offset globalPosition) {
    final renderBox =
        _canvasKey.currentContext!.findRenderObject() as RenderBox;
    return renderBox.globalToLocal(globalPosition);
  }

  void _createNodeAt(Offset globalPosition, {String? parentId}) {
    final localPosition = _localFromGlobal(globalPosition);

    final node = MindNode(
      id: _uuid.v4(),
      position: localPosition,
      parentId: parentId,
    );
    setState(() => _nodes.add(node));

    _openCategoryDialog(node);
  }

  Future<void> _openCategoryDialog(MindNode node) async {
    final controller = TextEditingController(text: node.category);

    while (true) {
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          title: const Text('카테고리 입력'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: '예: 회의자료, 여행사진'),
            onSubmitted: (value) => Navigator.pop(context, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('확인'),
            ),
          ],
        ),
      );

      if (result == null) return;

      final trimmed = result.trim();
      final isDuplicate = _nodes.any(
        (n) => n.id != node.id && n.category.trim() == trimmed,
      );

      if (isDuplicate) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('중복된 이름'),
            content: const Text('이미 같은 이름의 노드가 존재합니다.\n다른 이름을 입력해주세요.'),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
        );
        // 확인 후 다시 입력 다이얼로그로 돌아감
        continue;
      }

      setState(() => node.category = trimmed.isEmpty ? result : trimmed);
      _saveNodes();
      return;
    }
  }

  void _openConnectSheet(MindNode node) {
    _closeFilePanel();
    _closeNotesPanel();
    _closeCrossLinkPanel();
    _showConnectPanel(node);
  }

  Future<void> _addYoutubeLinkForNode(MindNode node) async {
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('유튜브 링크 추가'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'https://youtube.com/watch?v=...'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('추가'),
          ),
        ],
      ),
    );

    if (url == null) return;
    final trimmed = url.trim();
    final uri = Uri.tryParse(trimmed);
    if (trimmed.isEmpty || uri == null || !uri.hasScheme) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('올바른 링크를 입력해주세요')),
        );
      }
      return;
    }

    setState(() {
      node.linkedFiles.add(
        LinkedFile(
          id: _uuid.v4(),
          name: trimmed,
          path: trimmed,
          extension: 'youtube',
        ),
      );
    });
    _saveNodes();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('유튜브 링크가 연결됨')),
      );
    }
  }

  Future<void> _addAppLinkForNode(MindNode node) async {
    final app = await showDialog<_AppInfo>(
      context: context,
      builder: (ctx) => const _AppPickerDialog(),
    );
    if (app == null || !mounted) return;
    setState(() {
      node.linkedFiles.add(LinkedFile(
        id: _uuid.v4(),
        name: app.name,
        path: app.scheme,
        extension: 'app',
      ));
    });
    _saveNodes();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${app.name}" 앱 연결됨')),
      );
    }
  }

  void _openNotesList(MindNode node) {
    _closeFilePanel();
    _closeCrossLinkPanel();
    _showNotesPanel(node);
  }

  Future<void> _openNoteEditor(MindNode node, HandwrittenNote? existing) async {
    final result = await Navigator.of(context).push<(
      {
        List<Stroke> strokes,
        String name,
        List<NoteImage> images,
      }
    )>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _NoteEditorScreen(
          initialStrokes: existing?.strokes,
          initialName: existing?.name ?? '메모 ${node.notes.length + 1}',
          initialImages: existing?.images,
        ),
      ),
    );
    if (result == null || !mounted) return;

    setState(() {
      if (existing != null) {
        existing.name = result.name;
        existing.images
          ..clear()
          ..addAll(result.images);
        existing.strokes
          ..clear()
          ..addAll(result.strokes);
      } else {
        node.notes.add(
          HandwrittenNote(
            id: _uuid.v4(),
            name: result.name,
            strokes: result.strokes,
            images: result.images,
          ),
        );
      }
    });
    _saveNodes();
  }

  Future<void> _pickFileForNode(MindNode node) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('파일 선택이 취소되었습니다')),
          );
        }
        return;
      }

      final file = result.files.first;
      if (!mounted) return;
      setState(() {
        node.linkedFiles.add(
          LinkedFile(
            id: _uuid.v4(),
            name: file.name,
            path: kIsWeb ? '' : (file.path ?? ''),
            extension: file.extension ?? '',
            bytes: file.bytes,
          ),
        );
      });
      _saveNodes();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${file.name}" 연결됨')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파일 연결 실패: $e')),
        );
      }
    }
  }

  MindNode? _hoverTarget;
  Timer? _hoverTimer;
  final Set<String> _selectedNodeIds = {};
  Set<String> _draggingNodeIds = {};

  List<MindNode> get _nodesInDrawOrder {
    if (_draggingNodeIds.isEmpty) return _nodes;
    final dragging = _nodes.where((n) => _draggingNodeIds.contains(n.id));
    final rest = _nodes.where((n) => !_draggingNodeIds.contains(n.id));
    return [...rest, ...dragging];
  }

  void _startNodeDrag(MindNode node) {
    _setCanvasPanEnabled(false);
    final ids = _selectedNodeIds.contains(node.id) && _selectedNodeIds.length > 1
        ? _selectedNodeIds
        : {node.id};
    setState(() => _draggingNodeIds = ids.toSet());
  }

  Rect _nodeRect(MindNode node) =>
      Rect.fromCenter(center: node.position, width: 120, height: 90);

  bool _isAncestorOf(MindNode possibleAncestor, MindNode node) {
    var parentId = node.parentId;
    while (parentId != null) {
      if (parentId == possibleAncestor.id) return true;
      final parent = _nodeById(parentId);
      if (parent == null) break;
      parentId = parent.parentId;
    }
    return false;
  }

  // 박스 선택
  Offset? _boxSelectStart;
  Offset? _boxSelectEnd;

  void _toggleSelect(MindNode node) {
    setState(() {
      if (_selectedNodeIds.contains(node.id)) {
        _selectedNodeIds.remove(node.id);
      } else {
        _selectedNodeIds.add(node.id);
      }
    });
  }

  void _enterSelectMode(MindNode node) {
    setState(() {
      _selectedNodeIds.clear();
      _selectedNodeIds.add(node.id);
    });
  }

  void _exitSelectMode() {
    setState(() {
      _selectedNodeIds.clear();
      _boxSelectStart = null;
      _boxSelectEnd = null;
    });
  }

  void _applyBorderColor(Color? color) {
    setState(() {
      for (final node in _nodes.where((n) => _selectedNodeIds.contains(n.id))) {
        node.borderColor = color;
      }
    });
    _saveNodes();
  }

  void _applyBackgroundColor(Color? color) {
    setState(() {
      for (final node in _nodes.where((n) => _selectedNodeIds.contains(n.id))) {
        node.backgroundColor = color;
      }
    });
    _saveNodes();
  }

  void _applyBoxSelect(Rect box) {
    setState(() {
      _selectedNodeIds.clear();
      for (final node in _nodes) {
        if (box.overlaps(_nodeRect(node))) {
          _selectedNodeIds.add(node.id);
        }
      }
    });
  }

  void _moveNode(MindNode node, Offset delta) {
    setState(() {
      if (_selectedNodeIds.contains(node.id) && _selectedNodeIds.length > 1) {
        for (final id in _selectedNodeIds) {
          _nodeById(id)?.position += delta;
        }
      } else {
        node.position += delta;
      }
    });
    _updateHoverTarget(node);
  }

  void _updateHoverTarget(MindNode draggedNode) {
    final isGroupDrag =
        _selectedNodeIds.contains(draggedNode.id) && _selectedNodeIds.length > 1;
    final groupIds = isGroupDrag ? _selectedNodeIds : {draggedNode.id};

    MindNode? candidate;
    for (final other in _nodes) {
      if (other.id == draggedNode.id) continue;
      if (isGroupDrag && _selectedNodeIds.contains(other.id)) continue;
      final isDescendantOfGroup = groupIds.any((id) {
        final groupNode = _nodeById(id);
        return groupNode != null && _isAncestorOf(groupNode, other);
      });
      if (isDescendantOfGroup) continue;
      if (_nodeRect(draggedNode).overlaps(_nodeRect(other))) {
        candidate = other;
        break;
      }
    }

    // 겹치는 즉시 하이라이트 표시 (타이머 없음)
    if (candidate?.id != _hoverTarget?.id) {
      _hoverTimer?.cancel();
      _hoverTimer = null;
      setState(() => _hoverTarget = candidate);
    }
  }

  void _finishNodeDrag(MindNode node) {
    _hoverTimer?.cancel();
    _hoverTimer = null;

    final target = _hoverTarget;
    if (target == null) return;

    final isGroupDrag =
        _selectedNodeIds.contains(node.id) && _selectedNodeIds.length > 1;
    final groupIds = isGroupDrag ? _selectedNodeIds.toSet() : {node.id};

    if (target.id == node.id || groupIds.contains(target.id)) {
      setState(() => _hoverTarget = null);
      return;
    }

    setState(() {
      final oldParents = <String, String?>{
        for (final id in groupIds) id: _nodeById(id)?.parentId,
      };

      // Reattach children of moved nodes (that aren't themselves part of the
      // move) to the moved node's old parent, so the chain doesn't break.
      for (final other in _nodes) {
        if (groupIds.contains(other.id)) continue;
        if (other.parentId != null && groupIds.contains(other.parentId)) {
          other.parentId = oldParents[other.parentId];
        }
      }

      // Only the top-level moved nodes (whose parent isn't also being moved)
      // attach to the new target; internal relationships stay intact.
      // Each one is nudged away from the target (in the direction it was
      // dropped from) by half a node's size, so it doesn't render on top of
      // the target; the rest of its subtree shifts by the same amount to
      // keep their relative layout.
      final pushDeltas = <String, Offset>{};
      for (final id in groupIds) {
        final moved = _nodeById(id);
        if (moved == null) continue;
        if (moved.parentId != null && groupIds.contains(moved.parentId)) continue;

        moved.parentId = target.id;
        final diff = moved.position - target.position;
        final dist = diff.distance;
        final direction = dist > 1 ? diff / dist : const Offset(0, 1);
        final pushDistance = _rectEdgeDistance(direction) +
            _nodeHalfSpacing +
            _rectEdgeDistance(direction);
        final newPosition = target.position + direction * pushDistance;
        pushDeltas[id] = newPosition - moved.position;
        moved.position = newPosition;
      }
      for (final id in groupIds) {
        if (pushDeltas.containsKey(id)) continue;
        final moved = _nodeById(id);
        if (moved == null) continue;
        final rootId = _groupRootId(id, groupIds);
        final delta = pushDeltas[rootId];
        if (delta != null) moved.position += delta;
      }

      _hoverTarget = null;
    });
    // 드롭 후 선택 해제 (다음 동작을 위해)
    setState(() => _selectedNodeIds.clear());
  }

  String _groupRootId(String id, Set<String> groupIds) {
    var current = id;
    while (true) {
      final node = _nodeById(current);
      if (node?.parentId == null || !groupIds.contains(node!.parentId)) {
        return current;
      }
      current = node.parentId!;
    }
  }

  // Lays out every descendant of [root] as a horizontal tree: each
  // generation forms its own column to the right, and separate branches are
  // spread out vertically so they don't cross or overlap one another.
  void _alignDescendantsHorizontally(MindNode root) {
    final childrenOf = <String, List<MindNode>>{};
    for (final n in _nodes) {
      final parentId = n.parentId;
      if (parentId != null) {
        childrenOf.putIfAbsent(parentId, () => []).add(n);
      }
    }
    for (final children in childrenOf.values) {
      children.sort((a, b) => a.position.dy.compareTo(b.position.dy));
    }

    final rootChildren = childrenOf[root.id];
    if (rootChildren == null || rootChildren.isEmpty) return;

    var nextSlot = 0;
    final updates = <MindNode, Offset>{};

    // Positions [node]'s whole subtree; returns the Y it ends up at (the
    // average of its children's Y, or its own row slot if it's a leaf).
    double layout(MindNode node, int depth) {
      final children = childrenOf[node.id];
      double y;
      if (children == null || children.isEmpty) {
        y = (nextSlot++) * _treeRowSpacing;
      } else {
        final childYs = [for (final child in children) layout(child, depth + 1)];
        y = childYs.reduce((a, b) => a + b) / childYs.length;
      }
      updates[node] = Offset(root.position.dx + depth * _treeColSpacing, y);
      return y;
    }

    for (final child in rootChildren) {
      layout(child, 1);
    }

    final ys = updates.values.map((o) => o.dy);
    final centerOffset = root.position.dy - (ys.reduce((a, b) => a + b) / ys.length);

    setState(() {
      for (final entry in updates.entries) {
        entry.key.position = Offset(entry.value.dx, entry.value.dy + centerOffset);
      }
    });
  }

  int _countLeaves(MindNode node, Map<String, List<MindNode>> childrenOf) {
    final children = childrenOf[node.id];
    if (children == null || children.isEmpty) return 1;
    return children.fold(0, (sum, child) => sum + _countLeaves(child, childrenOf));
  }

  // Arranges all top-level nodes (the ones directly connected to the start
  // button) in a non-overlapping vertical column to the right of the start
  // button, then re-runs the horizontal-tree alignment for each one's own
  // subtree so the whole map stays tidy.
  void _alignTopLevelNodesVertically() {
    final topLevel = _nodes.where((n) => n.parentId == null).toList()
      ..sort((a, b) => a.position.dy.compareTo(b.position.dy));
    if (topLevel.isEmpty) return;

    final childrenOf = <String, List<MindNode>>{};
    for (final n in _nodes) {
      final parentId = n.parentId;
      if (parentId != null) {
        childrenOf.putIfAbsent(parentId, () => []).add(n);
      }
    }

    final leafCounts = [for (final root in topLevel) _countLeaves(root, childrenOf)];
    final bandHeights = [for (final count in leafCounts) count * _treeRowSpacing];
    final totalHeight = bandHeights.fold(0.0, (sum, h) => sum + h) +
        _treeBranchGap * (topLevel.length - 1);
    final x = _canvasCenter.dx + _treeColSpacing;

    var cursorY = _canvasCenter.dy - totalHeight / 2;
    setState(() {
      for (var i = 0; i < topLevel.length; i++) {
        final bandHeight = bandHeights[i];
        topLevel[i].position = Offset(x, cursorY + bandHeight / 2);
        cursorY += bandHeight + _treeBranchGap;
      }
    });

    for (final root in topLevel) {
      _alignDescendantsHorizontally(root);
    }
    _saveNodes();
  }

  void _toggleCollapse(MindNode node) {
    setState(() => node.collapsed = !node.collapsed);
  }

  void _sortChildrenAlphabetically(MindNode node) {
    final children = _nodes.where((n) => n.parentId == node.id).toList();
    if (children.length < 2) return;
    final sortedYs = children.map((c) => c.position.dy).toList()..sort();
    children.sort((a, b) => a.category.compareTo(b.category));
    setState(() {
      for (var i = 0; i < children.length; i++) {
        final delta = Offset(0, sortedYs[i] - children[i].position.dy);
        _shiftSubtree(children[i], delta);
      }
    });
    _saveNodes();
  }

  void _shiftSubtree(MindNode node, Offset delta) {
    node.position += delta;
    for (final child in _nodes.where((n) => n.parentId == node.id)) {
      _shiftSubtree(child, delta);
    }
  }

  Future<void> _confirmDeleteNode(MindNode node) async {
    final name = node.category.trim().isEmpty ? '이름 없음' : node.category;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('노드 삭제'),
        content: Text('"$name" 노드를 삭제할까요?\n하위 노드가 있으면 상위 노드에 자동 연결됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      // 하위 노드를 삭제 노드의 상위 노드에 연결
      for (final child in _nodes.where((n) => n.parentId == node.id)) {
        child.parentId = node.parentId;
      }
      // 다른 노드의 crossLinks에서 제거
      for (final other in _nodes) {
        other.crossLinks.remove(node.id);
      }
      // 열려있는 패널 정리
      if (_filePanelNode?.id == node.id) _filePanelNode = null;
      if (_crossLinkPanelNode?.id == node.id) _crossLinkPanelNode = null;
      if (_notesPanelNode?.id == node.id) _notesPanelNode = null;
      if (_connectPanelNode?.id == node.id) _connectPanelNode = null;
      _nodes.remove(node);
    });
    _saveNodes();
  }

  MindNode? _nodeById(String id) {
    for (final node in _nodes) {
      if (node.id == id) return node;
    }
    return null;
  }

  bool _isHiddenByCollapse(MindNode node) {
    var parentId = node.parentId;
    while (parentId != null) {
      final parent = _nodeById(parentId);
      if (parent == null) return false;
      if (parent.collapsed) return true;
      parentId = parent.parentId;
    }
    return false;
  }

  Offset _foldTargetPosition(MindNode node) {
    var parentId = node.parentId;
    while (parentId != null) {
      final parent = _nodeById(parentId);
      if (parent == null) break;
      if (parent.collapsed) return parent.position;
      parentId = parent.parentId;
    }
    return node.position;
  }

  Future<void> _searchAndLinkNode(MindNode source) async {
    final candidates = _nodes
        .where((n) => n.id != source.id && !source.crossLinks.contains(n.id))
        .toList();

    final result = await showDialog<MindNode>(
      context: context,
      builder: (context) => _NodeSearchDialog(nodes: candidates),
    );
    if (result == null || !mounted) return;

    setState(() {
      if (!source.crossLinks.contains(result.id)) {
        source.crossLinks.add(result.id);
      }
      if (!result.crossLinks.contains(source.id)) {
        result.crossLinks.add(source.id);
      }
    });
    _saveNodes();
  }

  MindNode? _crossLinkPanelNode;

  void _showCrossLinkPanel(MindNode node) {
    setState(() => _crossLinkPanelNode = node);
  }

  void _closeCrossLinkPanel() {
    if (_crossLinkPanelNode == null) return;
    setState(() => _crossLinkPanelNode = null);
  }

  MindNode? _filePanelNode;
  LinkedFile? _previewFile;
  MindNode? _notesPanelNode;
  MindNode? _connectPanelNode;

  void _showFilePanel(MindNode node) {
    setState(() {
      _filePanelNode = node;
      _previewFile = null;
    });
  }

  void _closeFilePanel() {
    if (_filePanelNode == null) return;
    setState(() {
      _filePanelNode = null;
      _previewFile = null;
    });
  }

  void _showNotesPanel(MindNode node) {
    setState(() => _notesPanelNode = node);
  }

  void _closeNotesPanel() {
    if (_notesPanelNode == null) return;
    setState(() => _notesPanelNode = null);
  }

  void _showConnectPanel(MindNode node) {
    setState(() => _connectPanelNode = node);
  }

  void _closeConnectPanel() {
    if (_connectPanelNode == null) return;
    setState(() => _connectPanelNode = null);
  }

  void _showFilePreview(LinkedFile file) {
    if (file.extension == 'app') {
      _launchAppLink(file);
      return;
    }
    setState(() => _previewFile = file);
  }

  Future<void> _launchAppLink(LinkedFile file) async {
    final uri = Uri.tryParse(file.path);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${file.name}" 앱을 열 수 없습니다. 앱이 설치되어 있는지 확인하세요.')),
        );
      }
    }
  }

  double _clampLeft(double desired, {required double panelWidth}) {
    return desired.clamp(0, (_canvasExtent - panelWidth).clamp(0, double.infinity));
  }

  double _clampTop(double desired, {required double panelHeight}) {
    return desired.clamp(0, (_canvasExtent - panelHeight).clamp(0, double.infinity));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12132A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('MindLink', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'zoom_in',
            onPressed: () => _zoomBy(1.25),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'zoom_out',
            onPressed: () => _zoomBy(0.8),
            child: const Icon(Icons.remove),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 0 && constraints.maxHeight > 0) {
            _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
          }

          if (!_viewCentered && constraints.maxWidth > 0 && constraints.maxHeight > 0) {
            _viewCentered = true;
            final viewportWidth = constraints.maxWidth;
            final viewportHeight = constraints.maxHeight;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final dx = _canvasCenter.dx - viewportWidth / 2;
              final dy = _canvasCenter.dy - viewportHeight / 2;
              _transformController.value = Matrix4.identity()..translateByDouble(-dx, -dy, 0, 1);
            });
          }

          return Stack(
            children: [
              InteractiveViewer(
            transformationController: _transformController,
            panEnabled: _canvasPanEnabled,
            scaleEnabled: true,
            minScale: 0.4,
            maxScale: 2.5,
            trackpadScrollCausesScale: true,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(1000),
            child: SizedBox(
              width: _canvasExtent,
              height: _canvasExtent,
              child: DragTarget<String>(
                onAcceptWithDetails: (details) {
                  if (details.data.startsWith('child:')) {
                    _createNodeAt(
                      details.offset,
                      parentId: details.data.substring('child:'.length),
                    );
                  } else {
                    _createNodeAt(details.offset);
                  }
                },
                builder: (context, candidateData, rejectedData) {
                  return GestureDetector(
                    onTap: () {
                      _closeFilePanel();
                      _closeCrossLinkPanel();
                      _closeNotesPanel();
                      _closeConnectPanel();
                      if (_selectedNodeIds.isNotEmpty) {
                        _exitSelectMode();
                      }
                    },
                    onDoubleTapDown: (details) => _focusOn(details.localPosition),
                    onPanStart: _selectedNodeIds.isNotEmpty ? (details) {
                      setState(() {
                        _boxSelectStart = details.localPosition;
                        _boxSelectEnd = details.localPosition;
                      });
                    } : null,
                    onPanUpdate: _selectedNodeIds.isNotEmpty ? (details) {
                      setState(() => _boxSelectEnd = details.localPosition);
                    } : null,
                    onPanEnd: _selectedNodeIds.isNotEmpty ? (_) {
                      if (_boxSelectStart != null && _boxSelectEnd != null) {
                        _applyBoxSelect(Rect.fromPoints(_boxSelectStart!, _boxSelectEnd!));
                      }
                      setState(() {
                        _boxSelectStart = null;
                        _boxSelectEnd = null;
                      });
                    } : null,
                    child: SizedBox(
                      key: _canvasKey,
                      width: _canvasExtent,
                      height: _canvasExtent,
                      child: Stack(
                        children: [
                          // A4 페이지 배경
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _PageBackgroundPainter(),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _EdgePainter(
                                  edges: [
                                    for (final node in _nodes)
                                      if (!_isHiddenByCollapse(node))
                                        (
                                          from: node.parentId == null
                                              ? _canvasCenter
                                              : _nodes
                                                  .firstWhere((n) => n.id == node.parentId)
                                                  .position,
                                          to: node.position,
                                        ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          for (final node in _nodesInDrawOrder)
                            AnimatedPositioned(
                              key: ValueKey(node.id),
                              duration: _isHiddenByCollapse(node)
                                  ? const Duration(milliseconds: 350)
                                  : Duration.zero,
                              curve: Curves.easeInOut,
                              left: (_isHiddenByCollapse(node)
                                      ? _foldTargetPosition(node)
                                      : node.position)
                                  .dx -
                                  64,
                              top: (_isHiddenByCollapse(node)
                                      ? _foldTargetPosition(node)
                                      : node.position)
                                  .dy -
                                  30,
                              child: IgnorePointer(
                                ignoring: _isHiddenByCollapse(node),
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 350),
                                  opacity: _isHiddenByCollapse(node) ? 0 : 1,
                                  child: AnimatedScale(
                                    duration: const Duration(milliseconds: 350),
                                    scale: _isHiddenByCollapse(node) ? 0.2 : 1,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        _NodeWidget(
                                node: node,
                                onTap: () => _selectedNodeIds.isNotEmpty
                                    ? _toggleSelect(node)
                                    : _openCategoryDialog(node),
                                onConnectTap: () => _openConnectSheet(node),
                                onDragUpdate: (delta) => _moveNode(node, delta),
                                onDragStart: () => _setCanvasPanEnabled(false),
                                onDragEnd: () => _setCanvasPanEnabled(true),
                                onMoveStart: () => _startNodeDrag(node),
                                onMoveEnd: () {
                                  _setCanvasPanEnabled(true);
                                  setState(() => _draggingNodeIds = {});
                                  _finishNodeDrag(node);
                                  _saveNodes();
                                },
                                onDoubleTap: () => _enterSelectMode(node),
                                onFilesLongPress: () => _showFilePanel(node),
                                onNotesTap: () => _openNotesList(node),
                                onHomeTap: _goHome,
                                onToggleCollapse: () => _toggleCollapse(node),
                                onAlignTap: () { _alignDescendantsHorizontally(node); _saveNodes(); },
                                onSortTap: () => _sortChildrenAlphabetically(node),
                                onCrossLinkTap: () => _searchAndLinkNode(node),
                                onCrossLinkNodesTap: () => _showCrossLinkPanel(node),
                                onDeleteTap: () => _confirmDeleteNode(node),
                                crossLinkedNodes: [
                                  for (final id in node.crossLinks)
                                    if (_nodeById(id) != null) _nodeById(id)!,
                                ],
                                isHighlighted: _hoverTarget?.id == node.id,
                                isSelected: _selectedNodeIds.contains(node.id),
                                isSelectMode: _selectedNodeIds.isNotEmpty,
                                onSelectIconTap: () {
                                  if (_selectedNodeIds.isEmpty) {
                                    _enterSelectMode(node);
                                  } else {
                                    _toggleSelect(node);
                                  }
                                },
                                        ),
                                        if (_highlightedNodeId == node.id)
                                          Positioned.fill(
                                            child: IgnorePointer(
                                              child: AnimatedBuilder(
                                                animation: _pulseAnim,
                                                builder: (ctx, _) => DecoratedBox(
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(20),
                                                    border: Border.all(
                                                      color: Theme.of(ctx).colorScheme.primary.withValues(alpha: _pulseAnim.value),
                                                      width: 3,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Theme.of(ctx).colorScheme.primary.withValues(alpha: _pulseAnim.value * 0.5),
                                                        blurRadius: 20 + _pulseAnim.value * 16,
                                                        spreadRadius: _pulseAnim.value * 6,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          // 박스 선택 드래그 표시
                          if (_boxSelectStart != null && _boxSelectEnd != null)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _BoxSelectPainter(
                                    start: _boxSelectStart!,
                                    end: _boxSelectEnd!,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            left: _canvasCenter.dx - 36,
                            top: _canvasCenter.dy - 36,
                            child: Draggable<String>(
                              data: 'new-node',
                              onDragStarted: () => _setCanvasPanEnabled(false),
                              onDragEnd: (_) => _setCanvasPanEnabled(true),
                              onDraggableCanceled: (_, __) => _setCanvasPanEnabled(true),
                              feedback: const _StartButton(),
                              childWhenDragging: const Opacity(
                                opacity: 0.3,
                                child: _StartButton(),
                              ),

                              child: _StartButton(
                                onSearchTap: _openSearch,
                                onAlignTap: _alignTopLevelNodesVertically,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
              // 다중 선택 배너 + 색상 팔레트
              if (_selectedNodeIds.isNotEmpty)
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Material(
                      elevation: 6,
                      borderRadius: BorderRadius.circular(20),
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 상단 타이틀 행
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline_rounded,
                                    color: Theme.of(context).colorScheme.primary, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  '${_selectedNodeIds.length}개 선택됨  •  드래그하여 이동',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: _exitSelectMode,
                                  child: Icon(Icons.close_rounded,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant, size: 18),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // 색상 팔레트 행
                            _NodeColorPalette(
                              onBorderColor: _applyBorderColor,
                              onBackgroundColor: _applyBackgroundColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              // 패널이 열려있을 때 전체화면 투명 배리어
              if (_connectPanelNode != null || _notesPanelNode != null ||
                  _filePanelNode != null || _crossLinkPanelNode != null)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _closeConnectPanel();
                      _closeNotesPanel();
                      _closeFilePanel();
                      _closeCrossLinkPanel();
                    },
                  ),
                ),
              // 패널들 (배리어 위에 위치 — 화면 좌표로 변환)
              AnimatedBuilder(
                animation: _transformController,
                builder: (context, _) {
                  final matrix = _transformController.value;
                  Offset toScreen(Offset canvas) =>
                      MatrixUtils.transformPoint(matrix, canvas);

                  return Stack(children: [
                    if (_connectPanelNode != null) Builder(builder: (ctx) {
                      final sp = toScreen(_connectPanelNode!.position);
                      return Positioned(
                        left: (sp.dx + 66).clamp(0, MediaQuery.of(ctx).size.width - 190),
                        top: (sp.dy - 30).clamp(0, MediaQuery.of(ctx).size.height - 130),
                        child: _ConnectPanel(
                          node: _connectPanelNode!,
                          onClose: _closeConnectPanel,
                          onPickFile: () {
                            final node = _connectPanelNode!;
                            _closeConnectPanel();
                            _pickFileForNode(node);
                          },
                          onAddYoutube: () {
                            final node = _connectPanelNode!;
                            _closeConnectPanel();
                            _addYoutubeLinkForNode(node);
                          },
                          onAddApp: () {
                            final node = _connectPanelNode!;
                            _closeConnectPanel();
                            _addAppLinkForNode(node);
                          },
                        ),
                      );
                    }),
                    if (_notesPanelNode != null) Builder(builder: (ctx) {
                      final sp = toScreen(_notesPanelNode!.position);
                      return Positioned(
                        left: (sp.dx + 66).clamp(0, MediaQuery.of(ctx).size.width - 180),
                        top: (sp.dy - 30).clamp(0, MediaQuery.of(ctx).size.height - 260),
                        child: _NotesPanel(
                          node: _notesPanelNode!,
                          onClose: _closeNotesPanel,
                          onAddNote: () {
                            final node = _notesPanelNode!;
                            _closeNotesPanel();
                            _openNoteEditor(node, null);
                          },
                          onOpenNote: (note) {
                            final node = _notesPanelNode!;
                            _closeNotesPanel();
                            _openNoteEditor(node, note);
                          },
                        ),
                      );
                    }),
                    if (_filePanelNode != null) Builder(builder: (ctx) {
                      final sp = toScreen(_filePanelNode!.position);
                      return Positioned(
                        left: (sp.dx + 66).clamp(0, MediaQuery.of(ctx).size.width - 170),
                        top: (sp.dy - 30).clamp(0, MediaQuery.of(ctx).size.height - 200),
                        child: _FilePanel(
                          node: _filePanelNode!,
                          onViewTap: _showFilePreview,
                          onDelete: (file) {
                            setState(() {
                              _filePanelNode!.linkedFiles.remove(file);
                              if (_previewFile?.id == file.id) _previewFile = null;
                            });
                            _saveNodes();
                          },
                        ),
                      );
                    }),
                    if (_filePanelNode != null && _previewFile != null) Builder(builder: (ctx) {
                      final sp = toScreen(_filePanelNode!.position);
                      return Positioned(
                        left: (sp.dx + 246).clamp(0, MediaQuery.of(ctx).size.width - 180),
                        top: (sp.dy - 30).clamp(0, MediaQuery.of(ctx).size.height - 200),
                        child: _FilePreview(file: _previewFile!),
                      );
                    }),
                    if (_crossLinkPanelNode != null) Builder(builder: (ctx) {
                      final sp = toScreen(_crossLinkPanelNode!.position);
                      return Positioned(
                        left: (sp.dx + 66).clamp(0, MediaQuery.of(ctx).size.width - 170),
                        top: (sp.dy - 30).clamp(0, MediaQuery.of(ctx).size.height - 200),
                        child: _CrossLinkPanel(
                          node: _crossLinkPanelNode!,
                          allNodes: _nodes,
                          onNavigate: (target) {
                            _closeCrossLinkPanel();
                            _focusOnNode(target);
                          },
                          onDeleteLink: (targetId) {
                            setState(() {
                              _crossLinkPanelNode!.crossLinks.remove(targetId);
                              // 상대 노드에서도 제거
                              final other = _nodes.firstWhere((n) => n.id == targetId, orElse: () => _crossLinkPanelNode!);
                              if (other.id != _crossLinkPanelNode!.id) other.crossLinks.remove(_crossLinkPanelNode!.id);
                            });
                            _saveNodes();
                          },
                        ),
                      );
                    }),
                  ]);
                },
              ),
              // 줌아웃 시 노드 이름 태그 오버레이
              AnimatedBuilder(
                animation: _transformController,
                builder: (context, _) {
                  final scale = _transformController.value.getMaxScaleOnAxis();
                  final opacity = ((0.65 - scale) / 0.15).clamp(0.0, 1.0);
                  if (opacity <= 0) return const SizedBox.shrink();
                  final matrix = _transformController.value;
                  return IgnorePointer(
                    child: Stack(
                      children: [
                        for (final node in _nodes)
                          if (!_isHiddenByCollapse(node) && node.category.trim().isNotEmpty)
                            Builder(builder: (context) {
                              final sp = MatrixUtils.transformPoint(matrix, node.position);
                              return Positioned(
                                left: sp.dx + 6,
                                top: sp.dy - 11,
                                child: Opacity(
                                  opacity: opacity,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3D4A6B).withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      node.category,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}


// ─── 노드 색상 팔레트 ──────────────────────────────────────────────
class _NodeColorPalette extends StatefulWidget {
  final ValueChanged<Color?> onBorderColor;
  final ValueChanged<Color?> onBackgroundColor;

  const _NodeColorPalette({
    required this.onBorderColor,
    required this.onBackgroundColor,
  });

  @override
  State<_NodeColorPalette> createState() => _NodeColorPaletteState();
}

class _NodeColorPaletteState extends State<_NodeColorPalette> {
  static const _colors = [
    Color(0xFFEF5350), // 빨강
    Color(0xFFFF7043), // 주황
    Color(0xFFFFCA28), // 노랑
    Color(0xFF66BB6A), // 초록
    Color(0xFF29B6F6), // 하늘
    Color(0xFF5C6BC0), // 남색
    Color(0xFFAB47BC), // 보라
    Color(0xFFEC407A), // 분홍
    Color(0xFF8D6E63), // 갈색
    Color(0xFF78909C), // 회색
  ];

  bool _showBorder = true; // true=테두리, false=배경

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 탭 토글
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TabBtn(label: '테두리', selected: _showBorder,
                onTap: () => setState(() => _showBorder = true)),
            const SizedBox(width: 6),
            _TabBtn(label: '배경색', selected: !_showBorder,
                onTap: () => setState(() => _showBorder = false)),
          ],
        ),
        const SizedBox(height: 8),
        // 색상 칩들
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 초기화(없음) 버튼
            GestureDetector(
              onTap: () => _showBorder
                  ? widget.onBorderColor(null)
                  : widget.onBackgroundColor(null),
              child: Container(
                width: 26,
                height: 26,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.outline, width: 1.5),
                ),
                child: Icon(Icons.block_rounded, size: 14, color: cs.outline),
              ),
            ),
            // 색상 팔레트
            for (final c in _colors)
              GestureDetector(
                onTap: () => _showBorder
                    ? widget.onBorderColor(c)
                    : widget.onBackgroundColor(c),
                child: Container(
                  width: 26,
                  height: 26,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: c.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────

class _BoxSelectPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  const _BoxSelectPainter({required this.start, required this.end});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromPoints(start, end);
    canvas.drawRect(rect, Paint()..color = const Color(0x224C6EF5));
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xFF4C6EF5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_BoxSelectPainter old) => old.start != start || old.end != end;
}

class _PageBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [
            Color(0xFFEEF1F8),
            Color(0xFFE4E8F2),
            Color(0xFFD8DCE8),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _PageBackgroundPainter old) => false;
}

class _EdgePainter extends CustomPainter {
  final List<({Offset from, Offset to})> edges;
  _EdgePainter({required this.edges});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.indigo.withValues(alpha: 0.35)
      ..strokeWidth = 1.5;

    for (final edge in edges) {
      canvas.drawLine(edge.from, edge.to, paint);
    }

  }

  @override
  bool shouldRepaint(covariant _EdgePainter oldDelegate) => true;
}

class _StartButton extends StatelessWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onAlignTap;

  const _StartButton({this.onSearchTap, this.onAlignTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
              Text(
                '시작',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (onSearchTap != null)
          Positioned(
            right: -10,
            top: -10,
            child: InkWell(
              onTap: onSearchTap,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Icon(
                  Icons.search,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ),
          ),
        if (onAlignTap != null)
          Positioned(
            left: -10,
            top: -10,
            child: InkWell(
              onTap: onAlignTap,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Icon(
                  Icons.align_vertical_center,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ChildAddButton extends StatelessWidget {
  const _ChildAddButton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.add_rounded, size: 13, color: Colors.white),
    );
  }
}

class _NodeWidget extends StatelessWidget {
  final MindNode node;
  final VoidCallback onTap;
  final VoidCallback onConnectTap;
  final ValueChanged<Offset> onDragUpdate;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;
  final VoidCallback onFilesLongPress;
  final VoidCallback onNotesTap;
  final VoidCallback onHomeTap;
  final VoidCallback onToggleCollapse;
  final VoidCallback onAlignTap;
  final VoidCallback onSortTap;
  final VoidCallback onMoveStart;
  final VoidCallback onMoveEnd;
  final VoidCallback onDoubleTap;
  final VoidCallback onCrossLinkTap;
  final VoidCallback onCrossLinkNodesTap;
  final VoidCallback onDeleteTap;
  final List<MindNode> crossLinkedNodes;
  final bool isHighlighted;
  final bool isSelected;
  final bool isSelectMode;
  final VoidCallback onSelectIconTap;

  const _NodeWidget({
    required this.node,
    required this.onTap,
    required this.onConnectTap,
    required this.onDragUpdate,
    required this.onDragStart,
    required this.onDragEnd,
    required this.onFilesLongPress,
    required this.onNotesTap,
    required this.onHomeTap,
    required this.onToggleCollapse,
    required this.onAlignTap,
    required this.onSortTap,
    required this.onMoveStart,
    required this.onMoveEnd,
    required this.onDoubleTap,
    required this.onCrossLinkTap,
    required this.onCrossLinkNodesTap,
    required this.onDeleteTap,
    required this.crossLinkedNodes,
    required this.isHighlighted,
    required this.isSelected,
    required this.isSelectMode,
    required this.onSelectIconTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasCategory = node.category.trim().isNotEmpty;
    final primary = Theme.of(context).colorScheme.primary;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: isSelected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                )
              : null,
          child: _buildCard(context, hasCategory),
        ),
        // 좌측상단 다중선택 아이콘 (항상 표시)
        Positioned(
            left: -10,
            top: -10,
            child: GestureDetector(
              onTap: onSelectIconTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.withValues(alpha: 0.45),
                    width: isSelected ? 2 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                    : null,
              ),
            ),
          ),
        Positioned(
          right: -8,
          top: -8,
          child: Listener(
            onPointerDown: (_) => onDragStart(),
            onPointerUp: (_) => onDragEnd(),
            onPointerCancel: (_) => onDragEnd(),
            child: GestureDetector(
              onTap: onToggleCollapse,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  node.collapsed ? Icons.add_rounded : Icons.remove_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, bool hasCategory) {
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 128,
      decoration: BoxDecoration(
        color: node.backgroundColor,
        gradient: node.backgroundColor != null
            ? null
            : isLight
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFFFFF), Color(0xFFF0F4FF)],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cs.surfaceContainerHigh, cs.surfaceContainerHighest],
                  ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHighlighted
              ? cs.error
              : node.borderColor ?? cs.primary.withValues(alpha: 0.18),
          width: isHighlighted ? 2 : (node.borderColor != null ? 2 : 1),
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: cs.error.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                // ambient — 넓고 연한 그림자
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
                // directional — 아래쪽 진한 그림자
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  spreadRadius: -2,
                  offset: const Offset(0, 4),
                ),
                // top highlight — 위쪽 흰빛 반사
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.95),
                  blurRadius: 0,
                  spreadRadius: 0,
                  offset: const Offset(0, -1),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 상단 컬러 액센트 바
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.tertiary],
                ),
              ),
            ),
            // 본문 영역
            GestureDetector(
              onTap: onTap,
              onDoubleTap: onDoubleTap,
              onPanStart: (_) => onMoveStart(),
              onPanUpdate: (details) => onDragUpdate(details.delta),
              onPanEnd: (_) => onMoveEnd(),
              onPanCancel: onMoveEnd,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasCategory ? node.category : '카테고리 없음',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: -0.2,
                        color: hasCategory
                            ? cs.onSurface
                            : cs.onSurface.withValues(alpha: 0.35),
                      ),
                    ),
                    if (node.linkedFiles.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Listener(
                        onPointerDown: (_) => onDragStart(),
                        onPointerUp: (_) => onDragEnd(),
                        onPointerCancel: (_) => onDragEnd(),
                        child: InkWell(
                          onTap: onFilesLongPress,
                          onLongPress: onFilesLongPress,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: cs.secondaryContainer.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.description_outlined, size: 11, color: cs.secondary),
                                const SizedBox(width: 3),
                                Text(
                                  '${node.linkedFiles.length}개 파일',
                                  style: TextStyle(fontSize: 10, color: cs.secondary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (crossLinkedNodes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Listener(
                        onPointerDown: (_) => onDragStart(),
                        onPointerUp: (_) => onDragEnd(),
                        onPointerCancel: (_) => onDragEnd(),
                        child: InkWell(
                          onTap: onCrossLinkNodesTap,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.link_rounded, size: 11, color: Colors.orange),
                                const SizedBox(width: 3),
                                Text(
                                  '${crossLinkedNodes.length}개 연결',
                                  style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // 구분선
            Divider(height: 1, thickness: 1, color: cs.primary.withValues(alpha: 0.08)),
            // 하단 버튼 행: 메뉴 + 자식 추가
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Listener(
                    onPointerDown: (_) => onDragStart(),
                    onPointerUp: (_) => onDragEnd(),
                    onPointerCancel: (_) => onDragEnd(),
                    child: PopupMenuButton<String>(
                      icon: Icon(Icons.more_horiz_rounded, size: 18,
                          color: cs.primary.withValues(alpha: 0.7)),
                      padding: EdgeInsets.zero,
                      position: PopupMenuPosition.over,
                      offset: const Offset(132, 0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 6,
                      onSelected: (value) {
                        switch (value) {
                          case 'home': onHomeTap();
                          case 'connect': onConnectTap();
                          case 'notes': onNotesTap();
                          case 'align': onAlignTap();
                          case 'sort': onSortTap();
                          case 'crosslink': onCrossLinkTap();
                          case 'delete': onDeleteTap();
                        }
                      },
                      itemBuilder: (context) => [
                        _menuItem('home', Icons.home_rounded, '홈으로 이동'),
                        _menuItem('connect', Icons.link_rounded, '파일 / 유튜브 연결'),
                        _menuItem('notes', Icons.edit_note_rounded, '메모 ${node.notes.isEmpty ? '추가' : '(${node.notes.length}개)'}'),
                        _menuItem('align', Icons.align_horizontal_center_rounded, '수평 정렬'),
                        _menuItem('sort', Icons.sort_by_alpha_rounded, '가나다순 정렬'),
                        _menuItem('crosslink', Icons.add_link_rounded, '노드 연결'),
                        const PopupMenuDivider(),
                        _menuItem('delete', Icons.delete_outline_rounded, '노드 삭제', color: Colors.red),
                      ],
                    ),
                  ),
                  Listener(
                    onPointerDown: (_) => onDragStart(),
                    onPointerUp: (_) => onDragEnd(),
                    onPointerCancel: (_) => onDragEnd(),
                    child: Draggable<String>(
                      data: 'child:${node.id}',
                      onDragStarted: onDragStart,
                      onDragEnd: (_) => onDragEnd(),
                      onDraggableCanceled: (_, __) => onDragEnd(),
                      feedback: const _ChildAddButton(),
                      childWhenDragging:
                          const Opacity(opacity: 0.3, child: _ChildAddButton()),
                      child: const _ChildAddButton(),
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

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label, {Color? color}) {
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 13, color: color)),
        ],
      ),
    );
  }
}

class _FilePanel extends StatelessWidget {
  final MindNode node;
  final ValueChanged<LinkedFile> onViewTap;
  final ValueChanged<LinkedFile> onDelete;

  const _FilePanel({required this.node, required this.onViewTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final file in node.linkedFiles)
              _SwipeableFileRow(
                key: ValueKey(file.id),
                file: file,
                onViewTap: () => onViewTap(file),
                onDelete: () => onDelete(file),
              ),
          ],
        ),
      ),
    );
  }
}

class _ConnectPanel extends StatelessWidget {
  final MindNode node;
  final VoidCallback onClose;
  final VoidCallback onPickFile;
  final VoidCallback onAddYoutube;
  final VoidCallback onAddApp;

  const _ConnectPanel({
    required this.node,
    required this.onClose,
    required this.onPickFile,
    required this.onAddYoutube,
    required this.onAddApp,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.link_rounded, size: 14, color: cs.secondary),
                const SizedBox(width: 4),
                Text(
                  '자료 연결',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.secondary),
                ),
              ],
            ),
            const Divider(height: 10),
            InkWell(
              onTap: onPickFile,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Row(
                  children: [
                    Icon(Icons.attach_file_rounded, size: 14, color: cs.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '파일 / 사진 / PDF',
                        style: TextStyle(fontSize: 12, color: cs.onSurface, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: onAddYoutube,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Row(
                  children: [
                    Icon(Icons.smart_display_rounded, size: 14, color: Colors.red.shade400),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '유튜브 링크',
                        style: TextStyle(fontSize: 12, color: cs.onSurface, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: onAddApp,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Row(
                  children: [
                    Icon(Icons.apps_rounded, size: 14, color: Colors.indigo.shade400),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '앱 연결',
                        style: TextStyle(fontSize: 12, color: cs.onSurface, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesPanel extends StatelessWidget {
  final MindNode node;
  final VoidCallback onClose;
  final VoidCallback onAddNote;
  final ValueChanged<HandwrittenNote> onOpenNote;

  const _NotesPanel({
    required this.node,
    required this.onClose,
    required this.onAddNote,
    required this.onOpenNote,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note_rounded, size: 14, color: cs.tertiary),
                const SizedBox(width: 4),
                Text(
                  '메모',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.tertiary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (node.notes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('메모 없음', style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
              ),
            for (final note in node.notes)
              InkWell(
                onTap: () => onOpenNote(note),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    children: [
                      Icon(Icons.edit_note, size: 13, color: cs.tertiary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          note.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const Divider(height: 10),
            InkWell(
              onTap: onAddNote,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  children: [
                    Icon(Icons.add_rounded, size: 14, color: cs.primary),
                    const SizedBox(width: 4),
                    Text('새 메모 추가', style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilePreview extends StatelessWidget {
  final LinkedFile file;

  const _FilePreview({required this.file});

  bool get _isImage => _imageExtensions.contains(file.extension.toLowerCase());
  bool get _isYoutube => file.extension == 'youtube';
  bool get _isApp => file.extension == 'app';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 180,
        height: 200,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: _isImage && file.bytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(file.bytes!, fit: BoxFit.cover, width: double.infinity),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _isApp
                            ? Text(
                                _kApps.firstWhere((a) => a.name == file.name,
                                    orElse: () => _AppInfo(file.name, file.path, '📱', '')).emoji,
                                style: const TextStyle(fontSize: 42),
                              )
                            : Icon(_isYoutube ? Icons.smart_display : _iconForExtension(file.extension), size: 48),
                        const SizedBox(height: 8),
                        Text(
                          file.name,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (_isApp) ...[
                          const SizedBox(height: 4),
                          Text(
                            file.path,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 9, color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  minimumSize: const Size(0, 32),
                ),
                onPressed: _isYoutube
                    ? () => _openYoutubeLink(context)
                    : _isApp
                        ? () => _openAppLink(context)
                        : () => _openFullScreen(context),
                icon: Icon(
                  _isYoutube || _isApp ? Icons.open_in_new : Icons.fullscreen,
                  size: 16,
                ),
                label: Text(
                  _isYoutube ? 'YouTube에서 열기' : _isApp ? '앱 열기' : '전체보기',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _FullScreenFileView(file: file, isImage: _isImage),
      ),
    );
  }

  Future<void> _openYoutubeLink(BuildContext context) async {
    final uri = Uri.tryParse(file.path);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크를 열 수 없습니다')),
        );
      }
    }
  }

  Future<void> _openAppLink(BuildContext context) async {
    final uri = Uri.tryParse(file.path);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${file.name}" 앱을 열 수 없습니다. 앱이 설치되어 있는지 확인하세요.')),
        );
      }
    }
  }

  IconData _iconForExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.movie;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }
}

class _FullScreenFileView extends StatelessWidget {
  final LinkedFile file;
  final bool isImage;

  const _FullScreenFileView({required this.file, required this.isImage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(file.name, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: isImage && file.bytes != null
            ? InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: Image.memory(file.bytes!, fit: BoxFit.contain),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.insert_drive_file, size: 96, color: Colors.white70),
                  const SizedBox(height: 16),
                  Text(
                    file.name,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '이 파일 형식은 앱 내 미리보기를 지원하지 않습니다',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CrossLinkPanel extends StatelessWidget {
  final MindNode node;
  final List<MindNode> allNodes;
  final ValueChanged<MindNode> onNavigate;
  final ValueChanged<String> onDeleteLink;

  const _CrossLinkPanel({
    required this.node,
    required this.allNodes,
    required this.onNavigate,
    required this.onDeleteLink,
  });

  @override
  Widget build(BuildContext context) {
    final linked = [
      for (final id in node.crossLinks)
        for (final n in allNodes)
          if (n.id == id) n,
    ];

    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final target in linked)
              _SwipeableLinkRow(
                key: ValueKey(target.id),
                target: target,
                onNavigate: () => onNavigate(target),
                onDelete: () => onDeleteLink(target.id),
              ),
          ],
        ),
      ),
    );
  }
}

class _NodeSearchDialog extends StatefulWidget {
  final List<MindNode> nodes;
  const _NodeSearchDialog({required this.nodes});

  @override
  State<_NodeSearchDialog> createState() => _NodeSearchDialogState();
}

class _NodeSearchDialogState extends State<_NodeSearchDialog> {
  final _controller = TextEditingController();
  late List<MindNode> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.nodes;
    _controller.addListener(() {
      final q = _controller.text.toLowerCase();
      setState(() {
        _filtered = q.isEmpty
            ? widget.nodes
            : widget.nodes
                .where((n) => n.category.toLowerCase().contains(q))
                .toList();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('노드 연결 검색'),
      content: SizedBox(
        width: 300,
        height: 350,
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '노드 이름으로 검색',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(child: Text('검색 결과가 없습니다'))
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final node = _filtered[index];
                        final name =
                            node.category.isEmpty ? '(이름 없음)' : node.category;
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.circle, size: 10),
                          title: Text(name),
                          onTap: () => Navigator.pop(context, node),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
      ],
    );
  }
}

// 올가미 선택 상태
class _LassoState extends ChangeNotifier {
  List<Offset> points = [];
  bool complete = false;
  List<int> selectedIndices = [];
  Offset? centroid;
  bool moving = false;

  void startLasso(Offset p) {
    points = [p];
    complete = false;
    selectedIndices = [];
    centroid = null;
    moving = false;
    notifyListeners();
  }

  void addPoint(Offset p) {
    points.add(p);
    notifyListeners();
  }

  void completeSelection(List<int> selected, Offset c) {
    complete = true;
    selectedIndices = selected;
    centroid = c;
    notifyListeners();
  }

  void stopMoving() {
    moving = false;
    notifyListeners();
  }

  void reset() {
    points = [];
    complete = false;
    selectedIndices = [];
    centroid = null;
    moving = false;
    notifyListeners();
  }

  void moveDelta(List<Stroke> allStrokes, Offset delta) {
    for (final idx in selectedIndices) {
      if (idx < allStrokes.length) {
        final pts = allStrokes[idx].points;
        for (var i = 0; i < pts.length; i++) {
          pts[i] = pts[i] + delta;
        }
      }
    }
    if (centroid != null) centroid = centroid! + delta;
    notifyListeners();
  }
}

enum _CanvasBg { blank, dots, lines, grid, diagonal }

// 드로잉 상태만 분리 — ChangeNotifier로 캔버스만 repaint, 전체 rebuild 없음
class _DrawingState extends ChangeNotifier {
  final List<Stroke> strokes;
  Stroke? currentStroke;

  _DrawingState(this.strokes);

  void startStroke(Stroke s) {
    currentStroke = s;
    notifyListeners();
  }

  void addPoint(Offset p) {
    currentStroke?.points.add(p);
    notifyListeners();
  }

  void updateStraightLine(Offset start, Offset end) {
    final pts = currentStroke?.points;
    if (pts == null) return;
    pts.clear();
    pts.add(start);
    pts.add(end);
    notifyListeners();
  }

  void finishStroke() {
    if (currentStroke == null) return;
    strokes.add(currentStroke!);
    currentStroke = null;
    notifyListeners();
  }

  void cancelStroke() {
    currentStroke = null;
    notifyListeners();
  }

  void eraseAt(Offset position, double radius) {
    final newStrokes = <Stroke>[];
    bool changed = false;

    for (final stroke in strokes) {
      final segments = _splitErase(stroke, position, radius);
      if (segments.length == 1 && identical(segments[0], stroke)) {
        newStrokes.add(stroke);
      } else {
        newStrokes.addAll(segments);
        changed = true;
      }
    }

    if (changed) {
      strokes.clear();
      strokes.addAll(newStrokes);
      notifyListeners();
    }
  }

  List<Stroke> _splitErase(Stroke stroke, Offset center, double radius) {
    final pts = stroke.points;
    final keep = [for (final p in pts) (p - center).distance > radius];

    if (keep.every((k) => k)) return [stroke];
    if (keep.every((k) => !k)) return [];

    final result = <Stroke>[];
    Stroke? seg;
    for (var i = 0; i < pts.length; i++) {
      if (keep[i]) {
        seg ??= Stroke(color: stroke.color, width: stroke.width);
        seg.points.add(pts[i]);
      } else {
        if (seg != null && seg.points.length >= 2) result.add(seg);
        seg = null;
      }
    }
    if (seg != null && seg.points.length >= 2) result.add(seg);
    return result;
  }

  void undo() {
    if (strokes.isNotEmpty) {
      strokes.removeLast();
      notifyListeners();
    }
  }

  void clear() {
    strokes.clear();
    currentStroke = null;
    notifyListeners();
  }
}

class _NoteEditorScreen extends StatefulWidget {
  final List<Stroke>? initialStrokes;
  final String initialName;
  final List<NoteImage>? initialImages;

  const _NoteEditorScreen({
    this.initialStrokes,
    required this.initialName,
    this.initialImages,
  });

  @override
  State<_NoteEditorScreen> createState() => _NoteEditorScreenState();
}

// 에디터 내부에서 ui.Image까지 함께 보관
class _EditorImage {
  final NoteImage noteImage;
  final ui.Image decoded;
  _EditorImage({required this.noteImage, required this.decoded});
  Uint8List get bytes => noteImage.bytes;
  Rect get rect => noteImage.rect;
  set rect(Rect r) => noteImage.rect = r;
}

class _NoteEditorScreenState extends State<_NoteEditorScreen> {
  late _DrawingState _drawing;
  late TextEditingController _nameController;
  bool _erasing = false;
  bool _highlighting = false;
  bool _straightLine = false;
  bool _drawingEnabled = true;
  bool _lassoMode = false;
  late _LassoState _lassoState;
  double _strokeWidth = 4.0;
  Color _penColor = Colors.black;
  Offset? _straightLineStart;
  bool _pointerOnImage = false;
  bool _imageSelected = false;
  final List<_EditorImage> _images = [];
  int _selectedImageIndex = -1;

  // 캔버스 배경
  _CanvasBg _canvasBg = _CanvasBg.blank;

  // 지우개
  double _eraserSize = 20.0; // 캔버스 좌표 반지름
  Offset? _eraserScreenPos;  // 화면 좌표 (커서 표시용)

  // 핀치 줌
  double _canvasScale = 1.0;
  Offset _canvasOffset = Offset.zero;
  final Map<int, Offset> _pointerPositions = {};
  bool _isPinching = false;
  double? _lastPinchDistance;
  Offset? _lastPinchMid;

  @override
  void initState() {
    super.initState();
    final strokes = widget.initialStrokes != null
        ? widget.initialStrokes!
            .map((s) => Stroke(color: s.color, width: s.width, points: List.of(s.points)))
            .toList()
        : <Stroke>[];
    _drawing = _DrawingState(strokes);
    _lassoState = _LassoState();
    _nameController = TextEditingController(text: widget.initialName);
    if (widget.initialImages != null) {
      for (final img in widget.initialImages!) {
        _loadExistingImage(img);
      }
    }
  }

  @override
  void dispose() {
    _drawing.dispose();
    _lassoState.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingImage(NoteImage noteImage) async {
    final codec = await ui.instantiateImageCodec(noteImage.bytes);
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(() => _images.add(_EditorImage(noteImage: NoteImage(bytes: noteImage.bytes, rect: noteImage.rect), decoded: frame.image)));
  }

  Future<void> _setBackgroundImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    const initialWidth = 240.0;
    final aspect = frame.image.width / frame.image.height;
    final rect = Rect.fromLTWH(40 + _images.length * 20.0, 80 + _images.length * 20.0, initialWidth, initialWidth / aspect);
    final noteImage = NoteImage(bytes: bytes, rect: rect);
    setState(() {
      _images.add(_EditorImage(noteImage: noteImage, decoded: frame.image));
      _selectedImageIndex = _images.length - 1;
      _imageSelected = true;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    await _setBackgroundImage(bytes);
  }

  void _resizeImage(String handle, Offset delta) {
    if (_selectedImageIndex < 0 || _selectedImageIndex >= _images.length) return;
    var rect = _images[_selectedImageIndex].rect;
    switch (handle) {
      case 'tl':
        rect = Rect.fromLTRB(rect.left + delta.dx, rect.top + delta.dy, rect.right, rect.bottom);
      case 'tr':
        rect = Rect.fromLTRB(rect.left, rect.top + delta.dy, rect.right + delta.dx, rect.bottom);
      case 'bl':
        rect = Rect.fromLTRB(rect.left + delta.dx, rect.top, rect.right, rect.bottom + delta.dy);
      case 'br':
        rect = Rect.fromLTRB(rect.left, rect.top, rect.right + delta.dx, rect.bottom + delta.dy);
    }
    const minSize = 30.0;
    if (rect.width >= minSize && rect.height >= minSize) {
      setState(() => _images[_selectedImageIndex].rect = rect);
    }
  }

  // 화면 좌표 → 캔버스 좌표 변환
  Offset _toCanvas(Offset screenPos) =>
      (screenPos - _canvasOffset) / _canvasScale;

  void _handlePinch() {
    if (_pointerPositions.length < 2) return;
    final pts = _pointerPositions.values.toList();
    final p1 = pts[0];
    final p2 = pts[1];
    final dist = (p2 - p1).distance;
    final mid = (p1 + p2) / 2;

    if (_lastPinchDistance != null && _lastPinchDistance! > 0) {
      final scaleDelta = dist / _lastPinchDistance!;
      final newScale = (_canvasScale * scaleDelta).clamp(0.25, 6.0);
      final ratio = newScale / _canvasScale;
      // 핀치 중점 기준 스케일 보정 + 중점 이동(패닝) 반영
      _canvasOffset = mid - (mid - _canvasOffset) * ratio;
      if (_lastPinchMid != null) {
        _canvasOffset += mid - _lastPinchMid!;
      }
      _canvasScale = newScale;
      setState(() {});
    }
    _lastPinchDistance = dist;
    _lastPinchMid = mid;
  }

  void _cancelDrawingForPinch() {
    _drawing.cancelStroke();
    _lassoState.reset();
    _activePointerId = null;
    _straightLineStart = null;
    setState(() => _pointerOnImage = false);
  }

  // 팜 리젝션: 첫 번째 포인터만 드로잉에 사용, 나머지는 무시
  int? _activePointerId;

  void _onPointerDown(PointerDownEvent event) {
    _pointerPositions[event.pointer] = event.localPosition;

    // 두 손가락 이상 → 핀치 줌 모드 진입
    if (_pointerPositions.length >= 2) {
      if (!_isPinching) {
        _isPinching = true;
        _lastPinchDistance = null;
        _lastPinchMid = null;
        _cancelDrawingForPinch();
      }
      return;
    }

    // 핀치 중이면 추가 드로잉 무시
    if (_isPinching) return;

    // 이미 다른 포인터가 드로잉 중이면 무시 (손바닥 차단)
    if (_activePointerId != null && _activePointerId != event.pointer) return;
    _activePointerId = event.pointer;
    final pos = _toCanvas(event.localPosition);

    // 올가미 모드
    if (_lassoMode) {
      if (_lassoState.complete) {
        // 라쏘 폴리곤 안을 탭하면 이동 시작
        if (_lassoState.points.length >= 3 &&
            _pointInPolygon(pos, _lassoState.points)) {
          _lassoState.moving = true;
          return;
        }
        _lassoState.reset();
        setState(() {});
      }
      _lassoState.startLasso(pos);
      return;
    }

    // 드로잉 비활성 상태 → 이미지 편집 중이면 빈 캔버스 탭으로 해제
    if (!_drawingEnabled) {
      if (_imageSelected) {
        final onAnyImage = _images.any((img) => img.rect.contains(pos));
        if (!onAnyImage) setState(() { _imageSelected = false; _selectedImageIndex = -1; });
      }
      _activePointerId = null;
      return;
    }
    // 선택 모드 이미지 위 → 드로잉 차단
    if (_imageSelected && _selectedImageIndex >= 0 &&
        _images[_selectedImageIndex].rect.contains(pos)) {
      setState(() => _pointerOnImage = true);
      _activePointerId = null;
      return;
    }
    // 선택 모드에서 다른 이미지 탭 → 그 이미지 선택
    if (_imageSelected) {
      final idx = _images.indexWhere((img) => img.rect.contains(pos));
      if (idx >= 0) {
        setState(() { _selectedImageIndex = idx; _pointerOnImage = true; });
        _activePointerId = null;
        return;
      }
      setState(() { _imageSelected = false; _selectedImageIndex = -1; });
      _pointerOnImage = false;
    } else {
      _pointerOnImage = false;
    }
    if (_erasing) {
      setState(() => _eraserScreenPos = event.localPosition);
      _drawing.eraseAt(pos, _eraserSize);
      return;
    }
    final color = _highlighting ? _penColor.withValues(alpha: 0.35) : _penColor;
    final width = _highlighting ? _strokeWidth * 4 : _strokeWidth;
    if (_straightLine) {
      _straightLineStart = pos;
      _drawing.startStroke(Stroke(color: color, width: width)
        ..points.add(pos)
        ..points.add(pos));
    } else {
      _drawing.startStroke(Stroke(color: color, width: width)
        ..points.add(pos));
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    _pointerPositions[event.pointer] = event.localPosition;

    // 핀치 줌 처리
    if (_isPinching || _pointerPositions.length >= 2) {
      _handlePinch();
      return;
    }

    if (_activePointerId != null && _activePointerId != event.pointer) return;
    final pos = _toCanvas(event.localPosition);
    final delta = event.delta / _canvasScale;

    // 올가미 모드
    if (_lassoMode) {
      if (_lassoState.complete && _lassoState.moving) {
        _lassoState.moveDelta(_drawing.strokes, delta);
        return;
      }
      if (!_lassoState.complete) {
        _lassoState.addPoint(pos);
      }
      return;
    }

    if (!_drawingEnabled) return;
    if (_pointerOnImage) return;
    if (_erasing) {
      setState(() => _eraserScreenPos = event.localPosition);
      _drawing.eraseAt(pos, _eraserSize);
      return;
    }
    if (_drawing.currentStroke == null) return;
    if (_straightLine && _straightLineStart != null) {
      _drawing.updateStraightLine(_straightLineStart!, pos);
    } else {
      _drawing.addPoint(pos);
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _pointerPositions.remove(event.pointer);

    // 핀치 종료 감지
    if (_isPinching) {
      if (_pointerPositions.length < 2) {
        _isPinching = false;
        _lastPinchDistance = null;
        _lastPinchMid = null;
        _activePointerId = null;
      }
      return;
    }

    if (_activePointerId == event.pointer) _activePointerId = null;

    // 올가미 모드
    if (_lassoMode) {
      if (_lassoState.moving) {
        _lassoState.stopMoving();
        _drawing.notifyListeners();
        setState(() {});
        return;
      }
      if (!_lassoState.complete && _lassoState.points.length > 15) {
        final first = _lassoState.points.first;
        final last = _lassoState.points.last;
        if ((first - last).distance < 50 / _canvasScale) {
          _closeLasso();
          setState(() {});
        } else {
          _lassoState.reset();
          setState(() {});
        }
      } else if (!_lassoState.complete) {
        _lassoState.reset();
        setState(() {});
      }
      return;
    }

    if (_activePointerId != null) return;
    setState(() { _pointerOnImage = false; _eraserScreenPos = null; });
    _drawing.finishStroke();
    _straightLineStart = null;
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointerPositions.remove(event.pointer);
    if (_isPinching) {
      if (_pointerPositions.length < 2) {
        _isPinching = false;
        _lastPinchDistance = null;
        _lastPinchMid = null;
        _activePointerId = null;
      }
      return;
    }
    if (_activePointerId == event.pointer) _activePointerId = null;
    setState(() => _eraserScreenPos = null);
    if (_lassoMode) {
      _lassoState.reset();
      return;
    }
    _drawing.cancelStroke();
    _straightLineStart = null;
  }

  void _closeLasso() {
    final points = _lassoState.points;
    if (points.length < 3) { _lassoState.reset(); return; }

    final selected = <int>[];
    for (var i = 0; i < _drawing.strokes.length; i++) {
      final stroke = _drawing.strokes[i];
      if (stroke.points.any((p) => _pointInPolygon(p, points))) {
        selected.add(i);
      }
    }

    final cx = points.fold(0.0, (s, p) => s + p.dx) / points.length;
    final cy = points.fold(0.0, (s, p) => s + p.dy) / points.length;
    _lassoState.completeSelection(selected, Offset(cx, cy));
  }

  bool _pointInPolygon(Offset point, List<Offset> polygon) {
    int crossings = 0;
    for (int i = 0; i < polygon.length; i++) {
      final a = polygon[i];
      final b = polygon[(i + 1) % polygon.length];
      if ((a.dy <= point.dy && b.dy > point.dy) ||
          (b.dy <= point.dy && a.dy > point.dy)) {
        final t = (point.dy - a.dy) / (b.dy - a.dy);
        if (point.dx < a.dx + t * (b.dx - a.dx)) crossings++;
      }
    }
    return crossings.isOdd;
  }

  void _undo() => _drawing.undo();

  void _clear() => _drawing.clear();

  Widget _toolBtn(BuildContext context, {
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
    Color? activeColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    final color = activeColor ?? cs.primary;
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: active ? Border.all(color: color.withValues(alpha: 0.4), width: 1.5) : null,
          ),
          child: Icon(icon, size: 22, color: active ? color : cs.onSurface.withValues(alpha: 0.4)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _nameController,
          style: const TextStyle(fontSize: 18),
          decoration: const InputDecoration(
            hintText: '메모 제목',
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: '되돌리기',
            onPressed: _undo,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '전체 지우기',
            onPressed: _clear,
          ),
          TextButton(
            onPressed: () {
              final name = _nameController.text.trim();
              Navigator.pop(
                context,
                (
                  strokes: _drawing.strokes,
                  name: name.isEmpty ? '메모' : name,
                  images: _images.map((e) => NoteImage(bytes: e.bytes, rect: e.rect)).toList(),
                ),
              );
            },
            child: const Text('저장'),
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            elevation: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      _toolBtn(context, icon: Icons.edit, label: '자유 필기',
                        active: _drawingEnabled && !_erasing && !_straightLine,
                        onTap: () => setState(() {
                          _imageSelected = false; _selectedImageIndex = -1;
                          _lassoMode = false; _lassoState.reset();
                          if (_drawingEnabled && !_erasing && !_straightLine) {
                            _drawingEnabled = false;
                          } else {
                            _drawingEnabled = true; _erasing = false; _straightLine = false;
                          }
                        }),
                      ),
                      _toolBtn(context, icon: Icons.horizontal_rule_rounded, label: '직선',
                        active: _drawingEnabled && !_erasing && _straightLine,
                        onTap: () => setState(() {
                          _imageSelected = false; _selectedImageIndex = -1;
                          _lassoMode = false; _lassoState.reset();
                          if (_drawingEnabled && !_erasing && _straightLine) {
                            _drawingEnabled = false;
                          } else {
                            _drawingEnabled = true; _erasing = false; _straightLine = true;
                          }
                        }),
                      ),
                      _toolBtn(context, icon: Icons.highlight, label: '형광펜',
                        active: _highlighting,
                        activeColor: Theme.of(context).colorScheme.tertiary,
                        onTap: () => setState(() {
                          _imageSelected = false; _selectedImageIndex = -1;
                          _lassoMode = false; _lassoState.reset();
                          _highlighting = !_highlighting;
                        }),
                      ),
                      _toolBtn(context, icon: Icons.auto_fix_normal, label: '지우개',
                        active: _drawingEnabled && _erasing,
                        onTap: () => setState(() {
                          _imageSelected = false; _selectedImageIndex = -1;
                          _lassoMode = false; _lassoState.reset();
                          if (_drawingEnabled && _erasing) {
                            _drawingEnabled = false;
                          } else {
                            _drawingEnabled = true; _erasing = true; _straightLine = false; _highlighting = false;
                          }
                        }),
                      ),
                      _toolBtn(context, icon: Icons.gesture, label: '올가미 선택',
                        active: _lassoMode,
                        activeColor: Colors.deepPurple,
                        onTap: () => setState(() {
                          _imageSelected = false; _selectedImageIndex = -1;
                          if (_lassoMode) {
                            _lassoMode = false;
                            _lassoState.reset();
                          } else {
                            _lassoMode = true;
                            _drawingEnabled = false;
                            _erasing = false;
                            _straightLine = false;
                            _lassoState.reset();
                          }
                        }),
                      ),
                      const SizedBox(width: 4),
                      const SizedBox(height: 24, child: VerticalDivider(width: 1)),
                      const SizedBox(width: 4),
                      // 색상 팔레트
                      for (final color in [
                        Colors.black,
                        Colors.blue,
                        Colors.red,
                        Colors.green,
                        Colors.orange,
                        Colors.purple,
                      ])
                        GestureDetector(
                          onTap: () => setState(() { _penColor = color; _erasing = false; }),
                          child: Container(
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _penColor == color ? Colors.white : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: _penColor == color
                                  ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)]
                                  : null,
                            ),
                          ),
                        ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.camera_alt),
                        tooltip: '사진 촬영',
                        onPressed: () => _pickImage(ImageSource.camera),
                      ),
                      IconButton(
                        icon: const Icon(Icons.image),
                        tooltip: '사진 보관함에서 가져오기',
                        onPressed: () => _pickImage(ImageSource.gallery),
                      ),
                    ],
                  ),
                ),
                // 크기 행 — 지우개 모드일 때는 지우개 크기 표시
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
                  child: _erasing
                      ? _buildEraserSizeRow(context)
                      : _buildPenSizeRow(context),
                ),
                // 배경 선택 행
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: _buildBgRow(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
            Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
              child: ClipRect(
                child: Transform(
                  transform: Matrix4.identity()
                    ..translateByDouble(_canvasOffset.dx, _canvasOffset.dy, 0, 1)
                    ..scaleByDouble(_canvasScale, _canvasScale, 1, 1),
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: Size.infinite,
                        painter: _StrokePainter(
                          drawing: _drawing,
                          images: _images,
                          lassoState: _lassoState,
                          lassoSelectedIndices: _lassoState.selectedIndices,
                          canvasBg: _canvasBg,
                        ),
                      ),
                      ..._buildImageHandles(),
                    ],
                  ),
                ),
              ),
            ),
            // 지우개 커서 오버레이 (화면 좌표)
            if (_erasing && _eraserScreenPos != null)
              Positioned(
                left: _eraserScreenPos!.dx - _eraserSize * _canvasScale,
                top: _eraserScreenPos!.dy - _eraserSize * _canvasScale,
                child: IgnorePointer(
                  child: Container(
                    width: _eraserSize * _canvasScale * 2,
                    height: _eraserSize * _canvasScale * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.5),
                      border: Border.all(color: Colors.black54, width: 1.5),
                    ),
                  ),
                ),
              ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPenSizeRow(BuildContext context) {
    return Row(
      children: [
        const Text('크기', style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(width: 10),
        for (final size in [2.0, 4.0, 7.0, 12.0, 20.0])
          GestureDetector(
            onTap: () => setState(() => _strokeWidth = size),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 40,
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: _strokeWidth == size
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: _strokeWidth == size
                    ? Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4), width: 1.5)
                    : Border.all(color: Colors.transparent),
              ),
              child: Center(
                child: Container(
                  width: size.clamp(2, 28),
                  height: size.clamp(2, 28),
                  decoration: BoxDecoration(
                    color: _highlighting ? _penColor.withValues(alpha: 0.45) : _penColor,
                    shape: _highlighting ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: _highlighting ? BorderRadius.circular(2) : null,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEraserSizeRow(BuildContext context) {
    // 지우개 반지름 옵션 (캔버스 단위)
    const sizes = [8.0, 16.0, 28.0, 48.0, 80.0];
    return Row(
      children: [
        const Icon(Icons.circle_outlined, size: 13, color: Colors.grey),
        const SizedBox(width: 6),
        const Text('지우개 크기', style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(width: 8),
        for (final r in sizes)
          GestureDetector(
            onTap: () => setState(() => _eraserSize = r),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 44,
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: _eraserSize == r
                    ? Colors.grey.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: _eraserSize == r
                    ? Border.all(color: Colors.grey.shade400, width: 1.5)
                    : Border.all(color: Colors.transparent),
              ),
              child: Center(
                child: Container(
                  width: (r * 0.35).clamp(6, 32),
                  height: (r * 0.35).clamp(6, 32),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(color: Colors.black54, width: 1.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBgRow(BuildContext context) {
    const options = [
      (_CanvasBg.blank,    '백지',  Icons.crop_landscape_rounded),
      (_CanvasBg.dots,     '점',    Icons.grain_rounded),
      (_CanvasBg.lines,    '줄',    Icons.format_list_bulleted_rounded),
      (_CanvasBg.grid,     '모눈',  Icons.grid_4x4_rounded),
      (_CanvasBg.diagonal, '사선',  Icons.expand_rounded),
    ];
    return Row(
      children: [
        const Text('배경', style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(width: 8),
        for (final (bg, label, icon) in options)
          GestureDetector(
            onTap: () => setState(() => _canvasBg = bg),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 52,
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: _canvasBg == bg
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: _canvasBg == bg
                    ? Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5), width: 1.5)
                    : Border.all(color: Colors.grey.withValues(alpha: 0.25), width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Stack(
                  children: [
                    // 미리보기
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _BgPreviewPainter(bg),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 12,
                            color: _canvasBg == bg
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade500),
                          const SizedBox(height: 1),
                          Text(label, style: TextStyle(
                            fontSize: 8,
                            color: _canvasBg == bg
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade500,
                            fontWeight: _canvasBg == bg ? FontWeight.w700 : FontWeight.normal,
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _moveImage(Offset delta) {
    if (_selectedImageIndex < 0 || _selectedImageIndex >= _images.length) return;
    setState(() {
      _images[_selectedImageIndex].rect = _images[_selectedImageIndex].rect.translate(delta.dx, delta.dy);
    });
  }

  List<Widget> _buildImageHandles() {
    const handleSize = 20.0; // 시각적 크기
    const inner = 10.0;      // 꼭짓점 안쪽 여유
    const outer = 44.0;      // 꼭짓점 바깥쪽 여유 (펜슬이 많이 벗어나도 잡힘)
    const total = inner + outer;
    final widgets = <Widget>[];

    for (var i = 0; i < _images.length; i++) {
      final img = _images[i];
      final rect = img.rect;
      final isSelected = _imageSelected && _selectedImageIndex == i;

      // 각 꼭짓점마다 바깥 방향으로 hit 영역을 치우쳐 배치
      // dx/dy: -1 = 왼쪽/위, +1 = 오른쪽/아래 (바깥 방향)
      Widget resizeHandle(String id, double cx, double cy, double dx, double dy) {
        // 바깥 방향으로 outer, 안쪽으로 inner 만큼 영역 확장
        final left = dx < 0 ? cx - outer : cx - inner;
        final top  = dy < 0 ? cy - outer : cy - inner;
        // 시각적 핸들 위치: hit box 안에서 꼭짓점 위치
        final visualLeft = dx < 0 ? outer - handleSize / 2 : inner - handleSize / 2;
        final visualTop  = dy < 0 ? outer - handleSize / 2 : inner - handleSize / 2;
        return Positioned(
          left: left, top: top,
          child: GestureDetector(
            onPanUpdate: (d) => _resizeImage(id, d.delta),
            child: SizedBox(
              width: total, height: total,
              child: Stack(children: [
                Positioned(
                  left: visualLeft, top: visualTop,
                  child: Container(
                    width: handleSize, height: handleSize,
                    decoration: BoxDecoration(
                      color: Colors.blue, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        );
      }

      // 이미지 터치 영역
      // 고정 상태(isSelected=false)일 때는 translucent → 펜/터치가 Listener까지 통과
      widgets.add(Positioned(
        left: rect.left, top: rect.top, width: rect.width, height: rect.height,
        child: GestureDetector(
          behavior: isSelected ? HitTestBehavior.opaque : HitTestBehavior.translucent,
          onPanUpdate: isSelected ? (d) => _moveImage(d.delta) : null,
          onLongPress: () => setState(() { _imageSelected = true; _selectedImageIndex = i; }),
          child: Container(
            decoration: BoxDecoration(
              border: isSelected ? Border.all(color: Colors.blue.withValues(alpha: 0.7), width: 2) : null,
            ),
            child: isSelected ? const Center(child: Icon(Icons.open_with, color: Colors.white70, size: 28)) : null,
          ),
        ),
      ));

      // 크기 핸들 — 선택된 이미지만
      if (isSelected) {
        widgets.addAll([
          resizeHandle('tl', rect.left,  rect.top,    -1, -1),
          resizeHandle('tr', rect.right, rect.top,     1, -1),
          resizeHandle('bl', rect.left,  rect.bottom, -1,  1),
          resizeHandle('br', rect.right, rect.bottom,  1,  1),
        ]);
        // 삭제 버튼 — 우측 상단
        widgets.add(Positioned(
          left: rect.right - 14,
          top: rect.top - 14,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _images.removeAt(i);
                _imageSelected = false;
                _selectedImageIndex = -1;
              });
            },
            child: Container(
              width: 28, height: 28,
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
            ),
          ),
        ));
        // 고정 힌트 라벨
        widgets.add(Positioned(
          left: rect.left, top: rect.top - 22,
          child: GestureDetector(
            onTap: () => setState(() { _imageSelected = false; _selectedImageIndex = -1; }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.lock_open, color: Colors.white70, size: 11),
                SizedBox(width: 3),
                Text('탭하여 고정', style: TextStyle(color: Colors.white70, fontSize: 10)),
              ]),
            ),
          ),
        ));
      } else {
        // 고정 상태 — 길게 누르기 힌트
        widgets.add(Positioned(
          left: rect.left, top: rect.top - 22,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(4)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.lock_outline, color: Colors.white60, size: 11),
              SizedBox(width: 3),
              Text('길게 눌러 편집', style: TextStyle(color: Colors.white60, fontSize: 10)),
            ]),
          ),
        ));
      }
    }
    return widgets;
  }
}

class _StrokePainter extends CustomPainter {
  final _DrawingState drawing;
  final List<_EditorImage> images;
  final _LassoState? lassoState;
  final List<int> lassoSelectedIndices;
  final _CanvasBg canvasBg;

  _StrokePainter({
    required this.drawing,
    this.images = const [],
    this.lassoState,
    this.lassoSelectedIndices = const [],
    this.canvasBg = _CanvasBg.blank,
  }) : super(
            repaint: lassoState != null
                ? Listenable.merge([drawing, lassoState])
                : drawing);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width.isFinite ? size.width : 4000.0;
    final h = size.height.isFinite ? size.height : 4000.0;
    canvas.drawRect(Offset.zero & Size(w, h), Paint()..color = Colors.white);
    _paintBg(canvas, w, h);
    for (final img in images) {
      paintImage(canvas: canvas, rect: img.rect, image: img.decoded, fit: BoxFit.fill);
    }
    for (var i = 0; i < drawing.strokes.length; i++) {
      _paintStroke(canvas, drawing.strokes[i]);
    }
    if (drawing.currentStroke != null) {
      _paintStroke(canvas, drawing.currentStroke!);
    }
    // 올가미 선택된 스트로크 강조
    final _selIndices = lassoState?.selectedIndices ?? lassoSelectedIndices;
    if (_selIndices.isNotEmpty) {
      for (final idx in _selIndices) {
        if (idx < drawing.strokes.length) {
          final stroke = drawing.strokes[idx];
          if (stroke.points.length < 2) continue;
          final hPaint = Paint()
            ..color = Colors.deepPurple.withValues(alpha: 0.4)
            ..strokeWidth = stroke.width + 6
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke;
          for (var i = 0; i < stroke.points.length - 1; i++) {
            canvas.drawLine(stroke.points[i], stroke.points[i + 1], hPaint);
          }
        }
      }
    }
    // 올가미 경로 그리기
    if (lassoState != null && lassoState!.points.length > 1) {
      final path = Path()
        ..moveTo(lassoState!.points.first.dx, lassoState!.points.first.dy);
      for (final p in lassoState!.points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      if (lassoState!.complete) path.close();

      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.deepPurple.withValues(alpha: lassoState!.complete ? 0.12 : 0.08)
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.deepPurple.withValues(alpha: lassoState!.complete ? 0.9 : 0.6)
          ..strokeWidth = lassoState!.complete ? 2.0 : 1.5
          ..style = PaintingStyle.stroke,
      );
      // 선택 완료 후 이동 핸들 그리기 (캔버스 좌표 내에서)
      if (lassoState!.complete && lassoState!.centroid != null && !lassoState!.moving) {
        final c = lassoState!.centroid!;
        canvas.drawCircle(c, 24, Paint()..color = Colors.deepPurple.withValues(alpha: 0.85));
        canvas.drawCircle(c, 24, Paint()..color = Colors.white.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 2);
      }
    }
  }

  void _paintBg(Canvas canvas, double w, double h) {
    if (canvasBg == _CanvasBg.blank) return;
    const spacing = 30.0;
    final dotPaint = Paint()..color = const Color(0xFFBBBBBB);
    final linePaint = Paint()
      ..color = const Color(0xFFD0D0D0)
      ..strokeWidth = 0.6;

    switch (canvasBg) {
      case _CanvasBg.blank:
        break;
      case _CanvasBg.dots:
        for (double x = spacing; x <= w; x += spacing) {
          for (double y = spacing; y <= h; y += spacing) {
            canvas.drawCircle(Offset(x, y), 1.4, dotPaint);
          }
        }
      case _CanvasBg.lines:
        for (double y = spacing; y <= h; y += spacing) {
          canvas.drawLine(Offset(0, y), Offset(w, y), linePaint);
        }
      case _CanvasBg.grid:
        for (double y = spacing; y <= h; y += spacing) {
          canvas.drawLine(Offset(0, y), Offset(w, y), linePaint);
        }
        for (double x = spacing; x <= w; x += spacing) {
          canvas.drawLine(Offset(x, 0), Offset(x, h), linePaint);
        }
      case _CanvasBg.diagonal:
        // 45도 대각선 — 화면 왼쪽 위부터 오른쪽 아래 방향
        for (double d = -h; d <= w; d += spacing) {
          canvas.drawLine(
            Offset(d < 0 ? 0 : d, d < 0 ? -d : 0),
            Offset(d + h > w ? w : d + h, d + h > w ? w - d : h),
            linePaint,
          );
        }
    }
  }

  void _paintStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.length < 2) return;
    final isHighlight = stroke.color.a < 0.9;
    final paint = Paint()
      ..color = isHighlight ? stroke.color.withValues(alpha: 1) : stroke.color
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    if (isHighlight) {
      // saveLayer로 감싸면 같은 stroke 내에서 겹쳐도 번지지 않음
      canvas.saveLayer(null, Paint()..color = stroke.color);
      final innerPaint = Paint()
        ..color = stroke.color.withValues(alpha: 1)
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.square
        ..style = PaintingStyle.stroke;
      for (var i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], innerPaint);
      }
      canvas.restore();
    } else {
      for (var i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) =>
      oldDelegate.canvasBg != canvasBg || true;
}

// 배경 선택 버튼의 미리보기 painter
class _BgPreviewPainter extends CustomPainter {
  final _CanvasBg bg;
  const _BgPreviewPainter(this.bg);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    if (bg == _CanvasBg.blank) return;

    const spacing = 8.0;
    final dotPaint = Paint()..color = const Color(0xFFBBBBBB);
    final linePaint = Paint()
      ..color = const Color(0xFFCCCCCC)
      ..strokeWidth = 0.5;

    switch (bg) {
      case _CanvasBg.blank:
        break;
      case _CanvasBg.dots:
        for (double x = spacing; x < size.width; x += spacing) {
          for (double y = spacing; y < size.height; y += spacing) {
            canvas.drawCircle(Offset(x, y), 0.8, dotPaint);
          }
        }
      case _CanvasBg.lines:
        for (double y = spacing; y < size.height; y += spacing) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
        }
      case _CanvasBg.grid:
        for (double y = spacing; y < size.height; y += spacing) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
        }
        for (double x = spacing; x < size.width; x += spacing) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
        }
      case _CanvasBg.diagonal:
        for (double d = -size.height; d <= size.width; d += spacing) {
          canvas.drawLine(
            Offset(d < 0 ? 0 : d, d < 0 ? -d : 0),
            Offset(d + size.height > size.width ? size.width : d + size.height,
                   d + size.height > size.width ? size.width - d : size.height),
            linePaint,
          );
        }
    }
  }

  @override
  bool shouldRepaint(covariant _BgPreviewPainter old) => old.bg != bg;
}

// ── 앱 선택 다이얼로그 ──────────────────────────────────────
// ── 스와이프로 삭제 버튼 드러내는 노드 연결 행 ──────────────
class _SwipeableLinkRow extends StatefulWidget {
  final MindNode target;
  final VoidCallback onNavigate;
  final VoidCallback onDelete;

  const _SwipeableLinkRow({
    super.key,
    required this.target,
    required this.onNavigate,
    required this.onDelete,
  });

  @override
  State<_SwipeableLinkRow> createState() => _SwipeableLinkRowState();
}

class _SwipeableLinkRowState extends State<_SwipeableLinkRow>
    with SingleTickerProviderStateMixin {
  static const _revealWidth = 56.0;
  late final AnimationController _ctrl;
  late final Animation<double> _offsetAnim;
  double _dragStart = 0;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _offsetAnim = Tween<double>(begin: 0, end: -_revealWidth)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails d) => _dragStart = d.localPosition.dx;

  void _onDragUpdate(DragUpdateDetails d) {
    final delta = d.localPosition.dx - _dragStart;
    final progress = (_open ? 1.0 + delta / _revealWidth : delta / (-_revealWidth)).clamp(0.0, 1.0);
    _ctrl.value = progress;
  }

  void _onDragEnd(DragEndDetails d) {
    if (_ctrl.value > 0.4) {
      _ctrl.forward().then((_) => setState(() => _open = true));
    } else {
      _ctrl.reverse().then((_) => setState(() => _open = false));
    }
  }

  Future<void> _confirmDelete() async {
    final label = widget.target.category.isEmpty ? '(이름 없음)' : widget.target.category;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('연결을 삭제하시겠습니까?'),
        content: Text('"$label" 노드와의 연결을 삭제합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('아니요'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('네'),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = widget.target.category.isEmpty ? '(이름 없음)' : widget.target.category;
    return GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _offsetAnim,
          builder: (context, _) => Stack(
            children: [
              Positioned(
                right: 0, top: 0, bottom: 0,
                width: _revealWidth,
                child: GestureDetector(
                  onTap: _confirmDelete,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(_offsetAnim.value, 0),
                child: Container(
                  color: cs.surface,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 8, color: Colors.orange),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: const Size(0, 28),
                          ),
                          onPressed: widget.onNavigate,
                          child: const Text('이동', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 스와이프로 삭제 버튼 드러내는 파일 행 ───────────────────
class _SwipeableFileRow extends StatefulWidget {
  final LinkedFile file;
  final VoidCallback onViewTap;
  final VoidCallback onDelete;

  const _SwipeableFileRow({
    super.key,
    required this.file,
    required this.onViewTap,
    required this.onDelete,
  });

  @override
  State<_SwipeableFileRow> createState() => _SwipeableFileRowState();
}

class _SwipeableFileRowState extends State<_SwipeableFileRow>
    with SingleTickerProviderStateMixin {
  static const _revealWidth = 56.0;
  late final AnimationController _ctrl;
  late final Animation<double> _offsetAnim;
  double _dragStart = 0;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _offsetAnim = Tween<double>(begin: 0, end: -_revealWidth)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onHorizontalDragStart(DragStartDetails d) {
    _dragStart = d.localPosition.dx;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails d) {
    final delta = d.localPosition.dx - _dragStart;
    // 왼쪽 드래그 → 열기, 오른쪽 → 닫기
    final progress = (_open ? 1.0 + delta / _revealWidth : delta / (-_revealWidth)).clamp(0.0, 1.0);
    _ctrl.value = progress;
  }

  void _onHorizontalDragEnd(DragEndDetails d) {
    if (_ctrl.value > 0.4) {
      _ctrl.forward().then((_) => setState(() => _open = true));
    } else {
      _ctrl.reverse().then((_) => setState(() => _open = false));
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제하시겠습니까?'),
        content: Text('"${widget.file.name}"을(를) 삭제합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('아니요'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('네'),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final file = widget.file;
    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _offsetAnim,
          builder: (context, _) {
            return Stack(
              children: [
                // 뒤에 숨어있는 삭제 버튼
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: _revealWidth,
                  child: GestureDetector(
                    onTap: _confirmDelete,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ),
                // 앞에 있는 행 (슬라이드)
                Transform.translate(
                  offset: Offset(_offsetAnim.value, 0),
                  child: Container(
                    color: cs.surface,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          if (file.extension == 'app') ...[
                            Text(
                              _kApps.firstWhere((a) => a.name == file.name,
                                  orElse: () => _AppInfo(file.name, file.path, '📱', '')).emoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                          ] else if (file.extension == 'youtube') ...[
                            Icon(Icons.smart_display_rounded, size: 16, color: Colors.red.shade400),
                            const SizedBox(width: 4),
                          ] else ...[
                            Icon(Icons.insert_drive_file_rounded, size: 16, color: cs.primary),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              file.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              minimumSize: const Size(0, 28),
                            ),
                            onPressed: widget.onViewTap,
                            child: Text(
                              file.extension == 'app' ? '열기' : '보기',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AppPickerDialog extends StatefulWidget {
  const _AppPickerDialog();
  @override
  State<_AppPickerDialog> createState() => _AppPickerDialogState();
}

class _AppPickerDialogState extends State<_AppPickerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _query = '';
  final _customSchemeController = TextEditingController();

  static const _categories = ['전체', 'SNS', '생산성', '미디어', '교육', '쇼핑/금융', '지도/교통', '건강', '기타'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _customSchemeController.dispose();
    super.dispose();
  }

  List<_AppInfo> _filtered(String category) {
    final q = _query.toLowerCase();
    return _kApps.where((a) {
      final catOk = category == '전체' || a.category == category;
      final nameOk = q.isEmpty || a.name.toLowerCase().contains(q);
      return catOk && nameOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 480,
        height: 560,
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
              child: Row(
                children: [
                  Icon(Icons.apps_rounded, color: cs.primary, size: 22),
                  const SizedBox(width: 8),
                  Text('앱 연결', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: cs.onSurface)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                  ),
                ],
              ),
            ),
            // 검색
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '앱 이름 검색...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            // 탭
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              tabs: _categories.map((c) => Tab(text: c)).toList(),
            ),
            // 앱 그리드
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _categories.map((cat) {
                  final apps = _filtered(cat);
                  return apps.isEmpty
                      ? const Center(child: Text('검색 결과 없음', style: TextStyle(color: Colors.grey)))
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: apps.length,
                          itemBuilder: (context, i) {
                            final app = apps[i];
                            return InkWell(
                              onTap: () => Navigator.pop(context, app),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(app.emoji, style: const TextStyle(fontSize: 28)),
                                    const SizedBox(height: 4),
                                    Text(
                                      app.name,
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                }).toList(),
              ),
            ),
            // 직접 입력
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customSchemeController,
                      decoration: InputDecoration(
                        hintText: '직접 입력: 앱이름::url스킴://',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: const Size(0, 36),
                    ),
                    onPressed: () {
                      final text = _customSchemeController.text.trim();
                      if (text.isEmpty) return;
                      final parts = text.split('::');
                      final name = parts.length >= 2 ? parts[0].trim() : text;
                      final scheme = parts.length >= 2 ? parts[1].trim() : text;
                      Navigator.pop(context, _AppInfo(name, scheme, '📱', '기타'));
                    },
                    child: const Text('추가', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
