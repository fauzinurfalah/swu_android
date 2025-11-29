// jadwal_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  // Replace with your real base url and token
  final String baseUrl = 'http://36.88.99.179:8000';
  final String token = '<YOUR_BEARER_TOKEN>';

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

  /// Map bahasa hari -> weekday int (DateTime.weekday: Mon=1 .. Sun=7)
  final Map<String, int> _hariToWeekday = {
    'Senin': DateTime.monday,
    'Selasa': DateTime.tuesday,
    'Rabu': DateTime.wednesday,
    'Kamis': DateTime.thursday,
    'Jumat': DateTime.friday,
    'Sabtu': DateTime.saturday,
    'Minggu': DateTime.sunday,
  };

  Future<void> _fetchAndBuildEventsForMonth(DateTime monthFocus) async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final uri = Uri.parse('$baseUrl/api/jadwal/daftar-jadwal');
      final res = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      // Validate HTTP status first
      if (res.statusCode != 200) {
        setState(() {
          _error = 'Server error: ${res.statusCode}';
          _loading = false;
          _events = {};
        });
        return;
      }

      // Guard against empty body
      if (res.body.trim().isEmpty) {
        setState(() {
          _error = 'Respons kosong dari server';
          _loading = false;
          _events = {};
        });
        return;
      }

      // Parse JSON safely
      Map<String, dynamic> body;
      try {
        body = json.decode(res.body) as Map<String, dynamic>;
      } catch (e) {
        setState(() {
          _error = 'Gagal parsing JSON: $e';
          _loading = false;
          _events = {};
        });
        return;
      }

      final List<dynamic> jadwals = body['jadwals'] ?? [];

      // Build events map for the visible month range
      final lastDayOfMonth = DateTime(monthFocus.year, monthFocus.month + 1, 0);

      Map<DateTime, List<Event>> newEvents = {};

      for (var j in jadwals) {
        final namaHari = j['nama_hari'] as String? ?? '';
        final weekday = _hariToWeekday[namaHari];
        if (weekday == null) continue; // unknown day

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
                        // Show "Mg Sen Sel Rab Kam Jum Sab" as in image abbreviations
                        final names = [
                          'Mg',
                          'Sen',
                          'Sel',
                          'Rab',
                          'Kam',
                          'Jum',
                          'Sab',
                        ];
                        return Center(
                          child: Text(
                            names[day.weekday - 1],
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
