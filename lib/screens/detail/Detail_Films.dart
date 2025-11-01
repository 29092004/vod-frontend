import 'package:flutter/material.dart';
import '../watch/Watch_Screen.dart';

class DetailFilmScreen extends StatefulWidget {
  final String title;
  final String description;
  final String director;
  final String posterUrl;
  final String url360;
  final String url720;

  const DetailFilmScreen({
    super.key,
    required this.title,
    required this.description,
    required this.director,
    required this.posterUrl,
    required this.url360,
    required this.url720,
  });

  @override
  State<DetailFilmScreen> createState() => _DetailFilmScreenState();
}

class _DetailFilmScreenState extends State<DetailFilmScreen> {
  bool isFavorite = false;

  final List<Map<String, String>> actors = [
    {
      "image":
      "https://image.tmdb.org/t/p/w500/jpRELzFqMO5TkSGwNbXKM1oQPCd.jpg",
      "realName": "He Landou",
      "role": "Lu Yingying"
    },
    {
      "image":
      "https://image.tmdb.org/t/p/w500/yfCqhGohVxPGrEbnvvlW9ojqVNY.jpg",
      "realName": "Deng Xiaoci",
      "role": "Jun Che"
    },
    {
      "image":
      "https://i.pinimg.com/736x/09/f2/ba/09f2ba76f5456e01f1a9c79c8c3d489c.jpg",
      "realName": "Zhong Chenyao",
      "role": "Sang Li"
    },
    {
      "image":
      "https://i.pinimg.com/736x/3f/44/df/3f44df29b749e0a1a31965ff7f4f1a26.jpg",
      "realName": "Zhu Liangqi",
      "role": "Yan Hui"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Poster phim ---
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      widget.posterUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        color: Colors.grey[900],
                        child: const Center(
                          child: Icon(Icons.image_not_supported,
                              color: Colors.white54, size: 40),
                        ),
                      ),
                    ),
                  ),

                  // --- Giới thiệu phim ---
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        const Text(
                          "2025 | T16 | Trung Quốc | 3 Phần | Full HD",
                          style: TextStyle(color: Colors.white60, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: const [
                            Icon(Icons.visibility,
                                color: Colors.white54, size: 16),
                            SizedBox(width: 5),
                            Text("91.019 lượt xem",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            SizedBox(width: 10),
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            SizedBox(width: 4),
                            Text("5.0",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // --- Nút Xem ngay ---
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon:
                            const Icon(Icons.play_arrow, color: Colors.black),
                            label: const Text("Xem ngay",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              padding:
                              const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WatchScreen(
                                    title: widget.title,
                                    url360: widget.url360,
                                    url720: widget.url720,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // --- Mô tả phim ---
                        Text(
                          widget.description,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        const Text("Thể loại: Phim cổ trang, Phim tình cảm",
                            style: TextStyle(
                                color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 20),

                        // --- Diễn viên ---
                        const Text("Diễn viên",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                        const SizedBox(height: 16),

                        // --- Hàng ngang diễn viên ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: actors
                              .map((actor) => _buildActorAvatar(
                            imageUrl: actor["image"]!,
                            realName: actor["realName"]!,
                            roleName: actor["role"]!,
                          ))
                              .toList(),
                        ),

                        const SizedBox(height: 30),

                        // --- Hàng nút hành động ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildActionButton(
                                Icons.favorite,
                                "Yêu thích",
                                isFavorite
                                    ? Colors.redAccent
                                    : Colors.white70, () {
                              setState(() {
                                isFavorite = !isFavorite;
                              });
                            }),
                            _buildActionButton(Icons.bookmark, "Lưu lại",
                                Colors.white70, () {}),
                            _buildActionButton(Icons.star_border, "Đánh giá",
                                Colors.white70, () {}),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 🔙 Nút quay về
            Positioned(
              top: 10,
              left: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget diễn viên avatar tròn (kích thước vừa khung) ---
  Widget _buildActorAvatar({
    required String imageUrl,
    required String realName,
    required String roleName,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 35, // nhỏ hơn để vừa khung
          backgroundImage: NetworkImage(imageUrl),
          backgroundColor: Colors.grey[800],
        ),
        const SizedBox(height: 6),
        Text(
          realName,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        Text(
          roleName,
          style: const TextStyle(color: Colors.redAccent, fontSize: 11),
        ),
      ],
    );
  }

  // --- Widget nút hành động ---
  Widget _buildActionButton(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
