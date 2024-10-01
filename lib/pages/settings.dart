import 'package:flutter/material.dart';
import 'package:mygamemaster/pages/help_support.dart';
import 'package:provider/provider.dart';
import 'package:mygamemaster/pages/theme_notifier.dart';
import 'package:mygamemaster/pages/account_manage.dart';

import 'privacy.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true; // Initial value

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Account'),
            subtitle: const Text('Manage your account details'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AccountManagementPage(),
                ),
              );
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle between light and dark mode'),
            value: themeNotifier.isDarkMode,
            onChanged: (bool value) {
              themeNotifier.toggleTheme();
            },
            secondary: Icon(
              themeNotifier.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: themeNotifier.isDarkMode ? Colors.yellow : Colors.black,
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Enable or disable notifications'),
            value: _notificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _notificationsEnabled = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(value
                      ? 'Notifications enabled'
                      : 'Notifications disabled'),
                ),
              );
            },
            secondary: const Icon(Icons.notifications),
          ),
          const Divider(),
          ListTile(
            title: const Text('Privacy'),
            subtitle: const Text('Privacy settings'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PrivacySettingsPage(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Help & Support'),
            subtitle: const Text('Get help or send feedback'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const HelpAndSupportPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
