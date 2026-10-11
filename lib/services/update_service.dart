import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

/// Information about an available app release on GitHub.
class AppReleaseInfo {
  final String tagName;
  final String name;
  final String body;
  final String htmlUrl;
  final String publishedAt;
  final bool hasUpdate;

  const AppReleaseInfo({
    required this.tagName,
    required this.name,
    required this.body,
    required this.htmlUrl,
    required this.publishedAt,
    required this.hasUpdate,
  });
}

/// Service that checks GitHub Releases for new SweetBites versions.
class UpdateService {
  /// Queries GitHub Releases API for the latest release in [repo].
  /// [repo] format: 'owner/repo' (defaults to [AppConstants.defaultGithubRepo]).
  static Future<AppReleaseInfo?> checkForUpdates({
    String repo = AppConstants.defaultGithubRepo,
    String currentVersion = AppConstants.appVersion,
  }) async {
    final cleanRepo = repo.trim().isEmpty ? AppConstants.defaultGithubRepo : repo.trim();
    final url = Uri.parse('https://api.github.com/repos/$cleanRepo/releases/latest');

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'SweetBites-App',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = (data['tag_name'] as String? ?? '').trim();
      final releaseName = data['name'] as String? ?? tagName;
      final body = data['body'] as String? ?? 'No release notes provided.';
      final htmlUrl = data['html_url'] as String? ?? 'https://github.com/$cleanRepo/releases';
      final publishedAt = data['published_at'] as String? ?? '';

      final hasUpdate = isNewerVersion(
        remoteTag: tagName,
        currentVersion: currentVersion,
      );

      return AppReleaseInfo(
        tagName: tagName,
        name: releaseName,
        body: body,
        htmlUrl: htmlUrl,
        publishedAt: publishedAt,
        hasUpdate: hasUpdate,
      );
    } else if (response.statusCode == 404) {
      // No releases published yet on this repository
      return null;
    } else {
      throw Exception('GitHub API returned status ${response.statusCode}');
    }
  }

  /// Compares semantic versions (e.g. 'v1.1.0' vs '1.0.0').
  static bool isNewerVersion({
    required String remoteTag,
    required String currentVersion,
  }) {
    // Strip leading 'v' or 'V'
    final remoteClean = remoteTag.replaceAll(RegExp(r'^[vV]'), '').trim();
    final currentClean = currentVersion.replaceAll(RegExp(r'^[vV]'), '').trim();

    if (remoteClean.isEmpty) return false;
    if (remoteClean == currentClean) return false;

    final remoteParts = remoteClean.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final currentParts = currentClean.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    final maxLen = remoteParts.length > currentParts.length ? remoteParts.length : currentParts.length;

    for (int i = 0; i < maxLen; i++) {
      final r = i < remoteParts.length ? remoteParts[i] : 0;
      final c = i < currentParts.length ? currentParts[i] : 0;
      if (r > c) return true;
      if (r < c) return false;
    }

    return false;
  }
}
