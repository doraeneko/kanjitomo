import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_dependencies.dart';
import '../l10n/app_localizations.dart';
import 'kanji_browser/kanji_browser_screen.dart';
import 'learning/help_screen.dart';
import 'learning/learning_screen.dart';
import 'lookup/lookup_screen.dart';
import 'lookup/word_lookup_screen.dart';
import 'welcome_screen.dart';

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

  // Tour overlay state.
  int? _tourStep; // null = not in tour
  bool _tourMinimized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showWelcomeIfNeeded());
  }

  Future<void> _showWelcomeIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(welcomeSeenKey) == true) return;
    if (!mounted) return;
    final startTour = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
    if (startTour == true && mounted) {
      _beginTour();
    }
  }

  void _beginTour() {
    final l = AppLocalizations.of(context)!;
    final steps = tourSteps(l);
    setState(() {
      _tourStep = 0;
      _tourMinimized = false;
      _tabIndex = steps[0].tabIndex;
    });
  }

  void _endTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(welcomeSeenKey, true);
    if (mounted) setState(() => _tourStep = null);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _tabIndex,
            children: [
              LookupScreen(deps: widget.deps),
              WordLookupScreen(deps: widget.deps),
              LearningScreen(deps: widget.deps),
              KanjiBrowserScreen(deps: widget.deps),
              HelpScreen(deps: widget.deps, onStartTour: _beginTour),
            ],
          ),
          if (_tourStep != null) _buildTourOverlay(l),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: _tourStep != null
            ? null // disable tab switching during tour
            : (i) => setState(() => _tabIndex = i),
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

  Widget _buildTourOverlay(AppLocalizations l) {
    final steps = tourSteps(l);
    final step = steps[_tourStep!];
    final isFirst = _tourStep == 0;
    final isLast = _tourStep == steps.length - 1;

    if (_tourMinimized) {
      return Positioned(
        right: 12,
        bottom: 12,
        child: FloatingActionButton.small(
          onPressed: isLast
              ? _endTour
              : () {
                  setState(() {
                    _tourStep = _tourStep! + 1;
                    _tabIndex = steps[_tourStep!].tabIndex;
                    _tourMinimized = false;
                  });
                },
          child: Icon(isLast ? Icons.check : Icons.arrow_forward),
        ),
      );
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onTap: () {}, // absorb taps on the scrim
        child: Container(
          color: Colors.black54,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.55,
                ),
                child: Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Step indicator dots + minimize button
                      Row(
                        children: [
                          const SizedBox(width: 32), // balance the close button
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(steps.length, (i) {
                                return Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: i == _tourStep
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey.shade300,
                                  ),
                                );
                              }),
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: 20,
                              onPressed: () => setState(() => _tourMinimized = true),
                              icon: const Icon(Icons.minimize),
                              tooltip: 'Try it out',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(step.icon, size: 28, color: step.color),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              step.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Text(
                            step.message,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (!isFirst)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _tourStep = _tourStep! - 1;
                                  _tabIndex = steps[_tourStep!].tabIndex;
                                  _tourMinimized = false;
                                });
                              },
                              child: Text(l.tourBack),
                            )
                          else
                            TextButton(
                              onPressed: _endTour,
                              child: Text(l.welcomeSkip),
                            ),
                          ElevatedButton(
                            onPressed: isLast
                                ? _endTour
                                : () {
                                    setState(() {
                                      _tourStep = _tourStep! + 1;
                                      _tabIndex = steps[_tourStep!].tabIndex;
                                      _tourMinimized = false;
                                    });
                                  },
                            child: Text(isLast ? l.welcomeDone : l.tourNext),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }
}
