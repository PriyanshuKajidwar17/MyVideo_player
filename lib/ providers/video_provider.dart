import 'package:flutter/material.dart';
import '../models/video_model.dart';
import '../services/video_service.dart';

class VideoProvider extends ChangeNotifier {
  List<VideoModel> videos = [];

  bool isLoading = true;

  Future<void> loadVideos() async {
    isLoading = true;
    notifyListeners();

    videos = await VideoService.getVideos();

    isLoading = false;
    notifyListeners();
  }

  Map<String, List<VideoModel>> get folders {
    Map<String, List<VideoModel>> map = {};

    for (var v in videos) {
      map.putIfAbsent(v.folder, () => []).add(v);
    }

    return map;
  }
}