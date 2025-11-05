import 'package:flutter/material.dart';
import '../../models/Film_info.dart';
import '../../services/Film_Service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, String> selectedFilters = {};

  List<FilmInfo> _films = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFilms();
  }

  Future<void> _loadFilms() async {
    try {
      final films = await FilmService.getSearchFilms(); // ✅ Gọi DB thật
      setState(() {
        _films = films;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Lỗi tải dữ liệu phim: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Kho phim",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.search, color: Colors.white, size: 26),
          )
        ],
        bottom: TabBar(
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
          : TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryTab(isSeries: true), // Phim Bộ
          _buildCategoryTab(isSeries: false), // Phim Lẻ
        ],
      ),
    );
  }

  Widget _buildCategoryTab({required bool isSeries}) {
    final filteredFilms = _films
        .where((film) => film.isSeries == isSeries)
        .toList(); // ✅ Lọc phim bộ / phim lẻ

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterSection("Khu vực", [
            "Toàn bộ khu vực",
            "Trung Quốc",
            "Hàn Quốc",
            "Thái Lan",
            "Việt Nam",
            "Nhật Bản"
          ]),
          _buildFilterSection("Thể loại", [
            "Toàn bộ các loại",
            "Thanh Xuân",
            "Bí Ẩn",
            "Cổ Trang"
          ]),
          _buildFilterSection("Thập niên", [
            "Toàn bộ các thập niên",
            "2025",
            "2024",
            "2023",
            "2022"
          ]),
          _buildFilterSection("Sắp xếp", ["Độ hot", "Mới nhất"]),
          const SizedBox(height: 10),
          const Divider(color: Colors.grey, thickness: 0.2),
          const SizedBox(height: 10),
          _buildMovieGrid(filteredFilms),
        ],
      ),
    );
  }

  /// 🔹 Bộ lọc giữ nguyên
  Widget _buildFilterSection(String title, List<String> options) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((option) {
          bool isSelected = selectedFilters[title] == option;
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  selectedFilters.remove(title);
                } else {
                  selectedFilters[title] = option;
                }
              });
            },
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green : Colors.grey[850],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                option,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// ✅ Grid hiển thị phim thật từ DB
  Widget _buildMovieGrid(List<FilmInfo> films) {
    if (films.isEmpty) {
      return const Center(
        child: Text("Không có phim nào",
            style: TextStyle(color: Colors.grey, fontSize: 14)),
      );
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: film.posterMain != null &&
                      film.posterMain!.isNotEmpty
                      ? Image.network(
                    film.posterMain!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                      : Image.asset(
                    'assets/posters/default.jpg',
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "Top 10",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              film.countryName ?? '',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              film.originalName ?? film.filmName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        );
      },
    );
  }
}
