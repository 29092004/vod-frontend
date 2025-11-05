import 'package:flutter/material.dart';
import 'package:diacritic/diacritic.dart';
import '../../models/Film_info.dart';
import '../../models/Genre.dart';
import '../../services/Film_Service.dart';
import '../../services/Gerne_Service.dart';
import '../detail/Detail_Films.dart'; // ✅ Thêm import này

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, Set<String>> selectedFilters = {};

  List<FilmInfo> _films = [];
  List<FilmInfo> _filteredFilms = [];
  List<Genre> _genres = [];

  bool _isLoading = true;
  String _searchKeyword = "";
  bool _showAllGenres = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        FilmService.getSearchFilms(),
        GenreService.getAll(),
      ]);
      setState(() {
        _films = results[0] as List<FilmInfo>;
        _filteredFilms = _films;
        _genres = results[1] as List<Genre>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Lỗi tải dữ liệu: $e");
      setState(() => _isLoading = false);
    }
  }

  String _normalize(String input) =>
      removeDiacritics(input.toLowerCase().trim());

  /// ✅ Quốc gia là chính, thể loại / năm là phụ (thêm chứ không lọc mất)
  void _applyFilters() {
    List<FilmInfo> filtered = [];

    final selectedCountries = selectedFilters["Khu vực"] ?? {};
    final selectedGenres = selectedFilters["Thể loại"] ?? {};
    final selectedYears = selectedFilters["Thập niên"] ?? {};
    final keyword = _normalize(_searchKeyword);

    // 🔹 1️⃣ Nếu chọn quốc gia → luôn giữ phim của quốc gia đó
    if (selectedCountries.isNotEmpty &&
        !selectedCountries.contains("Toàn bộ khu vực")) {
      filtered = _films
          .where((f) => selectedCountries.contains(f.countryName))
          .toList();
    } else {
      filtered = List.from(_films);
    }

    // 🔹 2️⃣ Nếu có chọn thể loại → thêm phim có thể loại đó
    if (selectedGenres.isNotEmpty) {
      final genreFilms = _films.where((f) => selectedGenres.any(
              (g) => f.genres.toLowerCase().contains(g.toLowerCase()))).toList();
      for (final film in genreFilms) {
        if (!filtered.contains(film)) filtered.add(film);
      }
    }

    // 🔹 3️⃣ Nếu có chọn năm → thêm phim có năm đó
    if (selectedYears.isNotEmpty) {
      final yearFilms = _films
          .where((f) => selectedYears.contains(f.releaseYear.toString()))
          .toList();
      for (final film in yearFilms) {
        if (!filtered.contains(film)) filtered.add(film);
      }
    }

    // 🔹 4️⃣ Lọc theo từ khóa tìm kiếm
    if (_searchKeyword.isNotEmpty) {
      filtered = filtered
          .where((f) =>
      _normalize(f.filmName).contains(keyword) ||
          _normalize(f.originalName).contains(keyword))
          .toList();
    }

    // 🔹 5️⃣ Nếu không có bộ lọc → hiển thị toàn bộ phim
    if ((selectedFilters.values.every((s) => s.isEmpty)) &&
        _searchKeyword.isEmpty) {
      filtered = List.from(_films);
    }

    setState(() => _filteredFilms = filtered);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCountries = selectedFilters["Khu vực"] ?? {};
    final bool hasCountryFilter = selectedCountries.isNotEmpty &&
        !selectedCountries.contains("Toàn bộ khu vực");

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Container(
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
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: "Tìm kiếm phim...",
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    _searchKeyword = value;
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
        ),
        bottom: hasCountryFilter
            ? null
            : TabBar(
          controller: _tabController,
          indicatorColor: Colors.green,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "Phim Bộ"),
            Tab(text: "Phim Lẻ"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : hasCountryFilter
          ? _buildAllFilmsView()
          : TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryTab(isSeries: true),
          _buildCategoryTab(isSeries: false),
        ],
      ),
    );
  }

  /// ✅ Khi chọn quốc gia: hiển thị toàn bộ phim
  Widget _buildAllFilmsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterSection("Khu vực", _getCountries()),
          _buildFilterSection("Thể loại", _getGenres()),
          _buildFilterSection("Thập niên", _getYears()),
          _buildFilterSection("Sắp xếp", ["Độ hot", "Mới nhất"]),
          const Divider(color: Colors.grey, thickness: 0.2),
          const SizedBox(height: 10),
          _buildMovieGrid(_filteredFilms),
        ],
      ),
    );
  }

  Widget _buildCategoryTab({required bool isSeries}) {
    final films = _filteredFilms.where((f) => f.isSeries == isSeries).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterSection("Khu vực", _getCountries()),
          _buildFilterSection("Thể loại", _getGenres()),
          _buildFilterSection("Thập niên", _getYears()),
          _buildFilterSection("Sắp xếp", ["Độ hot", "Mới nhất"]),
          const Divider(color: Colors.grey, thickness: 0.2),
          const SizedBox(height: 10),
          _buildMovieGrid(films),
        ],
      ),
    );
  }

  List<String> _getCountries() => [
    "Toàn bộ khu vực",
    ..._films
        .map((f) => f.countryName)
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList(),
  ];

  List<String> _getGenres() {
    final allGenres = _genres.map((g) => g.genreName).toList();
    return _showAllGenres
        ? ["Toàn bộ các loại", ...allGenres]
        : ["Toàn bộ các loại", ...allGenres.take(6), "..."];
  }

  List<String> _getYears() => [
    "Toàn bộ các thập niên",
    ..._films
        .map((f) => f.releaseYear.toString())
        .where((y) => y.isNotEmpty)
        .toSet()
        .toList(),
  ];

  Widget _buildFilterSection(String title, List<String> options) {
    selectedFilters.putIfAbsent(title, () => {});
    bool isGenreSection = title == "Thể loại";

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((option) {
          final bool isSelected = selectedFilters[title]!.contains(option);
          if (option == "..." && isGenreSection) {
            return GestureDetector(
              onTap: () => _showGenrePopup(context),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                const Text("...", style: TextStyle(color: Colors.white)),
              ),
            );
          }
          return GestureDetector(
            onTap: () {
              setState(() {
                if (option.startsWith("Toàn bộ")) {
                  selectedFilters[title]!.clear();
                } else {
                  if (isSelected) {
                    selectedFilters[title]!.remove(option);
                  } else {
                    selectedFilters[title]!.add(option);
                  }
                }
                _applyFilters();
              });
            },
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green : Colors.grey[850],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(option,
                  style:
                  const TextStyle(color: Colors.white, fontSize: 13)),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showGenrePopup(BuildContext context) {
    final allGenres = _genres.map((g) => g.genreName).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allGenres.map((genre) {
                    final isSelected =
                    selectedFilters["Thể loại"]!.contains(genre);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedFilters["Thể loại"]!.remove(genre);
                          } else {
                            selectedFilters["Thể loại"]!.add(genre);
                          }
                          _applyFilters();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color:
                          isSelected ? Colors.green : Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(genre,
                            style: const TextStyle(color: Colors.white)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// ✅ Khi nhấn phim → chuyển sang DetailFilms
  Widget _buildMovieGrid(List<FilmInfo> films) {
    if (films.isEmpty) {
      return const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text("Không có phim phù hợp",
                style: TextStyle(color: Colors.grey, fontSize: 14)),
          ));
    }
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 12,
        childAspectRatio: 0.55,
      ),
      itemCount: films.length,
      itemBuilder: (context, index) {
        final film = films[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailFilmScreen(
                  title: film.filmName,
                  description: film.description,
                  director: film.originalName,
                  posterUrl: film.posterMain,
                  url360: "", // có thể để rỗng nếu chưa có
                  url720: "",
                ),
              ),
            );
          },

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  film.posterMain.isNotEmpty
                      ? film.posterMain
                      : "https://via.placeholder.com/150",
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 6),
              Text(film.countryName,
                  style:
                  const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(film.filmName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                  const TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        );
      },
    );
  }
}
