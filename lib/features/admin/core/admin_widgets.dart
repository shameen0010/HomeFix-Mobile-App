import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import 'admin_feedback.dart';
import 'admin_format.dart';
import 'admin_theme.dart';

enum Tone { blue, green, orange, red, grey }

class _ToneColors {
  const _ToneColors(this.fg, this.bg);
  final Color fg, bg;
}

_ToneColors _tone(Tone t) {
  switch (t) {
    case Tone.blue:
      return const _ToneColors(AdminColors.primary, AdminColors.chipBg);
    case Tone.green:
      return const _ToneColors(Color(0xFF047857), AdminColors.greenBg);
    case Tone.orange:
      return const _ToneColors(Color(0xFFB45309), AdminColors.orangeBg);
    case Tone.red:
      return const _ToneColors(Color(0xFFB91C1C), AdminColors.redBg);
    case Tone.grey:
      return const _ToneColors(Color(0xFF4B5563), Color(0xFFE5E7EB));
  }
}

Color toneColor(Tone t) => _tone(t).fg;
Color toneBackground(Tone t) => _tone(t).bg;

/// Themed page scaffold used by every admin screen.
class AdminPage extends StatelessWidget {
  const AdminPage({super.key, required this.child, this.floatingActionButton});
  final Widget child;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: adminTheme,
      child: Scaffold(
        backgroundColor: AdminColors.bg,
        floatingActionButton: floatingActionButton,
        body: SafeArea(bottom: false, child: child),
      ),
    );
  }
}

/// "HomeFix [ADMIN] + subtitle" header, or back-arrow + screen title variant.
class AdminHeader extends StatelessWidget {
  const AdminHeader({super.key, this.subtitle, this.screenTitle, this.onBack});
  final String? subtitle;
  final String? screenTitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final logo = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
          color: AdminColors.primary, borderRadius: BorderRadius.circular(10)),
      child: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded))
          else
            const SizedBox(width: 8),
          logo,
          const SizedBox(width: 10),
          Expanded(
            child: screenTitle != null
                ? Text(screenTitle!,
                    style: ts(16, w: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(children: [
                        Text('HomeFix', style: ts(18, w: FontWeight.w700)),
                        const SizedBox(width: 6),
                        const StatusPill('ADMIN', size: 9.5),
                      ]),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: ts(11.5, color: AdminColors.grey)),
                    ],
                  ),
          ),
          IconButton(
            onPressed: () => showAdminSnack(context, 'No new notifications'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: () => _logout(context),
            icon: const CircleAvatar(
              radius: 17,
              backgroundColor: AdminColors.primary,
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await confirmAction(
      context,
      title: 'Log out of admin account?',
      message: 'You will need to sign in again to access the admin dashboard.',
      confirmLabel: 'Log out',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) context.go('/login');
    } on FirebaseAuthException catch (error) {
      if (context.mounted) {
        showAdminSnack(
          context,
          error.message ?? 'Could not log out. Please try again.',
          error: true,
        );
      }
    }
  }
}

class AdminCard extends StatelessWidget {
  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderColor,
    this.color = Colors.white,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: 1.2),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F0F2A43), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label,
      {super.key, this.tone = Tone.blue, this.icon, this.size = 11});
  final String label;
  final Tone tone;
  final IconData? icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = _tone(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: size + 2, color: c.fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: ts(size, w: FontWeight.w600, color: c.fg)),
          ),
        ],
      ),
    );
  }
}

class AdminAvatar extends StatelessWidget {
  const AdminAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 26,
    this.badgeColor,
    this.badgeIcon,
  });
  final String name;
  final String? photoUrl;
  final double radius;
  final Color? badgeColor;
  final IconData? badgeIcon;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: AdminColors.chipBg,
          backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
          onBackgroundImageError: hasPhoto ? (_, _) {} : null,
          child: hasPhoto
              ? null
              : Text(initials(name),
                  style: ts(radius * .6,
                      w: FontWeight.w600, color: AdminColors.primary)),
        ),
        if (badgeColor != null)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: badgeIcon == null
                  ? null
                  : Icon(badgeIcon, size: 10, color: Colors.white),
            ),
          ),
      ],
    );
  }
}

class AdminSearchBox extends StatelessWidget {
  const AdminSearchBox({super.key, required this.hint, required this.onChanged});
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: ts(13.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: ts(13, color: AdminColors.grey),
        prefixIcon: const Icon(Icons.search_rounded, color: AdminColors.grey),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AdminColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AdminColors.primary),
        ),
      ),
    );
  }
}

class AdminChoiceChip extends StatelessWidget {
  const AdminChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    this.dotColor,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AdminColors.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AdminColors.primary : Colors.white,
        shape: StadiumBorder(
            side: BorderSide(
                color: selected ? AdminColors.primary : AdminColors.border)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dotColor != null) ...[
                  Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: dotColor, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                ],
                Text(label, style: ts(12.5, w: FontWeight.w600, color: fg)),
                if (count != null) ...[
                  const SizedBox(width: 6),
                  Text(formatCount(count!),
                      style: ts(11,
                          color: selected ? Colors.white : AdminColors.grey)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum ButtonKind { tonal, danger, filled }

class AdminButton extends StatelessWidget {
  const AdminButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.kind = ButtonKind.tonal,
    this.icon,
    this.height = 40,
  });
  final String label;
  final VoidCallback? onPressed;
  final ButtonKind kind;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (kind) {
      case ButtonKind.tonal:
        bg = AdminColors.chipBg;
        fg = AdminColors.primary;
      case ButtonKind.danger:
        bg = AdminColors.redBg;
        fg = const Color(0xFFB91C1C);
      case ButtonKind.filled:
        bg = AdminColors.primary;
        fg = Colors.white;
    }
    if (onPressed == null) {
      bg = const Color(0xFFE5E7EB);
      fg = AdminColors.grey;
    }
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ts(12.5, w: FontWeight.w600, color: fg)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminDropdown<T> extends StatelessWidget {
  const AdminDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = items.containsKey(value) ? value : items.keys.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ts(11, w: FontWeight.w600, color: AdminColors.grey)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AdminColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: current,
              isExpanded: true,
              borderRadius: BorderRadius.circular(12),
              items: items.entries
                  .map((e) => DropdownMenuItem<T>(
                        value: e.key,
                        child: Text(e.value,
                            overflow: TextOverflow.ellipsis, style: ts(13)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class InfoField extends StatelessWidget {
  const InfoField({
    super.key,
    required this.label,
    required this.value,
    this.verified = false,
    this.trailing,
    this.icon,
  });
  final String label, value;
  final bool verified;
  final Widget? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AdminColors.field, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AdminColors.primary),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(label, style: ts(11, color: AdminColors.grey)),
                  if (verified) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded,
                        size: 13, color: AdminColors.primary),
                  ],
                ]),
                const SizedBox(height: 3),
                Text(value, style: ts(14, w: FontWeight.w600)),
              ],
            ),
          ),
          ...trailing == null ? const <Widget>[] : [trailing!],
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.caption,
    this.captionTone = Tone.green,
    this.onTap,
  });
  final String label, value;
  final IconData icon;
  final String? caption;
  final Tone captionTone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = AdminCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts(10, w: FontWeight.w600, color: AdminColors.grey)),
            ),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                  color: AdminColors.field,
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: AdminColors.primary),
            ),
          ]),
          const SizedBox(height: 8),
          Text(value, style: ts(22, w: FontWeight.w700)),
          ...caption == null
              ? const <Widget>[]
              : [Text(caption!, style: ts(11, color: toneColor(captionTone)))],
        ],
      ),
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.icon, this.trailing});
  final String text;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      if (icon != null) ...[
        Icon(icon, size: 18, color: AdminColors.primary),
        const SizedBox(width: 8),
      ],
      Expanded(child: Text(text, style: ts(15, w: FontWeight.w700))),
      ...trailing == null ? const <Widget>[] : [trailing!],
    ]);
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 40, color: AdminColors.red),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: ts(13, color: AdminColors.grey)),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.message, this.icon = Icons.inbox_outlined});
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(icon, size: 42, color: AdminColors.grey),
          const SizedBox(height: 8),
          Text(message, style: ts(13, color: AdminColors.grey)),
        ],
      ),
    );
  }
}

class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onPage,
  });
  final int page, totalPages;
  final ValueChanged<int> onPage;

  List<int?> _items() {
    if (totalPages <= 5) return List.generate(totalPages, (i) => i + 1);
    final set = <int>{1, totalPages, page - 1, page, page + 1}
      ..removeWhere((p) => p < 1 || p > totalPages);
    final sorted = set.toList()..sort();
    final out = <int?>[];
    for (var i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i] - sorted[i - 1] > 1) out.add(null);
      out.add(sorted[i]);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: page > 1 ? () => onPage(page - 1) : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        for (final p in _items())
          if (p == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('...', style: ts(13, color: AdminColors.grey)),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: p == page ? AdminColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onPage(p),
                  child: Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    child: Text('$p',
                        style: ts(13,
                            w: FontWeight.w600,
                            color: p == page ? Colors.white : AdminColors.grey)),
                  ),
                ),
              ),
            ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: page < totalPages ? () => onPage(page + 1) : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}
