import 'package:flutter/material.dart';

import '../models.dart';

// 화면 C: 코디 추천 결과
//
// ┌──────── 디자인 가이드 대응표: C 코디 추천 결과 ────────────────────────────┐
// │ 번호 │ Flutter 위젯명                   │ 비즈니스 명칭(한글) │ 원칙(P번호)  │
// │ C-1  │ showModalBottomSheet             │ 코디 추천 결과 시트 │ P03          │
// │ C-2  │ Text(bodyMedium)                 │ 선택 아이템 안내    │ P01          │
// │ C-3  │ ChoiceChip + 코디 정보 카드      │ 코디 아이디어 선택  │ P06          │
// │ C-4  │ Text(bodySmall, 회색)            │ 예시 결과 안내      │ P10          │
// └────────────────────────────────────────────────────────────────────────────┘
//
// 실제 AI 계산·추천 로직 없음. 미리 정한 예시 코디만 표시한다.

class _PresetOutfit {
  const _PresetOutfit({
    required this.title,
    required this.style,
    required this.items,
    required this.occasion,
    required this.reason,
  });

  final String title;
  final String style;
  final String items;
  final String occasion;
  final String reason;
}

// 기존 세 가지 코디를 유지하고 db.json에 있는 의류 이름으로 표시한다.
const _presetResults = [
  _PresetOutfit(
    title: '캐주얼 데일리룩',
    style: '캐주얼',
    items: '노란색 반팔 티셔츠 · 회색 트레이닝 팬츠 · 검은색 스니커즈',
    occasion: '학교 수업·등하교, 편한 일상 외출',
    reason: '노란색 티셔츠가 산뜻한 포인트가 되고, 편한 팬츠와 검은 스니커즈가 활동성을 더해요.',
  ),
  _PresetOutfit(
    title: '러블리 스커트룩',
    style: '러블리',
    items: '분홍색 니트 · 화이트 미니 스커트 · 화이트 베이직 스니커즈',
    occasion: '주말 약속, 카페 나들이',
    reason: '분홍색 니트와 밝은 스커트가 부드럽고 사랑스러운 분위기를 내요.',
  ),
  _PresetOutfit(
    title: '미니멀 레이어드룩',
    style: '미니멀',
    items: '흰색 니트 · 회색 트레이닝 팬츠 · 갈색 롱코트 · 검은색 스니커즈',
    occasion: '일상 외출, 도서관에서 보내는 날',
    reason: '차분한 색을 겹쳐 입어 깔끔하면서도 편안한 분위기를 연출해요.',
  ),
];

class ResultSheet extends StatefulWidget {
  const ResultSheet({super.key, required this.baseItem});

  final Item baseItem;

  // C-1: 현재 화면 위에 결과 시트를 표시한다.
  static Future<void> show(BuildContext context, Item item) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => ResultSheet(baseItem: item),
    );
  }

  @override
  State<ResultSheet> createState() => _ResultSheetState();
}

class _ResultSheetState extends State<ResultSheet> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final outfit = _presetResults[_selectedIndex];

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => ConstrainedBox(
          constraints: BoxConstraints(maxHeight: constraints.maxHeight * 0.9),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('코디 추천', style: text.titleLarge),
                const SizedBox(height: 4),
                Text(
                  '선택한 아이템: ${widget.baseItem.title}',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final (index, result) in _presetResults.indexed)
                      ChoiceChip(
                        label: Text('${index + 1}. ${result.style}'),
                        selected: _selectedIndex == index,
                        onSelected: (_) =>
                            setState(() => _selectedIndex = index),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(outfit.title, style: text.titleMedium),
                        const SizedBox(height: 8),
                        Chip(
                          avatar: const Icon(Icons.style_outlined, size: 18),
                          label: Text(outfit.style),
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(height: 8),
                        Text('코디 아이템', style: text.labelLarge),
                        const SizedBox(height: 4),
                        Text(outfit.items, style: text.bodyMedium),
                        const SizedBox(height: 12),
                        Text('추천 상황', style: text.labelLarge),
                        const SizedBox(height: 4),
                        Text(outfit.occasion, style: text.bodyMedium),
                        const SizedBox(height: 12),
                        Text('이런 점이 좋아요', style: text.labelLarge),
                        const SizedBox(height: 4),
                        Text(outfit.reason, style: text.bodyMedium),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '미리 준비한 코디 예시예요. 실제 AI 분석 결과가 아닙니다.',
                  style: text.bodySmall?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('닫기'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
