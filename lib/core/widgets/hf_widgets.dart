import 'package:flutter/material.dart';
import '../theme/hf_theme.dart';

// Card widget
class HfCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const HfCard({
    super.key,
    required this.child,
    this.color,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// Primary button
class HfPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const HfPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? HfColors.primary,
        foregroundColor: foregroundColor ?? Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// Soft button (secondary)
class HfSoftButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? color;
  final Color? foreground;

  const HfSoftButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: color ?? HfColors.primarySoft,
        foregroundColor: foreground ?? HfColors.primary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide.none,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// Avatar widget
class HfAvatar extends StatelessWidget {
  final String? url;
  final String fallback;
  final double size;

  const HfAvatar({
    super.key,
    this.url,
    required this.fallback,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: HfColors.primarySoft,
      backgroundImage: url != null ? NetworkImage(url!) : null,
      child: url == null
          ? Text(
              fallback.isNotEmpty ? fallback[0].toUpperCase() : '?',
              style: TextStyle(
                color: HfColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: size * 0.4,
              ),
            )
          : null,
    );
  }
}

// Badge widget
enum BadgeTone { green, orange, teal, blue, red, navy }

class HfBadge extends StatelessWidget {
  final String label;
  final BadgeTone tone;

  const HfBadge({
    super.key,
    required this.label,
    required this.tone,
  });

  Color get _color {
    switch (tone) {
      case BadgeTone.green:
        return HfColors.success;
      case BadgeTone.orange:
        return HfColors.orange;
      case BadgeTone.teal:
        return HfColors.primary;
      case BadgeTone.blue:
        return HfColors.info;
      case BadgeTone.red:
        return HfColors.error;
      case BadgeTone.navy:
        return HfColors.navy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// Input field widget
class HfField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData? icon;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final int? maxLines;

  const HfField({
    super.key,
    required this.label,
    required this.hint,
    this.icon,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
    this.onChanged,
    this.validator,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: HfColors.navy,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: validator,
          maxLines: maxLines ?? 1,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: HfColors.muted),
            prefixIcon: icon != null ? Icon(icon, color: HfColors.grey) : null,
            suffixIcon: suffix,
            filled: true,
            fillColor: HfColors.field,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

// Screen header widget
class HfScreenHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  const HfScreenHeader({
    super.key,
    required this.title,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null)
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
          )
        else
          const SizedBox(width: 48),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: HfColors.navy,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

// Brand mark widget
class HfBrandMark extends StatelessWidget {
  final bool compact;

  const HfBrandMark({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 36 : 48,
          height: compact ? 36 : 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B8FB5), Color(0xFF0B5F7A)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.home_rounded,
            color: Colors.white,
            size: compact ? 20 : 28,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'HomeFix',
              style: TextStyle(
                fontSize: compact ? 18 : 24,
                fontWeight: FontWeight.w800,
                color: HfColors.navy,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Bottom navigation widget
class HfBottomNav extends StatelessWidget {
  final List<HfNavItem> items;
  final int index;
  final ValueChanged<int> onTap;

  const HfBottomNav({
    super.key,
    required this.items,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isSelected = i == index;
              return _NavItem(
                icon: item.icon,
                label: item.label,
                isSelected: isSelected,
                onTap: () => onTap(i),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? HfColors.primary : HfColors.muted,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? HfColors.primary : HfColors.muted,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// Nav item data class
class HfNavItem {
  final IconData icon;
  final String label;

  const HfNavItem(this.icon, this.label);
}

// Pill/filter widget
class HfPill extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? color;

  const HfPill({
    super.key,
    required this.label,
    this.selected = false,
    this.icon,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color ?? (selected ? HfColors.primary : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? HfColors.primary : HfColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : (color ?? HfColors.primary),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : HfColors.navy,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Stars rating widget
class HfStars extends StatelessWidget {
  final double value;

  const HfStars({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < value.floor()) {
          return const Icon(Icons.star, color: HfColors.orange, size: 16);
        } else if (index < value) {
          return const Icon(Icons.star_half, color: HfColors.orange, size: 16);
        } else {
          return const Icon(Icons.star_border, color: HfColors.orange, size: 16);
        }
      }),
    );
  }
}

// Snack helper
void hfSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

// Logo widget
class HfLogo extends StatelessWidget {
  final double size;

  const HfLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B8FB5), Color(0xFF0B5F7A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: HfColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(Icons.home_rounded, color: Colors.white, size: size * 0.55),
    );
  }
}
