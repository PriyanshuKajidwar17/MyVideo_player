import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../ providers/video_provider.dart';
import 'folder_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Request permission first
    await Permission.manageExternalStorage.request();

    // Load videos AFTER permission
    await Provider.of<VideoProvider>(context, listen: false).loadVideos();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VideoProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Play VideoX")),

      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.folders.isEmpty
          ? const Center(child: Text("No Videos Found"))
          : ListView(
        children: provider.folders.keys.map((folder) {
          return ListTile(
            title: Text(folder.split('/').last),
            leading: const Icon(Icons.folder),

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FolderScreen(folder: folder),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}