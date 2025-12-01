import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';
import 'absen_submit_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AbsenPage extends StatefulWidget {
  final int idKrsDetail;
  final String namaMatkul;

  const AbsenPage({
    super.key,
    required this.idKrsDetail,
    required this.namaMatkul,
  });

  @override
  State<AbsenPage> createState() => _AbsenPageState();
}

class _AbsenPageState extends State<AbsenPage> {
  List<bool> sudahAbsen = List.generate(16, (_) => false);
  bool isLoading = true;
  String today = '';
  Map<String, dynamic>? user;

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    today = DateFormat("EEEE, d MMMM yyyy", "id_ID").format(DateTime.now());
    await Future.wait([_loadUser(), loadStatusAbsen()]);
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final email = prefs.getString('auth_email');

      if (email == null) return;

      Dio dio = Dio();
      if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.headers['Content-type'] = 'application/json';
      dio.options.validateStatus = (_) => true;

      final resp = await dio.post(
        "${ApiService.baseUrl}mahasiswa/detail-mahasiswa",
        data: {"email": email},
      );

      if (resp.statusCode == 200 &&
          resp.data != null &&
          resp.data['data'] != null) {
        setState(
          () => user = (resp.data['data'] is Map)
              ? Map<String, dynamic>.from(resp.data['data'])
              : null,
        );
      }
    } catch (e) {
      // ignore, optional user photo
    }
  }

  Future<void> loadStatusAbsen() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final dio = Dio();
      if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.headers['Content-type'] = 'application/json';
      dio.options.validateStatus = (_) => true;

      for (int i = 1; i <= 16; i++) {
        try {
          final url =
              "${ApiService.baseUrl}absensi/detail?id_krs_detail=${widget.idKrsDetail}&pertemuan=$i";
          final res = await dio.get(url);
          if (res.statusCode == 200 &&
              res.data != null &&
              res.data['data'] != null) {
            sudahAbsen[i - 1] = true;
          } else {
            sudahAbsen[i - 1] = false;
          }
        } catch (_) {
          sudahAbsen[i - 1] = false;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat status absensi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _openAbsen(int pertemuan) async {
    final result = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(
        builder: (_) => AbsenSubmitScreen(
          idKrsDetail: widget.idKrsDetail,
          pertemuan: pertemuan,
          namaMatkul: widget.namaMatkul,
        ),
      ),
    );

    if (result == true) {
      setState(() => sudahAbsen[pertemuan - 1] = true);
    }
  }

  Widget _buildCard(int index) {
    final pertemuan = index + 1;
    final done = sudahAbsen[index];

    final cardColor = done ? Colors.green.shade600 : Colors.grey.shade700;
    final pillBg = done ? Colors.white : const Color(0xFF91B9FF);
    final pillTextColor = done ? Colors.green.shade800 : Colors.white;
    final icon = done ? Icons.check_circle : Icons.event_note;
    final label = done ? 'LIHAT' : 'PRESENSI';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pertemuan $pertemuan',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: GestureDetector(
              onTap: () => _openAbsen(pertemuan),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: pillTextColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: pillTextColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fotoUrl =
        user != null && (user!['foto']?.toString().isNotEmpty ?? false)
        ? user!['foto'].toString()
        : null;
    final avatar = fotoUrl != null
        ? NetworkImage(fotoUrl) as ImageProvider
        : const AssetImage('assets/images/default_user.png');

    // logo kampus gaya seperti krs_detail_page
    final logoWidget = Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Image.asset('assets/images/swu.png', fit: BoxFit.contain),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF7BA7E2),
      body: SafeArea(
        child: Column(
          children: [
            // top header (back + small logo)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: const Color(0xFF7BA7E2),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'List Presensi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  logoWidget,
                ],
              ),
            ),

            // white header area with title + date + user photo (foto user ditampilkan di header putih)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Presensi ${widget.namaMatkul}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          today.isNotEmpty ? today : 'Memuat tanggal...',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(radius: 28, backgroundImage: avatar),
                ],
              ),
            ),

            // list area (keeps white background continuous)
            Expanded(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: 16,
                        itemBuilder: (context, idx) => _buildCard(idx),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
