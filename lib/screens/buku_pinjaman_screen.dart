import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BukuPinjamanScreen extends StatefulWidget {
  const BukuPinjamanScreen({super.key});

  @override
  State<BukuPinjamanScreen> createState() => _BukuPinjamanScreenState();
}

class _BukuPinjamanScreenState extends State<BukuPinjamanScreen> {
  // Dummy data for loaned books
  final List<Map<String, String>> _loanedBooks = [
    {
      "title": "Harry Potter",
      "author": "J.K. Rowling",
      "expiry": "18/12/2025"
    },
    {
      "title": "Perahu Kertas",
      "author": "Dee Lestari",
      "expiry": "20/02/2026"
    },
    {
      "title": "Dilan 1945",
      "author": "Pidi Baiq",
      "expiry": "03/11/2025"
    },
    {
      "title": "Peter Pan",
      "author": "James M. Barrie",
      "expiry": "30/01/2026"
    },
    {
      "title": "Ronggeng Dukuh Paruk",
      "author": "Ahmad Tohari",
      "expiry": "12/02/2026"
    },
    {
      "title": "Mariposa",
      "author": "Luluk HF",
      "expiry": "25/03/2026"
    },
    {
      "title": "5 cm",
      "author": "Donny Dhirgantoro",
      "expiry": "08/01/2026"
    },
    {
      "title": "Sebuah Seni untuk Bersikap Bodo Amat",
      "author": "Mark Manson",
      "expiry": "17/04/2026"
    },
    {
      "title": "Gadis Kretek",
      "author": "Ratih Kumala",
      "expiry": "30/12/2025"
    },
    {
      "title": "1984",
      "author": "George Orwell",
      "expiry": "14/02/2026"
    },
  ];

  List<Map<String, String>> _filteredBooks = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredBooks = _loanedBooks;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBooks = _loanedBooks.where((book) {
        final title = book['title']!.toLowerCase();
        final author = book['author']!.toLowerCase();
        return title.contains(query) || author.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get current date for the subtitle
    final String currentDate = DateFormat('EEEE, d MMMM', 'id_ID').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFF7BA7E2),
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
                      'Buku',
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Buku Pinjaman Kamu',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentDate, // e.g. "Minggu, 30 November"
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
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
                            hintText: 'Cari Buku Pinjaman',
                            hintStyle: TextStyle(color: Colors.grey),
                            prefixIcon: Icon(Icons.search, color: Colors.black54),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // LIST OF LOANED BOOKS
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
                                onTap: () {},
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
                                              'Kadaluarsa Peminjaman : ${book['expiry']}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.red,
                                                fontWeight: FontWeight.w500,
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
