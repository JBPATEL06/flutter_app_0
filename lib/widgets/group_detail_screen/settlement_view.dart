// lib/widgets/group_detail_screen/settlement_view.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SettlementView extends StatelessWidget {
  final List<Map<String, dynamic>> settlements;
  const SettlementView({super.key, required this.settlements});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    if (settlements.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'No balances to settle. All expenses are either paid and split equally among involved members, or the settlement is complete.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Center(
          child: Text(
            'Final Settlement',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const Divider(),
        ...settlements.map((s) => Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${s['payer']} owes ${s['receiver']}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'must give →',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    Text(
                      currencyFormat.format(s['amount']),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 80),
      ],
    );
  }
}