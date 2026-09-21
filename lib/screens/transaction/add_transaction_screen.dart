import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/category_model.dart';
import '../../services/api_service.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState
    extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController amountController =
      TextEditingController();

  final TextEditingController descriptionController =
      TextEditingController();

  String selectedType = 'expense';

  int? selectedCategoryId;

  DateTime selectedDate = DateTime.now();

  List<CategoryModel> categories = [];

  bool isLoadingCategories = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    loadCategories();
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();

    super.dispose();
  }

  // ==========================================
  // MENGAMBIL KATEGORI DARI API
  // ==========================================

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

  // ==========================================
  // MEMILIH KATEGORI SESUAI JENIS TRANSAKSI
  // ==========================================

  List<CategoryModel> get filteredCategories {
    return categories.where((category) {
      return category.type == selectedType;
    }).toList();
  }

  // ==========================================
  // UPDATE KATEGORI TERPILIH
  // ==========================================

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

  // ==========================================
  // MEMILIH TANGGAL
  // ==========================================

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

  // ==========================================
  // FORMAT TANGGAL
  // ==========================================

  String formatDate(DateTime date) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    final year =
        date.year.toString();

    return '$day/$month/$year';
  }

  // ==========================================
  // SIMPAN TRANSAKSI
  // ==========================================

  Future<void> saveTransaction() async {
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
      await ApiService.createTransaction(
        categoryId: selectedCategoryId!,
        type: selectedType,
        amount: amount,
        description:
            descriptionController.text.trim().isEmpty
                ? null
                : descriptionController.text.trim(),
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
            'Transaksi berhasil disimpan.',
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
            'Gagal menyimpan transaksi: $e',
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
          'Tambah Transaksi',
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

                  // ==================================
                  // JENIS TRANSAKSI
                  // ==================================

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

                  // ==================================
                  // NOMINAL
                  // ==================================

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
                      hintText: 'Masukkan nominal',
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

                  // ==================================
                  // KATEGORI
                  // ==================================

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

                  // ==================================
                  // KETERANGAN
                  // ==================================

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

                  // ==================================
                  // TANGGAL
                  // ==================================

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

                  // ==================================
                  // TOMBOL SIMPAN
                  // ==================================

                  SizedBox(
                    width: double.infinity,
                    height: 50,

                    child: ElevatedButton(
                      onPressed:
                          isSaving
                              ? null
                              : saveTransaction,

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
                              'Simpan Transaksi',
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}