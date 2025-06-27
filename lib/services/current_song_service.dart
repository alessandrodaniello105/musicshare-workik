import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/current_song.dart';

class CurrentSongService {
  static const MethodChannel _channel = MethodChannel('music_share_app/current_song');

  /// Returns the current playing song on the device using native platform code.
  /// The native side should respond with a map containing 'title' and 'artist' keys.
  static Future<CurrentSong?> getCurrentSong() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>?>('getCurrentSong');
      debugPrint('Raw platform channel result: $result');
      if (result == null) return null;
      final Map<String, dynamic> data = Map<String, dynamic>.from(result);
      final song = CurrentSong.fromJson(data);
      if (song.title.isEmpty && song.artist.isEmpty) {
        return null;
      }
      return song;
    } catch (e) {
      debugPrint('Error in getCurrentSong: $e');

      return null;
    }
  }
}
