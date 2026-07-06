import 'package:flutter/material.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// Privacy Policy screen — App Store compliance requirement.
///
/// Covers data collection, storage, sharing, user rights, and contact info.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.s5,
            vertical: tokens.s4,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Policy',
                  style: tokens.headlineLarge,
                ),
                SizedBox(height: tokens.s2),
                Text(
                  'Last updated: July 2026',
                  style: tokens.bodySmall,
                ),
                SizedBox(height: tokens.s5),
                _PolicySection(
                  title: '1. Data We Collect',
                  tokens: tokens,
                  children: const [
                    _Bullet(
                        'Workout data: exercises, sets, reps, weights, duration, and session notes.'),
                    _Bullet(
                        'Mood and wellness data: mood check-ins, stress levels, sleep quality, and recovery scores.'),
                    _Bullet(
                        'Health data: body composition measurements, hydration logs, and wearable-sourced metrics (when connected).'),
                    _Bullet(
                        'Profile data: name, email, fitness goals, experience level, and equipment preferences.'),
                    _Bullet(
                        'Usage data: screen views, feature interactions, and crash diagnostics.'),
                  ],
                ),
                _PolicySection(
                  title: '2. How We Store Your Data',
                  tokens: tokens,
                  children: const [
                    _Bullet(
                        'On-device storage: session history, preferences, and cached data are stored locally using SQLite.'),
                    _Bullet(
                        'Cloud storage: your authenticated profile, workout history, and nutrition logs are synced to Supabase (PostgreSQL) under your account.'),
                    _Bullet(
                        'Encryption: data in transit is protected by TLS. Data at rest in Supabase uses disk-level encryption.'),
                  ],
                ),
                _PolicySection(
                  title: '3. Data Sharing',
                  tokens: tokens,
                  children: const [
                    _Bullet(
                        'We do not sell, rent, or share your personal data with third parties for advertising.'),
                    _Bullet(
                        'Anonymous, aggregated analytics may be used to improve the app.'),
                    _Bullet(
                        'Data is shared only with your explicit consent (e.g., exporting your own data).'),
                  ],
                ),
                _PolicySection(
                  title: '4. Your Rights',
                  tokens: tokens,
                  children: const [
                    _Bullet(
                        'Export: you can download all your data as JSON from Settings → Data Export.'),
                    _Bullet(
                        'Delete: you can request full account and data deletion from Settings → Delete Account.'),
                    _Bullet(
                        'Access: you may request a copy of all data we hold about you at any time.'),
                    _Bullet(
                        'Withdrawal: you may stop using the app and delete your account at any time with no penalty.'),
                  ],
                ),
                _PolicySection(
                  title: '5. Children\'s Privacy',
                  tokens: tokens,
                  children: const [
                    _Bullet(
                        'TransformFit is not intended for users under 16. We do not knowingly collect data from children.'),
                  ],
                ),
                _PolicySection(
                  title: '6. Contact Us',
                  tokens: tokens,
                  children: const [
                    _Bullet(
                        'For privacy inquiries or data requests, email: privacy@transformfit.app'),
                  ],
                ),
                SizedBox(height: tokens.s7),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.title,
    required this.tokens,
    required this.children,
  });

  final String title;
  final DigitalAtelierExtension tokens;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: tokens.titleLarge),
          SizedBox(height: tokens.s2),
          ...children,
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
