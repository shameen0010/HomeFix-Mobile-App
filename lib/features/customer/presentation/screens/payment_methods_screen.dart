import 'package:flutter/material.dart';

import '../../core/customer_ui.dart';
import '../widgets/customer_header.dart';

/// HomeFix is cash-on-completion only (no card data is stored in the app).
class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: Column(children: [
        const CustomerHeader(title: 'Payment Methods', showBack: true),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            AdminCard(
              borderColor: AdminColors.primary,
              child: Row(children: [
                const CircleAvatar(radius: 20, backgroundColor: AdminColors.chipBg,
                    child: Icon(Icons.payments_outlined, color: AdminColors.primary)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Cash on completion', style: ts(14.5, w: FontWeight.w700)),
                    Text('Pay the technician hand-to-hand after inspecting the finished work.',
                        style: ts(11, color: AdminColors.grey)),
                  ]),
                ),
                const StatusPill('Default', size: 9.5),
              ]),
            ),
            const SizedBox(height: 12),
            AdminCard(
              color: AdminColors.field,
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.lock_outline_rounded, size: 18, color: AdminColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                      'No online payments or cards are used. Every job is closed with the Dual Handshake: you confirm the cash handed over and the technician confirms receipt.',
                      style: ts(11.5, color: AdminColors.grey, height: 1.45)),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}
