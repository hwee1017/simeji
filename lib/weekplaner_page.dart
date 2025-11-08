import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ===== Hive 모델 정의 =====
part 'weekplaner_page.g.dart'; // ✅ build_runner로 생성될 어댑터 파일

@HiveType(typeId: 0)
class Schedule extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  String description;
  @HiveField(3)
  int day; // 0=월 ... 6=일
  @HiveField(4)
  int startHour;
  @HiveField(5)
  int startMinute;
  @HiveField(6)
  int endHour;
  @HiveField(7)
  int endMinute;
  @HiveField(8)
  int colorValue;

  Schedule(
      this.id,
      this.name,
      this.description,
      this.day,
      this.startHour,
      this.startMinute,
      this.endHour,
      this.endMinute,
      this.colorValue,
      );
}

// ===== Hive 기반 스토어 =====
class ScheduleStore {
  static final ScheduleStore I = ScheduleStore._();
  ScheduleStore._();

  final ValueNotifier<List<Schedule>> items = ValueNotifier<List<Schedule>>([]);
  late Box<Schedule> _box;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ScheduleAdapter());
    _box = await Hive.openBox<Schedule>('schedules');
    items.value = _box.values.toList();
  }

  void add(Schedule s) async {
    await _box.put(s.id, s);
    items.value = _box.values.toList();
  }

  void deleteById(String id) async {
    await _box.delete(id);
    items.value = _box.values.toList();
  }

  List<Schedule> byDay(int d) => (List<Schedule>.from(items.value)
    ..retainWhere((e) => e.day == d)
    ..sort((a, b) => (a.startHour * 60 + a.startMinute)
        .compareTo(b.startHour * 60 + b.startMinute)));
}

// ===== 앱 시작 =====
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ScheduleStore.I.init(); // ✅ Hive 초기화 및 데이터 로드
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '주간 시간표',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
      home: const RootTabs(),
    );
  }
}

// ===== Root Tabs (일별/주간) =====
class RootTabs extends StatelessWidget {
  const RootTabs({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('주간 시간표'),
          bottom: const TabBar(tabs: [Tab(text: '일별 보기'), Tab(text: '주간 보기')]),
          actions: [
            IconButton(
              icon: const Icon(Icons.list_alt),
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const AllSchedulesPage())),
            ),
          ],
        ),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [DayTabs(), WeeklyView()],
        ),
        floatingActionButton: Builder(
          builder: (ctx) => FloatingActionButton(
            onPressed: () {
              final today = DateTime.now().weekday - 1;
              final nested = DayTabs.nestedTabKey.currentState;
              final idx = nested?.currentIndex ?? today;
              showModalBottomSheet(
                context: ctx,
                isScrollControlled: true,
                builder: (_) => AddScheduleForm(currentDayIndex: idx),
              );
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

// ===== Day Tabs =====
class DayTabs extends StatefulWidget {
  const DayTabs({super.key});
  static final nestedTabKey = GlobalKey<_DayTabsState>();
  @override
  State<DayTabs> createState() => _DayTabsState();
}

class _DayTabsState extends State<DayTabs> {
  int currentIndex = DateTime.now().weekday - 1;
  static const tabs = ['월', '화', '수', '목', '금', '토', '일'];
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      key: DayTabs.nestedTabKey,
      length: 7,
      initialIndex: currentIndex.clamp(0, 6),
      child: Builder(builder: (ctx) {
        final c = DefaultTabController.of(ctx)!;
        c.addListener(() {
          if (c.indexIsChanging) setState(() => currentIndex = c.index);
        });
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 44,
            titleSpacing: 0,
            title: TabBar(tabs: tabs.map((t) => Tab(text: t)).toList()),
          ),
          body: const TabBarView(
            physics: NeverScrollableScrollPhysics(),
            children: [
              DayView(dayIndex: 0),
              DayView(dayIndex: 1),
              DayView(dayIndex: 2),
              DayView(dayIndex: 3),
              DayView(dayIndex: 4),
              DayView(dayIndex: 5),
              DayView(dayIndex: 6),
            ],
          ),
        );
      }),
    );
  }
}

// ===== Day View (일별 화면) =====
class DayView extends StatefulWidget {
  final int dayIndex;
  const DayView({super.key, required this.dayIndex});
  @override
  State<DayView> createState() => _DayViewState();
}

class _DayViewState extends State<DayView> {
  // 레이아웃 상수
  final double hourHeight = 64;
  final double labelWidth = 48; // 더 왼쪽으로 붙임
  final double labelGap = 4;
  final double vGutter = 12; // 위/아래 숫자 안 잘리게 여백

  Timer? _timer;
  int get _today => DateTime.now().weekday - 1;
  double _minToPx(int m) => m * (hourHeight / 60.0);
  String _h(int x) => x.toString().padLeft(2, '0');

  @override
  void initState() {
    super.initState();
    if (widget.dayIndex == _today) {
      _timer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didUpdateWidget(covariant DayView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dayIndex != widget.dayIndex) {
      _timer?.cancel();
      if (widget.dayIndex == _today) {
        _timer = Timer.periodic(const Duration(minutes: 1), (_) {
          if (mounted) setState(() {});
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isToday = widget.dayIndex == _today;
    final now = DateTime.now();
    final redTop = vGutter + _minToPx(now.hour * 60 + now.minute);

    return ValueListenableBuilder<List<Schedule>>(
      valueListenable: ScheduleStore.I.items,
      builder: (_, __, ___) {
        final items = ScheduleStore.I.byDay(widget.dayIndex);
        final gridLeft = labelWidth + labelGap + 1; // divider
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: hourHeight * 24 + vGutter * 2, // 위아래 여백 추가
            child: Stack(
              children: [
                // 좌측 라벨 + 세로 구분선
                Positioned.fill(
                  child: Row(
                    children: [
                      SizedBox(
                        width: labelWidth,
                        child: Stack(
                          children: [
                            for (int h = 0; h <= 23; h++)
                              Positioned(
                                top: vGutter + h * hourHeight - 8,
                                right: 0,
                                child: Text(
                                  '${_h(h)}시',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(width: 1, color: Colors.grey.shade300),
                      SizedBox(width: labelGap),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ),
                // 가로 시간선
                for (int h = 0; h <= 23; h++)
                  Positioned(
                    top: vGutter + h * hourHeight,
                    left: gridLeft,
                    right: 8,
                    child: Container(height: 1, color: Colors.grey.shade300),
                  ),
                // 일정 블록 (좌: 제목 / 우: 설명)
                for (final e in items)
                  Positioned(
                    top: vGutter + _minToPx(e.startHour * 60 + e.startMinute),
                    left: gridLeft + 8,
                    right: 8,
                    height: max(
                      6.0,
                      _minToPx((e.endHour * 60 + e.endMinute) -
                          (e.startHour * 60 + e.startMinute)),
                    ),
                    child: GestureDetector(
                      onLongPress: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('삭제'),
                            content: Text('“${e.name}” 일정을 삭제할까요?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('취소')),
                              FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('삭제')),
                            ],
                          ),
                        );
                        if (ok == true) ScheduleStore.I.deleteById(e.id);
                      },
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(e.colorValue).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  e.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 13, height: 1.2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // 현재시간 빨간선 (일별만, 두껍게)
                if (isToday)
                  Positioned(
                    top: redTop,
                    left: labelWidth + 1,
                    right: 0,
                    child: Container(height: 4, color: Colors.red),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ===== Weekly View (주간 보기) =====
class WeeklyView extends StatelessWidget {
  const WeeklyView({super.key});
  String _h(int x) => x.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Schedule>>(
      valueListenable: ScheduleStore.I.items,
      builder: (_, list, __) {
        // 요일별 수집 & 정렬
        final byDay = List.generate(7, (_) => <Schedule>[]);
        for (final e in list) byDay[e.day].add(e);
        for (final l in byDay) {
          l.sort((a, b) => (a.startHour * 60 + a.startMinute)
              .compareTo(b.startHour * 60 + b.startMinute));
        }

        // 시간 범위 계산
        int? minMin, maxMin;
        for (final l in byDay) {
          for (final e in l) {
            minMin = (minMin == null)
                ? (e.startHour * 60 + e.startMinute)
                : min(minMin!, e.startHour * 60 + e.startMinute);
            maxMin = (maxMin == null)
                ? (e.endHour * 60 + e.endMinute)
                : max(maxMin!, e.endHour * 60 + e.endMinute);
          }
        }
        final fallbackStart = 8 * 60, fallbackEnd = 18 * 60;
        final startMin = minMin ?? fallbackStart;
        final endMin = maxMin ?? fallbackEnd;
        final minH = startMin ~/ 60;
        final maxH = (endMin % 60 == 0) ? endMin ~/ 60 : endMin ~/ 60 + 1;

        // 레이아웃 상수 (왼쪽 더 타이트 + 위아래 여백)
        const double hourHeight = 64;
        const double labelWidth = 48;
        const double labelGap = 4;
        const double vGutter = 12;
        final gridHeight = (maxH - minH) * hourHeight + vGutter * 2;

        // 헤더(월~일) — 세로 구분선
        final header = Row(
          children: [
            SizedBox(width: labelWidth),
            Container(width: 1, color: Colors.grey.shade300),
            const SizedBox(width: labelGap),
            Expanded(
              child: Row(
                children: [
                  for (int i = 0; i < 7; i++) ...[
                    Expanded(
                      child: Center(
                        child: Text(
                          const ['월','화','수','목','금','토','일'][i],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    if (i != 6) Container(width: 1, height: 20, color: Colors.grey.shade300),
                  ],
                ],
              ),
            ),
          ],
        );

        // 본문
        final body = SizedBox(
          height: gridHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 왼쪽 시간 라벨 (색 없음, 여백 적용)
              SizedBox(
                width: labelWidth,
                child: Stack(
                  children: [
                    for (int h = minH; h <= maxH; h++)
                      Positioned(
                        top: vGutter + (h - minH) * hourHeight - 8,
                        right: 0,
                        child: Text('${_h(h)}시',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade700)),
                      ),
                  ],
                ),
              ),
              Container(width: 1, color: Colors.grey.shade300),
              const SizedBox(width: labelGap),
              // 오른쪽 7개 칼럼 + 가로/세로 선
              Expanded(
                child: Stack(
                  children: [
                    // 가로 시간선
                    for (int h = minH; h < maxH; h++)
                      Positioned(
                        top: vGutter + (h - minH) * hourHeight,
                        left: 0,
                        right: 0,
                        child: Container(height: 1, color: Colors.grey.shade300),
                      ),
                    // 세로 구분선
                    LayoutBuilder(builder: (context, cons) {
                      final colW = (cons.maxWidth - 6) / 7;
                      return Stack(
                        children: [
                          for (int i = 1; i < 7; i++)
                            Positioned(
                              left: i * colW + (i - 1) * 1,
                              top: 0,
                              bottom: 0,
                              child:
                              Container(width: 1, color: Colors.grey.shade300),
                            ),
                        ],
                      );
                    }),
                    // 이벤트 칼럼
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int d = 0; d < 7; d++) Expanded(
                          child: _WeeklyDayColumn(
                            events: byDay[d],
                            globalMinH: minH,
                            hourHeight: hourHeight,
                            vGutter: vGutter,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        return Column(
          children: [
            const SizedBox(height: 8),
            header,
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: body,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WeeklyDayColumn extends StatelessWidget {
  final List<Schedule> events;
  final int globalMinH;
  final double hourHeight;
  final double vGutter;
  const _WeeklyDayColumn({
    required this.events,
    required this.globalMinH,
    required this.hourHeight,
    required this.vGutter,
  });

  double _minToPx(int m) => m * (hourHeight / 60.0);

  @override
  Widget build(BuildContext context) {
    const double minBlockHeight = 28;
    return Stack(
      children: [
        for (final e in events)
          Positioned(
            top: vGutter +
                _minToPx((e.startHour * 60 + e.startMinute) - globalMinH * 60),
            left: 4,
            right: 4,
            height: max(
              minBlockHeight,
              _minToPx((e.endHour * 60 + e.endMinute) -
                  (e.startHour * 60 + e.startMinute)),
            ),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Color(e.colorValue).withOpacity(0.95),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('',
                      style: TextStyle(fontSize: 0)), // 레이아웃 안정용(없어도 무방)
                ],
              ),
            ),
          ),
        for (final e in events)
          Positioned(
            top: vGutter +
                _minToPx((e.startHour * 60 + e.startMinute) - globalMinH * 60) +
                6,
            left: 10,
            right: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 1),
                Text(
                  e.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, height: 1.1),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ===== Add BottomSheet =====
class AddScheduleForm extends StatefulWidget {
  final int currentDayIndex;
  const AddScheduleForm({super.key, required this.currentDayIndex});
  @override
  State<AddScheduleForm> createState() => _AddScheduleFormState();
}

class _AddScheduleFormState extends State<AddScheduleForm> {
  final _nameC = TextEditingController();
  final _descC = TextEditingController();
  int _day = 0;
  TimeOfDay? _start, _end;
  @override
  void initState() {
    super.initState();
    _day = widget.currentDayIndex;
  }
  @override
  void dispose() {
    _nameC.dispose();
    _descC.dispose();
    super.dispose();
  }

  Future<void> _pick(bool start) async {
    final p = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (p != null) setState(() => start ? _start = p : _end = p);
  }

  void _save() {
    final n = _nameC.text.trim();
    final d = _descC.text.trim();
    if (n.isEmpty || d.isEmpty || _start == null || _end == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('모든 값을 입력하세요.')));
      return;
    }
    final s = _start!.hour * 60 + _start!.minute;
    final e = _end!.hour * 60 + _end!.minute;
    if (e <= s) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('종료 시간이 시작 시간보다 커야 합니다.')));
      return;
    }
    final color =
        Colors.primaries[Random().nextInt(Colors.primaries.length)].shade400.value;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    ScheduleStore.I.add(Schedule(
      id, n, d, _day,
      _start!.hour, _start!.minute, _end!.hour, _end!.minute, color,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding:
        EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('새 일정 추가',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _nameC,
              decoration: const InputDecoration(
                  labelText: '일정 이름', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descC,
              decoration:
              const InputDecoration(labelText: '설명', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(children: [
              const Text('요일: '),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _day,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('월')),
                  DropdownMenuItem(value: 1, child: Text('화')),
                  DropdownMenuItem(value: 2, child: Text('수')),
                  DropdownMenuItem(value: 3, child: Text('목')),
                  DropdownMenuItem(value: 4, child: Text('금')),
                  DropdownMenuItem(value: 5, child: Text('토')),
                  DropdownMenuItem(value: 6, child: Text('일')),
                ],
                onChanged: (v) => setState(() => _day = v ?? 0),
              ),
              const Spacer(),
              TextButton(
                  onPressed: () => _pick(true),
                  child:
                  Text(_start == null ? '시작 시간' : '시작 ${_start!.format(context)}')),
              const SizedBox(width: 8),
              TextButton(
                  onPressed: () => _pick(false),
                  child: Text(_end == null ? '종료 시간' : '종료 ${_end!.format(context)}')),
            ]),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(onPressed: _save, child: const Text('저장')),
            ),
          ]),
        ),
      ),
    );
  }
}

// ===== All Schedules =====
class AllSchedulesPage extends StatelessWidget {
  const AllSchedulesPage({super.key});
  String _day(int d) => const ['월','화','수','목','금','토','일'][d];
  String _p2(int x) => x.toString().padLeft(2, '0');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('전체 일정')),
      body: ValueListenableBuilder<List<Schedule>>(
        valueListenable: ScheduleStore.I.items,
        builder: (_, list, __) {
          if (list.isEmpty) return const Center(child: Text('저장된 일정이 없습니다.'));
          final s = List<Schedule>.from(list)
            ..sort((a, b) {
              final ka = a.day * 1440 + a.startHour * 60 + a.startMinute;
              final kb = b.day * 1440 + b.startHour * 60 + b.startMinute;
              return ka.compareTo(kb);
            });
          return ListView.separated(
            itemCount: s.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final e = s[i];
              final time =
                  '${_p2(e.startHour)}:${_p2(e.startMinute)} ~ ${_p2(e.endHour)}:${_p2(e.endMinute)}';
              return ListTile(
                leading: Container(width: 14, height: 14, color: Color(e.colorValue)),
                title: Text('${_day(e.day)} ${e.name}'),
                subtitle: Text('$time • ${e.description}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('삭제'),
                        content: Text('“${e.name}” 일정을 삭제할까요?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('취소')),
                          FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('삭제')),
                        ],
                      ),
                    );
                    if (ok == true) ScheduleStore.I.deleteById(e.id);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}