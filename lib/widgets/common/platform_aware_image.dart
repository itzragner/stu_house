// lib/widgets/common/platform_aware_image.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PlatformAwareImage extends StatelessWidget {
  final File? imageFile;
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const PlatformAwareImage({
    Key? key,
    this.imageFile,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Default placeholder widget
    final defaultPlaceholder = Container(
      color: Colors.grey[300],
      child: Center(
        child: Icon(
          Icons.image,
          color: Colors.grey[600],
          size: 50,
        ),
      ),
    );

    // Default error widget
    final defaultErrorWidget = Container(
      color: Colors.grey[300],
      child: Center(
        child: Icon(
          Icons.error_outline,
          color: Colors.grey[600],
          size: 50,
        ),
      ),
    );

    // For web, we can't use File directly
    if (kIsWeb) {
      // If we have a file (from ImagePicker), we need to convert it
      if (imageFile != null) {
        // For web, ImagePicker provides a network accessible URL
        return Image.network(
          imageFile!.path, // On web, this is actually a blob URL
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return placeholder ?? defaultPlaceholder;
          },
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ?? defaultErrorWidget;
          },
        );
      }

      // If we have a URL, use it
      else if (imageUrl != null && imageUrl!.isNotEmpty) {
        return Image.network(
          imageUrl!,
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return placeholder ?? defaultPlaceholder;
          },
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ?? defaultErrorWidget;
          },
        );
      }

      // Fallback to placeholder
      else {
        return SizedBox(
          width: width,
          height: height,
          child: placeholder ?? defaultPlaceholder,
        );
      }
    }
    // For mobile platforms, we can use File directly
    else {
      if (imageFile != null) {
        return Image.file(
          imageFile!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return SizedBox(
              width: width,
              height: height,
              child: errorWidget ?? defaultErrorWidget,
            );
          },
        );
      }
      else if (imageUrl != null && imageUrl!.isNotEmpty) {
        return Image.network(
          imageUrl!,
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: width,
              height: height,
              child: placeholder ?? defaultPlaceholder,
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return SizedBox(
              width: width,
              height: height,
              child: errorWidget ?? defaultErrorWidget,
            );
          },
        );
      }
      else {
        return SizedBox(
          width: width,
          height: height,
          child: placeholder ?? defaultPlaceholder,
        );
      }
    }
  }
}