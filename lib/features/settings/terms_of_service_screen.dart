import 'package:flutter/material.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// Terms of Service screen — App Store compliance requirement.
///
/// Covers service description, user responsibilities, health disclaimer,
/// limitation of liability, and termination.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<DigitalAtelierExtension>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
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
                Text('Terms of Service', style: tokens.headlineLarge),
                SizedBox(height: tokens.s2),
                Text('Last updated: July 2026', style: tokens.bodySmall),
                SizedBox(height: tokens.s5),
                _TosSection(
                  title: '1. Service Description',
                  tokens: tokens,
                  text:
                      'TransformFit provides AI-assisted fitness coaching, workout tracking, nutrition logging, mood monitoring, and progress analytics. The service is delivered through a mobile application powered by on-device intelligence and cloud-backed personalization.',
                ),
                _TosSection(
                  title: '2. User Responsibilities',
                  tokens: tokens,
                  children: const [
                    _Bullet(
                        'You must provide accurate information during onboarding (goals, experience level, equipment).'),
                    _Bullet(
                        'You are responsible for your own safety during any workout or physical activity.'),
                    _Bullet(
                        'You must consult a physician before beginning any exercise program, especially if you have pre-existing health conditions.'),
                    _Bullet(
                        'You agree not to misuse the app, attempt unauthorized access, or disrupt the service.'),
                  ],
                ),
                _TosSection(
                  title: '3. Health Disclaimer',
                  tokens: tokens,
                  text:
                      'TRANSFORMFIT IS NOT MEDICAL ADVICE. The AI coach, workout suggestions, mood tracking, and all other features are for informational and educational purposes only. They do not constitute medical diagnosis, treatment, or professional health advice. Always consult a qualified healthcare provider before making changes to your exercise, nutrition, or wellness routine.',
                ),
                _TosSection(
                  title: '4. Limitation of Liability',
                  tokens: tokens,
                  text:
                      'To the maximum extent permitted by law, TransformFit and its creators shall not be liable for any injury, loss, or damage arising from your use of the app. This includes, without limitation, physical injury from workouts, reliance on AI-generated coaching, or data loss. The service is provided "as is" without warranties of any kind.',
                ),
                _TosSection(
                  title: '5. Intellectual Property',
                  tokens: tokens,
                  text:
                      'All app content, design, code, and branding are the property of TransformFit. You retain ownership of your personal data and workout content.',
                ),
                _TosSection(
                  title: '6. Termination',
                  tokens: tokens,
                  text:
                      'You may terminate your account at any time from Settings → Delete Account. We may suspend or terminate access if you violate these terms. Upon termination, your data will be deleted within 30 days except where retention is required by law.',
                ),
                _TosSection(
                  title: '7. Changes to Terms',
                  tokens: tokens,
                  text:
                      'We may update these terms from time to time. Material changes will be communicated through the app. Continued use after changes constitutes acceptance.',
                ),
                _TosSection(
                  title: '8. Contact',
                  tokens: tokens,
                  text:
                      'For questions about these terms, email: legal@transformfit.app',
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

class _TosSection extends StatelessWidget {
  const _TosSection({
    required this.title,
    required this.tokens,
    this.text,
    this.children,
  }) : assert(text != null || children != null);

  final String title;
  final DigitalAtelierExtension tokens;
  final String? text;
  final List<Widget>? children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: tokens.titleLarge),
          SizedBox(height: tokens.s2),
          if (text != null)
            Text(text!, style: tokens.bodyMedium)
          else
            ...children!,
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
