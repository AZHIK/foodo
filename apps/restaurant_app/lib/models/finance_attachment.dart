import 'dart:typed_data';
import 'package:flutter/material.dart';

@immutable
class FinanceAttachment {
  const FinanceAttachment({required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;
}
