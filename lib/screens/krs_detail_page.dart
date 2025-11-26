import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';

class KrsDetailPage extends StatefulWidget {
  final int idKrs;
  final String semester;
  final String tahunAjaran;

  const KrsDetailPage({
    super.key,
    required this.idKrs,
    required this.semester,
    required this.tahunAjaran,
  });

  @override
  State<KrsDetailPage> createState() => _KrsDetailPageState();
}

class _KrsDetailPageState extends State<KrsDetailPage> {
  List<dynamic> daftarMatkul = [];
  Map<String, dynamic>? user;
  bool isLoading = true;
  final int maxSks = 24;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => isLoading = true);
    await Future.wait([_loadUser(), _getDetailKrs()]);
    setState(() => isLoading = false);
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final email = prefs.getString('auth_email');

      if (email == null) return;

      final dio = Dio();
      if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.headers['Content-type'] = 'application/json';
      dio.options.validateStatus = (_) => true;

      final resp = await dio.post(
        "${ApiService.baseUrl}mahasiswa/detail-mahasiswa",
        data: {"email": email},
      );
      if (resp.statusCode == 200) {
        setState(
          () => user = (resp.data['data'] is Map)
              ? Map<String, dynamic>.from(resp.data['data'])
              : null,
        );
      }
    } catch (_) {
      // ignore, optional user photo
    }
  }

  Future<void> _getDetailKrs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final dio = Dio();
      if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.headers['Content-type'] = 'application/json';
      dio.options.validateStatus = (_) => true;

      final url = "${ApiService.baseUrl}krs/detail-krs?id_krs=${widget.idKrs}";
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        setState(() => daftarMatkul = response.data['data'] ?? []);
      } else {
        setState(() => daftarMatkul = []);
        final msg = (response.data is Map)
            ? (response.data['message'] ??
                  response.data['msg'] ??
                  response.data.toString())
            : response.data.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat detail KRS: $msg'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error get KRS: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memuat detail KRS'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => daftarMatkul = []);
    }
  }

  int get currentTotalSks {
    try {
      return daftarMatkul.fold(0, (sum, m) {
        final s = m['jumlah_sks'];
        final v = s is int ? s : int.tryParse(s?.toString() ?? '0') ?? 0;
        return sum + v;
      });
    } catch (_) {
      return 0;
    }
  }

  Future<void> _hapusMatakuliah(int idKrsDetail) async {
    final dio = Dio();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';
    dio.options.headers['Content-type'] = 'application/json';
    dio.options.validateStatus = (_) => true;

    try {
      final response = await dio.delete(
        "${ApiService.baseUrl}krs/hapus-course-krs?id=${idKrsDetail}",
      );
      final msg = (response.data is Map)
          ? (response.data['message'] ??
                response.data['msg'] ??
                response.data.toString())
          : response.data.toString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.green),
        );
        await _getDetailKrs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hapus gagal: $msg'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('hapus error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menghapus matakuliah'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // helper sets to prevent duplicate adds
  Set<int> _existingJadwalIds() {
    final s = <int>{};
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
            if (jid != null) s.add(jid);
            break;
          }
        }
      } catch (_) {}
    }
    return s;
  }

  Set<String> _existingNames() {
    final s = <String>{};
    for (final m in daftarMatkul) {
      final name = (m['nama_matakuliah'] ?? m['nama'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      if (name.isNotEmpty) s.add(name);
    }
    return s;
  }

  void _tambahMatkulModal() {
    final existingJadwal = _existingJadwalIds();
    final existingNames = _existingNames();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return TambahMatkulSheet(
          idKrs: widget.idKrs,
          currentTotalSks: currentTotalSks,
          maxSks: maxSks,
          existingJadwalIds: existingJadwal,
          existingNames: existingNames,
          onSuccess: () => _getDetailKrs(),
        );
      },
    );
  }

  void _confirmDelete(int? id) {
    if (id == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Matakuliah'),
        content: const Text('Yakin menghapus matakuliah ini dari KRS?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _hapusMatakuliah(id);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderContent() {
    final foto =
        (user != null && (user!['foto']?.toString().isNotEmpty ?? false))
        ? user!['foto'].toString()
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Semester ${widget.semester}",
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Tahun ${widget.tahunAjaran}",
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 36,
                backgroundImage: foto != null
                    ? NetworkImage(foto) as ImageProvider
                    : const AssetImage('assets/images/default_user.png'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(child: Divider()),
              const SizedBox(width: 8),
              Text(
                "$currentTotalSks / $maxSks SKS",
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCourseItem(Map<String, dynamic> mk) {
    final jumlah = mk['jumlah_sks'] is int
        ? mk['jumlah_sks']
        : int.tryParse(mk['jumlah_sks']?.toString() ?? '0') ?? 0;
    final hari = mk['nama_hari'] ?? mk['hari'] ?? '-';
    final jamMulai = mk['jam_mulai'] ?? '-';
    final jamSelesai = mk['jam_selesai'] ?? '-';
    final dosen = mk['dosen'] ?? '-';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Container(
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          child: const Icon(Icons.menu_book_rounded, color: Colors.blue),
        ),
        title: Text(
          mk['nama_matakuliah'] ?? mk['nama'] ?? '-',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text("SKS: $jumlah  •  Dosen: $dosen"),
            const SizedBox(height: 4),
            Text(
              "Jadwal: $hari, $jamMulai - $jamSelesai",
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
        trailing: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDelete(mk['id']),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7BA7E2),
      body: SafeArea(
        child: Column(
          children: [
            // header bar with back & title & small logo
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
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Detail KRS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(
                        'assets/images/swu.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // single white container for header + list to keep continuous background
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          // header content (inside same white area)
                          _buildHeaderContent(),
                          // list
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                              child: daftarMatkul.isEmpty
                                  ? const Center(
                                      child: Text(
                                        "Belum ada matakuliah yang dipilih.",
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: daftarMatkul.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 12),
                                      itemBuilder: (context, idx) {
                                        final mk = Map<String, dynamic>.from(
                                          daftarMatkul[idx],
                                        );
                                        return _buildCourseItem(mk);
                                      },
                                    ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: currentTotalSks >= maxSks ? null : _tambahMatkulModal,
        backgroundColor: currentTotalSks >= maxSks
            ? Colors.grey
            : const Color(0xFF42A5F5),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class TambahMatkulSheet extends StatefulWidget {
  final int idKrs;
  final VoidCallback onSuccess;
  final int currentTotalSks;
  final int maxSks;
  final Set<int> existingJadwalIds;
  final Set<String> existingNames;

  const TambahMatkulSheet({
    super.key,
    required this.idKrs,
    required this.onSuccess,
    required this.currentTotalSks,
    required this.maxSks,
    required this.existingJadwalIds,
    required this.existingNames,
  });

  @override
  State<TambahMatkulSheet> createState() => _TambahMatkulSheetState();
}

class _TambahMatkulSheetState extends State<TambahMatkulSheet> {
  List<dynamic> daftarMatkulTersedia = [];
  bool isLoading = true;
  bool adding = false;

  @override
  void initState() {
    super.initState();
    loadMatkul();
  }

  Future<void> loadMatkul() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final dio = Dio();
      if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.headers['Content-type'] = 'application/json';
      dio.options.validateStatus = (_) => true;

      final res = await dio.get("${ApiService.baseUrl}jadwal/daftar-jadwal");
      setState(
        () => daftarMatkulTersedia =
            res.data['jadwals'] ?? res.data['data'] ?? [],
      );
    } catch (e) {
      debugPrint('load jadwal error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memuat matakuliah'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> tambahMatkul(int idJadwal, int jumlahSks) async {
    if (widget.currentTotalSks + jumlahSks > widget.maxSks) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Melebihi batas maksimum SKS'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => adding = true);
    try {
      final dio = Dio();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.headers['Content-type'] = 'application/json';
      dio.options.validateStatus = (_) => true;

      final res = await dio.post(
        "${ApiService.baseUrl}krs/tambah-course-krs",
        data: {"id_krs": widget.idKrs, "id_jadwal": idJadwal},
      );
      final msg = (res.data is Map)
          ? (res.data['message'] ?? res.data['msg'] ?? res.data.toString())
          : res.data.toString();

      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.green),
        );
        widget.onSuccess();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan: $msg'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('tambah error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menambahkan matakuliah'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 460,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: daftarMatkulTersedia.length,
              itemBuilder: (context, index) {
                final mk = daftarMatkulTersedia[index];
                final jumlah = mk['jumlah_sks'] is int
                    ? mk['jumlah_sks']
                    : int.tryParse(mk['jumlah_sks']?.toString() ?? '0') ?? 0;

                final int? jadwalId = mk['id'] is int
                    ? mk['id']
                    : int.tryParse(mk['id']?.toString() ?? '');
                final String name = (mk['nama_matakuliah'] ?? mk['nama'] ?? '')
                    .toString()
                    .trim();
                final bool alreadyByJadwal =
                    jadwalId != null &&
                    widget.existingJadwalIds.contains(jadwalId);
                final bool alreadyByName =
                    name.isNotEmpty &&
                    widget.existingNames.contains(name.toLowerCase());
                final bool alreadyAdded = alreadyByJadwal || alreadyByName;

                final willExceed =
                    widget.currentTotalSks + jumlah > widget.maxSks;
                final disabled =
                    adding ||
                    willExceed ||
                    widget.currentTotalSks >= widget.maxSks ||
                    alreadyAdded;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(mk['nama_matakuliah'] ?? mk['nama'] ?? '-'),
                    subtitle: Text(
                      "SKS: $jumlah | ${mk['nama_hari'] ?? '-'}, ${mk['jam_mulai'] ?? '-'} - ${mk['jam_selesai'] ?? '-'}",
                    ),
                    trailing: Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(left: 6),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: disabled
                                ? Colors.grey.shade400
                                : Colors.green,
                          ),
                          IconButton(
                            icon: Icon(
                              alreadyAdded ? Icons.check : Icons.add,
                              color: Colors.white,
                            ),
                            onPressed: disabled
                                ? null
                                : () => tambahMatkul(
                                    jadwalId ?? mk['id'],
                                    jumlah,
                                  ),
                            tooltip: alreadyAdded
                                ? 'Sudah ditambahkan'
                                : 'Tambah',
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
