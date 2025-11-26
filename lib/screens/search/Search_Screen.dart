import 'package:flutter/material.dart';
import 'package:diacritic/diacritic.dart';
import '../../models/Film_info.dart';
import '../../models/Genre.dart';
import '../../services/Film_Service.dart';
import '../../services/Gerne_Service.dart';
import '../detail/Detail_Films.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final Map<String, Set<String>> selectedFilters = {};
  List<FilmInfo> _films = [];
  List<FilmInfo> _filteredFilms = [];
  List<Genre> _genres = [];

  bool _isLoading = true;
  bool _showFilterPanel = false;
  String _searchKeyword = "";

  @override
  void initState() {
    super.initState();
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

  void _applyFilters() {
    List<FilmInfo> filtered = List.from(_films);

    final selectedCountries = selectedFilters["Khu vực"] ?? {};
    final selectedGenres = selectedFilters["Thể loại"] ?? {};
    final selectedYears = selectedFilters["Thập niên"] ?? {};
    final selectedType = selectedFilters["Loại phim"] ?? {};
    final keyword = _normalize(_searchKeyword);

    if (selectedType.isNotEmpty &&
        !selectedType.contains("Toàn bộ loại phim")) {
      if (selectedType.contains("Phim Bộ")) {
        filtered = filtered.where((f) => f.isSeries == true).toList();
      } else if (selectedType.contains("Phim Lẻ")) {
        filtered = filtered.where((f) => f.isSeries == false).toList();
      }
    }

    if (selectedCountries.isNotEmpty &&
        !selectedCountries.contains("Toàn bộ khu vực")) {
      filtered = filtered
          .where((f) => selectedCountries.contains(f.countryName))
          .toList();
    }

    if (selectedGenres.isNotEmpty &&
        !selectedGenres.contains("Toàn bộ các loại")) {
      filtered = filtered
          .where((f) =>
          selectedGenres.any(
                  (g) => f.genres.toLowerCase().contains(g.toLowerCase())))
          .toList();
    }

    if (selectedYears.isNotEmpty &&
        !selectedYears.contains("Toàn bộ các thập niên")) {
      filtered = filtered
          .where((f) => selectedYears.contains(f.releaseYear.toString()))
          .toList();
    }

    if (_searchKeyword.isNotEmpty) {
      filtered = filtered
          .where((f) =>
      _normalize(f.filmName).contains(keyword) ||
          _normalize(f.originalName).contains(keyword))
          .toList();
    }

    setState(() => _filteredFilms = filtered);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "KHO PHIM",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _buildMainView(),
    );
  }

  Widget _buildMainView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔍 Thanh tìm kiếm
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Container(
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
                        style: const TextStyle(
                            color: Colors.white, fontSize: 15),
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
            ),

            // 🔹 Nút Bộ lọc
            Padding(
              padding: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  _showFilterPanel ? Colors.green : Colors.grey[850],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: () {
                  setState(() => _showFilterPanel = !_showFilterPanel);
                },
                icon: const Icon(Icons.filter_list,
                    color: Colors.white, size: 18),
                label: const Text("Bộ lọc",
                    style: TextStyle(color: Colors.white, fontSize: 14)),
              ),
            ),

            // 🔽 Bộ lọc xổ xuống
            if (_showFilterPanel)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterSection(
                        "Loại phim",
                        ["Toàn bộ loại phim", "Phim Bộ", "Phim Lẻ"]),
                    _buildFilterSection("Khu vực", _getCountries()),
                    _buildGenreSection(),
                    _buildFilterSection("Thập niên", _getYears()),
                    _buildFilterSection("Sắp xếp", ["Độ hot", "Mới nhất"]),
                    const Divider(color: Colors.grey),
                  ],
                ),
              ),

            // 🔹 Kết quả tìm kiếm + Grid phim
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: _buildMovieGrid(_filteredFilms),
            ),
          ],
        ),
      ),
    );
  }

  // 🔸 Thể loại chỉ hiện 5 cái đầu + popup
  Widget _buildGenreSection() {
    final genres = _getGenres();
    final visibleGenres = genres.length > 6 ? genres.sublist(0, 6) : genres;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Thể loại",
              style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...visibleGenres.map((g) => _buildOption("Thể loại", g)),
              if (genres.length > 6)
                GestureDetector(
                  onTap: () => _showGenrePopup(genres),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text("...", // nút mở popup
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }


  // 🔸 Popup hiển thị tất cả thể loại (hiển thị xanh ngay khi chọn)
  void _showGenrePopup(List<String> genres) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // ✅ Cho phép setState bên trong popup
          builder: (context, setStatePopup) {
            return Dialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: genres.map((g) {
                      final bool isSelected =
                          selectedFilters["Thể loại"]?.contains(g) ?? false;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            // Cập nhật trạng thái chính
                            if (isSelected) {
                              selectedFilters["Thể loại"]!.remove(g);
                            } else {
                              if (g.startsWith("Toàn bộ")) {
                                selectedFilters["Thể loại"]!.clear();
                              }
                              selectedFilters["Thể loại"]!.add(g);
                            }
                            _applyFilters();
                          });
                          // ✅ Cập nhật lại trong popup để đổi màu ngay
                          setStatePopup(() {});
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.green
                                : Colors.grey[850],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            g,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  // ✅ Các danh sách
  List<String> _getCountries() =>
      [
        "Toàn bộ khu vực",
        ..._films
            .map((f) => f.countryName)
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList(),
      ];

  List<String> _getGenres() {
    final allGenres = _genres.map((g) => g.genreName).toList();
    return ["Toàn bộ các loại", ...allGenres];
  }

  List<String> _getYears() {
    final years = _films
        .map((f) => f.releaseYear.toString())
        .where((y) => y.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return ["Toàn bộ các thập niên", ...years];
  }

  // ✅ Nút chọn – nhấn 1 lần xanh, nhấn 2 lần đen
  Widget _buildOption(String title, String option) {
    selectedFilters.putIfAbsent(title, () => {});
    final bool isSelected = selectedFilters[title]!.contains(option);

    return GestureDetector(
      onTap: () {
        setState(() {
          // 🔹 Nếu đang chọn -> bỏ chọn (đen lại)
          if (isSelected) {
            selectedFilters[title]!.remove(option);
          } else {
            // 🔹 Nếu là "Loại phim" thì chỉ được chọn 1
            if (title == "Loại phim") {
              selectedFilters[title]!.clear();
              selectedFilters[title]!.add(option);
            }
            // 🔹 Nếu chọn "Toàn bộ ..." thì bỏ hết các lựa chọn khác
            else if (option.startsWith("Toàn bộ")) {
              selectedFilters[title]!.clear();
              selectedFilters[title]!.add(option);
            }
            // 🔹 Nếu chọn lựa chọn khác -> bỏ chọn "Toàn bộ ..."
            else {
              selectedFilters[title]!.removeWhere((o) =>
                  o.startsWith("Toàn bộ"));
              selectedFilters[title]!.add(option);
            }
          }

          _applyFilters();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.grey[850],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          option,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }

  // ✅ Các phần khác
  Widget _buildFilterSection(String title, List<String> options) {
    selectedFilters.putIfAbsent(title, () => {});
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options
                .map((option) => _buildOption(title, option))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieGrid(List<FilmInfo> films) {
    final int count = films.length;

    // ❗ Điều kiện nhận biết đang search / lọc
    final bool isFiltering =
        _searchKeyword.isNotEmpty ||
            selectedFilters.values.any((s) => s.isNotEmpty);

    // ❗ Khi không search & không filter → chỉ hiện 6 phim đầu tiên
    final List<FilmInfo> displayFilms =
    (!isFiltering && films.length > 6) ? films.sublist(0, 6) : films;

    // ❗ Nếu không có phim -> hiện thông báo
    if (displayFilms.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            "Không có phim phù hợp",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    // ❗ Chỉ hiển thị tiêu đề khi có search hoặc filter
    final bool shouldShowTitle = isFiltering;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (shouldShowTitle)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              "Kết quả tìm kiếm ($count)",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        // 🌟 GIỮ NGUYÊN GRID CŨ (chỉ thay danh sách là displayFilms)
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 12,
            childAspectRatio: 0.55,
          ),
          itemCount: displayFilms.length,
          itemBuilder: (context, index) {
            final film = displayFilms[index];
            final poster = film.posterMain.isNotEmpty
                ? film.posterMain
                : "https://via.placeholder.com/150";

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

                  Text(
                    film.filmName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}