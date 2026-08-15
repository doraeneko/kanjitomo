import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A small coffee-cup icon for the AppBar that opens the Buy Me a Coffee page.
class CoffeeButton extends StatelessWidget {
  const CoffeeButton({super.key});

  static final _uri = Uri.parse('https://buymeacoffee.com/kanjitomo');

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.coffee, size: 20, color: Colors.brown.shade300),
      tooltip: 'Support development',
      onPressed: () => launchUrl(_uri, mode: LaunchMode.externalApplication),
    );
  }
}
