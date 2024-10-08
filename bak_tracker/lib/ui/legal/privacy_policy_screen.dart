import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This privacy policy applies to the BAK app ("Application") for mobile devices that was created by Ruben Talstra ("Service Provider") as a Free service. This service is intended for use "AS IS".',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Information Collection and Use'),
            const SizedBox(height: 8),
            const Text(
              'The Application collects certain information when you download and use it, including:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildBulletPoints([
              'Your device\'s Internet Protocol address (e.g. IP address)',
              'Pages you visit in the Application and time spent on them',
              'Operating system of your mobile device',
            ]),
            const SizedBox(height: 8),
            const Text(
              'The Application does not gather precise information about the location of your mobile device.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Third Party Access'),
            const SizedBox(height: 8),
            const Text(
              'Aggregated, anonymized data is periodically transmitted to external services to improve the Application. Some third-party services may access your information in ways outlined in this privacy policy.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () =>
                  _launchURL('https://www.google.com/policies/privacy/'),
              child: const Text(
                'Google Play Services',
                style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    decoration: TextDecoration.underline),
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Opt-Out Rights'),
            const SizedBox(height: 8),
            const Text(
              'You can stop all collection of information by the Application by uninstalling it.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Children'),
            const SizedBox(height: 8),
            const Text(
              'The Application does not knowingly collect data from or market to children under the age of 13.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Security'),
            const SizedBox(height: 8),
            const Text(
              'The Service Provider uses safeguards to protect the confidentiality of your information.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Changes'),
            const SizedBox(height: 8),
            const Text(
              'This Privacy Policy may be updated. The Service Provider will notify you by updating this page.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Effective Date: 2024-09-29',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Your Consent'),
            const SizedBox(height: 8),
            const Text(
              'By using the Application, you consent to the processing of your information as set forth in this Privacy Policy.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Contact Us'),
            const SizedBox(height: 8),
            const Text(
              'If you have any questions, contact us at:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _launchURL('mailto:info@baktracker.com'),
              child: const Text(
                'info@baktracker.com',
                style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Utility to create bullet points with proper alignment
  Widget _buildBulletPoints(List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: points.map((point) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Baseline(
              baseline: 14.0,
              baselineType: TextBaseline.alphabetic,
              child: const Icon(Icons.circle, size: 6, color: Colors.white),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                point,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // Utility to create section titles
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  // Utility to handle launching URLs
  void _launchURL(String url) async {
    final uriUrl = Uri.parse(url);
    if (await canLaunchUrl(uriUrl)) {
      await launchUrl(uriUrl);
    } else {
      throw 'Could not launch $url';
    }
  }
}
