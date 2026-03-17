import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ providers/video_provider.dart';
import 'player_screen.dart';

class FolderScreen extends StatelessWidget {
  final String folder;

  const FolderScreen({super.key, required this.folder});

  @override
  Widget build(BuildContext context) {
    final videos =
        Provider.of<VideoProvider>(context).folders[folder] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(folder.split('/').last)),

      body: videos.isEmpty
          ? const Center(child: Text("No Videos in this folder"))
          : ListView.builder(
        itemCount: videos.length,
        itemBuilder: (_, i) {
          return ListTile(
            title: Text(videos[i].name),
            leading: const Icon(Icons.video_file),

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PlayerScreen(videoPath: videos[i].path),
                ),
              );
            },
          );
        },
      ),
    );
  }
}