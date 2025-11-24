// lib/models/split_group.dart

// Represents a single expense within a group (e.g., 'Dinner bill')
class GroupExpense {
  final String id;
  final String title;
  final double totalAmount;
  final String paidBy; 
  // Key: Member Name, Value: Amount they owe/is responsible for
  final Map<String, double> memberShares; 
  final DateTime date;
  final bool isHold; 

  GroupExpense({
    required this.id,
    required this.title,
    required this.totalAmount,
    required this.paidBy,
    required this.memberShares, 
    required this.date,
    this.isHold = false, 
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'totalAmount': totalAmount.toString(),
        'paidBy': paidBy,
        // Convert Map<String, double> to Map<String, String> for Firestore storage
        'memberShares': memberShares.map((k, v) => MapEntry(k, v.toString())), 
        'date': date.toIso8601String(),
        'isHold': isHold, 
      };

  factory GroupExpense.fromMap(Map<String, dynamic> map, String docId) =>
      GroupExpense(
        id: docId,
        title: map['title'],
        totalAmount: double.parse(map['totalAmount']),
        paidBy: map['paidBy'],
        // Convert Map<String, String> from Firestore back to Map<String, double>
        memberShares: (map['memberShares'] as Map<String, dynamic>).map((k, v) => MapEntry(k, double.parse(v as String))), 
        date: DateTime.parse(map['date']),
        // FIX: Provide a fallback value (false) if the field is missing (null) in Firestore.
        isHold: map['isHold'] as bool? ?? false, 
      );
}

// Represents a group for splitting expenses (e.g., 'Trip to Goa')
class SplitGroup {
  final String id;
  final String title;
  final List<String> members; 
  double totalExpenses;
  bool isHold; 

  SplitGroup({
    required this.id,
    required this.title,
    required this.members,
    this.totalExpenses = 0.0,
    this.isHold = false, 
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'members': members,
        'totalExpenses': totalExpenses.toString(),
        'isHold': isHold, 
      };

  factory SplitGroup.fromMap(Map<String, dynamic> map, String docId) =>
      SplitGroup(
        id: docId,
        title: map['title'],
        members: List<String>.from(map['members'] ?? []),
        totalExpenses: double.tryParse(map['totalExpenses'] ?? '0.0') ?? 0.0,
        // FIX: Provide a fallback value (false) if the field is missing (null) in Firestore.
        isHold: map['isHold'] as bool? ?? false, 
      );
}