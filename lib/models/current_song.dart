class CurrentSong {
  final String title;
  final String artist;

  CurrentSong({required this.title, required this.artist});

  factory CurrentSong.fromJson(Map<String, dynamic> json) {
    return CurrentSong(
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'artist': artist,
    };
  }
}
