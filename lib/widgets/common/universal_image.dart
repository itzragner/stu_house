// lib/widgets/common/universal_image.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UniversalImage extends StatelessWidget {
  final dynamic source; // Can be File, String (URL or path), or null
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;
  final BorderRadius? borderRadius;

  const UniversalImage({
    Key? key,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
    this.loadingBuilder,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    // Default error widget
    final defaultErrorWidget = Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Center(
        child: Icon(
          Icons.broken_image,
          size: 40,
          color: Colors.grey[600],
        ),
      ),
    );

    // Default loading widget
    Widget defaultLoadingBuilder(BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
      if (loadingProgress == null) return child;
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
          ),
        ),
      );
    }

    // Custom error builder that uses the provided one or falls back to default
    Widget Function(BuildContext, Object, StackTrace?) customErrorBuilder =
        (context, error, stackTrace) => errorBuilder?.call(context, error, stackTrace) ?? defaultErrorWidget;

    if (source == null) {
      // No image source
      imageWidget = defaultErrorWidget;
    } else if (source is File) {
      // File source
      if (kIsWeb) {
        // On web, File.path is actually a blob URL
        imageWidget = Image.network(
          (source as File).path,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: customErrorBuilder,
          loadingBuilder: loadingBuilder ?? defaultLoadingBuilder,
        );
      } else {
        // On mobile, use Image.file
        imageWidget = Image.file(
          source as File,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: customErrorBuilder,
        );
      }
    } else if (source is String) {
      // String source (URL or path)
      if ((source as String).startsWith('http://') ||
          (source as String).startsWith('https://') ||
          (source as String).startsWith('blob:')) {
        // It's a URL, use Image.network
        imageWidget = Image.network(
          source as String,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: customErrorBuilder,
          loadingBuilder: loadingBuilder ?? defaultLoadingBuilder,
        );
      } else if (!kIsWeb && (source as String).startsWith('/')) {
        // It's a file path on mobile, use Image.file
        imageWidget = Image.file(
          File(source as String),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: customErrorBuilder,
        );
      } else {
        // Treat as asset or network based on prefix
        if ((source as String).startsWith('assets/')) {
          imageWidget = Image.asset(
            source as String,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: customErrorBuilder,
          );
        } else {
          // Default to network image
          imageWidget = Image.network(
            source as String,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: customErrorBuilder,
            loadingBuilder: loadingBuilder ?? defaultLoadingBuilder,
          );
        }
      }
    } else {
      // Unknown source type
      imageWidget = defaultErrorWidget;
    }

    // Apply border radius if specified
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}