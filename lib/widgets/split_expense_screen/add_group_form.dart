// lib/widgets/split_expense_screen/add_group_form.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/database_provider.dart';

class AddGroupForm extends StatefulWidget {
  const AddGroupForm({super.key});

  @override
  State<AddGroupForm> createState() => _AddGroupFormState();
}

class _AddGroupFormState extends State<AddGroupForm> {
  final _groupTitleController = TextEditingController();
  final _memberNameController = TextEditingController();
  List<String> _members = [];

  void _addMember() {
    final name = _memberNameController.text.trim();
    if (name.isNotEmpty && !_members.contains(name)) {
      setState(() {
        _members.add(name);
        _memberNameController.clear();
      });
    }
  }

  void _createGroup() {
    final title = _groupTitleController.text.trim();
    if (title.isNotEmpty && _members.isNotEmpty) {
      final provider = Provider.of<DatabaseProvider>(context, listen: false);
      provider.addSplitGroup(title, _members);
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a group title and at least one member.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create New Group',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),
            // Group Title
            TextField(
              controller: _groupTitleController,
              decoration: const InputDecoration(
                labelText: 'Group Title (e.g., Goa Trip)',
              ),
            ),
            const SizedBox(height: 20.0),
            // Add Member
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _memberNameController,
                    decoration: const InputDecoration(
                      labelText: 'Member Name',
                    ),
                    onSubmitted: (_) => _addMember(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: _addMember,
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            // Members List
            Wrap(
              spacing: 8.0,
              children: _members
                  .map(
                    (name) => Chip(
                      label: Text(name),
                      onDeleted: () {
                        setState(() {
                          _members.remove(name);
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 30.0),
            // Create Button
            ElevatedButton.icon(
              onPressed: _createGroup,
              icon: const Icon(Icons.check),
              label: const Text('Create Group'),
            ),
          ],
        ),
      ),
    );
  }
}