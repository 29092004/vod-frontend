import 'dart:async';
import 'package:flutter/material.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:volume_controller/volume_controller.dart';
import '../../models/Film_info.dart';
import '../../services/Film_Service.dart';
import '../../services/History_Service.dart'; // ✅ thêm
import 'package:flutter/services.dart';

class DetailFilmScreen extends StatefulWidget {
  final int filmId;
  final Duration? startPosition;

  const DetailFilmScreen({super.key, required this.filmId, this.startPosition,});

  @override
  State<DetailFilmScreen> createState() => _DetailFilmScreenState();
}

class _DetailFilmScreenState extends State<DetailFilmScreen> {
  bool isFavorite = false;
  bool _isLoading = true;
  bool _isVideoReady = false;
  int _selectedRating = 0;

  FilmInfo? _film;
  List<FilmInfo>? _recommendations;

  VideoPlayerController? _videoController;
  YoutubePlayerController? _youtubeController;
  BetterPlayerController? _betterPlayerController;

  int _selectedEpisode = 1;
  int _selectedSeason = 0;
  int _selectedTab = 0;

  final List<Map<String, String>> _comments = [];
  final TextEditingController _commentController = TextEditingController();

  // 🎧 Biến điều khiển âm lượng hệ thống
  final VolumeController _volumeController = VolumeController();
  double _systemVolume = 1.0;

  // ✅ Biến theo dõi tiến độ xem phim
  int _watchPosition = 0;
  int _videoDuration = 0;
  int _profileId = 1; // giả định người dùng hiện tại
  bool _hasSaved = false;
  Timer? _saveTimer; // để lưu định kỳ

  @override
  void initState() {
    super.initState();
    _loadFilm();

    // 🎧 Khởi tạo volume hệ thống
    _volumeController.showSystemUI = true;
    _volumeController.getVolume().then((vol) {
      setState(() => _systemVolume = vol);
    });
    _volumeController.listener((volume) {
      setState(() => _systemVolume = volume);
    });
  }

  Future<void> _loadFilm() async {
    try {
      final data = await FilmService.getFilmDetail(widget.filmId);
      setState(() => _film = data);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadVideoAsync(data);
      });

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

  // ✅ Xử lý video (m3u8 / youtube / mp4)
  Future<void> _loadVideoAsync(FilmInfo data) async {
    try {
      final sources = data.sources ?? "";
      final trailer = data.trailerUrl.trim();
      String? playUrl;

      if (sources.isNotEmpty && sources.contains(".m3u8")) {
        final urls = _extractEpisodeUrls(sources);
        if (urls.isNotEmpty) {
          final firstUrl = urls.first;
          _initBetterPlayer(firstUrl);
          setState(() {
            _isVideoReady = true;
            _selectedEpisode = 1;
          });
          return;
        }
      }

      if (trailer.isNotEmpty) {
        if (trailer.contains("youtube.com") || trailer.contains("youtu.be")) {
          final id = _extractYouTubeId(trailer);
          if (id != null && id.isNotEmpty) {
            playUrl = "https://www.youtube.com/embed/$id";
          }
        } else if (trailer.endsWith(".mp4")) {
          playUrl = trailer;
        }

        if (playUrl != null) {
          await _initVideoPlayer(playUrl);
          setState(() => _isVideoReady = true);
          return;
        }
      }

      setState(() => _isVideoReady = false);
    } catch (e) {
      debugPrint("⚠️ Lỗi tải video: $e");
      setState(() => _isVideoReady = false);
    }
  }

  // 🎬 Khởi tạo VideoPlayer
  Future<void> _initVideoPlayer(String url) async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController!.initialize();
      await _videoController!.play();
      _videoController!.setLooping(true);
      debugPrint("🎬 Đang phát video: $url");
    } catch (e) {
      debugPrint("❌ Lỗi khởi tạo video_player: $e");
    }
  }

  String? _extractYouTubeId(String url) {
    final RegExp regExp = RegExp(
      r"(?:v=|\/)([0-9A-Za-z_-]{11}).*",
      caseSensitive: false,
      multiLine: false,
    );
    final match = regExp.firstMatch(url);
    return match != null ? match.group(1) : null;
  }

  List<String> _extractEpisodeUrls(String sources) {
    final parts = sources.split(',');
    List<String> urls = [];
    for (var p in parts) {
      if (p.contains('http')) {
        final idx = p.indexOf(':');
        urls.add(p.substring(idx + 1).trim());
      }
    }
    return urls;
  }


// ✅ Khởi tạo BetterPlayer phát tiếp ngay vị trí đang xem
  void _initBetterPlayer(String url) {
    // 🔹 Tạo bản đồ độ phân giải chỉ có 720p và 480p
    final qualityUrls = {
      "720p": url.replaceAll("480p", "720p").replaceAll("480p", "720p"),
      "480p": url.replaceAll("720p", "480p").replaceAll("720p", "480p"),
    };

    // ✅ DataSource chính kèm hai độ phân giải
    final dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      url,
      videoFormat: BetterPlayerVideoFormat.hls,
      resolutions: {
        "720p": qualityUrls["720p"]!,
        "480p": qualityUrls["480p"]!,
      },
    );

    _betterPlayerController = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: true,
        aspectRatio: 16 / 9,
        fit: BoxFit.cover,
        startAt: widget.startPosition,
        fullScreenByDefault: false,
        allowedScreenSleep: false,
        autoDetectFullscreenDeviceOrientation: true,
        autoDetectFullscreenAspectRatio: true,
        deviceOrientationsOnFullScreen: const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        deviceOrientationsAfterFullScreen: const [
          DeviceOrientation.portraitUp,
        ],

        // 🎮 Giữ nguyên controls
        controlsConfiguration: const BetterPlayerControlsConfiguration(
          enableFullscreen: true,
          enableQualities: true,
          enablePlaybackSpeed: true,
          enableProgressBar: true,
          enablePlayPause: true,
          enableSkips: true,
          enableMute: true,
          enableAudioTracks: true,
          enableOverflowMenu: true,
          controlBarColor: Colors.transparent,
          loadingColor: Colors.white,
          enablePip: false,
        ),
      ),
      betterPlayerDataSource: dataSource,
    );

    // 🟢 Khi video load xong thì seek tới vị trí cũ & phát luôn
    _betterPlayerController!.addEventsListener((event) async {
      if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
        if (widget.startPosition != null && widget.startPosition!.inSeconds > 5) {
          await _betterPlayerController!.seekTo(widget.startPosition!);
          await _betterPlayerController!.play();
          debugPrint("▶️ Tiếp tục phát từ ${widget.startPosition!.inSeconds}s");
        } else {
          await _betterPlayerController!.play();
        }
      }

      // 🔹 Cập nhật tiến độ xem
      if (event.betterPlayerEventType == BetterPlayerEventType.progress) {
        final pos = event.parameters?['progress'] as Duration?;
        final dur = event.parameters?['duration'] as Duration?;
        if (pos != null && dur != null) {
          _watchPosition = pos.inSeconds;
          _videoDuration = dur.inSeconds;
        }
      }

      // 🔹 Khi phát xong phim
      if (event.betterPlayerEventType == BetterPlayerEventType.finished) {
        debugPrint("🎬 Xem hết phim — đặt tiến độ về 0");
        _watchPosition = 0;
        _saveWatchProgress();
      }
    });

    // 💾 Lưu định kỳ mỗi 10 giây
    _saveTimer?.cancel();
    _saveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_videoDuration > 0 && _watchPosition > 5) {
        _saveWatchProgress();
      }
    });
  }

  void _playEpisode(int episodeIndex) {
    if (_film == null || _film!.sources == null) return;
    final urls = _extractEpisodeUrls(_film!.sources!);
    if (urls.isEmpty) return;

    final selectedUrl =
    episodeIndex <= urls.length ? urls[episodeIndex - 1] : urls.last;

    if (_betterPlayerController != null) {
      _betterPlayerController!.setupDataSource(
        BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          selectedUrl,
          videoFormat: BetterPlayerVideoFormat.hls,
        ),
      );
    } else {
      _initBetterPlayer(selectedUrl);
    }

    setState(() {
      _isVideoReady = true;
      _selectedEpisode = episodeIndex;
    });
  }

  // ✅ Hàm lưu tiến độ xem
  Future<void> _saveWatchProgress() async {
    try {
      await HistoryService.updateProgress(
        profileId: _profileId,
        filmId: widget.filmId,
        episodeId: _selectedEpisode,
        positionSeconds: _watchPosition,
        durationSeconds: _videoDuration,
      );
      debugPrint("💾 Đã lưu tiến độ: $_watchPosition / $_videoDuration");
    } catch (e) {
      debugPrint("❌ Lỗi lưu tiến độ xem: $e");
    }
  }

  @override
  void dispose() {
    // ✅ Lưu khi thoát
    if (!_hasSaved && _videoDuration > 0 && _watchPosition > 5) {
      _saveWatchProgress();
      _hasSaved = true;
    }
    _saveTimer?.cancel();
    _videoController?.dispose();
    _youtubeController?.dispose();
    _betterPlayerController?.dispose();
    _commentController.dispose();
    _volumeController.removeListener();
    super.dispose();
  }

  // ============================================================
  // UI PHẦN DƯỚI VẪN GIỮ NGUYÊN
  // ============================================================

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
                AspectRatio(aspectRatio: 16 / 9, child: _buildVideoSection()),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _film!.filmName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${_film!.releaseYear} | ${_film!.maturityRating.isNotEmpty ? _film!.maturityRating : 'Tất cả'} | ${_film!.countryName} | ${_film!.isSeries ? 'Phim bộ' : 'Phim lẻ'} | ${_film!.filmStatus}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildViewAndStar(),
                        const SizedBox(height: 12),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(Icons.favorite, "Yêu thích",
                                isFavorite ? Colors.redAccent : Colors.white,
                                    () => setState(() => isFavorite = !isFavorite)),
                            _buildActionButton(
                                Icons.bookmark, "Danh sách", Colors.white, () {}),
                            _buildRatingButton(),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTabs(),
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
            Positioned(
              top: 10,
              left: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    // 🟢 Khi nhấn nút quay lại, gửi tiến độ xem mới nhất về màn hình trước
                    Navigator.pop(context, _watchPosition);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSection() {
    if (_betterPlayerController != null) {
      return BetterPlayer(controller: _betterPlayerController!);
    }

    if (_videoController != null && _videoController!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      );
    }

    return Stack(
      children: [
        Image.network(
          _film!.posterMain.isNotEmpty
              ? _film!.posterMain
              : "https://cdn.vtc/poster_default.png",
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
        const Positioned.fill(
          child: Center(
            child: Text(
              "Không có video khả dụng",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildViewAndStar() {
    return Row(
      children: [
        const Icon(Icons.remove_red_eye, color: Colors.white70, size: 16),
        const SizedBox(width: 4),
        const Text("91.019 lượt xem",
            style: TextStyle(color: Colors.white70, fontSize: 13)),
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
                (index) =>
            const Icon(Icons.star, color: Colors.amberAccent, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    final tabs = ["Tập phim", "Diễn viên", "Bình luận"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(tabs.length, (i) {
        final isSelected = _selectedTab == i;
        return GestureDetector(
          onTap: () => setState(() => _selectedTab = i),
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
                tabs[i],
                style: TextStyle(
                  color: isSelected ? Colors.amberAccent : Colors.white70,
                  fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEpisodesSection() {
    final seasons = _film!.seasons ?? [];
    if (seasons.isEmpty) {
      return const Text("Chưa có danh sách tập phim",
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
                onTap: () => _playEpisode(epNum),
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
  // --- Nút đánh giá (⭐) ---
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

// --- Popup chọn sao ---
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
                      color: isSelected ? Colors.amberAccent : Colors.white24,
                      size: 34,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        if (tempRating == starIndex) {
                          tempRating = 0;
                        } else {
                          tempRating = starIndex;
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
              ],
            );
          },
        );
      },
    );
  }

}
