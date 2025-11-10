import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../models/Film_info.dart';
import '../../services/Film_Service.dart';

class DetailFilmScreen extends StatefulWidget {
  final int filmId;

  const DetailFilmScreen({super.key, required this.filmId});

  @override
  State<DetailFilmScreen> createState() => _DetailFilmScreenState();
}

class _DetailFilmScreenState extends State<DetailFilmScreen> {
  bool isFavorite = false;
  bool _isLoading = true;
  bool _isVideoReady = false;
  int _selectedRating = 0; // ⭐ lưu số sao người dùng chọn

  FilmInfo? _film;
  List<FilmInfo>? _recommendations;
  VideoPlayerController? _videoController;
  YoutubePlayerController? _youtubeController;

  int _selectedEpisode = 1;
  int _selectedSeason = 0;
  int _selectedTab = 0;

  final List<Map<String, String>> _comments = [];
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFilm();
  }

  Future<void> _loadFilm() async {
    try {
      final data = await FilmService.getFilmDetail(widget.filmId);
      setState(() => _film = data);

      final trailer = data.trailerUrl.trim();
      if (trailer.contains("youtube.com") || trailer.contains("youtu.be")) {
        final videoId = YoutubePlayer.convertUrlToId(trailer);
        if (videoId != null) {
          _youtubeController = YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(autoPlay: true),
          );
        }
      } else if (trailer.isNotEmpty) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(trailer))
          ..initialize().then((_) {
            setState(() => _isVideoReady = true);
            _videoController?.play();
          });
      }

      final recs =
      await FilmService.getRecommendations(data.countryName, data.filmId);
      setState(() {
        _recommendations = recs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Lỗi tải chi tiết phim: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _youtubeController?.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.greenAccent),
        ),
      );
    }

    if (_film == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text("Không tìm thấy phim",
              style: TextStyle(color: Colors.white, fontSize: 18)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                AspectRatio(aspectRatio: 16 / 9, child: _buildTrailerOrPoster()),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔹 Tên phim
                        Text(
                          _film!.filmName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // 🔹 Thông tin cơ bản
                        Text(
                          "${_film!.releaseYear} | ${_film!.maturityRating.isNotEmpty ? _film!.maturityRating : 'Tất cả'} | ${_film!.countryName} | ${_film!.isSeries ? 'Phim bộ' : 'Phim lẻ'} | ${_film!.filmStatus}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // 🔹 Lượt xem + Đánh giá sao
                        Row(
                          children: [
                            const Icon(Icons.remove_red_eye,
                                color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            const Text("91.019 lượt xem",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            const SizedBox(width: 10),
                            const Text("5.0",
                                style: TextStyle(
                                    color: Colors.amberAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            const SizedBox(width: 6),
                            Row(
                              children: List.generate(
                                5,
                                    (index) => const Icon(
                                  Icons.star,
                                  color: Colors.amberAccent,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // 🔹 Mô tả phim
                        Text(
                          _film!.description.isNotEmpty
                              ? _film!.description
                              : "Chưa có mô tả cho bộ phim này.",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),

                        if (_film!.genres.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              "Thể loại: ${_film!.genres}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                        const SizedBox(height: 14),

                        // 🔹 Hàng nút hành động
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(
                              Icons.favorite,
                              "Yêu thích",
                              isFavorite ? Colors.redAccent : Colors.white,
                                  () => setState(() => isFavorite = !isFavorite),
                            ),
                            _buildActionButton(Icons.bookmark, "Danh sách",
                                Colors.white, () {}),
                            _buildRatingButton(), // ⭐ Nút đánh giá
                          ],
                        ),

                        const SizedBox(height: 16),

                        // 🔹 Tabs
                        Container(
                          height: 38,
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildTabItem("Tập phim", 0),
                              _buildTabItem("Diễn viên", 1),
                              _buildTabItem("Bình luận", 2),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // 🔹 Nội dung tab
                        if (_selectedTab == 0) ...[
                          _buildEpisodesSection(),
                          const SizedBox(height: 10),
                          _buildRecommendations(),
                        ] else if (_selectedTab == 1) ...[
                          _buildActorsSection(),
                          const SizedBox(height: 10),
                          _buildRecommendations(),
                        ] else if (_selectedTab == 2) ...[
                          _buildCommentSection(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 🔙 Nút quay lại
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

  // --- Tab Item ---
  Widget _buildTabItem(String title, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.amberAccent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.amberAccent : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // --- Trailer hoặc Poster ---
  Widget _buildTrailerOrPoster() {
    if (_youtubeController != null) {
      return YoutubePlayer(
        controller: _youtubeController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.greenAccent,
      );
    }
    if (_videoController != null && _isVideoReady) {
      return VideoPlayer(_videoController!);
    }
    return Image.network(
      _film!.posterMain.isNotEmpty ? _film!.posterMain : '',
      fit: BoxFit.cover,
    );
  }

  // --- Nút Đánh giá (bên ngoài) ---
  Widget _buildRatingButton() {
    return GestureDetector(
      onTap: _showRatingDialog,
      child: Column(
        children: [
          Icon(
            Icons.star,
            color: _selectedRating > 0 ? Colors.amberAccent : Colors.white,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            "Đánh giá",
            style: TextStyle(
              color: _selectedRating > 0 ? Colors.amberAccent : Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // --- Popup chọn sao (toggle bật/tắt) ---
  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        int tempRating = _selectedRating; // Lưu trạng thái tạm trong dialog

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.black87,
              title: const Text(
                "Đánh giá phim",
                style: TextStyle(color: Colors.amberAccent, fontSize: 18),
              ),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  final isSelected = tempRating >= starIndex;
                  return IconButton(
                    icon: Icon(
                      Icons.star,
                      color: isSelected
                          ? Colors.amberAccent
                          : Colors.white24,
                      size: 34,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        // ✅ Nếu nhấn lại cùng sao => tắt toàn bộ
                        if (tempRating == starIndex) {
                          tempRating = 0;
                          _selectedRating = 0;
                        } else {
                          tempRating = starIndex;
                          _selectedRating = starIndex;
                        }
                      });

                      // Cập nhật UI bên ngoài
                      setState(() => _selectedRating = tempRating);
                    },
                  );
                }),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Đóng",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- Danh sách tập phim ---
  Widget _buildEpisodesSection() {
    final seasons = _film!.seasons ?? [];

    if (seasons.isEmpty) {
      return const Text("Chưa có danh sách mùa hoặc tập.",
          style: TextStyle(color: Colors.white70));
    }

    final currentSeason = seasons[_selectedSeason];
    final episodes = currentSeason["Episodes"] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.menu, color: Colors.amberAccent, size: 22),
            const SizedBox(width: 6),
            DropdownButton<int>(
              value: _selectedSeason,
              dropdownColor: Colors.grey[900],
              underline: const SizedBox(),
              style: const TextStyle(color: Colors.white),
              items: List.generate(seasons.length, (index) {
                final s = seasons[index];
                return DropdownMenuItem<int>(
                  value: index,
                  child: Text(s["Season_name"] ?? "Phần ${index + 1}",
                      style: const TextStyle(color: Colors.white)),
                );
              }),
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _selectedSeason = v;
                    _selectedEpisode = 1;
                  });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: List.generate(episodes.length, (i) {
              final epNum = episodes[i]["Episode_number"];
              final isSelected = _selectedEpisode == epNum;
              return GestureDetector(
                onTap: () => setState(() => _selectedEpisode = epNum),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.greenAccent.withOpacity(0.15)
                        : Colors.grey[850],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color:
                      isSelected ? Colors.greenAccent : Colors.transparent,
                      width: 1.1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "$epNum",
                      style: TextStyle(
                        color:
                        isSelected ? Colors.greenAccent : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // --- Danh sách diễn viên ---
  Widget _buildActorsSection() {
    final actors = _film!.actors;
    if (actors.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text("Chưa có thông tin diễn viên",
            style: TextStyle(color: Colors.white)),
      );
    }

    return SizedBox(
      height: 170,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: actors.length,
        itemBuilder: (context, index) {
          final actor = actors[index];
          final name = actor['Actor_name'] ?? "Không rõ";
          final avatar = actor['Actor_avatar'] ?? "";
          final role = actor['Character_name'] ?? "";

          return Container(
            width: 110,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: avatar.isNotEmpty
                      ? NetworkImage(avatar)
                      : const NetworkImage(
                      "https://cdn.vtc/avatar_default.png"),
                ),
                const SizedBox(height: 8),
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                if (role.isNotEmpty)
                  Text(role,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600)),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Bình luận ---
  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Bình luận",
            style: TextStyle(
                color: Colors.amberAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Nhập bình luận của bạn...",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.greenAccent),
              onPressed: _addComment,
            )
          ],
        ),
        const SizedBox(height: 10),
        if (_comments.isEmpty)
          const Text("Chưa có bình luận nào",
              style: TextStyle(color: Colors.white70))
        else
          Column(
            children: _comments
                .map((c) => ListTile(
              leading: const CircleAvatar(
                backgroundImage: NetworkImage(
                    "https://cdn.vtc/avatar_default.png"),
              ),
              title: Text(c['name'] ?? "Người dùng",
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14)),
              subtitle: Text(c['text'] ?? "",
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12)),
            ))
                .toList(),
          ),
      ],
    );
  }

  void _addComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _comments.insert(0, {"name": "Bạn", "text": text});
      _commentController.clear();
    });
  }

  // --- Phim đề xuất ---
  Widget _buildRecommendations() {
    if (_recommendations == null || _recommendations!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child:
        Text("Không có phim đề xuất", style: TextStyle(color: Colors.white70)),
      );
    }

    final films = _recommendations!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Phim đề xuất",
            style: TextStyle(
                color: Colors.amberAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: films.length,
            itemBuilder: (context, i) {
              final film = films[i];
              return GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailFilmScreen(filmId: film.filmId),
                    ),
                  );
                },
                child: Container(
                  width: 130,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          film.posterMain.isNotEmpty
                              ? film.posterMain
                              : "https://cdn.vtc/poster_default.png",
                          fit: BoxFit.cover,
                          height: 160,
                          width: 130,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        film.filmName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style:
                        const TextStyle(color: Colors.white, fontSize: 12),
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

  // --- Nút chung ---
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
