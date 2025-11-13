import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../config/api.dart';
import '../../models/Film_info.dart';
import '../../services/Film_Service.dart';
import '../../services/Comment_Service.dart';
import '../../services/auth_service.dart';
import '../../services/Rating_Service.dart';

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
  int _selectedRating = 0;
  double _avgScore = 0.0;
  int _totalReviews = 0;

  FilmInfo? _film;
  List<FilmInfo>? _recommendations;
  VideoPlayerController? _videoController;
  YoutubePlayerController? _youtubeController;

  int _selectedEpisode = 1;
  int _selectedSeason = 0;
  int _selectedTab = 0;

  //  Bình luận
  List<dynamic> _comments = [];
  bool _loadingComments = true;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await Api.loadToken();
    await _loadFilm();
    await _loadAverageScore();
    await _loadComments();
  }

  //  PHIM
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

      final recs = await FilmService.getRecommendations(
        data.countryName,
        data.filmId,
      );
      setState(() {
        _recommendations = recs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(" Lỗi tải chi tiết phim: $e");
      setState(() => _isLoading = false);
    }
  }

  // BÌNH LUẬN
  Future<void> _loadComments() async {
    try {
      final data = await CommentService.getComments(widget.filmId);
      debugPrint("🎬 filmId gửi lên CommentService: ${widget.filmId}");

      //  Tải replies cho từng comment
      for (final c in data) {
        final replies = await CommentService.getReplies(c['Comment_id']);
        c['Replies'] = replies;
      }

      setState(() {
        _comments = data;
        _loadingComments = false;
      });
    } catch (e) {
      debugPrint(" Lỗi load bình luận: $e");
      setState(() => _loadingComments = false);
    }
  }

  Future<void> _loadAverageScore() async {
    try {
      final data = await RatingService.getAverageScore(widget.filmId);
      setState(() {
        final avg = data['avg_score'];
        _avgScore = avg is num
            ? avg.toDouble()
            : double.tryParse(avg.toString()) ?? 0.0;
        _totalReviews = data['total_reviews'] is int
            ? data['total_reviews']
            : int.tryParse(data['total_reviews'].toString()) ?? 0;
      });
    } catch (e) {
      debugPrint(" Lỗi load average score: $e");
    }
  }

  Future<void> _submitRating(int rating) async {
    if (rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn số sao để đánh giá")),
      );
      return;
    }

    try {
      await Api.loadToken();
      final me = await AuthService.getMe();
      final user = me?['user'];

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vui lòng đăng nhập để đánh giá")),
        );
        return;
      }

      final profileId = user['Profile_id'] ?? user['id'];

      final ok = await RatingService.upsertRating(
        profileId: profileId,
        filmId: widget.filmId,
        score: rating.toDouble(),
      );

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Cảm ơn bạn đã đánh giá $rating sao!")),
        );
        await _loadAverageScore(); // Cập nhật lại đánh giá trung bình
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Không thể gửi đánh giá")));
      }
    } catch (e) {
      debugPrint(" Lỗi gửi đánh giá: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã xảy ra lỗi khi gửi đánh giá")),
      );
    }
  }

  //UI
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
          child: Text(
            "Không tìm thấy phim",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
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
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _buildTrailerOrPoster(),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //  Tên phim
                        Text(
                          _film!.filmName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Thông tin cơ bản
                        Text(
                          "${_film!.releaseYear} | ${_film!.maturityRating.isNotEmpty ? _film!.maturityRating : 'Tất cả'} | ${_film!.countryName} | ${_film!.isSeries ? 'Phim bộ' : 'Phim lẻ'} | ${_film!.filmStatus}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 10),

                        //  Lượt xem + Đánh giá
                        Row(
                          children: [
                            const Icon(
                              Icons.remove_red_eye,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              "91.019 lượt xem",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Điểm trung bình
                            Text(
                              _avgScore.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.amberAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 6),

                            //  Hiển thị sao trung bình
                            Row(
                              children: List.generate(5, (index) {
                                double starValue = index + 1;
                                return Icon(
                                  _avgScore >= starValue
                                      ? Icons.star
                                      : (_avgScore >= starValue - 0.5
                                            ? Icons.star_half
                                            : Icons.star_border),
                                  color: Colors.amberAccent,
                                  size: 16,
                                );
                              }),
                            ),
                            const SizedBox(width: 6),

                            // 🔹 Hiển thị số lượt đánh giá
                            Text(
                              "($_totalReviews)",
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        //  Mô tả phim
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

                        //  Hàng nút hành động
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(
                              Icons.favorite,
                              "Yêu thích",
                              isFavorite ? Colors.redAccent : Colors.white,
                              () => setState(() => isFavorite = !isFavorite),
                            ),
                            _buildActionButton(
                              Icons.bookmark,
                              "Danh sách",
                              Colors.white,
                              () {},
                            ),
                            _buildRatingButton(),
                          ],
                        ),

                        const SizedBox(height: 16),

                        //  Tabs
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

            // Nút quay lại
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

  //CÁC HÀM HỖ TRỢ
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

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        int tempRating = _selectedRating;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.black87,
              title: const Text(
                "Đánh giá phim",
                style: TextStyle(color: Colors.amberAccent),
              ),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  final isSelected = tempRating >= starIndex;
                  return IconButton(
                    icon: Icon(
                      Icons.star,
                      color: isSelected ? Colors.amberAccent : Colors.white24,
                      size: 34,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        if (tempRating == starIndex) {
                          tempRating = 0;
                          _selectedRating = 0;
                        } else {
                          tempRating = starIndex;
                          _selectedRating = starIndex;
                        }
                      });
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
                TextButton(
                  onPressed: () async {
                    await _submitRating(tempRating);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Gửi",
                    style: TextStyle(color: Colors.greenAccent),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Danh sách tập phim
  Widget _buildEpisodesSection() {
    final seasons = _film!.seasons ?? [];

    if (seasons.isEmpty) {
      return const Text(
        "Chưa có danh sách mùa hoặc tập.",
        style: TextStyle(color: Colors.white70),
      );
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
                  child: Text(
                    s["Season_name"] ?? "Phần ${index + 1}",
                    style: const TextStyle(color: Colors.white),
                  ),
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
                      color: isSelected
                          ? Colors.greenAccent
                          : Colors.transparent,
                      width: 1.1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "$epNum",
                      style: TextStyle(
                        color: isSelected ? Colors.greenAccent : Colors.white,
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

  //Danh sách diễn viên
  Widget _buildActorsSection() {
    final actors = _film!.actors;
    if (actors.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "Chưa có thông tin diễn viên",
          style: TextStyle(color: Colors.white),
        ),
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
                      ? NetworkImage(
                          avatar.startsWith('http')
                              ? avatar
                              : '${Api.baseHost}${avatar.startsWith('/') ? avatar : '/$avatar'}',
                        )
                      : const NetworkImage(
                          "https://cdn.vtc.vn/avatar_default.png",
                        ),
                ),

                const SizedBox(height: 8),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (role.isNotEmpty)
                  Text(
                    role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Bình luận
  Widget _buildCommentSection() {
    if (_loadingComments) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.greenAccent),
      );
    }

    // Hàm dựng từng comment
    Widget buildCommentItem(Map<String, dynamic> c, int depth, int parentId) {
      c['showReplyBox'] ??= false;
      final replyCtrl = TextEditingController();
      final replies = c['Replies'] ?? [];
      final double indent = 40.0 * depth;
      return Padding(
        padding: EdgeInsets.only(left: indent),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //AVATAR + NAME + BÌNH LUẬN
            ListTile(
              leading: CircleAvatar(
                radius: depth == 0 ? 20 : 16,
                backgroundImage: (c['Avatar_url'] != null &&
                    c['Avatar_url'].toString().isNotEmpty)
                    ? NetworkImage(
                  c['Avatar_url'].toString().startsWith('http')
                      ? c['Avatar_url']
                      : '${Api.baseHost}${c['Avatar_url'].toString().startsWith('/') ? c['Avatar_url'] : '/${c['Avatar_url']}'}',
                )
                    : const NetworkImage("https://cdn.vtc.vn/avatar_default.png"),
              ),
              title: Text(
                c['Profile_name'] ?? "Người dùng",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: depth == 0 ? 14 : 13,
                  fontWeight: depth == 0 ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c['Content'] ?? "",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: depth == 0 ? 12 : 11.5,
                    ),
                  ),

                  if (c['Created_at'] != null)
                    Builder(
                      builder: (_) {
                        try {
                          final dt = DateTime.parse(c['Created_at']).toLocal();
                          return Text(
                            timeago.format(dt, locale: 'vi'),
                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                          );
                        } catch (_) {
                          return const SizedBox.shrink();
                        }
                      },
                    ),

                  const SizedBox(height: 4),

                  //  LIKE + REPLY BUTTONS
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () =>
                        depth == 0 ? _toggleLike(c['Comment_id']) : _toggleLikeReply(c),
                        child: Row(
                          children: [
                            Icon(
                              c['liked'] == true
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: c['liked'] == true
                                  ? Colors.redAccent
                                  : Colors.white54,
                              size: depth == 0 ? 16 : 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${c['Likes'] ?? 0}",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: depth == 0 ? 12 : 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      GestureDetector(
                        onTap: () {
                          setState(() {
                            c['showReplyBox'] = !(c['showReplyBox'] ?? false);
                          });
                        },
                        child: Text(
                          "Phản hồi",
                          style: TextStyle(
                            color: Colors.amberAccent,
                            fontSize: depth == 0 ? 12 : 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            //REPLY TEXTFIELD
            if (c['showReplyBox'] == true)
              Padding(
                padding: EdgeInsets.only(left: 45, bottom: 8, right: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: replyCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Nhập phản hồi...",
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.send,
                          color: Colors.greenAccent, size: 20),
                      onPressed: () {
                        final text = replyCtrl.text.trim();
                        if (text.isNotEmpty) {
                          _sendReply(parentId, text);
                          replyCtrl.clear();
                          setState(() => c['showReplyBox'] = false);
                        }
                      },
                    ),
                  ],
                ),
              ),


            //  NÚT HIỂN THỊ / ẨN REPLY
            if (replies.isNotEmpty)
              GestureDetector(
                onTap: () {
                  setState(() => c['showReplies'] = !(c['showReplies'] ?? false));
                },
                child: Padding(
                  padding: EdgeInsets.only(left: depth == 0 ? 50 : 40, bottom: 6),
                  child: Text(
                    c['showReplies'] == true
                        ? "Ẩn phản hồi"
                        : "Xem ${replies.length} phản hồi",
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            if (c['showReplies'] == true)
              Column(
                children: replies
                    .map<Widget>(
                      (r) => buildCommentItem(r, depth + 1, c['Comment_id']),
                )
                    .toList(),
              ),

          ],
        ),
      );
    }

    // BUILD UI
    return Column(
      children: _comments
          .map((c) => buildCommentItem(c, 0, c['Comment_id']))
          .toList(),
    );
  }



  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    try {
      await Api.loadToken();
      final me = await AuthService.getMe();
      final user = me?['user'];
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vui lòng đăng nhập để bình luận")),
        );
        return;
      }

      final profileId = user['Profile_id'] ?? user['id'];
      final userName = user['name'] ?? 'Người dùng';
      final userAvatar = user['avatar'];

      final ok = await CommentService.addComment(
        filmId: widget.filmId,
        profileId: profileId,
        content: text,
      );

      if (ok) {
        _commentController.clear();
        setState(() {
          _comments.insert(0, {
            'Comment_id': DateTime.now().millisecondsSinceEpoch,
            'Profile_name': userName,
            'Avatar_url': userAvatar,
            'Content': text,
            'Likes': 0,
            'liked': false,
            'Created_at': DateTime.now().toIso8601String(),
            'Replies': [],
          });
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không thể gửi bình luận")),
        );
      }
    } catch (e) {
      debugPrint(" Lỗi gửi bình luận: $e");
    }
  }

  Future<void> _sendReply(int parentId, String text) async {
    if (text.trim().isEmpty) return;

    try {
      await Api.loadToken();
      final me = await AuthService.getMe();
      final user = me?['user'];
      if (user == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Vui lòng đăng nhập")));
        return;
      }

      final profileId = user['Profile_id'] ?? user['id'];
      final userName = user['name'] ?? 'Người dùng';
      final userAvatar = user['avatar'];

      final ok = await CommentService.addReply(
        filmId: widget.filmId,
        profileId: profileId,
        parentId: parentId,
        content: text,
      );

      if (!ok) return;
      bool insertRecursive(List list) {
        for (var comment in list) {
          if (comment['Comment_id'] == parentId) {
            comment['Replies'] ??= [];
            comment['Replies'].insert(0, {
              'Comment_id': DateTime.now().millisecondsSinceEpoch,
              'Profile_name': userName,
              'Avatar_url': userAvatar,
              'Content': text,
              'Created_at': DateTime.now().toIso8601String(),
              'Replies': [],
            });
            return true;
          }

          if (comment['Replies'] != null &&
              insertRecursive(comment['Replies'])) {
            return true;
          }
        }
        return false;
      }

      setState(() {
        insertRecursive(_comments);
      });
    } catch (e) {
      debugPrint(" Lỗi gửi reply: $e");
    }
  }


  Future<void> _toggleLike(int commentId) async {
    try {
      final index = _comments.indexWhere((c) => c['Comment_id'] == commentId);
      if (index == -1) return;

      final c = _comments[index];
      final liked = !(c['liked'] ?? false);

      setState(() {
        c['liked'] = liked;
        c['Likes'] = (c['Likes'] ?? 0) + (liked ? 1 : -1);
      });

      final ok = await CommentService.likeComment(commentId);
      if (!ok) {
        //  rollback nếu server fail
        setState(() {
          c['liked'] = !liked;
          c['Likes'] = (c['Likes'] ?? 0) + (liked ? -1 : 1);
        });
      }
    } catch (e) {
      debugPrint(" Lỗi like bình luận: $e");
    }
  }
  void _toggleLikeReply(dynamic reply) {
    try {
      final liked = !(reply['liked'] ?? false);

      setState(() {
        reply['liked'] = liked;
        reply['Likes'] = (reply['Likes'] ?? 0) + (liked ? 1 : -1);
      });

    } catch (e) {
      debugPrint(" Lỗi like reply: $e");
    }
  }


  // Phim đề xuất
  Widget _buildRecommendations() {
    if (_recommendations == null || _recommendations!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          "Không có phim đề xuất",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final films = _recommendations!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Phim đề xuất",
          style: TextStyle(
            color: Colors.amberAccent,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
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

  // Nút chung
  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
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
