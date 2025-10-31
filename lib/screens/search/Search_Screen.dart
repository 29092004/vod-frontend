import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, String> selectedFilters = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
            Tab(text: "Phim Ngắn"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryTab(),
          _buildCategoryTab(),
          _buildCategoryTab(),
        ],
      ),
    );
  }

  Widget _buildCategoryTab() {
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
          _buildFilterSection("Phụ đề", ["Toàn bộ phụ đề", "Dịch thủ công"]),
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
          _buildMovieGrid(),
        ],
      ),
    );
  }

  /// 🔹 Bộ lọc với chip chọn
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

  /// ✅ Grid danh sách phim (đã sửa hiển thị ảnh)
  Widget _buildMovieGrid() {
    final movies = [
      {
        "title": "Nhất Tiếu Tùy Ca",
        "episodes": "Trọn bộ 38 tập",
        "image": 'assets/anh_chinh/nhat_tieu_tuy_ca_chinh.jpg',
        "tag": "Top 10"
      },
      {
        "title": "Ám Hà Truyện",
        "episodes": "Trọn bộ 12 tập",
        "image": 'assets/anh_chinh/am_ha_truyen_chinh.jpg',
        "tag": "Top 10"
      },
      {
        "title": "Thần Đèn Ơi Ước Đi!",
        "episodes": "Trọn bộ 10 tập",
        "image": 'assets/anh_chinh/than_den_oi_uoc_di_chinh.jpg',
        "tag": "Top 10"
      },
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 12,
        childAspectRatio: 0.55,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    movie["image"]!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      movie["tag"]!,
                      style: const TextStyle(
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
              movie["episodes"]!,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              movie["title"]!,
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
