String formatRupiah(double amount) {
  final value = amount.toStringAsFixed(0);

  final reversed = value.split('').reversed.toList();

  final groups = <String>[];

  for (var i = 0; i < reversed.length; i += 3) {
    final end = (i + 3 < reversed.length)
        ? i + 3
        : reversed.length;

    groups.add(
      reversed.sublist(i, end).reversed.join(),
    );
  }

  return 'Rp ${groups.reversed.join('.')}';
}