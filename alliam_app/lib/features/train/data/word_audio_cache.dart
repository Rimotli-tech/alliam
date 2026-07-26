import 'dart:async';

typedef ResolveAudioUrl = Future<String> Function(String storagePath);
typedef PreloadAudioUrl =
    Future<void> Function(String storagePath, String resolvedUrl);

class WordAudioCache {
  WordAudioCache({
    required ResolveAudioUrl resolveUrl,
    required PreloadAudioUrl preloadUrl,
  }) : _resolveUrl = resolveUrl,
       _preloadUrl = preloadUrl;

  final ResolveAudioUrl _resolveUrl;
  final PreloadAudioUrl _preloadUrl;
  final Map<String, String> _urls = {};
  final Set<String> _prepared = {};
  final Map<String, Future<String>> _inFlight = {};

  bool isPrepared(String storagePath) => _prepared.contains(storagePath);

  String? resolvedUrl(String storagePath) => _urls[storagePath];

  Future<String> prepare(String storagePath) {
    if (storagePath.isEmpty) {
      return Future<String>.error(
        StateError('A pronunciation Storage path is required.'),
      );
    }
    final readyUrl = _urls[storagePath];
    if (readyUrl != null && _prepared.contains(storagePath)) {
      return Future.value(readyUrl);
    }
    return _inFlight[storagePath] ??= _prepare(storagePath).whenComplete(() {
      _inFlight.remove(storagePath);
    });
  }

  Future<String> resolve(String storagePath) async {
    if (storagePath.isEmpty) {
      throw StateError('A pronunciation Storage path is required.');
    }
    return _urls[storagePath] ??= await _resolveUrl(storagePath);
  }

  Future<String> _prepare(String storagePath) async {
    final url = await resolve(storagePath);
    await _preloadUrl(storagePath, url);
    _prepared.add(storagePath);
    return url;
  }
}
