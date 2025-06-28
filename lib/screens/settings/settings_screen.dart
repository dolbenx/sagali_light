import 'package:flutter/material.dart';
import '../../main.dart'; // for primaryColor

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          SettingsTile(
            icon: Icons.person,
            title: 'Profile',
            subtitle: 'Update your personal info',
            onTap: () {},
          ),
          SettingsTile(
            icon: Icons.lock,
            title: 'Change Password',
            subtitle: 'Update your login credentials',
            onTap: () {},
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('App Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          SettingsTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage notification settings',
            onTap: () {},
          ),
          SettingsTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: 'Choose app language',
            onTap: () {},
          ),
          SettingsTile(
            icon: Icons.color_lens,
            title: 'Theme',
            subtitle: 'Light or dark mode',
            onTap: () {},
          ),
          const Divider(),
          SettingsTile(
            icon: Icons.info,
            title: 'About',
            subtitle: 'App version and legal info',
            onTap: () {},
          ),
          SettingsTile(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            iconColor: Colors.red,
            onTap: () {
              // TODO: Add logout logic
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: primaryColor.withOpacity(0.1),
        child: Icon(icon, color: iconColor ?? primaryColor),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}