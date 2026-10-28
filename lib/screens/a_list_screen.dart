// 화면 A: 내 옷장 (GET /items)
//
// ┌──────── 디자인 가이드 대응표: A 내 옷장 ────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                    │ 비즈니스 명칭       │ 원칙     │
// │ A-1  │ AppBar                            │ 내 옷장 제목줄      │ P04      │
// │ A-2  │ ListView + Card (ItemCard)        │ 옷 카드 목록        │ P08      │
// │ A-3  │ GridView (넓은 화면 ≥600dp)        │ 옷 카드 격자        │ P08      │
// │ A-4  │ LoadingView                       │ 옷장 불러오는 중    │ P01      │
// │ A-5  │ ErrorView + FilledButton          │ 오류 안내·다시 시도 │ P09      │
// │ A-6  │ EmptyView                         │ 빈 옷장 안내        │ P01      │
// └──────────────────────────────────────────────────────────────────────────┘
// 전환: A → B 쌓기(Navigator.push). 너비 600dp 기준으로 목록/격자를 전환한다.
import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';
import 'b_detail_screen.dart';

/// 넓은 화면의 기준 너비
const wideBreakpoint = 600.0;

class ListScreen extends StatefulWidget {
  const ListScreen({
    super.key,
    this.load = fetchItems,
    this.loadNotes = fetchNotes,
  });

  final ItemsLoader load;
  final NotesLoader loadNotes;

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  late Future<List<Item>> _future = widget.load();
  String _selectedCategory = '전체';
  String _selectedColor = '전체 색상';

  // STATE: 카테고리·색상 필터 → A-2 / A-3 옷 카드 목록

  // A-5 P09: 오류가 발생하면 사용자가 다시 요청할 수 있다.
  void _retry() {
    setState(() {
      _future = widget.load();
    });
  }

  void _open(Item item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetailScreen(item: item, loadNotes: widget.loadNotes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // A-1 P04: 제목과 브랜드 이름을 일관되게 사용한다.
        title: const Row(
          children: [
            Icon(Icons.checkroom_outlined),
            SizedBox(width: 8),
            Text('ReWear AI'),
          ],
        ),
      ),
      body: FutureBuilder<List<Item>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView(label: '내 옷장을 불러오는 중…'); // A-4 P01
          }

          if (snap.hasError) {
            return ErrorView(
              title: '옷장을 불러오지 못했습니다.',
              message: '${snap.error}',
              onRetry: _retry,
            ); // A-5 P09
          }

          final items = snap.data ?? const <Item>[];

          if (items.isEmpty) {
            return const EmptyView(
              message: '아직 옷이 없습니다.\n옷장 데이터가 준비되면 여기에 표시됩니다.',
            ); // A-6 P01
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final filteredItems = items.where((item) {
                final categoryMatches =
                    _selectedCategory == '전체' ||
                    item.category == _selectedCategory;
                final colorMatches =
                    _selectedColor == '전체 색상' || item.color == _selectedColor;
                return categoryMatches && colorMatches;
              }).toList();
              final isWide = constraints.maxWidth >= wideBreakpoint;

              return Column(
                children: [
                  _buildFilters(),
                  Expanded(
                    child: filteredItems.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.search_off, size: 40),
                                  const SizedBox(height: 8),
                                  const Text('조건에 맞는 옷이 없어요.'),
                                  const SizedBox(height: 12),
                                  TextButton.icon(
                                    onPressed: _resetFilters,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('필터 초기화'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : isWide
                        ? GridView.builder(
                            // A-3 P08: 넓은 화면에서 사진을 한눈에 비교한다.
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 320,
                                  mainAxisExtent: 270,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                            itemCount: filteredItems.length,
                            itemBuilder: (context, i) => ItemCard(
                              filteredItems[i],
                              vertical: true,
                              onTap: () => _open(filteredItems[i]),
                            ),
                          )
                        : ListView.builder(
                            // A-2 P08: 좁은 화면에서 사진과 설명을 간결하게 보여 준다.
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: filteredItems.length,
                            itemBuilder: (context, i) => ItemCard(
                              filteredItems[i],
                              onTap: () => _open(filteredItems[i]),
                            ),
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _filterRow(
              '종류',
              const ['전체', '상의', '하의', '신발'],
              _selectedCategory,
              (value) => setState(() => _selectedCategory = value),
            ),
            _filterRow(
              '색상',
              const ['전체 색상', '흰색', '파란색', '검은색', '노란색', '갈색', '분홍색', '회색'],
              _selectedColor,
              (value) => setState(() => _selectedColor = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterRow(
    String label,
    List<String> options,
    String selected,
    ValueChanged<String> onSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 42, child: Text(label)),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final option in options)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(option),
                        selected: selected == option,
                        onSelected: (_) => onSelected(option),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = '전체';
      _selectedColor = '전체 색상';
    });
  }
}

/// 옷 카드 — 화면 A의 A-2 / A-3
class ItemCard extends StatelessWidget {
  const ItemCard(this.item, {super.key, this.onTap, this.vertical = false});

  final Item item;
  final VoidCallback? onTap;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.title,
          style: text.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (item.category.isNotEmpty || item.color.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            [
              item.category,
              item.color,
            ].where((value) => value.isNotEmpty).join(' · '),
            style: text.bodySmall,
          ),
        ],
        const SizedBox(height: 4),
        Text(
          item.subtitle,
          style: text.bodySmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (item.tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final tag in item.tags.take(3))
                Chip(
                  label: Text(tag),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
        ],
      ],
    );

    return Card(
      margin: vertical
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: vertical
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: NetImage(item.image)),
                  Padding(padding: const EdgeInsets.all(12), child: info),
                ],
              )
            : Row(
                children: [
                  NetImage(item.image, width: 108, height: 112),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: info,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                  const SizedBox(width: 8),
                ],
              ),
      ),
    );
  }
}
