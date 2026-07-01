import 'dart:convert';
import 'package:flutter/material.dart';

/// Images are stored as base64 strings in the Realtime Database (a free
/// alternative to Firebase Storage). Legacy records may still hold http URLs,
/// so both are supported here.
ImageProvider? imageProviderFromString(String? value) {
  if (value == null || value.isEmpty) return null;
  if (value.startsWith('http')) return NetworkImage(value);
  try {
    return MemoryImage(base64Decode(value));
  } catch (_) {
    return null;
  }
}

/// Renders a stored image string (base64 or URL) with a graceful fallback.
Widget appImageFromString(
  String? value, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget? fallback,
}) {
  final provider = imageProviderFromString(value);
  final fb = fallback ??
      Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: Icon(Icons.person, size: (width ?? 40) * 0.6, color: Colors.grey),
      );
  if (provider == null) return fb;
  return Image(
    image: provider,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (_, __, ___) => fb,
  );
}
