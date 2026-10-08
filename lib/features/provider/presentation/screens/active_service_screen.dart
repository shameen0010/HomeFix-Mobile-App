import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/provider_ui.dart';
import '../../data/models/chat_models.dart';
import '../../data/models/job_model.dart';
import '../../data/repositories/provider_repository.dart';
import '../widgets/provider_header.dart';
import 'job_details_screen.dart';
import 'provider_chat_screen.dart';

const _stages = ['en_route', 'arrived', 'working', 'done'];
const _stageLabels = ['En Route', 'Arrived', 'Working', 'Done'];
const _stageIcons = [Icons.directions_car_rounded, Icons.location_on_rounded, Icons.build_rounded, Icons.flag_rounded];

/// FR-P07: live job progress, checklist, proof photos and cash collection.
class ActiveServiceScreen extends StatefulWidget {
  const ActiveServiceScreen({super.key, required this.jobId});
  final String jobId;

  @override
  State<ActiveServiceScreen> createState() => _ActiveServiceScreenState();
}

class _ActiveServiceScreenState extends State<ActiveServiceScreen> {
  final _repo = ProviderRepository.instance;
  late final Stream<JobModel?> _stream = _repo.watchJob(widget.jobId);

  Future<void> _setStage(JobModel j, int index) async {
    final current = _stages.indexOf(j.stage);
    if (index != current + 1 || index > 2) {
      if (index > current) {
        showAdminSnack(context, 'Update the steps in order.', error: true);
      }
      return;
    }
    await runAdminAction(context, () => _repo.setStage(j.id, _stages[index]),
        success: 'Status: ${_stageLabels[index]}', showLoader: false);
  }

  Future<void> _addMedia(JobModel j) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => Theme(
        data: adminTheme,
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
                leading: const Icon(Icons.edit_note_rounded),
                title: const Text('Add inspection note'),
                onTap: () => Navigator.pop(context, 'note')),
            ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take photo'),
                onTap: () => Navigator.pop(context, 'camera')),
            ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, 'gallery')),
          ]),
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == 'note') {
      final note = await promptText(context,
          title: 'Inspection note', hint: 'What did you find?', confirmLabel: 'Save note');
      if (note == null || !mounted) return;
      await runAdminAction(context, () => _repo.addNote(j.id, note), success: 'Note saved');
      return;
    }
    try {
      final file = await ImagePicker().pickImage(
          source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
          imageQuality: 75,
          maxWidth: 1600);
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      final label = await promptText(context,
          title: 'Photo label', hint: 'e.g. Before fix', required: false, confirmLabel: 'Upload');
      if (label == null || !mounted) return;
      await runAdminAction(
          context, () => _repo.addPhoto(j.id, bytes, label.isEmpty ? 'Photo' : label),
          success: 'Photo uploaded');
    } catch (_) {
      if (mounted) showAdminSnack(context, 'Could not access the camera or gallery.', error: true);
    }
  }

  Future<void> _complete(JobModel j) async {
    if (!j.mandatoryDone) {
      showAdminSnack(context, 'Finish all mandatory checklist items first.', error: true);
      return;
    }
    final ok = await confirmAction(context,
        title: 'Complete job?',
        message: 'Confirm that you will collect exactly ${formatMoney(j.amount)} in cash from ${j.customerName}.',
        confirmLabel: 'Complete');
    if (!ok || !mounted) return;
    final done = await runAdminAction(context, () => _repo.completeJob(j.id), success: 'Job marked as done');
    if (done && mounted) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => JobDetailsScreen(jobId: j.id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const ProviderHeader(title: 'Active Service Time', showBack: true),
        Expanded(
          child: StreamBuilder<JobModel?>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(message: 'Could not load the job.\n${snap.error}');
              if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
              final j = snap.data;
              if (j == null) return const ErrorView(message: 'This job no longer exists.');
              return _body(j);
            },
          ),
        ),
      ]),
    );
  }

  Widget _body(JobModel j) {
    final current = _stages.indexOf(j.stage).clamp(0, 3).toInt();
    final doneCount = j.checklist.where((c) => c.done).length;
    return Column(children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            AdminCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                const Icon(Icons.circle, size: 9, color: AdminColors.orange),
                const SizedBox(width: 6),
                Expanded(child: Text('Live Job: ${j.code}', style: ts(12, w: FontWeight.w700))),
                const StatusPill('IN REAL-TIME', size: 9.5, icon: Icons.bolt_rounded),
              ]),
            ),
            const SizedBox(height: 10),
            AdminCard(
              child: Column(children: [
                Row(children: [
                  for (var i = 0; i < 4; i++) ...[
                    Expanded(child: _step(j, i, current)),
                  ],
                ]),
                const SizedBox(height: 6),
                Text(current < 2 ? 'Tap the next step to update your status.' : 'Finish the checklist, then complete the job.',
                    style: ts(10.5, color: AdminColors.grey)),
              ]),
            ),
            const SizedBox(height: 10),
            AdminCard(
              child: Column(children: [
                Row(children: [
                  AdminAvatar(name: j.customerName, photoUrl: j.customerPhotoUrl, radius: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Flexible(child: Text(j.customerName, style: ts(16, w: FontWeight.w700))),
                        const SizedBox(width: 6),
                        const StatusPill('Verified', tone: Tone.orange, size: 9.5),
                      ]),
                      Text(j.title, style: ts(12, w: FontWeight.w600, color: AdminColors.primary)),
                      Row(children: [
                        const Icon(Icons.place_outlined, size: 13, color: AdminColors.grey),
                        const SizedBox(width: 3),
                        Expanded(child: Text(j.address, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: ts(11, color: AdminColors.grey))),
                      ]),
                    ]),
                  ),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: AdminButton('Call Customer', icon: Icons.phone_outlined, height: 42,
                        onPressed: () => callCustomer(context, j.customerPhone)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AdminButton('In-App Chat', icon: Icons.chat_bubble_outline_rounded, height: 42,
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) => ProviderChatScreen(thread: ChatThread.fromJob(j))))),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: Text('Service Checklist', style: ts(16, w: FontWeight.w700))),
              StatusPill('$doneCount/${j.checklist.length} Done', tone: Tone.grey, size: 10),
            ]),
            const SizedBox(height: 8),
            for (var i = 0; i < j.checklist.length; i++) _check(j, i),
            const SizedBox(height: 4),
            AdminButton('Add Inspection Note / Photo',
                icon: Icons.add_a_photo_outlined, height: 46, onPressed: () => _addMedia(j)),
            if (j.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final n in j.notes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.sticky_note_2_outlined, size: 15, color: AdminColors.grey),
                    const SizedBox(width: 6),
                    Expanded(child: Text(n, style: ts(11.5, color: AdminColors.grey))),
                  ]),
                ),
            ],
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Text('Attached Documentation', style: ts(13, w: FontWeight.w700))),
              Text('${j.photos.length} Uploaded',
                  style: ts(10.5, w: FontWeight.w600, color: AdminColors.primary)),
            ]),
            const SizedBox(height: 8),
            if (j.photos.isEmpty)
              Text('No photos yet.', style: ts(11.5, color: AdminColors.grey))
            else
              PhotoGrid(photos: j.photos),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AdminColors.orangeBg, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                const CircleAvatar(
                    radius: 18, backgroundColor: AdminColors.orange,
                    child: Icon(Icons.payments_outlined, color: Colors.white, size: 18)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Cash Collection Required', style: ts(13.5, w: FontWeight.w700)),
                    Text('Collect exactly ${formatMoney(j.amount)} in cash from ${j.customerName} upon finishing inspection.',
                        style: ts(11.5, color: const Color(0xFF92400E))),
                  ]),
                ),
              ]),
            ),
          ],
        ),
      ),
      Container(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + MediaQuery.of(context).viewPadding.bottom),
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, -2)),
        ]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(child: Text('Settlement total due:', style: ts(11.5, color: AdminColors.grey))),
            Text('${formatMoney(j.amount)} USD', style: ts(17, w: FontWeight.w700, color: AdminColors.primary)),
          ]),
          const SizedBox(height: 8),
          AdminButton('Complete Job & Collect Cash',
              kind: ButtonKind.filled, icon: Icons.check_circle_outline_rounded, height: 50,
              onPressed: () => _complete(j)),
        ]),
      ),
    ]);
  }

  Widget _step(JobModel j, int i, int current) {
    final done = i < current || (i == 3 && j.isDone);
    final active = i == current && !j.isDone;
    final color = done ? AdminColors.primary : active ? AdminColors.orange : AdminColors.border;
    return GestureDetector(
      onTap: () => _setStage(j, i),
      child: Column(children: [
        Row(children: [
          Expanded(child: Container(height: 2, color: i == 0 ? Colors.transparent : (i <= current ? AdminColors.primary : AdminColors.border))),
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: done || active ? color : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(done ? Icons.check : _stageIcons[i], size: 17,
                color: done || active ? Colors.white : AdminColors.grey),
          ),
          Expanded(child: Container(height: 2, color: i == 3 ? Colors.transparent : (i < current ? AdminColors.primary : AdminColors.border))),
        ]),
        const SizedBox(height: 4),
        Text(_stageLabels[i], style: ts(10, w: FontWeight.w600, color: active ? AdminColors.orange : AdminColors.dark)),
      ]),
    );
  }

  Widget _check(JobModel j, int i) {
    final c = j.checklist[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: c.done ? AdminColors.field : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AdminColors.border)),
      child: CheckboxListTile(
        value: c.done,
        onChanged: (v) => runAdminAction(context, () => _repo.toggleChecklist(j.id, i, v ?? false),
            success: v == true ? 'Checked off' : 'Unchecked', showLoader: false),
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
        title: Text(c.title,
            style: ts(13, w: FontWeight.w600, color: c.done ? AdminColors.grey : AdminColors.dark)
                .copyWith(decoration: c.done ? TextDecoration.lineThrough : null)),
        secondary: Icon(c.done ? Icons.check_circle_outline_rounded : Icons.remove_circle_outline_rounded,
            size: 18, color: c.done ? AdminColors.primary : AdminColors.grey),
      ),
    );
  }
}

class PhotoGrid extends StatelessWidget {
  const PhotoGrid({super.key, required this.photos});
  final List<JobPhoto> photos;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.45,
      children: [
        for (final p in photos)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(fit: StackFit.expand, children: [
              Image.network(p.url, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      color: AdminColors.field,
                      child: const Icon(Icons.broken_image_outlined, color: AdminColors.grey)),
                  loadingBuilder: (c, child, prog) =>
                      prog == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2))),
              Positioned(
                left: 6, bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                  child: Text(p.label, style: ts(10, w: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ]),
          ),
      ],
    );
  }
}
