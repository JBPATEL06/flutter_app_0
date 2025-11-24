// lib/widgets/group_detail_screen/group_expense_form.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/database_provider.dart';
import '../../models/split_group.dart';

class GroupExpenseForm extends StatefulWidget {
  final List<String> members;
  final GroupExpense? expenseToEdit;
  
  const GroupExpenseForm({
    super.key, 
    required this.members, 
    this.expenseToEdit
  });

  @override
  State<GroupExpenseForm> createState() => _GroupExpenseFormState();
}

class _GroupExpenseFormState extends State<GroupExpenseForm> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _date = DateTime.now();
  String? _paidBy;
  Map<String, TextEditingController> _shareControllers = {};
  double _amountLeftToAssign = 0.0;
  bool _isEditing = false;
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');


  @override
  void initState() {
    super.initState();
    _isEditing = widget.expenseToEdit != null;
    
    if (_isEditing) {
      _titleController.text = widget.expenseToEdit!.title;
      _amountController.text = widget.expenseToEdit!.totalAmount.toStringAsFixed(2);
      _date = widget.expenseToEdit!.date;
      _paidBy = widget.expenseToEdit!.paidBy;
    } else {
      _paidBy = widget.members.isNotEmpty ? widget.members.first : null;
    }

    // Initialize text controllers for custom shares
    for (var member in widget.members) {
      double initialShare = _isEditing
          ? widget.expenseToEdit!.memberShares[member] ?? 0.0
          : 0.0;
      _shareControllers[member] = TextEditingController(
          text: initialShare.toStringAsFixed(2));
      _shareControllers[member]!.addListener(_updateAmountLeft);
    }
    
    _amountController.addListener(_updateAmountLeft);
    _updateAmountLeft();
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateAmountLeft);
    _amountController.dispose();
    _titleController.dispose();
    for (var controller in _shareControllers.values) {
      controller.removeListener(_updateAmountLeft);
      controller.dispose();
    }
    super.dispose();
  }

  void _updateAmountLeft() {
    final totalAmount = double.tryParse(_amountController.text) ?? 0.0;
    double assignedTotal = 0.0;
    
    for (var controller in _shareControllers.values) {
      assignedTotal += double.tryParse(controller.text) ?? 0.0;
    }
    
    // Schedule a frame update to avoid calling setState during build/layout
    if (mounted) {
      setState(() {
        _amountLeftToAssign = totalAmount - assignedTotal;
      });
    }
  }

  void _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2022),
        lastDate: DateTime.now());

    if (pickedDate != null && mounted) {
      setState(() {
        _date = pickedDate;
      });
    }
  }

  void _handleSave() {
    final title = _titleController.text.trim();
    final totalAmount = double.tryParse(_amountController.text);

    if (title.isEmpty || totalAmount == null || _paidBy == null || totalAmount <= 0) {
      _showSnackbar('Please fill all required fields correctly.');
      return;
    }
    
    // Check if the amounts balance
    if (_amountLeftToAssign.abs() > 0.01) {
      _showSnackbar('Total member shares (${currencyFormat.format(totalAmount - _amountLeftToAssign)}) must match the Total Amount Paid (${currencyFormat.format(totalAmount)}).');
      return;
    }

    final memberShares = <String, double>{};
    for (var entry in _shareControllers.entries) {
      final share = double.tryParse(entry.value.text) ?? 0.0;
      // Only save shares greater than 0.01 (to ignore zero/empty inputs)
      if (share.abs() > 0.01) { 
        memberShares[entry.key] = share;
      }
    }
    
    if (memberShares.isEmpty) {
        _showSnackbar('At least one member must be responsible for a share.');
        return;
    }

    final expense = GroupExpense(
      id: _isEditing ? widget.expenseToEdit!.id : '',
      title: title,
      totalAmount: totalAmount,
      paidBy: _paidBy!,
      memberShares: memberShares, 
      date: _date,
      isHold: _isEditing ? widget.expenseToEdit!.isHold : false,
    );

    final provider = Provider.of<DatabaseProvider>(context, listen: false);
    if (_isEditing) {
      provider.updateGroupExpense(expense);
    } else {
      provider.addGroupExpense(expense);
    }
    
    Navigator.of(context).pop();
  }
  
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Text(
            _isEditing ? 'Edit Group Expense' : 'Add Group Expense',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20.0),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Expense Title'),
                  ),
                  const SizedBox(height: 10.0),
                  // Amount
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Total Amount Paid'),
                  ),
                  const SizedBox(height: 10.0),
                  // Date Picker
                  Row(
                    children: [
                      Expanded(
                        child: Text(DateFormat('MMMM dd, yyyy').format(_date)),
                      ),
                      IconButton(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_month),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10.0),
                  // Paid By
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Paid By'),
                    value: _paidBy,
                    items: widget.members.map((member) {
                      return DropdownMenuItem(value: member, child: Text(member));
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _paidBy = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 20.0),
                  // Custom Split Section
                  Text(
                    'Custom Split Shares:', 
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 5.0),
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: _amountLeftToAssign.abs() < 0.01 ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8.0)
                    ),
                    child: Text(
                      'Remaining to assign: ${currencyFormat.format(_amountLeftToAssign)}',
                      style: TextStyle(
                        color: _amountLeftToAssign.abs() < 0.01 ? Colors.green.shade800 : Colors.red.shade800,
                        fontWeight: FontWeight.bold
                      )
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  // Member Share Inputs
                  ...widget.members.map((member) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(child: Text(member)),
                          SizedBox(
                            width: 150,
                            child: TextFormField(
                              controller: _shareControllers[member],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Owed Amount',
                                prefixText: currencyFormat.currencySymbol,
                                border: const OutlineInputBorder(),
                                isDense: true
                              ),
                              onChanged: (_) => _updateAmountLeft(),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          // Add/Update Button
          const SizedBox(height: 20.0),
          ElevatedButton.icon(
            onPressed: _handleSave,
            icon: Icon(_isEditing ? Icons.save : Icons.add),
            label: Text(_isEditing ? 'Save Changes' : 'Add Expense'),
          ),
        ],
      ),
    );
  }
}