import 'package:url_launcher/url_launcher.dart';

class SharingService {
  /// Attempts to launch WhatsApp with the URL prefilled.
  /// If WhatsApp is not installed, opens the URL in browser.
  static Future<bool> shareToWhatsApp(String url) async {
    final encodedUrl = Uri.encodeComponent(url);
    final whatsappUrl = Uri.parse("whatsapp://send?text=$encodedUrl");
    final webUrl = Uri.parse("https://api.whatsapp.com/send?text=$encodedUrl");

    final canLaunchWhatsApp = await canLaunchUrl(whatsappUrl);
    final canLaunchWeb = await canLaunchUrl(webUrl);
    print('canLaunchWhatsApp: '
        '[32m$canLaunchWhatsApp[0m, canLaunchWeb: [34m$canLaunchWeb[0m');

    if (canLaunchWhatsApp) {
      return await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else if (canLaunchWeb) {
      return await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch WhatsApp or web fallback.');
      return false;
    }
  }

  /// Attempts to launch Telegram with the URL prefilled.
  /// If Telegram is not installed, opens the URL in browser.
  static Future<bool> shareToTelegram(String url) async {
    final encodedUrl = Uri.encodeComponent(url);
    // telegram://msg_url?url=... did not work reliably, so use tg://msg?text=...
    final telegramUrl = Uri.parse("tg://msg?text=$encodedUrl");

    if (await canLaunchUrl(telegramUrl)) {
      return await launchUrl(telegramUrl);
    } else {
      // Fallback: open telegram web messenger with text
      final webUrl = Uri.parse("https://t.me/share/url?url=$encodedUrl");
      if (await canLaunchUrl(webUrl)) {
        return await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
      return false;
    }
  }
}
