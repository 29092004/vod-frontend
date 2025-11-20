import 'dart:async';
import 'package:flutter/material.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:volume_controller/volume_controller.dart';
import '../../models/Film_info.dart';
import '../../services/Film_Service.dart';
import '../../services/History_Service.dart';
import 'package:flutter/services.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../config/api.dart';
import '../../services/Comment_Service.dart';
import '../../services/auth_service.dart';
import '../../services/Rating_Service.dart';
import '../../services/Favorite_Service.dart';
import '../../models/watchlist.dart';
import '../../services/WatchList_Service.dart' hide WatchListItemService;
import '../../services/WatchListItem_Service.dart';
import '../profile/Profile_Screen.dart';

class DetailFilmScreen extends StatefulWidget {
  final int filmId;
  final int? episodeId;
  final Duration? startPosition;


  const DetailFilmScreen({
    super.key,
    required this.filmId,
    this.startPosition,
    this.episodeId,
  });

  @override
  State<DetailFilmScreen> createState() => _DetailFilmScreenState();
}

class _DetailFilmScreenState extends State<DetailFilmScreen> {
  bool isFavorite = false;
  bool _isLoading = true;
  bool _isVideoReady = false;
  bool _favLoading = false; // để chặn spam khi đang gọi API
  int _selectedRating = 0;
  double _avgScore = 0.0;
  int _totalReviews = 0;
  bool _isPremiumUser = false;
  bool _isFilmPremium = false;

  FilmInfo? _film;
  List<FilmInfo>? _recommendations;

  VideoPlayerController? _videoController;
  YoutubePlayerController? _youtubeController;
  BetterPlayerController? _betterPlayerController;

  int _selectedEpisode = 1;
  int _selectedSeason = 0;
  int _selectedTab = 0;

  int _selectedEpisodeId = 1;
  int _selectedEpisodeNumber = 1;

  //  Bình luận
  List<dynamic> _comments = [];
  bool _loadingComments = true;
  final TextEditingController _commentController = TextEditingController();

  //  Biến điều khiển âm lượng hệ thống
  final VolumeController _volumeController = VolumeController();
  double _systemVolume = 1.0;

  //  Biến theo dõi tiến độ xem phim
  int _watchPosition = 0;
  int _videoDuration = 0;
  int _profileId = 0;
  bool _hasSaved = false;
  Timer? _saveTimer;

  // WatchList
  List<WatchList> _myWatchLists = [];
  bool _watchListLoading = false;
  bool _addingToWatchList = false;
  final TextEditingController _newListNameController = TextEditingController();
  void _showPremiumPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Nội dung Premium",
            style: TextStyle(
              color: Colors.amberAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            "Đây là nội dung chỉ dành cho tài khoản Premium.\n",
            style: TextStyle(color: Colors.white70, height: 1.3),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Đóng",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent,
              ),
              onPressed: () {
                Navigator.pop(context); // đóng popup
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountScreen()),
                );
              },
              child: const Text(
                "Nâng cấp tài khoản",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    _volumeController.showSystemUI = true;
    _volumeController.getVolume().then((vol) {
      setState(() => _systemVolume = vol);
    });
    _volumeController.listener((volume) {
      setState(() => _systemVolume = volume);
    });
    _initData();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleFavorite() async {
    if (_profileId == 0) {
      _showMessage('Vui lòng đăng nhập để sử dụng danh sách yêu thích');
      return;
    }

    if (_favLoading) return;

    setState(() {
      _favLoading = true;
    });

    try {
      if (!isFavorite) {
        // Chưa yêu thích → thêm vào danh sách
        final ok = await FavoriteService.addFavorite(
          profileId: _profileId,
          filmId: widget.filmId,
        );

        if (ok) {
          setState(() => isFavorite = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Đã thêm vào danh sách yêu thích")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Không thể thêm vào danh sách yêu thích"),
            ),
          );
        }
      } else {
        // Đã yêu thích -> xoá ra
        final ok = await FavoriteService.removeFavorite(
          _profileId,
          widget.filmId,
        );
        if (ok) {
          if (!mounted) return;
          setState(() {
            isFavorite = false;
          });
          _showMessage('Đã xóa khỏi danh sách yêu thích');
        } else {
          _showMessage('Không thể xóa khỏi danh sách yêu thích');
        }
      }
    } catch (e) {
      // Nếu muốn phân biệt lỗi duplicate có thể parse message từ Api.handleError
      _showMessage('Có lỗi xảy ra, vui lòng thử lại');
    } finally {
      if (!mounted) return;
      setState(() {
        _favLoading = false;
      });
    }
  }

  Future<void> _checkFavorite() async {
    if (!mounted) return;
    if (_profileId == 0) return;

    final result = await FavoriteService.isFavorite(_profileId, widget.filmId);
    if (!mounted) return;
    setState(() {
      isFavorite = result;
    });
  }

  Future<void> _loadMyWatchLists() async {
    if (_profileId == 0) return;

    setState(() {
      _watchListLoading = true;
    });

    try {
      final lists = await WatchListService.getByProfile(_profileId);
      if (!mounted) return;
      setState(() {
        _myWatchLists = lists;
      });
    } catch (e) {
      if (!mounted) return;
      _showMessage('Không thể tải danh sách của bạn');
    } finally {
      if (!mounted) return;
      setState(() {
        _watchListLoading = false;
      });
    }
  }

  Future<void> _handleAddToWatchList(WatchList list) async {
    if (_addingToWatchList) return;

    setState(() {
      _addingToWatchList = true;
    });

    try {
      final ok = await WatchListItemService.addFilmToWatchList(
        watchListId: list.id,
        filmId: widget.filmId,
      );

      if (!mounted) return;

      if (ok) {
        Navigator.of(context).pop();
        _showMessage('Đã thêm vào "${list.name}"');
      } else {
        _showMessage('Không thể thêm vào danh sách này');
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Không thể thêm vào danh sách này');
    } finally {
      if (!mounted) return;
      setState(() {
        _addingToWatchList = false;
      });
    }
  }

  Future<void> _showCreateWatchListDialog() async {
    if (_profileId == 0) {
      _showMessage('Vui lòng đăng nhập để sử dụng tính năng này');
      return;
    }

    _newListNameController.clear();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Tạo danh sách mới'),
          content: TextField(
            controller: _newListNameController,
            decoration: const InputDecoration(hintText: 'Nhập tên danh sách'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                final name = _newListNameController.text.trim();
                if (name.isEmpty) return;

                Navigator.of(ctx).pop(); // đóng dialog

                try {
                  // Tạo danh sách
                  await WatchListService.createWatchList(
                    profileId: _profileId,
                    name: name,
                  );

                  // Reload toàn bộ danh sách
                  await _loadMyWatchLists();

                  // Tìm lại list mới tạo theo tên (giả sử tên là duy nhất với user)
                  final created = _myWatchLists.firstWhere(
                    (x) => x.name == name,
                    orElse: () => _myWatchLists.first,
                  );

                  await WatchListItemService.addFilmToWatchList(
                    watchListId: created.id,
                    filmId: widget.filmId,
                  );

                  if (!mounted) return;
                  Navigator.of(context).pop(); // đóng bottom sheet
                  _showMessage('Đã tạo và thêm vào "$name"');
                } catch (e) {
                  if (!mounted) return;
                  _showMessage('Không thể tạo danh sách mới');
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openAddToWatchListSheet() async {
    if (_profileId == 0) {
      _showMessage('Vui lòng đăng nhập để sử dụng tính năng này');
      return;
    }

    await _loadMyWatchLists();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Thêm vào danh sách',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                if (_watchListLoading)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  if (_myWatchLists.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Bạn chưa có danh sách nào.\nHãy tạo danh sách mới để lưu phim.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _myWatchLists.length,
                        itemBuilder: (_, index) {
                          final wl = _myWatchLists[index];
                          return ListTile(
                            onTap: () => _handleAddToWatchList(wl),
                            leading: const Icon(
                              Icons.playlist_play,
                              color: Colors.white,
                            ),
                            title: Text(
                              wl.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: wl.createdAt != null
                                ? Text(
                                    'Tạo: ${wl.createdAt}',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  )
                                : null,
                          );
                        },
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showCreateWatchListDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo danh sách mới'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _initData() async {
    await Api.loadToken();
    //  LẤY PROFILE ID TỰ ĐỘNG TỪ JWT
    final me = await AuthService.getMe();
    final user = me?['user'];
    if (user != null) {
      setState(() {
        _profileId = user['Profile_id'] ?? user['profile_id'] ?? user['id'];
      });
    }
    if (user != null) {
      final exp = user['premium_expired'];
      if (exp != null && exp.toString().isNotEmpty) {
        final d = DateTime.tryParse(exp.toString());
        if (d != null && d.isAfter(DateTime.now())) {
          _isPremiumUser = true;
        }
      }
    }

    // kiểm tra trạng thái yêu thích
    if (_profileId != 0) {
      await _checkFavorite();
    }

    await _loadFilm();
    if (widget.episodeId != null) {
      _selectedEpisodeId = widget.episodeId!;
    }

    await _loadAverageScore();
    await _loadComments();
  }

  //  PHIM
  Future<void> _loadFilm() async {
    try {
      final data = await FilmService.getFilmDetail(widget.filmId);

      setState(() {
        _film = data;
        _isFilmPremium = data.isPremiumOnly;
      });
      if (_isFilmPremium && !_isPremiumUser) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _showPremiumPopup();
        });
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadVideoAsync(data);
      });

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


  //  Xử lý video (m3u8 / youtube / mp4)
  Future<void> _loadVideoAsync(FilmInfo data) async {
    if (_isFilmPremium && !_isPremiumUser) {
      setState(() {
        _isVideoReady = false;
      });
      return;
    }
    try {
      final sources = data.sources ?? "";
      final trailer = data.trailerUrl.trim();
      String? playUrl;

      if (sources.isNotEmpty && sources.contains(".m3u8")) {
        final urls = _extractEpisodeUrls(sources);
        if (urls.isNotEmpty) {
          final firstUrl = urls.first;
          _initBetterPlayer(firstUrl);
          final epId = data.seasons?[0]["Episodes"]?[0]["Episode_id"] ?? 1;

          setState(() {
            _isVideoReady = true;
            if (widget.episodeId != null) {
              //  Load tập đang xem từ xem tiếp
              _selectedEpisodeId = widget.episodeId!;
              _selectedEpisodeNumber = _findEpisodeNumberById(
                widget.episodeId!,
                data,
              );
            } else {
              //  Mặc định tập 1
              _selectedEpisodeId = epId;
              _selectedEpisodeNumber = 1;
            }
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
      debugPrint(" Lỗi tải video: $e");
      setState(() => _isVideoReady = false);
    }
  }

  //  Khởi tạo VideoPlayer
  Future<void> _initVideoPlayer(String url) async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController!.initialize();
      await _videoController!.play();
      _videoController!.setLooping(true);
      debugPrint("🎬 Đang phát video: $url");
    } catch (e) {
      debugPrint(" Lỗi khởi tạo video_player: $e");
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

  int _findEpisodeNumberById(int episodeId, FilmInfo film) {
    for (var season in film.seasons ?? []) {
      for (var ep in (season["Episodes"] ?? [])) {
        if (ep["Episode_id"] == episodeId) {
          return ep["Episode_number"];
        }
      }
    }
    return 1;
  }

  //  Khởi tạo BetterPlayer phát tiếp ngay vị trí đang xem
  void _initBetterPlayer(String url) {
    //  Tạo bản đồ độ phân giải chỉ có 720p và 480p
    final qualityUrls = {
      "720p": url.replaceAll("480p", "720p").replaceAll("480p", "720p"),
      "480p": url.replaceAll("720p", "480p").replaceAll("720p", "480p"),
    };

    //  DataSource chính kèm hai độ phân giải
    final dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      url,
      videoFormat: BetterPlayerVideoFormat.hls,
      resolutions: {"720p": qualityUrls["720p"]!, "480p": qualityUrls["480p"]!},
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
        deviceOrientationsAfterFullScreen: const [DeviceOrientation.portraitUp],

        //  Giữ nguyên controls
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

    //  Khi video load xong thì seek tới vị trí cũ & phát luôn
    _betterPlayerController!.addEventsListener((event) async {
      if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
        if (widget.startPosition != null &&
            widget.startPosition!.inSeconds > 5) {
          await _betterPlayerController!.seekTo(widget.startPosition!);
          await _betterPlayerController!.play();
          debugPrint(" Tiếp tục phát từ ${widget.startPosition!.inSeconds}s");
        } else {
          await _betterPlayerController!.play();
        }
      }

      //  Cập nhật tiến độ xem
      if (event.betterPlayerEventType == BetterPlayerEventType.progress) {
        final pos = event.parameters?['progress'] as Duration?;
        final dur = event.parameters?['duration'] as Duration?;
        if (pos != null && dur != null) {
          _watchPosition = pos.inSeconds;
          _videoDuration = dur.inSeconds;
        }
      }

      // Khi phát xong phim
      if (event.betterPlayerEventType == BetterPlayerEventType.finished) {
        debugPrint("🎬 Xem hết phim — đặt tiến độ về 0");
        _watchPosition = 0;
        _saveWatchProgress();
      }
    });

    //  Lưu định kỳ mỗi 10 giây
    _saveTimer?.cancel();
    _saveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_videoDuration > 0 && _watchPosition > 5) {
        _saveWatchProgress();
      }
    });
  }

  void _playEpisode(Map<String, dynamic> episodeData) async {
    if (_film == null || _film!.sources == null) return;

    final int episodeId = episodeData["Episode_id"];
    final int episodeNumber = episodeData["Episode_number"];

    final urls = _extractEpisodeUrls(_film!.sources!);
    if (urls.isEmpty) return;

    final int index = (episodeNumber - 1).clamp(0, urls.length - 1);
    final selectedUrl = urls[index];

    //  RESET tiến độ khi đổi tập
    _watchPosition = 0;

    final volume = _systemVolume;

    if (_betterPlayerController != null) {
      // Load tập mới
      await _betterPlayerController!.setupDataSource(
        BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          selectedUrl,
          videoFormat: BetterPlayerVideoFormat.hls,
        ),
      );

      //  QUAN TRỌNG — RESET VỀ 0 GIÂY
      await _betterPlayerController!.seekTo(Duration.zero);

      _betterPlayerController!.setVolume(volume);
    } else {
      _initBetterPlayer(selectedUrl);
    }

    setState(() {
      _selectedEpisodeId = episodeId;
      _selectedEpisodeNumber = episodeNumber;
      _isVideoReady = true;
    });
  }

  // Hàm lưu tiến độ xem
  Future<void> _saveWatchProgress() async {
    try {
      await HistoryService.updateProgress(
        profileId: _profileId,
        filmId: widget.filmId,
        episodeId: _selectedEpisodeId,
        positionSeconds: _watchPosition,
        durationSeconds: _videoDuration,
      );
      debugPrint(" Đã lưu tiến độ: $_watchPosition / $_videoDuration");
    } catch (e) {
      debugPrint(" Lỗi lưu tiến độ xem: $e");
    }
  }

  // BÌNH LUẬN
  Future<void> _loadComments() async {
    try {
      final data = await CommentService.getComments(widget.filmId);
      debugPrint(" filmId gửi lên CommentService: ${widget.filmId}");

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
    if (!_hasSaved && _videoDuration > 0 && _watchPosition > 5) {
      _saveWatchProgress();
      _hasSaved = true;
    }
    _saveTimer?.cancel();
    _videoController?.dispose();
    _youtubeController?.dispose();
    _betterPlayerController?.dispose();
    _commentController.dispose();
    _newListNameController.dispose();
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
                AspectRatio(aspectRatio: 16 / 9, child: _buildVideoSection()),

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
                              () {
                                if (!_favLoading) _toggleFavorite();
                              },
                            ),
                            _buildActionButton(
                              Icons.add,
                              "Thêm vào",
                              Colors.white,
                              () {
                                _openAddToWatchListSheet();
                              },
                            ),
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

            // Nút quay lại
            Positioned(
              top: 10,
              left: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context, {
                      "episode_id": _selectedEpisodeId,
                      "position": _watchPosition,
                      "duration": _videoDuration,
                    });
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
    //  Nếu phim Premium nhưng user KHÔNG Premium → khóa video
    if (_isFilmPremium && !_isPremiumUser) {
      return Stack(
        children: [
          // Poster nền
          Image.network(
            _film!.posterMain.isNotEmpty
                ? _film!.posterMain
                : "https://cdn.vtc/poster_default.png",
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // Lớp phủ tối
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.65),
          ),

          // Icon khóa + thông báo
          Positioned.fill(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.lock,
                    size: 70,
                    color: Colors.white,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Nội dung chỉ dành cho tài khoản Premium"
                        "Vui lòng vào tài khoản để nâng cấp",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    //  Nếu user có Premium → phát video như bình thường
    if (_betterPlayerController != null) {
      return BetterPlayer(controller: _betterPlayerController!);
    }

    if (_videoController != null && _videoController!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      );
    }

    //  Không có video
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
          const Text(
            "Đánh giá",
            style: TextStyle(
              color: Colors.amberAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
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
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }),
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
                  onPressed: () async {
                    await _submitRating(tempRating);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Gửi",
                    style: TextStyle(color: Colors.greenAccent),
                  ),
                ),
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

  // Danh sách tập phim

  Widget _buildEpisodesSection() {
    final seasons = _film!.seasons ?? [];
    if (seasons.isEmpty) {
      return const Text(
        "Chưa có danh sách tập phim",
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
              final isSelected =
                  (_selectedEpisodeId == episodes[i]["Episode_id"]);
              return GestureDetector(
                onTap: () => _playEpisode(episodes[i]),
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

  Widget _buildCommentSection() {
    if (_loadingComments) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.greenAccent),
      );
    }


    ///  Ô NHẬP BÌNH LUẬN

    Widget buildCommentInput() {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Nhập bình luận...",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.greenAccent),
              onPressed: _sendComment,
            ),
          ],
        ),
      );
    }


    ///  Hàm dựng 1 COMMENT + REPLY

    Widget buildCommentItem(Map<String, dynamic> c, int depth, int parentId) {
      c['showReplyBox'] ??= false;
      c['showReplies'] ??= false;

      final replyCtrl = TextEditingController();
      final replies = c['Replies'] ?? [];
      final double indent = 40.0 * depth;

      return Padding(
        padding: EdgeInsets.only(left: indent),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Avatar + tên + nội dung
            ListTile(
              leading: CircleAvatar(
                radius: depth == 0 ? 20 : 16,
                backgroundImage:
                    (c['Avatar_url'] != null &&
                        c['Avatar_url'].toString().isNotEmpty)
                    ? NetworkImage(
                        c['Avatar_url'].toString().startsWith('http')
                            ? c['Avatar_url']
                            : '${Api.baseHost}${c['Avatar_url'].toString().startsWith('/') ? c['Avatar_url'] : '/${c['Avatar_url']}'}',
                      )
                    : const NetworkImage(
                        "https://cdn.vtc.vn/avatar_default.png",
                      ),
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
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          );
                        } catch (_) {
                          return const SizedBox.shrink();
                        }
                      },
                    ),

                  const SizedBox(height: 4),

                  /// LIKE + PHẢN HỒI
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => depth == 0
                            ? _toggleLike(c['Comment_id'])
                            : _toggleLikeReply(c),
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


            ///  Ô nhập phản hồi

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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.greenAccent,
                        size: 20,
                      ),
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

            /// Nút ẩn/hiện reply
            if (replies.isNotEmpty)
              GestureDetector(
                onTap: () {
                  setState(
                    () => c['showReplies'] = !(c['showReplies'] ?? false),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.only(
                    left: depth == 0 ? 50 : 40,
                    bottom: 6,
                  ),
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

            /// Danh sách reply
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


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildCommentInput(), //  Thêm phần nhập bình luận
        ..._comments.map((c) => buildCommentItem(c, 0, c['Comment_id'])),
      ],
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

      final profileId = user['Profile_id'] ?? user['profile_id'] ?? user['id'];

      // GỬI COMMENT
      final ok = await CommentService.addComment(
        filmId: widget.filmId,
        profileId: profileId,
        content: text,
      );

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không thể gửi bình luận")),
        );
        return;
      }

      _commentController.clear();

      await _loadComments();

      setState(() {});
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Vui lòng đăng nhập")));
        return;
      }
      final profileId = user['Profile_id'] ?? user['profile_id'] ?? user['id'];
      final ok = await CommentService.addReply(
        filmId: widget.filmId,
        profileId: profileId,
        parentId: parentId,
        content: text,
      );

      if (!ok) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Không thể gửi phản hồi")));
        return;
      }

      await _loadComments();

      setState(() {}); // refresh UI
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
