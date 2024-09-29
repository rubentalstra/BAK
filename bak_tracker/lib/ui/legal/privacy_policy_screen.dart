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
              'This privacy policy applies to the BAK app (hereby referred to as "Application") for mobile devices that was created by Ruben Talstra (hereby referred to as "Service Provider") as a Free service. This service is intended for use "AS IS".',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Information Collection and Use'),
            const SizedBox(height: 8),
            const Text(
              'The Application collects information when you download and use it. This information may include information such as:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildBulletPoints([
              'Your device\'s Internet Protocol address (e.g. IP address)',
              'The pages of the Application that you visit, the time and date of your visit, the time spent on those pages',
              'The time spent on the Application',
              'The operating system you use on your mobile device',
            ]),
            const SizedBox(height: 8),
            const Text(
              'The Application does not gather precise information about the location of your mobile device.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildSectionTitle('Third Party Access'),
            const SizedBox(height: 8),
            const Text(
              'Only aggregated, anonymized data is periodically transmitted to external services to aid the Service Provider in improving the Application and their service. The Service Provider may share your information with third parties in the ways that are described in this privacy statement.',
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
              'You can stop all collection of information by the Application easily by uninstalling it. You may use the standard uninstall processes available as part of your mobile device or via the mobile application marketplace or network.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildSectionTitle('Children'),
            const SizedBox(height: 8),
            const Text(
              'The Service Provider does not use the Application to knowingly solicit data from or market to children under the age of 13.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildSectionTitle('Security'),
            const SizedBox(height: 8),
            const Text(
              'The Service Provider is concerned about safeguarding the confidentiality of your information. They provide physical, electronic, and procedural safeguards to protect information they process and maintain.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildSectionTitle('Changes'),
            const SizedBox(height: 8),
            const Text(
              'This Privacy Policy may be updated from time to time for any reason. The Service Provider will notify you of any changes by updating this page with the new Privacy Policy. Continued use of the Application is deemed as acceptance of all changes.',
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
              'By using the Application, you are consenting to the processing of your information as set forth in this Privacy Policy now and as amended by us.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Contact Us'),
            const SizedBox(height: 8),
            const Text(
              'If you have any questions regarding privacy while using the Application, or have questions about the practices, please contact the Service Provider via email at:',
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

  // Utility to create bullet points with properly aligned bullet icons
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  void _launchURL(String url) async {
    final uriUrl = Uri.parse(url);
    if (await canLaunchUrl(uriUrl)) {
      await launchUrl(uriUrl);
    } else {
      throw 'Could not launch $url';
    }
  }
}
