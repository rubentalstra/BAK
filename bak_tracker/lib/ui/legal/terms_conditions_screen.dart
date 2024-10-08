import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'These terms and conditions apply to the BAK app for mobile devices created by Ruben Talstra ("Service Provider") as a Free service.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Third-Party Services'),
            const SizedBox(height: 8),
            const Text(
              'The Application uses third-party services. Below are the links to their Terms and Conditions:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _launchURL('https://policies.google.com/terms'),
              child: const Text(
                'Google Play Services',
                style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    decoration: TextDecoration.underline),
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Service Responsibilities'),
            const SizedBox(height: 8),
            const Text(
              'Certain functions of the Application require an active internet connection. The Service Provider is not responsible for any issues due to lack of internet access.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Changes to These Terms'),
            const SizedBox(height: 8),
            const Text(
              'The Service Provider may update these Terms periodically. Please review them regularly for updates.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Effective Date: 2024-09-29',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Contact Us'),
            const SizedBox(height: 8),
            const Text(
              'For any questions, contact us at:',
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
