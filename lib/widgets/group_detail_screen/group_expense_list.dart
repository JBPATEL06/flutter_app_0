// lib/widgets/group_detail_screen/group_expense_list.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/database_provider.dart';
import '../../models/split_group.dart'; // <<< FIX: ADD MISSING IMPORT FOR GroupExpense
import './group_expense_form.dart'; 

class GroupExpenseList extends StatelessWidget {
  const GroupExpenseList({super.key});

  // FIX: Added GroupExpense type to function signature
  void _startEditExpense(BuildContext context, GroupExpense expense, List<String> members) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // Pass the existing expense data to the form for editing
      builder: (_) => GroupExpenseForm(members: members, expenseToEdit: expense), 
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseProvider>(
      builder: (_, db, __) {
        // We use allGroupExpenses to ensure held items are visible for management (editing/unholding)
        var expenseList = db.allGroupExpenses;
        final currentMembers = db.currentSplitGroup?.members ?? [];
        final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

        return expenseList.isNotEmpty
            ? ListView.builder(
                itemCount: expenseList.length,
                itemBuilder: (_, i) {
                  final exp = expenseList[i];
                  return Dismissible(
                    key: ValueKey(exp.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    // DELETE FUNCTIONALITY: Handled by swipe-to-dismiss
                    confirmDismiss: (_) => showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Delete ${exp.title}?'),
                        content: const Text('Are you sure you want to delete this expense? (This action is irreversible)'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              db.deleteGroupExpense(exp.id);
                              Navigator.of(ctx).pop(true);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    ),
                    child: ListTile(
                      onTap: () => _startEditExpense(context, exp, currentMembers), // ENABLE EDITING on tap
                      tileColor: exp.isHold ? Colors.yellow.shade100 : null,
                      title: Text(
                        exp.title,
                        style: TextStyle(
                            decoration: exp.isHold ? TextDecoration.lineThrough : null,
                            fontStyle: exp.isHold ? FontStyle.italic : null
                        ),
                      ),
                      // Update subtitle to reflect custom share logic
                      subtitle: Text('Paid by: ${exp.paidBy} | Total Shared: ${currencyFormat.format(exp.memberShares.values.fold(0.0, (sum, share) => sum + share))}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // HOLD/UNHOLD FUNCTIONALITY: Button to toggle status
                          IconButton(
                            icon: Icon(
                              exp.isHold ? Icons.play_arrow : Icons.pause,
                              color: exp.isHold ? Colors.green : Colors.orange,
                            ),
                            onPressed: () {
                              db.toggleGroupExpenseHold(exp);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${exp.title} set to ${exp.isHold ? 'Active' : 'On Hold'}.')),
                              );
                            },
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(currencyFormat.format(exp.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(DateFormat('dd MMM').format(exp.date), style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            : const Center(
                child: Text('No Expenses Added to this group.'),
              );
      },
    );
  }
}