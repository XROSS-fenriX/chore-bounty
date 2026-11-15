import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Displays uploaded chore proof thumbnails with full-screen zoom inspection.
class BountyProofGallery extends StatelessWidget {
  const BountyProofGallery({
    super.key,
    required this.imageUrls,
  });

  final List<String> imageUrls;

  static const int _chunkSize = 8192;
  static const int _maxCachedImages = 24;
  static final Map<String, Uint8List> _imageCache = <String, Uint8List>{};
  static final Map<String, Future<Uint8List>> _inFlight =
      <String, Future<Uint8List>>{};

  static String _resolveFetchUrl(String imageUrl) {
    if (imageUrl.contains('/storage/bounty-proofs/')) {
      return imageUrl.replaceFirst(
        '/storage/bounty-proofs/',
        '/api/bounty-proofs/',
      );
    }
    return imageUrl;
  }

  static int? _parseTotalLength(String? contentRange) {
    if (contentRange == null) return null;
    final slashIndex = contentRange.lastIndexOf('/');
    if (slashIndex == -1 || slashIndex + 1 >= contentRange.length) return null;
    return int.tryParse(contentRange.substring(slashIndex + 1).trim());
  }

  static Future<Uint8List> _loadImageBytes(String imageUrl) {
    final cached = _imageCache[imageUrl];
    if (cached != null) {
      return Future<Uint8List>.value(cached);
    }

    final existing = _inFlight[imageUrl];
    if (existing != null) {
      return existing;
    }

    final future = _fetchChunkedBytes(imageUrl).then((bytes) {
      if (_imageCache.length >= _maxCachedImages) {
        _imageCache.remove(_imageCache.keys.first);
      }
      _imageCache[imageUrl] = bytes;
      return bytes;
    }).whenComplete(() {
      _inFlight.remove(imageUrl);
    });

    _inFlight[imageUrl] = future;
    return future;
  }

  static Future<Uint8List> _fetchChunkedBytes(String imageUrl) async {
    final uri = Uri.parse(_resolveFetchUrl(imageUrl));
    final client = HttpClient();
    try {
      final builder = BytesBuilder(copy: false);
      int offset = 0;
      int? totalLength;

      while (true) {
        final request = await client.getUrl(uri);
        request.headers.set(
          HttpHeaders.rangeHeader,
          'bytes=$offset-${offset + _chunkSize - 1}',
        );
        final response = await request.close();

        final chunk = await response.fold<BytesBuilder>(
          BytesBuilder(copy: false),
          (acc, data) {
            acc.add(data);
            return acc;
          },
        );
        final chunkBytes = chunk.takeBytes();

        if (response.statusCode == HttpStatus.ok) {
          if (chunkBytes.isEmpty) {
            throw const HttpException('Empty proof image response');
          }
          return chunkBytes;
        }

        if (response.statusCode != HttpStatus.partialContent) {
          throw HttpException(
            'Failed to load proof image (HTTP ${response.statusCode})',
            uri: uri,
          );
        }

        totalLength ??= _parseTotalLength(
          response.headers.value(HttpHeaders.contentRangeHeader),
        );
        if (chunkBytes.isEmpty) {
          break;
        }

        builder.add(chunkBytes);
        offset = builder.length;

        if (totalLength != null && offset >= totalLength) {
          break;
        }
      }

      final bytes = builder.takeBytes();
      if (bytes.isEmpty || (totalLength != null && bytes.length < totalLength)) {
        throw const HttpException('Incomplete proof image response');
      }
      return bytes;
    } finally {
      client.close(force: true);
    }
  }

  void _openFullScreen(BuildContext context, String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: _ProofNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  loadingIndicator: const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorFallback: const Padding(
                    padding: EdgeInsets.all(24),
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white54,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final url = imageUrls[index];
          return GestureDetector(
            onTap: () => _openFullScreen(context, url),
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              clipBehavior: Clip.antiAlias,
              child: _ProofNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                loadingIndicator: const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF1B8354),
                    ),
                  ),
                ),
                errorFallback: const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Color(0xFF94A3B8),
                    size: 24,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProofNetworkImage extends StatefulWidget {
  const _ProofNetworkImage({
    required this.imageUrl,
    required this.fit,
    required this.loadingIndicator,
    required this.errorFallback,
  });

  final String imageUrl;
  final BoxFit fit;
  final Widget loadingIndicator;
  final Widget errorFallback;

  @override
  State<_ProofNetworkImage> createState() => _ProofNetworkImageState();
}

class _ProofNetworkImageState extends State<_ProofNetworkImage> {
  late Future<Uint8List> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = BountyProofGallery._loadImageBytes(widget.imageUrl);
  }

  @override
  void didUpdateWidget(covariant _ProofNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _bytesFuture = BountyProofGallery._loadImageBytes(widget.imageUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.loadingIndicator;
        }
        final bytes = snapshot.data;
        if (snapshot.hasError || bytes == null || bytes.isEmpty) {
          return widget.errorFallback;
        }
        return Image.memory(
          bytes,
          fit: widget.fit,
          errorBuilder: (_, _, _) => widget.errorFallback,
        );
      },
    );
  }
}
