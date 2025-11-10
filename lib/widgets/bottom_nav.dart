import 'package:flutter/material.dart';
import '../screens/berita.dart';
import '../screens/home_screen.dart';

class BottomNav extends StatefulWidget {
  final int initialIndex;
  const BottomNav({super.key, this.initialIndex = 0});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  late int index;

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
  }

  void _onItemTapped(int i, BuildContext context) {
    setState(() => index = i);
    
    // Handle navigation based on index
    if (i == 1) { // News tab
      // Check if we're not already on the Berita page
      if (!(context.widget is Berita)) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Berita()),
        );
      }
    } else if (i == 0) { // Home tab
      // Check if we're not already on the Home page
      if (!(context.widget is HomeScreen)) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed, // biar semua ikon tampil
      backgroundColor: Colors.white, // latar belakang bar putih
      selectedItemColor: Colors.black, // warna ikon aktif hitam solid
      unselectedItemColor: Colors.black54, // warna ikon nonaktif hitam transparan
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      unselectedLabelStyle: const TextStyle(color: Colors.black54),

      currentIndex: index,
      onTap: (i) => _onItemTapped(i, context),
      items: const [
        BottomNavigationBarItem(icon: ImageIcon(
            AssetImage('assets/icons/home.png'),
            size: 26,
          ), label: "Home"),
        BottomNavigationBarItem(icon: ImageIcon(
            AssetImage('assets/icons/news.png'),
            size: 26,
          ), label: "News"),
      ],
    );
  }
}
