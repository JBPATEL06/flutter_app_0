// lib/widgets/split_expense_screen/split_group_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/split_group.dart';
import '../../models/database_provider.dart';
import '../../screens/group_detail_screen.dart';

class SplitGroupCard extends StatelessWidget {
  final SplitGroup group;
  const SplitGroupCard(this.group, {super.key});

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${group.title}?'),
        content: const Text(
            'Are you sure you want to delete this group and all its expenses? (This action is irreversible)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  // NEW: Dialog to edit group name
  Future<void> _showEditGroupDialog(BuildContext context, DatabaseProvider provider) async {
    final TextEditingController controller = TextEditingController(text: group.title);
    
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Group Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'New Group Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newTitle = controller.text.trim();
                if (newTitle.isNotEmpty && newTitle != group.title) {
                  provider.updateSplitGroupTitle(group.id, newTitle);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DatabaseProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    
    return Dismissible(
      key: ValueKey(group.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      // DELETE FUNCTIONALITY: Handled by swipe-to-dismiss
      confirmDismiss: (_) => _showDeleteConfirmation(context),
      onDismissed: (_) {
        provider.deleteSplitGroup(group.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${group.title} deleted.')),
        );
      },
      child: ListTile(
        onTap: () {
          provider.selectSplitGroup(group);
          Navigator.of(context).pushNamed(GroupDetailScreen.name);
        },
        // Group Icon
        leading: const CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Icon(Icons.groups, color: Colors.white),
        ),
        title: Text(group.title),
        subtitle: Text('Members: ${group.members.length}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // NEW: EDIT BUTTON (Replaces Hold/Pause button)
            IconButton(
              icon: const Icon(
                Icons.edit,
                color: Colors.blue,
              ),
              onPressed: () => _showEditGroupDialog(context, provider),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Total Spent'),
                Text(
                  currencyFormat.format(group.totalExpenses),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}