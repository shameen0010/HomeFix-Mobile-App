import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/onboarding_screen.dart'; // AppColors

const kFieldBg = Color(0xFFF1F5FF);
const kSegOff = Color(0xFFD6E6FA);
const kDeepTeal = Color(0xFF0B5F7A);

TextStyle poppins(double size,
        {Color color = AppColors.dark, FontWeight w = FontWeight.w400}) =>
    GoogleFonts.poppins(fontSize: size, color: color, fontWeight: w);

/// [length>=8, upper+lower, number, symbol]
List<bool> passwordRules(String p) => [
      p.length >= 8,
      RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p),
      RegExp(r'[0-9]').hasMatch(p),
      RegExp(r'[^A-Za-z0-9]').hasMatch(p),
    ];

/// Top bar: back, logo, app name, profile circle
class AuthHeader extends StatelessWidget {
  final VoidCallback? onBack;
  const AuthHeader({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          InkWell(
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.arrow_back, color: AppColors.dark),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 8),
          Text('HomeFix', style: poppins(17, w: FontWeight.w600)),
          const Spacer(),
          Container(
            width: 34,
            height: 34,
            decoration:
                const BoxDecoration(color: kDeepTeal, shape: BoxShape.circle),
            child: const Icon(Icons.person_outline,
                color: Colors.white, size: 18),
          ),
        ]),
      ),
    );
  }
}

class AuthCard extends StatelessWidget {
  final Widget child;
  const AuthCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4)),
          ],
        ),
        child: child,
      );
}

class FieldLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const FieldLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(text, style: poppins(12, w: FontWeight.w600)),
            if (trailing case final trailingWidget?) trailingWidget,
          ],
        ),
      );
}

class AppField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const AppField({
    super.key,
    required this.hint,
    required this.icon,
    this.controller,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: 1.2),
        );
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      style: poppins(13),
      decoration: InputDecoration(
        filled: true,
        fillColor: kFieldBg,
        hintText: hint,
        hintStyle: poppins(13, color: const Color(0xFF9AA7B8)),
        prefixIcon: Icon(icon, size: 20, color: AppColors.grey),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: border(Colors.transparent),
        enabledBorder: border(Colors.transparent),
        focusedBorder: border(AppColors.primary),
        errorBorder: border(Colors.redAccent),
        focusedErrorBorder: border(Colors.redAccent),
        errorStyle: poppins(11, color: Colors.redAccent),
      ),
    );
  }
}

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  const PasswordField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.validator,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hide = true;

  @override
  Widget build(BuildContext context) => AppField(
        controller: widget.controller,
        hint: widget.hint,
        icon: Icons.lock_outline,
        obscure: _hide,
        onChanged: widget.onChanged,
        validator: widget.validator,
        suffix: IconButton(
          onPressed: () => setState(() => _hide = !_hide),
          icon: Icon(
            _hide ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20,
            color: AppColors.grey,
          ),
        ),
      );
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Color color;
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            disabledBackgroundColor: color.withValues(alpha: 0.7),
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label,
                        style: poppins(15,
                            color: Colors.white, w: FontWeight.w600)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
        ),
      );
}

class OrDivider extends StatelessWidget {
  final String text;
  const OrDivider(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Row(children: [
        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(text,
              style: poppins(10,
                  color: AppColors.grey, w: FontWeight.w500)),
        ),
        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
      ]);
}

/// Google + Apple buttons. Swap the icons for official brand assets later.
class SocialButtons extends StatelessWidget {
  final VoidCallback? onGoogle;
  final VoidCallback? onApple;
  const SocialButtons({super.key, this.onGoogle, this.onApple});

  Widget _btn(IconData icon, Color c, String label, VoidCallback? onTap) =>
      Expanded(
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          elevation: 1.5,
          shadowColor: Colors.black12,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: SizedBox(
              height: 48,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 24, color: c),
                const SizedBox(width: 8),
                Text(label, style: poppins(13, w: FontWeight.w600)),
              ]),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Row(children: [
        _btn(Icons.g_mobiledata_rounded, const Color(0xFFEA4335), 'Google',
            onGoogle),
        const SizedBox(width: 12),
        _btn(Icons.apple, Colors.black, 'Apple', onApple),
      ]);
}

/// Big icon with soft glow and orange shield badge
class HeroBadge extends StatelessWidget {
  final IconData icon;
  final bool circle;
  const HeroBadge({super.key, required this.icon, this.circle = false});

  @override
  Widget build(BuildContext context) {
    final shape = circle ? BoxShape.circle : BoxShape.rectangle;
    final radius = circle ? null : BorderRadius.circular(18);
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: shape,
              borderRadius: circle ? null : BorderRadius.circular(26),
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: shape,
              borderRadius: radius,
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6)),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.orange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.verified_user,
                  size: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class StrengthBar extends StatelessWidget {
  final int filled;
  final int total;
  const StrengthBar({super.key, required this.filled, required this.total});

  @override
  Widget build(BuildContext context) => Row(
        children: List.generate(
          total,
          (i) => Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
              height: 4,
              decoration: BoxDecoration(
                color: i < filled ? AppColors.primary : kSegOff,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      );
}