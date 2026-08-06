import 'dart:io';
import 'package:flutter/material.dart';

/// Visionneuse plein écran pour une liste de photos (URLs distantes ou chemins
/// locaux) : swipe horizontal, petits ronds en bas indiquant la position et le
/// nombre total de photos, flèche de retour en haut à gauche.
class PhotoGalleryViewer extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const PhotoGalleryViewer({super.key, required this.photos, this.initialIndex = 0});

  @override
  State<PhotoGalleryViewer> createState() => _PhotoGalleryViewerState();
}

class _PhotoGalleryViewerState extends State<PhotoGalleryViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildPhoto(String url) {
    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: Center(
        child: url.startsWith('http')
            ? Image.network(url, fit: BoxFit.contain)
            : Image.file(File(url.replaceAll('file://', '')), fit: BoxFit.contain),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => _buildPhoto(widget.photos[i]),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          if (widget.photos.length > 1)
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.photos.length, (i) {
                  final actif = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: actif ? 10 : 7,
                    height: actif ? 10 : 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: actif ? Colors.white : Colors.white38,
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
