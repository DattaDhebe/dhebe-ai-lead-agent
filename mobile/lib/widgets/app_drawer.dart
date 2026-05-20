import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../screens/ai/ai_reply_screen.dart';
import '../screens/business/business_profile_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/leads/leads_list_screen.dart';
import '../screens/reminders/reminders_screen.dart';
import '../screens/settings/settings_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.selectedItem});

  static const dashboard = 'dashboard';
  static const leads = 'leads';
  static const aiReply = 'ai_reply';
  static const reminders = 'reminders';
  static const businessProfile = 'business_profile';
  static const settings = 'settings';

  final String selectedItem;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
              ),
              accountName: Text(appState.currentUser?.name ?? 'Owner'),
              accountEmail: Text(
                appState.currentUser?.businessName?.isNotEmpty == true
                    ? appState.currentUser!.businessName!
                    : appState.currentUser?.email ?? 'dhebe.com',
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.15),
                child: const Icon(
                  Icons.support_agent,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            _drawerItem(
              context,
              icon: Icons.space_dashboard_rounded,
              label: 'Dashboard',
              item: dashboard,
              screen: const DashboardScreen(),
            ),
            _drawerItem(
              context,
              icon: Icons.people_alt_rounded,
              label: 'Leads',
              item: leads,
              screen: const LeadsListScreen(),
            ),
            _drawerItem(
              context,
              icon: Icons.auto_awesome_rounded,
              label: 'AI Reply',
              item: aiReply,
              screen: const AIReplyScreen(),
            ),
            _drawerItem(
              context,
              icon: Icons.alarm_rounded,
              label: 'Reminders',
              item: reminders,
              screen: const RemindersScreen(),
            ),
            _drawerItem(
              context,
              icon: Icons.business_center_rounded,
              label: 'Business Profile',
              item: businessProfile,
              screen: const BusinessProfileScreen(),
            ),
            _drawerItem(
              context,
              icon: Icons.settings_rounded,
              label: 'Settings',
              item: settings,
              screen: const SettingsScreen(),
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Logout'),
              onTap: () async {
                await context.read<AppState>().logout();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String item,
    required Widget screen,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: selectedItem == item,
      onTap: () {
        Navigator.of(context).pop();

        if (selectedItem == item) {
          return;
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => screen),
          (route) => false,
        );
      },
    );
  }
}
