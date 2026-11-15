import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/error_snack.dart';

final _youtubeId = RegExp(
  r'(?:youtube\.com/(?:watch\?(?:.*&)?v=|embed/|shorts/|live/)|youtu\.be/)([A-Za-z0-9_-]{11})',
);

/// The 11-character YouTube video id in [url], or null for other links.
String? youtubeIdOf(String url) => _youtubeId.firstMatch(url)?.group(1);

/// The in-app player route for a YouTube [url] (see `VideoPlayerScreen`).
String watchRoute(String url, {String? title}) => Uri(
  path: '/watch',
  queryParameters: {'url': url, 'title': ?title},
).toString();

/// Plays YouTube videos in the app; opens any other video link outside it.
Future<void> openVideo(BuildContext context, String url, {String? title}) {
  if (youtubeIdOf(url) != null) {
    return context.push(watchRoute(url, title: title));
  }
  return openExternalLink(context, url);
}

/// Opens [url] outside the app (browser or matching app). Only http(s)
/// links are allowed; shows a message when nothing can open it.
Future<void> openExternalLink(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  final ok =
      uri != null &&
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    showErrorSnack(context, 'Could not open the link. Please try again.');
  }
}
