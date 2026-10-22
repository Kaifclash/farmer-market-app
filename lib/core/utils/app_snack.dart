import 'package:flutter/material.dart';

class AppSnack {
  AppSnack._();

  static void success(BuildContext context, String message) =>
      _show(context, message, const Color(0xFF2E7D32), Icons.check_circle);

  static void error(BuildContext context, String message) =>
      _show(context, message, const Color(0xFFC62828), Icons.error);

  static void _show(
      BuildContext context, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: color,
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}
