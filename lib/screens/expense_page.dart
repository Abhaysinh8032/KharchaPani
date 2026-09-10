import 'package:flutter/material.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_textfield.dart';

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  String type = 'Expense';
  String account = 'SBI';
  String category = 'Food';

  final amountController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  final types = ['Income', 'Expense', 'Transfer'];
  final accounts = ['SBI', 'HDFC'];
  final categories = ['Food', 'Clothes', 'Education'];

  Future<void> pickDateTime() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null && mounted) {
      TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null && mounted) {
        setState(() {
          selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Add Transaction"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CustomDropdown(
              value: type,
              items: types,
              label: "Transaction Type",
              onChanged: (val) => setState(() => type = val!),
            ),
            const SizedBox(height: 12),

            CustomDropdown(
              value: account,
              items: accounts,
              label: "Account",
              onChanged: (val) => setState(() => account = val!),
            ),
            const SizedBox(height: 12),

            CustomDropdown(
              value: category,
              items: categories,
              label: "Category",
              onChanged: (val) => setState(() => category = val!),
            ),
            const SizedBox(height: 12),

            CustomTextField(
              controller: amountController,
              label: "Amount",
            ),
            const SizedBox(height: 12),

            // Date UI
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${selectedDate.toLocal()}".split('.')[0],
                    style: const TextStyle(fontSize: 14),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: pickDateTime,
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Save"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
