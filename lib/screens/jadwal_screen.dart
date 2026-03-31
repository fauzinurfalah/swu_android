import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'absensi_screen.dart';

class Event {
  final int id;
  final String kode;
  final String namaMatkul;
  final String dosen;
  final String ruang;
  final String jamMulai;
  final String jamSelesai;
  final String tipe;
  final String materi;
  final String linkZoom;

  Event({
    required this.id,
    required this.kode,
    required this.namaMatkul,
    required this.dosen,
    required this.ruang,
    required this.jamMulai,
    required this.jamSelesai,
    this.tipe = '',
    this.materi = '',
    this.linkZoom = '',
  });
}

class JadwalPage extends StatefulWidget {
  const JadwalPage({Key? key}) : super(key: key);

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  static const String _selectedKrsPrefKey = 'selected_krs_id';

  Map<DateTime, List<Event>> _events = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _loading = true;
  String _error = '';
  List<dynamic> _daftarKrs = [];
  int? _selectedKrsId;
  Set<int> _filterJadwalIds = {};
  Set<String> _filterNames = {};
  Map<int, int> _scheduleIdToKrsDetailId = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _initKrsAndEvents();
  }

  Future<void> _initKrsAndEvents() async {
    await _loadDaftarKrs();
    if (_selectedKrsId != null) {
      await _loadKrsDetailToFilter(_selectedKrsId!);
    }
    await _fetchAndBuildEventsForMonth(_focusedDay);
  }

  Future<void> _loadDaftarKrs() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final List<dynamic> list = [
        {
          "id": 1,
          "semester": "5",
          "tahun_ajaran": "2023/2024"
        }
      ];
      setState(() {
        _daftarKrs = list;
        _selectedKrsId = 1;
      });
    } catch (e) {
      setState(() => _daftarKrs = []);
    }
  }

  Future<void> _loadKrsDetailToFilter(int idKrs) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final List<dynamic> daftarMatkul = [
        {
          "id": 1,
          "id_jadwal": 101,
          "nama_matakuliah": "Pemrograman Mobile"
        },
        {
          "id": 2,
          "id_jadwal": 102,
          "nama_matakuliah": "Statistik"
        }
      ];
      final ids = <int>{};
      final names = <String>{};
      final scheduleMap = <int, int>{};

      for (final m in daftarMatkul) {
        final krsDetailId = m['id'] as int;
        final scheduleId = m['id_jadwal'] as int;

        ids.add(scheduleId);
        scheduleMap[scheduleId] = krsDetailId;
        names.add(m['nama_matakuliah'].toString().toLowerCase());
      }
      setState(() {
        _filterJadwalIds = ids;
        _filterNames = names;
        _scheduleIdToKrsDetailId = scheduleMap;
      });
    } catch (e) {
      setState(() {
        _filterJadwalIds = {};
        _filterNames = {};
        _scheduleIdToKrsDetailId = {};
      });
    }
  }

  /// Utility: normalize date (strip time)
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Map bahasa hari (lowercased) -> weekday int (DateTime.weekday: Mon=1 .. Sun=7)
  final Map<String, int> _hariToWeekday = {
    'senin': DateTime.monday,
    'selasa': DateTime.tuesday,
    'rabu': DateTime.wednesday,
    'kamis': DateTime.thursday,
    'jumat': DateTime.friday,
    'sabtu': DateTime.saturday,
    'minggu': DateTime.sunday,
  };

  // Try to parse various formats returned by API into a weekday int (1..7)
  int? _weekdayFrom(dynamic raw) {
    if (raw == null) return null;

    if (raw is int) {
      if (raw >= 1 && raw <= 7) return raw;
      return null;
    }

    final s = raw.toString().trim().toLowerCase();
    if (s.isEmpty) return null;

    // If contains a number (like '1' or '1 - Senin'), try parse
    final numMatch = RegExp(r"\d+").firstMatch(s);
    if (numMatch != null) {
      final v = int.tryParse(numMatch.group(0)!);
      if (v != null && v >= 1 && v <= 7) return v;
    }

    // Common english names
    final Map<String, int> alt = {
      'mon': DateTime.monday,
      'monday': DateTime.monday,
      'tue': DateTime.tuesday,
      'tues': DateTime.tuesday,
      'tuesday': DateTime.tuesday,
      'wed': DateTime.wednesday,
      'wednesday': DateTime.wednesday,
      'thu': DateTime.thursday,
      'thur': DateTime.thursday,
      'thursday': DateTime.thursday,
      'fri': DateTime.friday,
      'friday': DateTime.friday,
      'sat': DateTime.saturday,
      'saturday': DateTime.saturday,
      'sun': DateTime.sunday,
      'sunday': DateTime.sunday,

      // Indonesian common abbreviations
      'sen': DateTime.monday,
      'sel': DateTime.tuesday,
      'rab': DateTime.wednesday,
      'kam': DateTime.thursday,
      'jum': DateTime.friday,
      'sab': DateTime.saturday,
      'min': DateTime.sunday,
      'mg': DateTime.sunday,
    };

    if (_hariToWeekday.containsKey(s)) return _hariToWeekday[s];
    if (alt.containsKey(s)) return alt[s];

    final first = s.split(RegExp(r'[,/\\|;]')).first.trim();
    if (first.isNotEmpty) {
      if (_hariToWeekday.containsKey(first)) return _hariToWeekday[first];
      if (alt.containsKey(first)) return alt[first];
    }

    return null;
  }

  Future<void> _fetchAndBuildEventsForMonth(DateTime monthFocus) async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      final List<dynamic> jadwals = [
        {
          "id": 101,
          "hari": "Senin",
          "kode": "A11.1234",
          "nama_matakuliah": "Pemrograman Mobile",
          "dosen": "Dr. Dosen Dummy",
          "nama_ruang": "H.4.5",
          "jam_mulai": "08:00",
          "jam_selesai": "10:30",
          "materi": "Materi_Mobile.pdf",
          "link_zoom": "https://zoom.us/j/12345"
        },
        {
          "id": 102,
          "hari": "Kamis",
          "kode": "A11.5678",
          "nama_matakuliah": "Statistik",
          "dosen": "Prof. Data Dummy",
          "nama_ruang": "H.4.6",
          "jam_mulai": "10:00",
          "jam_selesai": "12:00",
          "materi": "Statistik.pdf",
          "link_zoom": ""
        }
      ];

      final Set<int> existingJadwalIds = _filterJadwalIds;
      final Set<String> existingNames = _filterNames;

      final lastDayOfMonth =
          DateTime(monthFocus.year, monthFocus.month + 1, 0);

      Map<DateTime, List<Event>> newEvents = {};

      for (var j in jadwals) {
        final namaHariRaw =
            j['nama_hari'] ?? j['hari'] ?? j['hari_nama'] ?? '';
        final weekday = _weekdayFrom(namaHariRaw);
        if (weekday == null) continue; // unknown day

        bool matchesKrs = false;
        try {
          final jid = j['id'] is int
              ? j['id']
              : int.tryParse(j['id']?.toString() ?? '');
          if (jid != null && existingJadwalIds.contains(jid)) matchesKrs = true;
        } catch (_) {}
        final namaMatkulFromApi = (j['nama_matakuliah'] ?? j['nama'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        if (!matchesKrs &&
            namaMatkulFromApi.isNotEmpty &&
            existingNames.contains(namaMatkulFromApi)) {
          matchesKrs = true;
        }

        if (!matchesKrs) continue;

        // Resolve ID: Use KRS Detail ID if available (mapped from Schedule ID), otherwise fallback to Schedule ID
        final scheduleId = j['id'] is int ? j['id'] : int.tryParse(j['id']?.toString() ?? '0') ?? 0;
        final finalId = _scheduleIdToKrsDetailId[scheduleId] ?? scheduleId;

        // Create Event object
        final ev = Event(
          id: finalId,
          kode: j['kode'] ?? '',
          namaMatkul: j['nama_matakuliah'] ?? '',
          dosen: j['dosen'] ?? '',
          ruang: j['nama_ruang'] ?? '',
          jamMulai: j['jam_mulai'] ?? '',
          jamSelesai: j['jam_selesai'] ?? '',
          materi: j['materi'] ?? '',
          linkZoom: j['link_zoom'] ?? '',
        );

        for (int d = 1; d <= lastDayOfMonth.day; d++) {
          final dt = DateTime(monthFocus.year, monthFocus.month, d);
          if (dt.weekday == weekday) {
            final key = _dateOnly(dt);
            newEvents.putIfAbsent(key, () => []).add(ev);
          }
        }
      }

      setState(() {
        _events = newEvents;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat jadwal: $e';
        _loading = false;
        _events = {};
      });
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[_dateOnly(day)] ?? [];
  }

  void _onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    _fetchAndBuildEventsForMonth(_focusedDay);
  }

  @override
  Widget build(BuildContext context) {
    final monthTitle = DateFormat.yMMMM('id').format(_focusedDay);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ===== CUSTOM HEADER (GANTI APPBAR) =====
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Image.asset(
                    'assets/images/swu.png',
                    width: 36,
                    height: 36,
                  ),
                ],
              ),
            ),

            // ===== MAIN CONTENT =====
            Expanded(
              child: Column(
                children: [
                  // Calendar area
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        if (_daftarKrs.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7BA7E2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButton<int>(
                                isExpanded: true,
                                value: _selectedKrsId,
                                dropdownColor: const Color(0xFF7BA7E2),
                                underline: const SizedBox.shrink(),
                                iconEnabledColor: Colors.white,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                items: _daftarKrs.map((krs) {
                                  final id = krs['id'] as int?;
                                  final semester =
                                      krs['semester']?.toString() ?? '-';
                                  final tahun =
                                      (krs['tahun_ajaran'] ?? krs['tahun'])
                                              ?.toString() ??
                                          '-';
                                  return DropdownMenuItem<int>(
                                    value: id,
                                    child: Text(
                                      'Semester $semester • $tahun',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) async {
                                  if (val == null) return;

                                  setState(() {
                                    _selectedKrsId = val;
                                    _loading = true;
                                  });

                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setInt(_selectedKrsPrefKey, val);

                                  await _loadKrsDetailToFilter(val);
                                  await _fetchAndBuildEventsForMonth(
                                      _focusedDay);
                                },
                              ),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          monthTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TableCalendar<Event>(
                          firstDay: DateTime.utc(2000, 1, 1),
                          lastDay: DateTime.utc(2100, 12, 31),
                          focusedDay: _focusedDay,
                          eventLoader: _getEventsForDay,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          startingDayOfWeek: StartingDayOfWeek.sunday,
                          locale: 'id_ID',
                          headerVisible: false, // hide default header
                          calendarStyle: CalendarStyle(
                            outsideDaysVisible: true,
                            markersMaxCount: 1,
                            todayDecoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  const Color.fromARGB(255, 131, 174, 255),
                              border: Border.all(
                                color: const Color.fromARGB(
                                    255, 156, 196, 255),
                              ),
                            ),
                            selectedDecoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.transparent,
                              border: Border.all(
                                color: const Color.fromARGB(
                                    255, 131, 174, 255),
                              ),
                            ),
                            todayTextStyle: const TextStyle(
                              color: Color.fromARGB(255, 255, 255, 255),
                              fontWeight: FontWeight.bold,
                            ),
                            selectedTextStyle: const TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          daysOfWeekStyle: const DaysOfWeekStyle(
                            weekdayStyle:
                                TextStyle(fontWeight: FontWeight.w500),
                            weekendStyle: TextStyle(color: Colors.red),
                          ),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          onPageChanged: _onPageChanged,
                          calendarBuilders: CalendarBuilders(
                            markerBuilder: (context, date, events) {
                              if (events.isNotEmpty) {
                                return Align(
                                  alignment: Alignment.bottomRight,
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(
                                      right: 6,
                                      bottom: 6,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                            dowBuilder: (context, day) {
                              const Map<int, String> names = {
                                DateTime.monday: 'Sen',
                                DateTime.tuesday: 'Sel',
                                DateTime.wednesday: 'Rab',
                                DateTime.thursday: 'Kam',
                                DateTime.friday: 'Jum',
                                DateTime.saturday: 'Sab',
                                DateTime.sunday: 'Mg',
                              };
                              final label = names[day.weekday] ?? '';
                              return Center(
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color.fromARGB(255, 5, 1, 1),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () {
                                final prev = DateTime(
                                  _focusedDay.year,
                                  _focusedDay.month - 1,
                                  1,
                                );
                                setState(() {
                                  _focusedDay = prev;
                                });
                                _onPageChanged(_focusedDay);
                              },
                              icon: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.chevron_left,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: () {
                                final next = DateTime(
                                  _focusedDay.year,
                                  _focusedDay.month + 1,
                                  1,
                                );
                                setState(() {
                                  _focusedDay = next;
                                });
                                _onPageChanged(_focusedDay);
                              },
                              icon: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.chevron_right,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Divider(color: Colors.grey.shade300, thickness: 1),
                      ],
                    ),
                  ),

                  // ===== LIST EVENT =====
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _error.isNotEmpty
                            ? Center(child: Text(_error))
                            : _buildEventList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay ?? _focusedDay);

    if (events.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada jadwal',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(children: events.map((e) => _buildEventCard(e)).toList()),
    );
  }

  Widget _buildEventCard(Event e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF8FB1F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${e.kode} ${e.namaMatkul}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            e.dosen,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Rg. ${e.ruang}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(width: 12),
              Text(
                '${e.jamMulai} - ${e.jamSelesai}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(width: 12),
              const Text(
                'Luring',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  if (e.linkZoom.isNotEmpty) {
                    // TODO: open link zoom
                  } else {
                    // TODO: show snackbar "Link Zoom belum tersedia"
                  }
                },
                icon: Icon(Icons.videocam,
                    color: Colors.blue.shade900, size: 18),
                label: Text(
                  'Link Zoom',
                  style: TextStyle(
                    color: Colors.blue.shade900,
                    fontSize: 12,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AbsenPage(
                        idKrsDetail: e.id,
                        namaMatkul: e.namaMatkul,
                      ),
                    ),
                  );
                },
                icon: Icon(
                  Icons.check_circle,
                  color: Colors.green.shade700,
                  size: 18,
                ),
                label: Text(
                  'Presensi',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 12,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: open/download materi
                },
                icon: Icon(Icons.picture_as_pdf,
                    color: Colors.red.shade700, size: 18),
                label: Text(
                  e.materi.isNotEmpty ? e.materi : 'materi.pdf',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 12,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
