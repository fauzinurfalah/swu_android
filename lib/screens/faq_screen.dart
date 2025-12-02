import 'package:flutter/material.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final TextEditingController _searchC = TextEditingController();

  // Data FAQ
  final List<_FaqItem> _items = [
    _FaqItem(
      question: "Apa yang harus saya lakukan jika lupa password?",
      answer:
          "Saat ini tidak ada fitur lupa password di aplikasi.\nSilakan hubungi bagian akademik di kampus untuk reset password.",
    ),
    _FaqItem(
      question: "Bagaimana cara menghubungi admin akademik?",
      answer:
          "Kamu bisa menghubungi admin akademik melalui nomor telepon kampus atau datang langsung ke ruang akademik.",
    ),
    _FaqItem(
      question: "Panduan penggunaan aplikasi?",
      answer:
          "Belum ada di aplikasi. \nKalo butuh panduan, dateng aja ke kampus. \nNanti di jelasin sama mimin admin kalo mood ",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7BA7E2), // biru header
      body: Column(
        children: [
          // ===== HEADER =====
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Tombol back
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(30),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Bantuan",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // Logo (isi dengan asset kamu sendiri)
                  Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      'assets/images/swu.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===== BODY PUTIH MELENGKUNG =====
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "FAQ",
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Frequently Asked Question",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),

                    // ===== SEARCH BAR =====
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchC,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.search),
                          hintText: "Search Help",
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          setState(() {
                            // kalau mau dibuat filter, tinggal di-handle di sini
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      "FAQ",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),

                    // ===== LIST FAQ =====
                    Expanded(
                      child: ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFFE0E0E0)),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return _buildFaqTile(item);
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ===== FOOTER CHAT ADMIN =====
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Butuh bantuan? Kirim pesan ke Admin",
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Pesan di balas kalau mood",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: arahkan ke screen chat admin
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7BA7E2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Chat Admin",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600,color: Colors.white),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildFaqTile(_FaqItem item) {
    return InkWell(
      onTap: () {
        setState(() {
          item.isExpanded = !item.isExpanded;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BARIS PERTANYAAN + ICON
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.question,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          item.isExpanded ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  item.isExpanded ? Icons.remove : Icons.add,
                  size: 20,
                ),
              ],
            ),
          ),

          // JAWABAN (EXPAND)
          if (item.isExpanded)
            Padding(
              padding: const EdgeInsets.only(
                  left: 4, right: 32, bottom: 12), // sedikit ke dalam
              child: Text(
                item.answer,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade800,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Model FAQ sederhana
class _FaqItem {
  final String question;
  final String answer;
  bool isExpanded;

  _FaqItem({
    required this.question,
    required this.answer,
    this.isExpanded = false,
  });
}
