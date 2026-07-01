import 'dart:convert';
import 'package:flutter/material.dart';

/// The driver app stores images as base64 strings in the Realtime Database
/// (a free alternative to Firebase Storage). Legacy records may hold http URLs,
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
