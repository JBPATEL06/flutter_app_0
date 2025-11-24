// lib/screens/group_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/database_provider.dart';
import '../widgets/group_detail_screen/group_expense_form.dart';
import '../widgets/group_detail_screen/group_expense_list.dart';
import '../widgets/group_detail_screen/settlement_view.dart';

class GroupDetailScreen extends StatelessWidget {
  const GroupDetailScreen({super.key});
  static const name = '/group_detail_screen';

  // Modal for managing members
  Future<void> _showManageMembers(BuildContext context, DatabaseProvider provider) async {
    final TextEditingController newMemberController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Manage Members'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newMemberController,
                            decoration: const InputDecoration(labelText: 'New Member Name'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.person_add),
                          onPressed: () {
                            if (newMemberController.text.trim().isNotEmpty) {
                              provider.addMemberToCurrentGroup(newMemberController.text.trim());
                              newMemberController.clear();
                              // setState is not strictly needed here as Provider updates UI outside the dialog
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Use Consumer here to ensure the list updates inside the dialog
                    Consumer<DatabaseProvider>(
                      builder: (context, db, child) {
                        return Column(
                          children: db.currentSplitGroup?.members.map(
                            (member) => ListTile(
                              title: Text(member),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  db.deleteMemberFromCurrentGroup(member);
                                },
                              ),
                            ),
                          ).toList() ?? [],
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseProvider>(
      builder: (context, provider, child) {
        final currentGroup = provider.currentSplitGroup;

        if (currentGroup == null) {
          return const Scaffold(
            body: Center(child: Text('Group not selected.')),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(currentGroup.title),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_add_alt_1),
                  tooltip: 'Manage Members',
                  onPressed: () => _showManageMembers(context, provider),
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Expenses', icon: Icon(Icons.receipt)),
                  Tab(text: 'Settlement', icon: Icon(Icons.handshake)),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                // Tab 1: Expenses List
                const GroupExpenseList(),

                // Tab 2: Settlement Report
                SettlementView(settlements: provider.calculateSettlement()),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  // Pass current members for selection
                  builder: (_) => GroupExpenseForm(members: currentGroup.members),
                );
              },
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }
}