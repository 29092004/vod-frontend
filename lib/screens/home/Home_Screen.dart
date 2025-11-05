import 'dart:async';
import 'package:flutter/material.dart';
import 'package:movie_app/services/Film_Service.dart';
import '../../models/Film_info.dart';
import '../detail/Detail_Films.dart';
import '../profile/Profile_Screen.dart';
import '../search/Search_Screen.dart';

class HomeScreen extends StatefulWidget {
  final String email;
  const HomeScreen({super.key, required this.email});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _currentBanner = 0;
  final PageController _pageController = PageController();
  Timer? _timer;

  final FilmService _filmService = FilmService();
  List<FilmInfo> _films = [];
  bool _isLoading = true;

  // 🔹 Quốc gia đang chọn
  String _selectedCountry = "Tất cả";

  @override
  void initState() {
    super.initState();
    _loadFilms();

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients && _films.isNotEmpty) {
        int nextPage = (_currentBanner + 1) % _films.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadFilms() async {
    try {
      final films = await _filmService.getHomeFilms();
      setState(() {
        _films = films;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Lỗi tải danh sách phim: $e");
      setState(() => _isLoading = false);
    }
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

  // 🔹 Trang chủ
  Widget _buildTrangChu(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }

    if (_films.isEmpty) {
      return const Center(
        child: Text('Không có dữ liệu phim',
            style: TextStyle(color: Colors.white, fontSize: 18)),
      );
    }

    // 🔹 Lọc phim theo quốc gia
    final vietNamFilms = _films.where((f) => f.countryName == "Việt Nam").toList();
    final hanFilms = _films.where((f) => f.countryName == "Hàn Quốc").toList();
    final trungFilms = _films.where((f) => f.countryName == "Trung Quốc").toList();

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.movie_creation_outlined,
                              color: Colors.green, size: 28),
                          SizedBox(width: 6),
                          Text("VTC Movie",
                              style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        children: const [
                          Icon(Icons.search, color: Colors.white),
                          SizedBox(width: 12),
                          Icon(Icons.workspace_premium, color: Colors.amber),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 🔹 Thanh chọn quốc gia
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildCountryTab("Tất cả"),
                        _buildCountryTab("Việt Nam"),
                        _buildCountryTab("Hàn Quốc"),
                        _buildCountryTab("Trung Quốc"),
                        _buildCountryTab("Mỹ"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 🔹 Banner — LUÔN GIỮ NGUYÊN KHÔNG LỌC
            _buildBannerSection(_films),

            const SizedBox(height: 20),

            // 🔹 Nếu chọn "Tất cả" => hiện đủ Top 10 + 3 quốc gia
            if (_selectedCountry == "Tất cả") ...[
              _buildMovieSection(
                title: "Top 10 Phim Thịnh Hành",
                films: _films.take(10).toList(),
              ),
              _buildMovieSection(title: "Phim Việt Nam", films: vietNamFilms),
              _buildMovieSection(title: "Phim Hàn Quốc", films: hanFilms),
              _buildMovieSection(title: "Phim Trung Quốc", films: trungFilms),
            ]
            // 🔹 Nếu chọn quốc gia => chỉ hiển thị danh mục quốc gia, ẨN Top 10
            else if (_selectedCountry == "Việt Nam")
              _buildMovieSection(title: "Phim Việt Nam", films: vietNamFilms)
            else if (_selectedCountry == "Hàn Quốc")
                _buildMovieSection(title: "Phim Hàn Quốc", films: hanFilms)
              else if (_selectedCountry == "Trung Quốc")
                  _buildMovieSection(title: "Phim Trung Quốc", films: trungFilms),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // 🔹 Banner giữ nguyên
  Widget _buildBannerSection(List<FilmInfo> films) {
    return SizedBox(
      height: 250,
      width: double.infinity,
      child: PageView.builder(
        controller: _pageController,
        itemCount: films.length,
        onPageChanged: (index) => setState(() => _currentBanner = index),
        itemBuilder: (context, index) {
          final film = films[index];
          final bannerUrl =
          film.posterBanner.isNotEmpty ? film.posterBanner : film.posterMain;

          return Stack(
            children: [
              Image.network(
                bannerUrl,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/posters/default.jpg',
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),
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
                    Text(film.originalName,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    Text("${film.countryName} • ${film.releaseYear}",
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 🔹 Movie Section
  Widget _buildMovieSection({
    required String title,
    required List<FilmInfo> films,
  }) {
    if (films.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: films.length,
            itemBuilder: (context, index) {
              final film = films[index];
              final mainPoster =
              film.posterMain.isNotEmpty ? film.posterMain : film.posterBanner;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailFilmScreen(
                        title: film.originalName,
                        description: film.description.isEmpty
                            ? film.countryName
                            : film.description,
                        director: "Đạo diễn đang cập nhật...",
                        posterUrl: mainPoster,
                        url360: film.trailerUrl,
                        url720: film.trailerUrl,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 150,
                  margin: const EdgeInsets.only(left: 10, right: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          mainPoster,
                          height: 200,
                          width: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/posters/default.jpg',
                            height: 200,
                            width: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        film.originalName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        film.countryName,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 🔹 Tab quốc gia
  Widget _buildCountryTab(String label) {
    final bool selected = _selectedCountry == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCountry = label),
      child: Container(
        margin: const EdgeInsets.only(right: 14),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: selected ? Colors.white : Colors.grey,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
