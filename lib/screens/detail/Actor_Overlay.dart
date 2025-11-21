import 'package:flutter/material.dart';
import '../../config/api.dart';
import '../../services/Actor_Service.dart';
import '../detail/Detail_Films.dart';

class ActorOverlay extends StatefulWidget {
  final Map<String, dynamic> actor;

  const ActorOverlay({super.key, required this.actor});

  @override
  State<ActorOverlay> createState() => _ActorOverlayState();
}

class _ActorOverlayState extends State<ActorOverlay> {
  List<dynamic> _films = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFilms();
  }

  Future<void> _loadFilms() async {
    final data = await ActorService.getFilmsByActor(widget.actor["Actor_id"]);
    setState(() {
      _films = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF101010),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          // --- Thanh kéo ---
          Container(
            margin: const EdgeInsets.only(top: 10),
            height: 5,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(50),
            ),
          ),

          // --- Nút đóng duy nhất ---
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // --- Avatar + Tên (không còn nút đóng ở đây) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(
                    widget.actor["Actor_avatar"].toString().startsWith("http")
                        ? widget.actor["Actor_avatar"]
                        : "${Api.baseHost}${widget.actor["Actor_avatar"]}",
                  ),
                ),

                const SizedBox(width: 14),

                // Tên diễn viên
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.actor["Actor_name"],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- Label "Phim đã tham gia" ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Phim đã tham gia",
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // --- Danh sách phim ---
          Expanded(
            child: _loading
                ? const Center(
              child: CircularProgressIndicator(color: Colors.amberAccent),
            )
                : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _films.length,
              itemBuilder: (context, index) {
                final f = _films[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DetailFilmScreen(filmId: f["Film_id"]),
                      ),
                    );
                  },
                  child: Container(
                    width: 150,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            f["poster_main"] ?? "",
                            width: 150,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          f["Film_name"],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
