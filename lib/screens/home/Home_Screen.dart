import 'dart:async';
import 'package:flutter/material.dart';
import '../profile/Profile_Screen.dart';
import '../search/Search_Screen.dart';
import '../watch/Watch_Screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _currentBanner = 0;
  final PageController _pageController = PageController();
  Timer? _timer;

  final List<Map<String, String>> banners = [
    {
      "image": "assets/posters/am_ha_truyen.jpg",
      "title": "Ám Hà Truyện",
      "desc": "Hành Động • 2024",
      "url360": "https://example.r2.cloud/ngutru_360.mp4",
      "url720": "https://example.r2.cloud/ngutru_720.mp4",
    },
    {
      "image": "assets/posters/tuyet_canh_ba.jpg",
      "title": "Tuyết Canh Ba",
      "desc": "Trung Quốc",
      "url480":
      "https://pub-ba53485be5b04ffe9192e4aae5ed2da6.r2.dev/phimtuyecanhba/480p/tuyetcanhba_480.m3u8",
      "url720":
      "https://pub-ba53485be5b04ffe9192e4aae5ed2da6.r2.dev/phimtuyecanhba/720p/tuyetcanhba_720p.m3u8",
    },
    {
      "image": "assets/posters/nhat_tieu_tuy_ca.jpg",
      "title": "Nhất Tiếu Tùy Ca",
      "desc": "Trung Quốc",
      "url360": "https://example.r2.cloud/nhattieutuyca_360.mp4",
      "url720": "https://example.r2.cloud/nhattieutuyca_720.mp4",
    },
    {
      "image": "assets/posters/than_den_oi_uoc_di.jpg",
      "title": "Thần Đèn Ơi Ước Đi!",
      "desc": "Hài hước • 2024",
      "url360": "https://example.r2.cloud/thanden_360.mp4",
      "url720": "https://example.r2.cloud/thanden_720.mp4",
    },
    {
      "image": "assets/posters/ngu_tru_cua_bao_chua.jpg",
      "title": "Ngự Trù Của Bạo Chúa!",
      "desc": "Hài hước • 2024",
      "url360": "https://example.r2.cloud/ngutru_360.mp4",
      "url720": "https://example.r2.cloud/ngutru_720.mp4",
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentBanner + 1) % banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildTrangChu(context),
      const SearchScreen(),
      const Center(child: Text('❤️ Yêu thích', style: TextStyle(fontSize: 22))),
      const AccountScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Tìm kiếm'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Yêu thích'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }

  Widget _buildTrangChu(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("VTC Movie",
                      style: TextStyle(
                          color: Colors.green,
                          fontSize: 26,
                          fontWeight: FontWeight.bold)),
                  Row(
                    children: const [
                      Icon(Icons.search, color: Colors.white),
                      SizedBox(width: 12),
                      Icon(Icons.workspace_premium, color: Colors.amber),
                    ],
                  )
                ],
              ),
            ),

            // Tabs ngang
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: const [
                  CategoryTab(title: "Đề xuất", selected: true),
                  CategoryTab(title: "Phim Hàn"),
                  CategoryTab(title: "Phim Trung"),
                  CategoryTab(title: "Phim Việt"),
                  CategoryTab(title: "Show"),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Banner
            _buildBannerSection(),

            const SizedBox(height: 20),

            _buildMovieSection(
              title: "Top 10 Phim Thịnh Hành",
              movies: const [
                MovieCardFull(
                    image: 'assets/anh_chinh/ngu_tru_cua_bao_chua_chinh.jpg',
                    title: 'Ngự Trù Của Báo Chúa'),
                MovieCardFull(
                    image: 'assets/anh_chinh/nhat_tieu_tuy_ca_chinh.jpg',
                    title: 'Nhất Tiếu Tùy Ca'),
                MovieCardFull(
                    image: 'assets/anh_chinh/than_den_oi_uoc_di_chinh.jpg',
                    title: 'Thần Đèn Ơi Ước Đi!'),
                MovieCardFull(
                    image: 'assets/anh_chinh/tuyet_canh_ba_chinh.jpg',
                    title: 'Tuyết Canh Ba'),
              ],
            ),

            _buildMovieSection(
              title: "Phim Việt Nam ",
              movies: const [
                MovieCardFull(
                    image: 'assets/anh_chinh/tham_tu_kien_chinh.jpg',
                    title: 'Thám Tử Kiên: Kỳ án Không Đầu'),
                MovieCardFull(
                    image: 'assets/anh_chinh/cach_em_1_milimet_chinh.jpg',
                    title: 'Cách em 1 milimet'),
                MovieCardFull(
                    image: 'assets/anh_chinh/gio_ngang_khoang_troi_xanh_chinh.jpg',
                    title: 'Gió Ngang Khoảng Trời Xanh'),
              ],
            ),

            _buildMovieSection(
              title: "Phim Hàn Quốc",
              movies: const [
                MovieCardFull(
                    image: 'assets/anh_chinh/ngu_tru_cua_bao_chua_chinh.jpg',
                    title: 'Ngự Trù Của Bạo Chúa'),
                MovieCardFull(
                    image: 'assets/anh_chinh/than_den_oi_uoc_di_chinh.jpg',
                    title: 'Thần Đèn Ơi Ước Đi'),
                MovieCardFull(
                    image: 'assets/anh_chinh/cung_dien_ma_am_chinh.jpg',
                    title: 'Cung Điện Ma Ám'),
              ],
            ),

            _buildMovieSection(
              title: "Phim Trung Quốc",
              movies: const [
                MovieCardFull(
                    image: 'assets/anh_chinh/tuyet_canh_ba_chinh.jpg',
                    title: 'Tuyết Canh Ba'),
                MovieCardFull(
                    image: 'assets/anh_chinh/nhat_tieu_tuy_ca_chinh.jpg',
                    title: 'Nhất Tiếu Tùy Ca'),
                MovieCardFull(
                    image: 'assets/anh_chinh/am_ha_truyen_chinh.jpg',
                    title: 'Ám Hà Truyện'),
              ],
            ),



            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Banner Section
  Widget _buildBannerSection() {
    return SizedBox(
      height: 250,
      width: double.infinity,
      child: PageView.builder(
        controller: _pageController,
        itemCount: banners.length,
        onPageChanged: (index) => setState(() => _currentBanner = index),
        itemBuilder: (context, index) {
          final banner = banners[index];
          final url360 = banner["url360"] ?? banner["url480"];
          final url720 = banner["url720"];

          return GestureDetector(
            onTap: () {
              if (url360 != null && url720 != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WatchScreen(
                      title: banner["title"] ?? "Không rõ tên",
                      url360: url360,
                      url720: url720,
                    ),
                  ),
                );
              }
            },
            child: Stack(
              children: [
                Image.asset(banner["image"] ?? "",
                    width: double.infinity, height: 250, fit: BoxFit.cover),
                Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                        Colors.black.withOpacity(0.6)
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(banner["title"] ?? "",
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      Text(banner["desc"] ?? "",
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Movie section reuse
  Widget _buildMovieSection({
    required String title,
    required List<MovieCardFull> movies,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ),
        SizedBox(
          height: 250,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: movies,
          ),
        ),
      ],
    );
  }
}

// --- Widget phụ ---
class CategoryTab extends StatelessWidget {
  final String title;
  final bool selected;

  const CategoryTab({super.key, required this.title, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        title,
        style: TextStyle(
          color: selected ? Colors.white : Colors.grey,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
        ),
      ),
    );
  }
}

// --- Card phim full hình (bo góc + spacing đẹp) ---
class MovieCardFull extends StatelessWidget {
  final String image;
  final String title;

  const MovieCardFull({super.key, required this.image, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(left: 10, right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child:
            Image.asset(image, height: 210, width: 150, fit: BoxFit.cover),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
