import 'package:flutter/material.dart';
import 'buku_pinjaman_screen.dart';
import 'detail_buku_screen.dart';

class EPerpusScreen extends StatefulWidget {
  const EPerpusScreen({super.key});

  @override
  State<EPerpusScreen> createState() => _EPerpusScreenState();
}

class _EPerpusScreenState extends State<EPerpusScreen> {
  final List<Map<String, String>> _books = [
    {
      "title": "Laskar Pelangi",
      "author": "Andrea Hirata",
      "description": "Novel Laskar Pelangi bercerita tentang kehidupan 10 anak dari keluarga miskin yang bersekolah (SD dan SMP) di sebuah sekolah Muhammadiyah di Belitung yang penuh dengan keterbatasan. Mereka adalah Ikal, Lintang, Sahara, Mahar, A Kiong, Syahdan, Kucai, Borek, Trapani, dan Harun."
    },
    {
      "title": "Rembulan Tenggelam di Wajahmu",
      "author": "Tere Liye",
      "description": "Novel ini berkisah tentang perjalanan hidup seorang pria bernama Rehan Raujana atau yang akrab dipanggil Ray. Ray adalah seorang anak yatim piatu yang tumbuh besar di panti asuhan. Kehidupan Ray dipenuhi dengan pertanyaan-pertanyaan besar tentang takdir, kehidupan, dan keadilan Tuhan."
    },
    {
      "title": "Laut Bercerita",
      "author": "Leila S. Chudori",
      "description": "Laut Bercerita bertutur tentang kisah keluarga yang kehilangan, sekumpulan sahabat yang merasakan kekosongan di dada, sekelompok orang yang gemar menyiksa dan lancar berkhianat, sejumlah keluarga yang mencari kejelasan makam anaknya, dan tentang cinta yang tak akan luntur."
    },
    {
      "title": "Dunia Sophie",
      "author": "Jostein Gaarder",
      "description": "Dunia Sophie adalah sebuah novel filsafat karya Jostein Gaarder yang diterbitkan pada tahun 1991. Novel ini berkisah tentang Sophie Amundsen, seorang remaja Norwegia yang suatu hari menerima surat misterius berisi pertanyaan-pertanyaan filosofis."
    },
    {
      "title": "Bumi Manusia",
      "author": "Pramoedya Ananta Toer",
      "description": "Bumi Manusia adalah buku pertama dari Tetralogi Buru karya Pramoedya Ananta Toer yang pertama kali diterbitkan oleh Hasta Mitra pada tahun 1980. Buku ini ditulis Pramoedya ketika ia masih mendekam di Pulau Buru. Menceritakan kisah Minke, seorang pribumi yang bersekolah di HBS."
    },
    {
      "title": "Cantik Itu Luka",
      "author": "Eka Kurniawan",
      "description": "Cantik Itu Luka adalah novel pertama karya Eka Kurniawan yang diterbitkan pada tahun 2002. Novel ini mengisahkan tentang Dewi Ayu, seorang pelacur yang bangkit dari kuburnya setelah dua puluh satu tahun kematiannya."
    },
    {
      "title": "Pulang",
      "author": "Leila S. Chudori",
      "description": "Pulang adalah sebuah novel karya Leila S. Chudori yang diterbitkan pada tahun 2012. Novel ini menceritakan kisah para eksil politik Indonesia yang terpaksa tinggal di luar negeri akibat peristiwa G30S/PKI."
    },
    {
      "title": "Hujan",
      "author": "Tere Liye",
      "description": "Novel Hujan menceritakan tentang persahabatan, cinta, perpisahan, melupakan, dan hujan. Berlatar belakang di tahun 2042 hingga 2050, di mana teknologi sudah sangat maju. Tokoh utamanya adalah Lail dan Esok."
    },
    {
      "title": "Negeri 5 Menara",
      "author": "Ahmad Fuadi",
      "description": "Negeri 5 Menara adalah novel karya Ahmad Fuadi yang diterbitkan oleh Gramedia pada tahun 2009. Novel ini bercerita tentang kehidupan 6 santri dari 6 daerah yang berbeda menuntut ilmu di Pondok Madani (PM) Ponorogo, Jawa Timur."
    },
    {
      "title": "Filosofi Teras",
      "author": "Henry Manampiring",
      "description": "Filosofi Teras adalah sebuah buku pengantar filsafat Stoa yang dibuat khusus untuk generasi milenial. Buku ini menjelaskan bagaimana menerapkan filosofi Stoa dalam kehidupan sehari-hari untuk mengatasi kekhawatiran dan hidup lebih tenang."
    },
  ];

  List<Map<String, String>> _filteredBooks = [];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _filteredBooks = _books;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBooks = _books.where((book) {
        final title = book['title']!.toLowerCase();
        final author = book['author']!.toLowerCase();
        return title.contains(query) || author.contains(query);
      }).toList();
    });
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7BA7E2),
      floatingActionButton: FloatingActionButton(
        onPressed: _scrollToTop,
        backgroundColor: const Color(0xFF7BA7E2),
        child: const Icon(Icons.arrow_upward, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'E-Perpus',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    height: 40,
                    width: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Image.asset('assets/images/swu.png'),
                  ),
                ],
              ),
            ),

            // BODY
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Perpustakaan Elektronik\nSTMIK Widya Utama',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // SEARCH BAR
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Cari Buku, Penulis',
                            hintStyle: TextStyle(color: Colors.grey),
                            prefixIcon: Icon(Icons.search, color: Colors.black54),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // BUTTON BUKU PINJAMAN
                      Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7BA7E2),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7BA7E2).withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const BukuPinjamanScreen(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: const [
                                  Icon(Icons.menu_book, color: Colors.white),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Buku Pinjaman Kamu',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios,
                                      color: Colors.white, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // LIST BUKU
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredBooks.length,
                        itemBuilder: (context, index) {
                          final book = _filteredBooks[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DetailBukuScreen(
                                        title: book['title']!,
                                        author: book['author']!,
                                        description: book['description']!,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // ICON BUKU
                                      Container(
                                        width: 50,
                                        height: 70,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.book,
                                          color: Colors.blue,
                                          size: 30,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // TEXT INFO
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              book['title']!,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              book['author']!,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black54,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              book['description']!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 40), // Bottom padding
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
