import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/category_model.dart';

class TransactionForm extends StatefulWidget {
  final String initialType;
  final int? initialCategoryId;
  final double? initialAmount;
  final String? initialDescription;
  final DateTime initialDate;

  final List<CategoryModel> categories;

  final bool isSaving;
  final String buttonText;

  final Future<void> Function({
    required String type,
    required int categoryId,
    required double amount,
    required String? description,
    required DateTime date,
  }) onSubmit;

  const TransactionForm({
    super.key,
    required this.categories,
    required this.onSubmit,
    required this.initialDate,
    this.initialType = 'expense',
    this.initialCategoryId,
    this.initialAmount,
    this.initialDescription,
    this.isSaving = false,
    this.buttonText = 'Simpan Transaksi',
  });

  @override
  State<TransactionForm> createState() =>
      _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController amountController;
  late final TextEditingController descriptionController;

  late String selectedType;
  int? selectedCategoryId;
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();

    selectedType = widget.initialType;
    selectedCategoryId = widget.initialCategoryId;
    selectedDate = widget.initialDate;

    amountController = TextEditingController(
      text: widget.initialAmount?.toStringAsFixed(0) ?? '',
    );

    descriptionController = TextEditingController(
      text: widget.initialDescription ?? '',
    );

    updateSelectedCategory();
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();

    super.dispose();
  }

  // ==============================
  // KATEGORI
  // ==============================

  List<CategoryModel> get filteredCategories {
    return widget.categories
        .where(
          (category) => category.type == selectedType,
        )
        .toList();
  }

  void updateSelectedCategory() {
    final availableCategories = filteredCategories;

    if (availableCategories.isEmpty) {
      selectedCategoryId = null;
      return;
    }

    final categoryExists = availableCategories.any(
      (category) => category.id == selectedCategoryId,
    );

    if (!categoryExists) {
      selectedCategoryId = availableCategories.first.id;
    }
  }

  // ==============================
  // TANGGAL
  // ==============================

  Future<void> selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      selectedDate = pickedDate;
    });
  }

  String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  // ==============================
  // SUBMIT
  // ==============================

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih kategori.'),
        ),
      );

      return;
    }

    final amount = double.tryParse(
      amountController.text,
    );

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal tidak valid.'),
        ),
      );

      return;
    }

    await widget.onSubmit(
      type: selectedType,
      categoryId: selectedCategoryId!,
      amount: amount,
      description:
          descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
      date: selectedDate,
    );
  }

  // ==============================
  // BUILD
  // ==============================

  @override
  Widget build(BuildContext context) {
    final availableCategories = filteredCategories;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ==============================
          // JENIS TRANSAKSI
          // ==============================

          const Text(
            'Jenis Transaksi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            initialValue: selectedType,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'income',
                child: Text('Pemasukan'),
              ),
              DropdownMenuItem(
                value: 'expense',
                child: Text('Pengeluaran'),
              ),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                selectedType = value;
                updateSelectedCategory();
              });
            },
          ),

          const SizedBox(height: 16),

          // ==============================
          // NOMINAL
          // ==============================

          const Text(
            'Nominal',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              prefixText: 'Rp ',
              border: OutlineInputBorder(),
              hintText: 'Masukkan nominal',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nominal wajib diisi';
              }

              final amount = double.tryParse(value);

              if (amount == null || amount <= 0) {
                return 'Nominal harus lebih dari 0';
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          // ==============================
          // KATEGORI
          // ==============================

          const Text(
            'Kategori',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<int>(
            initialValue: selectedCategoryId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            hint: const Text('Pilih kategori'),
            items: availableCategories.map(
              (category) {
                return DropdownMenuItem<int>(
                  value: category.id,
                  child: Text(category.name),
                );
              },
            ).toList(),
            onChanged: (value) {
              setState(() {
                selectedCategoryId = value;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Kategori wajib dipilih';
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          // ==============================
          // KETERANGAN
          // ==============================

          const Text(
            'Keterangan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Masukkan keterangan',
            ),
          ),

          const SizedBox(height: 16),

          // ==============================
          // TANGGAL
          // ==============================

          const Text(
            'Tanggal',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          InkWell(
            onTap: selectDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                suffixIcon: Icon(
                  Icons.calendar_today,
                ),
              ),
              child: Text(
                formatDate(selectedDate),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ==============================
          // TOMBOL
          // ==============================

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed:
                  widget.isSaving ? null : submit,
              child: widget.isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Text(widget.buttonText),
            ),
          ),
        ],
      ),
    );
  }
}