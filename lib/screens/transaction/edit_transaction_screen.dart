import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../services/api_service.dart';
import '../../controllers/transaction_controller.dart';

class EditTransactionScreen extends StatefulWidget {
  final TransactionModel transaction;

  const EditTransactionScreen({
    super.key,
    required this.transaction,
  });

  @override
  State<EditTransactionScreen> createState() =>
      _EditTransactionScreenState();
}

class _EditTransactionScreenState
    extends State<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController amountController;
  late TextEditingController descriptionController;

  late String selectedType;
  int? selectedCategoryId;
  late DateTime selectedDate;

  final TransactionController
    transactionController =
    TransactionController();

  List<CategoryModel> categories = [];

  bool isLoadingCategories = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    amountController = TextEditingController(
      text: widget.transaction.amount
          .toStringAsFixed(0),
    );

    descriptionController =
        TextEditingController(
      text: widget.transaction.description ?? '',
    );

    selectedType = widget.transaction.type;

    selectedCategoryId =
        widget.transaction.categoryId;

    selectedDate = widget.transaction.date;

    loadCategories();
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();

    super.dispose();
  }

  Future<void> loadCategories() async {
    try {
      final result =
          await ApiService.getCategories();

      if (!mounted) return;

      setState(() {
        categories = result;
        isLoadingCategories = false;

        updateSelectedCategory();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingCategories = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengambil kategori: $e',
          ),
        ),
      );
    }
  }

  List<CategoryModel> get filteredCategories {
    return categories.where((category) {
      return category.type == selectedType;
    }).toList();
  }

  void updateSelectedCategory() {
    final availableCategories =
        filteredCategories;

    if (availableCategories.isEmpty) {
      selectedCategoryId = null;
      return;
    }

    final stillAvailable =
        availableCategories.any(
      (category) =>
          category.id == selectedCategoryId,
    );

    if (!stillAvailable) {
      selectedCategoryId =
          availableCategories.first.id;
    }
  }

  Future<void> selectDate() async {
    final pickedDate =
        await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  String formatDate(DateTime date) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    final year =
        date.year.toString();

    return '$day/$month/$year';
  }

  Future<void> updateTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedCategoryId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Silakan pilih kategori.',
          ),
        ),
      );

      return;
    }

    final amount =
        double.tryParse(
      amountController.text,
    );

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Nominal tidak valid.',
          ),
        ),
      );

      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await transactionController.updateTransaction(
        id: widget.transaction.id,
        categoryId: selectedCategoryId!,
        type: selectedType,
        amount: amount,
        description:
            descriptionController.text
                    .trim()
                    .isEmpty
                ? null
                : descriptionController.text
                    .trim(),
        transactionDate:
            '${selectedDate.year}-'
            '${selectedDate.month.toString().padLeft(2, '0')}-'
            '${selectedDate.day.toString().padLeft(2, '0')}',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Transaksi berhasil diperbarui.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memperbarui transaksi: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableCategories =
        filteredCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Transaksi',
        ),
      ),

      body: isLoadingCategories
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Form(
              key: _formKey,

              child: ListView(
                padding:
                    const EdgeInsets.all(16),

                children: [
                  const Text(
                    'Jenis Transaksi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration:
                        const InputDecoration(
                      border:
                          OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'income',
                        child:
                            Text('Pemasukan'),
                      ),
                      DropdownMenuItem(
                        value: 'expense',
                        child:
                            Text('Pengeluaran'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        selectedType = value;
                        updateSelectedCategory();
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Nominal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextFormField(
                    controller:
                        amountController,
                    keyboardType:
                        TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .digitsOnly,
                    ],
                    decoration:
                        const InputDecoration(
                      prefixText: 'Rp ',
                      border:
                          OutlineInputBorder(),
                      hintText:
                          'Masukkan nominal',
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty) {
                        return 'Nominal wajib diisi';
                      }

                      final amount =
                          double.tryParse(value);

                      if (amount == null ||
                          amount <= 0) {
                        return 'Nominal harus lebih dari 0';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Kategori',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),

                  DropdownButtonFormField<int>(
                    value: selectedCategoryId,
                    decoration:
                        const InputDecoration(
                      border:
                          OutlineInputBorder(),
                    ),
                    hint: const Text(
                      'Pilih kategori',
                    ),
                    items:
                        availableCategories
                            .map(
                      (category) {
                        return DropdownMenuItem<
                            int>(
                          value: category.id,
                          child: Text(
                            category.name,
                          ),
                        );
                      },
                    ).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategoryId =
                            value;
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

                  const Text(
                    'Keterangan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextFormField(
                    controller:
                        descriptionController,
                    maxLines: 3,
                    decoration:
                        const InputDecoration(
                      border:
                          OutlineInputBorder(),
                      hintText:
                          'Masukkan keterangan',
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Tanggal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),

                  InkWell(
                    onTap: selectDate,
                    child: InputDecorator(
                      decoration:
                          const InputDecoration(
                        border:
                            OutlineInputBorder(),
                        suffixIcon: Icon(
                          Icons.calendar_today,
                        ),
                      ),
                      child: Text(
                        formatDate(
                          selectedDate,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          isSaving
                              ? null
                              : updateTransaction,
                      child: isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Simpan Perubahan',
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}