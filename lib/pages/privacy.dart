import 'package:flutter/material.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  _PrivacySettingsPageState createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  bool _dataSharingEnabled = false;
  bool _accountVisibilityEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: const Text('Enable Data Sharing'),
            subtitle: const Text('Allow sharing of your data with third parties'),
            value: _dataSharingEnabled,
            onChanged: (bool value) {
              setState(() {
                _dataSharingEnabled = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(value
                      ? 'Data sharing enabled'
                      : 'Data sharing disabled'),
                ),
              );
            },
            secondary: const Icon(Icons.share),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Account Visibility'),
            subtitle: const Text('Control whether your account is visible to others'),
            value: _accountVisibilityEnabled,
            onChanged: (bool value) {
              setState(() {
                _accountVisibilityEnabled = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(value
                      ? 'Account is visible to others'
                      : 'Account is hidden from others'),
                ),
              );
            },
            secondary: const Icon(Icons.visibility),
          ),
        ],
      ),
    );
  }
}
