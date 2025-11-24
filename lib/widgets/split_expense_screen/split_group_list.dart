// lib/widgets/split_expense_screen/split_group_list.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/database_provider.dart';
import './split_group_card.dart';

class SplitGroupList extends StatelessWidget {
  const SplitGroupList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseProvider>(
      builder: (_, db, __) {
        var list = db.splitGroups;

        return list.isNotEmpty
            ? ListView.builder(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                itemCount: list.length,
                itemBuilder: (_, i) => SplitGroupCard(list[i]),
              )
            : const Center(
                child: Text('No Groups Found. Tap "+" to create one.'),
              );
      },
    );
  }
}