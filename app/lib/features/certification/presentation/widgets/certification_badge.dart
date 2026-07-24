import 'package:flutter/material.dart';

class CertificationBadge extends StatelessWidget {
  final String level; // none, basic, advanced, expert

  const CertificationBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final config = _getBadgeConfig();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: config.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: config.colors.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('인증 리뷰어',
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
              Text(config.label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  _BadgeConfig _getBadgeConfig() {
    switch (level) {
      case 'expert':
        return _BadgeConfig(
          label: 'Expert',
          icon: Icons.diamond,
          colors: [Colors.purple, Colors.deepPurple],
        );
      case 'advanced':
        return _BadgeConfig(
          label: 'Advanced',
          icon: Icons.star,
          colors: [Colors.amber, Colors.orange],
        );
      case 'basic':
        return _BadgeConfig(
          label: 'Basic',
          icon: Icons.verified,
          colors: [Colors.blue, Colors.indigo],
        );
      default:
        return _BadgeConfig(
          label: '미인증',
          icon: Icons.lock_outline,
          colors: [Colors.grey, Colors.blueGrey],
        );
    }
  }
}

class _BadgeConfig {
  final String label;
  final IconData icon;
  final List<Color> colors;

  _BadgeConfig({required this.label, required this.icon, required this.colors});
}

/// Small inline badge for lists/cards
class CertificationBadgeSmall extends StatelessWidget {
  final bool isCertified;

  const CertificationBadgeSmall({super.key, required this.isCertified});

  @override
  Widget build(BuildContext context) {
    if (!isCertified) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: Colors.white, size: 12),
          SizedBox(width: 2),
          Text('인증', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
