import 'package:flutter/material.dart';
import 'package:mygamemaster/pages/faq.dart';
import 'package:mygamemaster/pages/feedback.dart';
import 'package:url_launcher/url_launcher.dart';


class HelpAndSupportPage extends StatelessWidget {
  const HelpAndSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            title: const Text('FAQs'),
            subtitle: const Text('Frequently Asked Questions'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to a page displaying FAQs
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const FAQsPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Contact Support'),
            subtitle: const Text('Send us an email for assistance'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Trigger email sending to support
              _sendSupportEmail();
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Feedback'),
            subtitle: const Text('Send us your feedback'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to a feedback form
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const FeedbackPage()),
              );
            },
          ),
        ],
      ),
    );
  }

void _sendSupportEmail() async {
  final Uri emailUri = Uri(
    scheme: 'mailto',
    path: 'owmw-wm22@student.tar.edu.my',
    queryParameters: {
      'subject': 'Help & Support Inquiry',
    },
  );

  if (await canLaunchUrl(emailUri)) {
    await launchUrl(emailUri);
  } else {
    throw 'Could not launch $emailUri';
  }
}
}
