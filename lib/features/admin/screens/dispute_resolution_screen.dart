import 'package:flutter/material.dart';

import 'admin_dashboard_screen.dart';

class DisputeResolutionScreen extends StatelessWidget {
  const DisputeResolutionScreen({super.key});
  @override
  Widget build(BuildContext context) => adminPage(
    'Dispute resolution',
    const Center(child: Text('No open disputes')),
  );
}
