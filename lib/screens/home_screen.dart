import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';

import '../ providers/video_provider.dart';
import 'folder_screen.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _titleController;
  late Animation<double> _fadeAnim;
  late Animation<double> _glowAnim;

  /// 🔥 ICON ANIMATION
  late Animation<double> _iconScaleAnim;
  late Animation<double> _iconGlowAnim;

  @override
  void initState() {
    super.initState();
    _init();

    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _fadeAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeInOut),
    );

    _glowAnim = Tween<double>(begin: 4, end: 10).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeInOut),
    );

    /// 🔥 ICON ANIMATION
    _iconScaleAnim = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeInOut),
    );

    _iconGlowAnim = Tween<double>(begin: 2, end: 8).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    var status = await Permission.videos.request();
    if (status.isGranted) {
      await Provider.of<VideoProvider>(context, listen: false).loadVideos();
    }
  }

  Future<void> pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null && result.files.single.path != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerScreen(
            videoPath: result.files.single.path!,
          ),
        ),
      );
    }
  }

  Future<List<File>> _getAllVideos() async {
    final dir = Directory('/storage/emulated/0');
    final List<File> videos = [];

    await for (var entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File &&
          (entity.path.endsWith(".mp4") ||
              entity.path.endsWith(".mkv") ||
              entity.path.endsWith(".avi"))) {
        videos.add(entity);
      }
    }

    return videos;
  }

  /// 🔥 ANIMATED TITLE with icon
  Widget _buildAnimatedTitle() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: AnimatedBuilder(
        animation: _titleController,
        builder: (context, child) {

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [

              /// 🔤 TEXT FIRST
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: "Nex",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: "Play",
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: _glowAnim.value,
                            color: Colors.greenAccent,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              /// 🎬 ICON ON RIGHT (ANIMATED)
              Transform.scale(
                scale: _iconScaleAnim.value,
                child: Icon(
                  Icons.ondemand_video,
                  color: Colors.greenAccent,
                  size: 24,
                  shadows: [
                    Shadow(
                      blurRadius: _iconGlowAnim.value,
                      color: Colors.greenAccent,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 🔥 ANIMATED ICON
  Widget _animatedIcon(IconData icon, VoidCallback onTap) {
    return AnimatedBuilder(
      animation: _titleController,
      builder: (context, child) {
        return Transform.scale(
          scale: _iconScaleAnim.value,
          child: IconButton(
            icon: Icon(
              icon,
              color: Colors.green,
              shadows: [
                Shadow(
                  blurRadius: _iconGlowAnim.value,
                  color: Colors.green,
                ),
              ],
            ),
            onPressed: onTap,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VideoProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black,

        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          title: _buildAnimatedTitle(),

          bottom: const TabBar(
            indicatorColor: Colors.green,
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(child: Text("Folders", style: TextStyle(fontWeight: FontWeight.bold))),
              Tab(child: Text("All Videos", style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),

          actions: [
            _animatedIcon(Icons.add, pickVideo),
            _animatedIcon(Icons.refresh, () {
              provider.loadVideos();
            }),
          ],
        ),

        body: TabBarView(
          children: [

            provider.isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : provider.folders.isEmpty
                ? _emptyState()
                : ListView.builder(
              itemCount: provider.folders.keys.length,
              itemBuilder: (context, index) {
                final folder = provider.folders.keys.elementAt(index);
                final count = provider.folders[folder]!.length;

                return Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: const Icon(Icons.folder, color: Colors.green),
                    title: Text(folder.split('/').last, style: const TextStyle(color: Colors.white)),
                    subtitle: Text("$count videos", style: const TextStyle(color: Colors.grey)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FolderScreen(folder: folder),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            FutureBuilder<List<File>>(
              future: _getAllVideos(),
              builder: (context, snapshot) {

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.green));
                }

                final videos = snapshot.data ?? [];

                if (videos.isEmpty) {
                  return _emptyState();
                }

                return ListView.builder(
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final file = videos[index];

                    return Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: const Icon(Icons.play_circle, color: Colors.green),
                        title: Text(file.path.split('/').last,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          "${(file.lengthSync() / (1024 * 1024)).toStringAsFixed(1)} MB",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlayerScreen(videoPath: file.path),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 🔥 ANIMATED EMPTY STATE
  Widget _emptyState() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.video_library, size: 70, color: Colors.grey),
          const SizedBox(height: 10),
          const Text("No Videos Found",
              style: TextStyle(fontSize: 16, color: Colors.white)),

          const SizedBox(height: 5),

          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              children: [
                TextSpan(
                  text: "Use + button ",
                  style: TextStyle(color: Colors.green),
                ),
                TextSpan(
                  text: "to",
                  style: TextStyle(color: Colors.red),
                ),
                TextSpan(
                  text: " add videos",
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}