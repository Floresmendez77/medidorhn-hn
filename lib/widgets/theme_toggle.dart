import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class ThemeToggle extends StatelessWidget {
  final bool showLabel;
  const ThemeToggle({super.key, this.showLabel = true});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GestureDetector(
          onTap: () => themeProvider.toggleTheme(),
          child: Tooltip(
            message: themeProvider.isDark ? 'Modo Claro' : 'Modo Oscuro',
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Icon(
                      themeProvider.isDark ? Icons.light_mode : Icons.dark_mode,
                      key: ValueKey(themeProvider.isDark),
                      color: AppTheme.cian,
                      size: 24,
                    ),
                  ),
                  if (showLabel) ...[
                    const SizedBox(width: 6),
                    Text(
                      themeProvider.isDark ? 'Claro' : 'Oscuro',
                      style: const TextStyle(
                        color: AppTheme.cian,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}