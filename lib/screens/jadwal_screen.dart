// jadwal_page.dart
// no direct json decoding needed; Dio handles response parsing
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class Event {
  final int id;
  final String kode;
  final String namaMatkul;
  final String dosen;
  final String ruang;
  final String jamMulai;
  final String jamSelesai;
  final String tipe; // optional
  final String materi; // optional
  final String linkZoom; // optional

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
  Map<DateTime, List<Event>> _events = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchAndBuildEventsForMonth(_focusedDay);
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
    // If already an int
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

    // direct mapping from full Indonesian name
    if (_hariToWeekday.containsKey(s)) return _hariToWeekday[s];
    if (alt.containsKey(s)) return alt[s];

    // sometimes API returns like "Senin, Rabu" or "Senin / Rabu" - take first
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
      // Use Dio and include auth token from SharedPreferences (like KRS page)
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final dio = Dio();
      if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.headers['Content-type'] = 'application/json';
      dio.options.validateStatus = (_) => true;

      final url = "${ApiService.baseUrl}jadwal/daftar-jadwal";
      final response = await dio.get(url);

      if (response.statusCode != 200) {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
          _loading = false;
          _events = {};
        });
        return;
      }

      final List<dynamic> jadwals =
          response.data['jadwals'] ?? response.data['data'] ?? [];

      // Load user's KRS info to filter jadwal only for courses taken
      final userCourseSets = await _getUserKrsCourseSets();
      final Set<int> existingJadwalIds =
          (userCourseSets['ids'] as Set<int>?) ?? <int>{};
      final Set<String> existingNames =
          (userCourseSets['names'] as Set<String>?) ?? <String>{};

      // Build events map for the visible month range
      final lastDayOfMonth = DateTime(monthFocus.year, monthFocus.month + 1, 0);

      Map<DateTime, List<Event>> newEvents = {};

      for (var j in jadwals) {
        final namaHariRaw = j['nama_hari'] ?? j['hari'] ?? j['hari_nama'] ?? '';
        final weekday = _weekdayFrom(namaHariRaw);
        if (weekday == null) continue; // unknown day

        // Filter: only include jadwal that matches user's KRS courses
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
            existingNames.contains(namaMatkulFromApi))
          matchesKrs = true;

        if (!matchesKrs) continue;

        // Create Event object
        final ev = Event(
          id: j['id'] ?? 0,
          kode: j['kode'] ?? '',
          namaMatkul: j['nama_matakuliah'] ?? '',
          dosen: j['dosen'] ?? '',
          ruang: j['nama_ruang'] ?? '',
          jamMulai: j['jam_mulai'] ?? '',
          jamSelesai: j['jam_selesai'] ?? '',
          materi: j['materi'] ?? '',
          linkZoom: j['link_zoom'] ?? '',
        );

        // Walk through the days of the month and add event when weekday matches
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

  // Helper: fetch user's KRS and return two sets: existing jadwal ids and lowercased mata kuliah names
  Future<Map<String, dynamic>> _getUserKrsCourseSets() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final email = prefs.getString('auth_email');

    final dio = Dio();
    if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';
    dio.options.headers['Content-type'] = 'application/json';
    dio.options.validateStatus = (_) => true;

    try {
      if (email == null) return {'ids': <int>{}, 'names': <String>{}};

      // get mahasiswa to obtain nim
      final respMahasiswa = await dio.post(
        '${ApiService.baseUrl}mahasiswa/detail-mahasiswa',
        data: {'email': email},
      );
      if (respMahasiswa.statusCode != 200)
        return {'ids': <int>{}, 'names': <String>{}};
      final nim = respMahasiswa.data['data']?['nim']?.toString();
      if (nim == null) return {'ids': <int>{}, 'names': <String>{}};

      // get daftar KRS for mahasiswa
      final respKrs = await dio.get(
        '${ApiService.baseUrl}krs/daftar-krs?id_mahasiswa=$nim',
      );
      if (respKrs.statusCode != 200)
        return {'ids': <int>{}, 'names': <String>{}};
      final List<dynamic> daftarKrs = respKrs.data['data'] ?? [];
      if (daftarKrs.isEmpty) return {'ids': <int>{}, 'names': <String>{}};

      // pick the most recent KRS: prefer highest semester, fallback to largest id
      dynamic chosen = daftarKrs.first;
      try {
        chosen = daftarKrs.reduce((a, b) {
          final ase = a['semester'];
          final bse = b['semester'];
          final ai = ase is int
              ? ase
              : int.tryParse(ase?.toString() ?? '0') ?? 0;
          final bi = bse is int
              ? bse
              : int.tryParse(bse?.toString() ?? '0') ?? 0;
          if (bi != ai) return bi > ai ? b : a;
          final aid = a['id'] is int
              ? a['id']
              : int.tryParse(a['id']?.toString() ?? '0') ?? 0;
          final bid = b['id'] is int
              ? b['id']
              : int.tryParse(b['id']?.toString() ?? '0') ?? 0;
          return bid > aid ? b : a;
        });
      } catch (_) {}

      final idKrs = chosen['id'];
      if (idKrs == null) return {'ids': <int>{}, 'names': <String>{}};

      final respDetail = await dio.get(
        '${ApiService.baseUrl}krs/detail-krs?id_krs=$idKrs',
      );
      if (respDetail.statusCode != 200)
        return {'ids': <int>{}, 'names': <String>{}};
      final List<dynamic> daftarMatkul = respDetail.data['data'] ?? [];

      final Set<int> ids = {};
      final Set<String> names = {};
      for (final m in daftarMatkul) {
        try {
          final candidates = [
            'id_jadwal',
            'jadwal_id',
            'id_jadwal_krs',
            'id_jadwal',
          ];
          for (final k in candidates) {
            if (m[k] != null) {
              final jid = m[k] is int ? m[k] : int.tryParse(m[k].toString());
              if (jid != null) ids.add(jid);
              break;
            }
          }
        } catch (_) {}
        final name = (m['nama_matakuliah'] ?? m['nama'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        if (name.isNotEmpty) names.add(name);
      }

      return {'ids': ids, 'names': names};
    } catch (_) {
      return {'ids': <int>{}, 'names': <String>{}};
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[_dateOnly(day)] ?? [];
  }

  // Called when page changes (month navigation)
  void _onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    _fetchAndBuildEventsForMonth(_focusedDay);
  }

  @override
  Widget build(BuildContext context) {
    final monthTitle = DateFormat.yMMMM('id').format(_focusedDay);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        title: Text('', style: TextStyle(color: Colors.black)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset('assets/images/swu.png', width: 36, height: 36),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Calendar area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  // Title "Oktober, 2025" like sample
                  SizedBox(height: 4),
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
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    startingDayOfWeek: StartingDayOfWeek.sunday,
                    locale: 'id_ID',
                    headerVisible: false, // hide default header
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: true,
                      markersMaxCount: 1,
                      todayDecoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      selectedDecoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue),
                      ),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(fontWeight: FontWeight.w500),
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
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      dowBuilder: (context, day) {
                        // Map DateTime.weekday (Mon=1..Sun=7) to Indonesian short names
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
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Prev / Next custom buttons like sample
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
                          child: Icon(
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
                          child: Icon(
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

            // Body: events list or message
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                  ? Center(child: Text(_error))
                  : _buildEventList(),
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
        color: Color(0xFF8FB1F3), // soft blue similar to sample
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row: "#127 Mobile Programming (Introduction)" style
          Text(
            '${e.kode} ${e.namaMatkul}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          // dosen and pertemuan etc (we only have dosen)
          Text(
            e.dosen,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Rg. ${e.ruang}',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(width: 12),
              Text(
                '${e.jamMulai} - ${e.jamSelesai}',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(width: 12),
              Text(
                'Luring',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ), // tipe mocked
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // left: Link Zoom
              TextButton(
                onPressed: () {
                  // open link if exists
                  if (e.linkZoom.isNotEmpty) {
                    // launch URL using url_launcher if added
                  } else {
                    // no link
                  }
                },
                child: Text(
                  'Link Zoom',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.white,
                  ),
                ),
              ),

              // right: small materi.pdf button
              ElevatedButton(
                onPressed: () {
                  // download / open materi
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  e.materi.isNotEmpty ? e.materi : 'materi.pdf',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
