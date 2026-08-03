import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../l10n/app_localizations.dart';
import 'kanji_browser/kanji_browser_screen.dart';
import 'learning/help_screen.dart';
import 'learning/learning_screen.dart';
import 'lookup/lookup_screen.dart';
import 'lookup/word_lookup_screen.dart';

/// Two overlapping brush icons — represents drawing multiple characters
/// for word lookup.
class _DoubleBrushIcon extends StatelessWidget {
  final Color? color;
  const _DoubleBrushIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color;
    return SizedBox(
      width: 28,
      height: 24,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Icon(Icons.brush, size: 20, color: c?.withValues(alpha: 0.5)),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(Icons.brush, size: 20, color: c),
          ),
        ],
      ),
    );
  }
}

/// Top-level shell: a Material 3 bottom navigation bar with five tabs.
/// Each tab keeps its own Scaffold and AppBar; this just provides the
/// tab switching.
class HomeScreen extends StatefulWidget {
  final AppDependencies deps;

  const HomeScreen({super.key, required this.deps});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: [
          LookupScreen(deps: widget.deps),
          WordLookupScreen(deps: widget.deps),
          LearningScreen(deps: widget.deps),
          KanjiBrowserScreen(deps: widget.deps),
          HelpScreen(deps: widget.deps),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.brush_outlined),
            selectedIcon: Icon(Icons.brush, color: Colors.deepOrange.shade700),
            label: l.lookupHeading,
          ),
          NavigationDestination(
            icon: const _DoubleBrushIcon(color: null),
            selectedIcon: _DoubleBrushIcon(color: Colors.teal.shade700),
            label: l.lookupWords,
          ),
          NavigationDestination(
            icon: const Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school, color: Colors.orange.shade700),
            label: l.lookupLearn,
          ),
          NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view, color: Colors.indigo.shade700),
            label: l.lookupBrowse,
          ),
          NavigationDestination(
            icon: const Icon(Icons.help_outline),
            selectedIcon: Icon(Icons.help, color: Colors.grey.shade700),
            label: l.lookupHelp,
          ),
        ],
      ),
    );
  }
}
