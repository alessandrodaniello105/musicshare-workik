import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/current_song.dart';
import 'services/api_keys.dart';
import 'services/current_song_service.dart';
import 'services/sharing_service.dart';
import 'services/youtube_service.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
  runApp(const MusicShareApp());
}

class MusicShareApp extends StatelessWidget {
  const MusicShareApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Share App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MusicShareHomePage(),
    );
  }
}

class MusicShareHomePage extends StatefulWidget {
  const MusicShareHomePage({Key? key}) : super(key: key);

  @override
  State<MusicShareHomePage> createState() => _MusicShareHomePageState();
}

class _MusicShareHomePageState extends State<MusicShareHomePage> {
  CurrentSong? _currentSong;
  String? _youtubeUrl;
  bool _loadingSong = false;
  bool _loadingYouTube = false;
  String? _errorMessage;

  late YoutubeService _youtubeService;

  @override
  void initState() {
    super.initState();
    _youtubeService = YoutubeService(youtubeApiKey);
    _fetchCurrentSong();
  }

  Future<void> _fetchCurrentSong() async {
    setState(() {
      _loadingSong = true;
      _errorMessage = null;
      // Do not clear _youtubeUrl here
    });
    try {
      final song = await CurrentSongService.getCurrentSong();
      debugPrint('Raw song object from service: $song');
      debugPrint('Fetched song: title="${song?.title}", artist="${song?.artist}"');
      // Only update UI if song changed
      if (song != null && (song.title.isNotEmpty || song.artist.isNotEmpty)) {
        if (_currentSong == null || _currentSong!.title != song.title || _currentSong!.artist != song.artist) {
          setState(() {
            _currentSong = song;
            _loadingSong = false;
            _youtubeUrl = null; // Clear YouTube result only if song changed
          });
        } else {
          setState(() {
            _loadingSong = false;
          });
        }
      } else {
        setState(() {
          _currentSong = null;
          _loadingSong = false;
          _youtubeUrl = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch song: $e';
        _loadingSong = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set up a periodic timer to poll for song changes every 2 seconds
    Future.microtask(() {
      _startSongPolling();
    });
  }

  void _startSongPolling() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));
      await _fetchCurrentSong();
      return mounted;
    });
  }

  Future<void> _searchYoutube() async {
    if (_currentSong == null || _currentSong!.title.isEmpty) {
      setState(() {
        _errorMessage = "No current song to search.";
      });
      return;
    }
    setState(() {
      _loadingYouTube = true;
      _errorMessage = null;
      _youtubeUrl = null;
    });
    final query = '${_currentSong!.title} ${_currentSong!.artist}';
    final url = await _youtubeService.searchFirstVideo(query);
    if (url == null) {
      setState(() {
        _errorMessage = "Failed to find YouTube video.";
      });
    } else {
      setState(() {
        _youtubeUrl = url;
      });
    }
    setState(() {
      _loadingYouTube = false;
    });
  }

  Future<void> _shareWhatsApp() async {
    if (_youtubeUrl == null) {
      setState(() {
        _errorMessage = "No YouTube URL to share.";
      });
      return;
    }
    final success = await SharingService.shareToWhatsApp(_youtubeUrl!);
    if (!success) {
      setState(() {
        _errorMessage = 'Could not open WhatsApp.';
      });
    }
  }

  Future<void> _shareTelegram() async {
    if (_youtubeUrl == null) {
      setState(() {
        _errorMessage = "No YouTube URL to share.";
      });
      return;
    }
    final success = await SharingService.shareToTelegram(_youtubeUrl!);
    if (!success) {
      setState(() {
        _errorMessage = 'Could not open Telegram.';
      });
    }
  }


  //testing the new widget
  Widget _buildSongInfo() {
    if (_loadingSong) {
      return const CircularProgressIndicator();
    }
    // Check if _currentSong is null or if both title and artist are empty
    if (_currentSong == null ||
        ((_currentSong!.title.isEmpty) && (_currentSong!.artist.isEmpty))) {
      return const Text(
        'No song detected.',
        style: TextStyle(fontSize: 18),
        textAlign: TextAlign.center,
      );
    }
    // Display song and artist if available
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_currentSong!.title.isNotEmpty)
          Text(
            _currentSong!.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        if (_currentSong!.artist.isNotEmpty)
          Text(
            _currentSong!.artist,
            style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  Widget _buildYouTubeSection() {
    if (_loadingYouTube) {
      return const Padding(
        padding: EdgeInsets.only(top: 20),
        child: CircularProgressIndicator(),
      );
    }
    if (_youtubeUrl != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: _youtubeUrl!));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('YouTube URL copied to clipboard!')),
            );
          },
          child: Text(
            _youtubeUrl!,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.blue, 
              decoration: TextDecoration.underline
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildError() {
    if (_errorMessage == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        _errorMessage!,
        style: const TextStyle(color: Colors.red, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasYouTubeUrl = _youtubeUrl != null && _youtubeUrl!.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Share App'),
        actions: [
          IconButton(
            tooltip: 'Refresh current song',
            icon: const Icon(Icons.refresh),
            onPressed: _loadingSong ? null : _fetchCurrentSong,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSongInfo(),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('Search YouTube'),
                onPressed: _loadingYouTube || _loadingSong || _currentSong == null ? null : _searchYoutube,
              ),
              _buildYouTubeSection(),
              const SizedBox(height: 24),
              if (hasYouTubeUrl)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                              Colors.white, BlendMode.srcIn),
                          child: Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/5/5e/WhatsApp_icon.png',
                              width: 24,
                              height: 24),
                        ),
                        label: const Text('Share to WhatsApp', style: TextStyle(color: Colors.white)),
                        onPressed: _shareWhatsApp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/8/82/Telegram_logo.png',
                          width: 24,
                          height: 24,
                          color: Colors.white,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.telegram, color: Colors.white),
                        ),
                        label: const Text('Share to Telegram', style: TextStyle(color: Colors.white)),
                        onPressed: _shareTelegram,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )

                  ],
                ),
              _buildError(),
            ],
          ),
        ),
      ),
    );
  }
}
