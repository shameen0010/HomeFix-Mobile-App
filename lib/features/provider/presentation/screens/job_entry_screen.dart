import 'package:flutter/material.dart';

import '../../core/provider_ui.dart';
import '../../data/models/job_model.dart';
import '../../data/repositories/provider_repository.dart';
import 'active_service_screen.dart';
import 'customer_details_screen.dart';
import 'job_details_screen.dart';
import 'request_details_screen.dart';

/// Router screen: shows the right job screen for the booking's current status
/// and swaps it automatically when the status changes (e.g. accept -> details).
class JobEntryScreen extends StatefulWidget {
  const JobEntryScreen({super.key, required this.jobId});
  final String jobId;

  @override
  State<JobEntryScreen> createState() => _JobEntryScreenState();
}

class _JobEntryScreenState extends State<JobEntryScreen> {
  late final Stream<JobModel?> _stream = ProviderRepository.instance.watchJob(widget.jobId);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<JobModel?>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return AdminPage(child: ErrorView(message: 'Could not load the job.\n${snap.error}'));
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const AdminPage(child: LoadingView());
        }
        final j = snap.data;
        if (j == null) return const AdminPage(child: ErrorView(message: 'This job no longer exists.'));
        if (j.status == 'pending') return RequestDetailsScreen(jobId: j.id);
        if (j.status == 'confirmed') return CustomerDetailsScreen(jobId: j.id);
        if (j.status == 'in_progress' && !j.isDone) return ActiveServiceScreen(jobId: j.id);
        return JobDetailsScreen(jobId: j.id);
      },
    );
  }
}
