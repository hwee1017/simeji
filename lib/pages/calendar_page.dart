import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/hive_service.dart';
import '../models/calendar_event_model.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late Box<CalendarEvent> _eventBox;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ko_KR', null);
    _selectedDay = DateTime.now();
    _eventBox = HiveService.calendarEventBox;
  }

  // ✅ 날짜 기준으로 일정 필터링
  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final normalized = DateTime.utc(day.year, day.month, day.day);
    return _eventBox.values
        .where((event) {
          final start = DateTime.utc(event.start.year, event.start.month, event.start.day);
          final end = DateTime.utc(event.end.year, event.end.month, event.end.day);
          return !normalized.isBefore(start) && !normalized.isAfter(end);
        })
        .toList();
  }

  // ✅ 일정 추가/수정 다이얼로그
  void _showAddEventDialog({CalendarEvent? existingEvent, DateTime? initialDate}) {
    final titleController = TextEditingController(text: existingEvent?.title ?? '');
    final descController = TextEditingController(text: existingEvent?.description ?? '');
    final locationController = TextEditingController(text: existingEvent?.location ?? '');
    DateTime startDate = existingEvent?.start ?? initialDate ?? DateTime.now();
    DateTime endDate = existingEvent?.end ?? startDate.add(const Duration(hours: 1));
    bool isAllDay = existingEvent?.isAllDay ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return AlertDialog(
            title: Text(existingEvent == null ? '일정 추가' : '일정 수정'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: '제목 (필수)'),
                  ),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: '설명'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('종일 일정'),
                      Switch(
                        value: isAllDay,
                        onChanged: (value) => setModalState(() => isAllDay = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text('시작 날짜: ${DateFormat('yyyy년 MM월 dd일', 'ko_KR').format(startDate)}'),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        locale: const Locale('ko', 'KR'),
                      );
                      if (picked != null) setModalState(() => startDate = picked);
                    },
                  ),
                  if (!isAllDay)
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text('시작 시간: ${DateFormat('a hh:mm', 'ko_KR').format(startDate)}'),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(startDate),
                        );
                        if (picked != null) {
                          setModalState(() {
                            startDate = DateTime(
                              startDate.year,
                              startDate.month,
                              startDate.day,
                              picked.hour,
                              picked.minute,
                            );
                          });
                        }
                      },
                    ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: Text('끝나는 날짜: ${DateFormat('yyyy년 MM월 dd일', 'ko_KR').format(endDate)}'),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        locale: const Locale('ko', 'KR'),
                      );
                      if (picked != null) setModalState(() => endDate = picked);
                    },
                  ),
                  if (!isAllDay)
                    ListTile(
                      leading: const Icon(Icons.access_time_filled),
                      title: Text('끝나는 시간: ${DateFormat('a hh:mm', 'ko_KR').format(endDate)}'),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(endDate),
                        );
                        if (picked != null) {
                          setModalState(() {
                            endDate = DateTime(
                              endDate.year,
                              endDate.month,
                              endDate.day,
                              picked.hour,
                              picked.minute,
                            );
                          });
                        }
                      },
                    ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: '위치'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('제목은 필수 입력 항목입니다.')),
                    );
                    return;
                  }

                  if (!isAllDay && !startDate.isBefore(endDate)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('시작 시각은 끝나는 시각보다 빨라야 합니다.')),
                    );
                    return;
                  }

                  if (existingEvent == null) {
                    await _addEvent(CalendarEvent(
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      location: locationController.text.trim(),
                      start: startDate,
                      end: endDate,
                      isAllDay: isAllDay,
                    ));
                  } else {
                    await _updateEvent(existingEvent, CalendarEvent(
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      location: locationController.text.trim(),
                      start: startDate,
                      end: endDate,
                      isAllDay: isAllDay,
                    ));
                  }

                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('완료'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _addEvent(CalendarEvent event) async {
    await _eventBox.add(event);
    setState(() {});
  }

  Future<void> _updateEvent(CalendarEvent oldEvent, CalendarEvent newEvent) async {
    oldEvent
      ..title = newEvent.title
      ..description = newEvent.description
      ..location = newEvent.location
      ..start = newEvent.start
      ..end = newEvent.end
      ..isAllDay = newEvent.isAllDay;
    await oldEvent.save();
    setState(() {});
  }

  Future<void> _deleteEvent(CalendarEvent event) async {
    await event.delete();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final events = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

    return Scaffold(
      appBar: AppBar(title: const Text('캘린더'), centerTitle: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final targetDate = _selectedDay ?? DateTime.now();
          _showAddEventDialog(initialDate: targetDate);
        },
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TableCalendar(
              locale: 'ko_KR',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: _getEventsForDay,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(color: Colors.deepPurpleAccent, shape: BoxShape.circle),
                markerDecoration: BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _selectedDay != null
                    ? DateFormat('yyyy년 MM월 dd일 일정', 'ko_KR').format(_selectedDay!)
                    : '날짜를 선택하세요',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: events.isEmpty
                  ? const Center(child: Text('등록된 일정이 없습니다.'))
                  : ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        final timeText = event.isAllDay
                            ? '종일'
                            : '${DateFormat('a hh:mm', 'ko_KR').format(event.start)} ~ ${DateFormat('a hh:mm', 'ko_KR').format(event.end)}';

                        return Dismissible(
                          key: ValueKey(event.key),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.redAccent,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) async {
                            await _deleteEvent(event);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('"${event.title}" 일정이 삭제되었습니다.')),
                            );
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            elevation: 2,
                            child: ListTile(
                              title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('$timeText\n${event.description ?? ''}'),
                              isThreeLine: true,
                              onTap: () => _showAddEventDialog(existingEvent: event),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
