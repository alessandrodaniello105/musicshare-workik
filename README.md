# Music Share App

A Flutter application that fetches the currently playing song and artist on your device, searches for the song on YouTube, retrieves the first video result, and allows you to share the YouTube URL via WhatsApp or Telegram.

## Features

- Fetch the currently playing song title and artist from your device's media player using platform channels.
- Search YouTube for the current song (combining title and artist).
- Retrieve the URL of the first YouTube video result.
- Share the YouTube video link via WhatsApp or Telegram using installed apps or their web fallback.

## Prerequisites

- Flutter SDK installed (Tested with Flutter 3.7+)
- A valid Google YouTube Data API v3 key
- Device with WhatsApp and/or Telegram installed for sharing (optional; app will fallback to web sharing)
- Android or iOS device/emulator with media playing capability for current song detection (native platform code needed)

## Setupflutter create .

### 1. Clone or download this repository

