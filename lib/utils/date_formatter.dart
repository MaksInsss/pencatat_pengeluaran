String formatTanggalIndonesia(DateTime date) {
  const bulan = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  return '${date.day} '
      '${bulan[date.month - 1]} '
      '${date.year}';
}

String formatWaktuIndonesia(DateTime date) {
  final localDate = date.toLocal();

  final jam =
      localDate.hour.toString().padLeft(2, '0');

  final menit =
      localDate.minute.toString().padLeft(2, '0');

  return '$jam:$menit';
}