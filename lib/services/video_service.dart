import 'dart:io';
import '../models/video_model.dart';

class VideoService {
  static Future<List<VideoModel>> getVideos() async {
    List<VideoModel> videos = [];

    try {
      Directory dir = Directory('/storage/emulated/0');

      if (!dir.existsSync()) return [];

      List<FileSystemEntity> files =
      dir.listSync(recursive: true, followLinks: false);

      for (var file in files) {
        if (file is File) {
          String path = file.path.toLowerCase();

          if (path.endsWith(".mp4") ||
              path.endsWith(".mkv") ||
              path.endsWith(".avi")) {
            videos.add(
              VideoModel(
                path: file.path,
                name: file.uri.pathSegments.last,
                folder: file.parent.path,
              ),
            );
          }
        }
      }
    } catch (e) {
      print("Error scanning videos: $e");
    }

    return videos;
  }
}