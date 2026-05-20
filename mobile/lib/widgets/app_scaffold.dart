import 'package:flutter/material.dart';

import 'app_drawer.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.selectedItem,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showDrawer = true,
  });

  final String title;
  final String selectedItem;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showDrawer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      drawer: showDrawer ? AppDrawer(selectedItem: selectedItem) : null,
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
    );
  }
}
