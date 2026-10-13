import 'package:flutter/material.dart';

/// Fade + slight slide transition used for all pushed screens.
Route<T> slideRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
                .animate(curved),
            child: child,
          ),
        );
      },
    );
