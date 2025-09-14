import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoDetailScreen extends StatefulWidget {
  final String videoId;
  const VideoDetailScreen({super.key, required this.videoId});

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  final firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Video Detail")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: firestore.collection("videos").doc(widget.videoId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) return const Center(child: Text("Video not found"));

          final videoType = data["videoType"] ?? "upload";
          String? videoUrl = data["videoUrl"];
          String? embedUrl = data["embedUrl"];

          if (videoType == "embed" && (embedUrl == null || embedUrl.isEmpty)) {
            return const Center(child: Text("No embed URL"));
          }

          if (videoType == "upload" && (videoUrl == null || videoUrl.isEmpty)) {
            return const Center(child: Text("No video URL"));
          }

          final String? finalUrl = videoType == "embed" ? embedUrl : videoUrl;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Video Player
                if (videoType == "embed")
                  SizedBox(
                    width: double.infinity,
                    height: 220,
                    child: YouTubeVideoWidget(videoUrl: finalUrl!),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 220,
                    child: VideoPlayerWidget(videoUrl: finalUrl!),
                  ),

                // Title & Description
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data["title"] ?? "",
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data["description"] ?? "",
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: (data["tags"] ?? [])
                            .map<Widget>((tag) => Chip(label: Text(tag)))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ------------------------- VideoPlayer for MP4 / Direct URL -------------------------
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _isLoading = false;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller),
          if (!_controller.value.isPlaying)
            Container(
              color: Colors.black26,
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 60),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Colors.blue,
                bufferedColor: Colors.grey,
                backgroundColor: Colors.black26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------- YouTube Player Widget -------------------------
class YouTubeVideoWidget extends StatefulWidget {
  final String videoUrl;
  const YouTubeVideoWidget({super.key, required this.videoUrl});

  @override
  State<YouTubeVideoWidget> createState() => _YouTubeVideoWidgetState();
}

class _YouTubeVideoWidgetState extends State<YouTubeVideoWidget> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    if (videoId == null) {
      throw "Invalid YouTube URL";
    }
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        controlsVisibleAtStart: true,
        enableCaption: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(
      controller: _controller,
      showVideoProgressIndicator: true,
      progressIndicatorColor: Colors.blue,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
