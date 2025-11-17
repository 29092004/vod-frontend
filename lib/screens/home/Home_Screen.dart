import 'dart:async';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:movie_app/services/Film_Service.dart';
import '../../models/Film_info.dart';
import '../../services/Country_Service.dart';
import '../detail/Detail_Films.dart';
import '../favorite/Favorite_Screen.dart';
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
  final TextEditingController _searchController = TextEditingController();
  Timer? _timer;

  List<FilmInfo> _films = [];
  List<FilmInfo> _filteredFilms = [];

  // 🔥 QUỐC GIA LẤY THEO DB
  List<String> _countryTabs = ["Tất cả"];

  bool _isLoading = true;
  String _searchKeyword = "";
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
      final films = await FilmService.getHomeFilms();
      final dbCountries = await CountryService.getAll();

      final List<String> countryNames =
      dbCountries.map((c) => c.countryName.trim()).toList();

      setState(() {
        _films = films;
        _filteredFilms = films;

        // 🔥 Tabs = tất cả quốc gia (từ DB)
        _countryTabs = ["Tất cả", ...countryNames];

        _isLoading = false;
      });
    } catch (e) {
      print("❌ Lỗi tải phim: $e");
      setState(() => _isLoading = false);
    }
  }


  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _normalize(String input) =>
      removeDiacritics(input.toLowerCase().trim());

  void _onSearchChanged(String value) {
    setState(() {
      _searchKeyword = value;
      if (value.isEmpty) {
        _filteredFilms = List.from(_films);
      } else {
        final keyword = _normalize(value);
        _filteredFilms = _films.where((film) {
          final name = _normalize(film.filmName);
          final original = _normalize(film.originalName);
          return name.contains(keyword) || original.contains(keyword);
        }).toList();
      }
    });
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHome(context),
      const SearchScreen(),
      const FavoriteScreen(),
      const AccountScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Tìm kiếm'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Phim của tôi'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }

  // ======================= HOME ==========================
  Widget _buildHome(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }

    if (_films.isEmpty) {
      return const Center(
        child: Text("Không có dữ liệu phim",
            style: TextStyle(color: Colors.white, fontSize: 18)),
      );
    }

    // 🔥 PHÂN LOẠI QUỐC GIA TỰ ĐỘNG THEO DB
    final Map<String, List<FilmInfo>> filmByCountry = {};
    for (var c in _countryTabs) {
      if (c == "Tất cả") continue;
      filmByCountry[c] = _films.where((f) => f.countryName == c).toList();
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildBannerSection(_films),
            const SizedBox(height: 15),

            // ================= SEARCH =================
            if (_searchKeyword.isNotEmpty) _buildSearchResults()
            else ...[
              if (_selectedCountry == "Tất cả") ...[
                _buildMovieSection(
                  title: "Top 10 Phim Thịnh Hành",
                  films: _films.take(10).toList(),
                ),

                // 🔥 TỰ ĐỘNG HIỂN THỊ TỪ DB
                ...filmByCountry.entries.map((e) {
                  return _buildMovieSectionWithCount(
                    title: "Phim ${e.key}",
                    films: e.value,
                  );
                }).toList(),
              ]
              else ...[
                // 🔥 KHI NGƯỜI DÙNG CHỌN QUỐC GIA
                _buildMovieSection(
                  title:
                  "Phim $_selectedCountry (${filmByCountry[_selectedCountry]?.length ?? 0})",
                  films: filmByCountry[_selectedCountry] ?? [],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // ======================= HEADER ==========================
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.movie_creation_outlined, color: Colors.green, size: 28),
              SizedBox(width: 6),
              Text("VTC Movie",
                  style: TextStyle(
                      color: Colors.green,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),

          // Tìm kiếm
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.white70, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Tìm kiếm phim...",
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 🔥 TAB QUỐC GIA ĐỘNG THEO DB (GIỮ NGUYÊN UI)
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _countryTabs
                  .map((name) => _buildCountryTab(name))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ======================= SEARCH RESULT ==========================
  Widget _buildSearchResults() {
    final int count = _filteredFilms.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Text("Kết quả tìm kiếm ($count)",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ),

        if (_filteredFilms.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text("Không có phim phù hợp",
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 12,
              childAspectRatio: 0.55,
            ),
            itemCount: _filteredFilms.length,
            itemBuilder: (context, index) {
              final film = _filteredFilms[index];
              final poster = film.posterMain.isNotEmpty
                  ? film.posterMain
                  : film.posterBanner;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => DetailFilmScreen(filmId: film.filmId)),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        poster,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(film.filmName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                        const TextStyle(color: Colors.white, fontSize: 13)),
                    Text(film.countryName,
                        style:
                        const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // ======================= BANNER ==========================
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

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => DetailFilmScreen(filmId:film.filmId)),
              );
            },
            child: Stack(
              children: [
                Image.network(
                  bannerUrl,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),
                Container(
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
            ),
          );
        },
      ),
    );
  }

  // ======================= MOVIE SECTION ==========================
  Widget _buildMovieSection(
      {required String title, required List<FilmInfo> films}) {
    if (films.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: films.length,
            itemBuilder: (context, index) {
              final film = films[index];
              final poster = film.posterMain.isNotEmpty
                  ? film.posterMain
                  : film.posterBanner;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => DetailFilmScreen(filmId:film.filmId)),
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
                          poster,
                          height: 200,
                          width: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(film.originalName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                      Text(film.countryName,
                          style:
                          const TextStyle(color: Colors.grey, fontSize: 12)),
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

  // ======================= MOVIE SECTION WITH COUNT ==========================
  Widget _buildMovieSectionWithCount({
    required String title,
    required List<FilmInfo> films,
  }) {
    if (films.isEmpty) return const SizedBox.shrink();

    final bool searching = _searchKeyword.isNotEmpty;
    final newTitle = searching ? "$title (${films.length})" : title;

    return _buildMovieSection(title: newTitle, films: films);
  }

  // ======================= TAB QUỐC GIA ==========================
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
