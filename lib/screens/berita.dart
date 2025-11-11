import 'package:flutter/material.dart';
import './detail_berita_pages.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../api/api_service.dart';
import 'login_screen.dart';
import '../widgets/bottom_nav.dart';

enum BeritaFilter { all, read, unread, starred }

class Berita extends StatefulWidget {
  const Berita({super.key});

  @override
  State<Berita> createState() => _BeritaState();
}

class _BeritaState extends State<Berita> {
  List<dynamic> beritaAkademik = [];
  bool isLoading = true;
  String? error;
  
  BeritaFilter selectedFilter = BeritaFilter.all;
  String searchQuery = '';

  final Set<String> _readSet = {};
  final Set<String> _starredSet = {};

  @override
  void initState() {
    super.initState();
    _getBeritaAkademik();
  }
  
  Future<void> _handleLogout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
  
  Future<void> _getBeritaAkademik() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      if (token == null) {
        setState(() {
          error = "Silakan login kembali";
          isLoading = false;
        });
        return;
      }

      Dio dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.headers['Content-type'] = 'application/json';

      final response = await dio.get("${ApiService.baseUrl}info/berita");
      
      if (response.statusCode == 200) {
        setState(() {
          beritaAkademik = response.data["data"] ?? [];
          isLoading = false;
          error = null;
        });
      } else {
        setState(() {
          error = "Gagal memuat berita";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Terjadi kesalahan: ${e.toString()}";
        isLoading = false;
      });
    }
  }

  String _keyForBerita(dynamic berita, int index) {
    if (berita is Map && berita["id"] != null) return berita["id"].toString();
    if (berita is Map && berita["slug"] != null) return berita["slug"].toString();
    return index.toString();
  }

  void _toggleStar(String key) {
    setState(() {
      if (_starredSet.contains(key)) _starredSet.remove(key);
      else _starredSet.add(key);
    });
  }

  void _markRead(String key) {
    if (!_readSet.contains(key)) {
      setState(() => _readSet.add(key));
    }
  }
  
  Widget _buildFilterChip(String label, BeritaFilter filter) {
    final selected = selectedFilter == filter;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => setState(() => selectedFilter = filter),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black26),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
            ),
            child: Text(
              label,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: selected ? 32 : 0,
          height: 4,
          decoration: BoxDecoration(
            color: selected ? Colors.blue.shade700 : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChipWithStar(BeritaFilter filter) {
    final selected = selectedFilter == filter;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => setState(() => selectedFilter = filter),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black26),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.star, size: 16, color: Colors.amber),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: selected ? 32 : 0,
          height: 4,
          decoration: BoxDecoration(
            color: selected ? Colors.blue.shade700 : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
  Widget build(BuildContext context) {
    final List<dynamic> displayed = [];
    for (var i = 0; i < beritaAkademik.length; i++) {
      final b = beritaAkademik[i];
      final key = _keyForBerita(b, i);
  final isRead = _readSet.contains(key) || (b is Map && (b['is_read'] == true || b['read'] == true));

      var include = true;
      switch (selectedFilter) {
        case BeritaFilter.all:
          include = true;
          break;
        case BeritaFilter.read:
          include = isRead;
          break;
        case BeritaFilter.unread:
          include = !isRead;
          break;
        case BeritaFilter.starred:
          include = _starredSet.contains(key) || (b is Map && (b['starred'] == true || b['is_starred'] == true));
          break;
      }

      // Search filter
      if (include && searchQuery.isNotEmpty) {
        final title = (b['judul'] ?? '').toString().toLowerCase();
        final slug = (b['slug'] ?? '').toString().toLowerCase();
        final search = searchQuery.toLowerCase();
        include = title.contains(search) || slug.contains(search);
      }

      if (include) displayed.add(b);
    }
    return WillPopScope(
      onWillPop: () async {
        await _handleLogout();
        return false;
      },
      child: Scaffold(
        body: RefreshIndicator(
        onRefresh: _getBeritaAkademik,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Top: logo + search
              Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 56, 
                  width: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'assets/images/swu.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 16), 
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            onChanged: (value) => setState(() => searchQuery = value),
                            decoration: const InputDecoration(
                              hintText: 'Cari berita...',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                        if (searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () => setState(() => searchQuery = ''),
                            child: const Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Icon(Icons.close, color: Colors.grey, size: 20),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              ),
              const SizedBox(height: 28),
              // Title
              Row(
                children: const [
                  Text(
                    'News',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildFilterChip('Terbaca', BeritaFilter.read),
                  const SizedBox(width: 8),
                  _buildFilterChip('Belum Dibaca', BeritaFilter.unread),
                  const SizedBox(width: 8),
                  _buildFilterChipWithStar(BeritaFilter.starred),
                ],
              ),
              const SizedBox(height: 16),
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          error!,
                          style: TextStyle(color: Colors.red.shade700),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _getBeritaAkademik,
                          child: const Text("Coba Lagi"),
                        ),
                      ],
                    ),
                  ),
                )
              else if (beritaAkademik.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text("Belum Ada Berita Akademik"),
                  ),
                )
              else
                ListView.builder(
                    itemCount: displayed.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final berita = displayed[index];
                      final key = _keyForBerita(berita, index);
                      final isRead = _readSet.contains(key) || (berita is Map && (berita['is_read'] == true || berita['read'] == true));

                      // card visuals
                      final bgColor = !isRead ? Colors.blue.shade300 : Colors.grey.shade200;
                      final titleColor = !isRead ? Colors.white : Colors.black87;

                      // star button 
                      Widget starButton(String key) => GestureDetector(
                            onTap: () => _toggleStar(key),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _starredSet.contains(key) ? Colors.amber : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0,2))],
                              ),
                              child: Icon(
                                Icons.star,
                                color: _starredSet.contains(key) ? Colors.white : Colors.amber,
                              ),
                            ),
                          );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            GestureDetector(
                              onTap: () {
                                _markRead(key);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailBeritaPages(berita: berita),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          berita["judul"]?.toString() ?? "No Title",
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                            color: titleColor,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "Diupload pada: ${berita["createdAt"]?.toString() ?? ""}",
                                          style: TextStyle(fontSize: 12, color: titleColor.withOpacity(0.85)),
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          berita["slug"]?.toString() ?? "",
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 14, color: titleColor.withOpacity(0.9)),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            starButton(key),
                                          ],
                                        ),
                                      ],
                                    ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(initialIndex: 1),
    ),
  );
  }
}