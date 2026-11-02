import 'package:intl/intl.dart';

const List<String> _monthShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

String formatDate(DateTime date) =>
    '${date.day} ${_monthShort[date.month - 1]} ${date.year}';

String formatUnixSeconds(int? seconds) {
  if (seconds == null) return '-';
  final date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
  return formatDate(date.toLocal());
}

String formatIsoDate(String? iso) {
  if (iso == null || iso.isEmpty) return '-';
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  return formatDate(parsed.toLocal());
}

String wordTypeLabel(String wordType) {
  switch (wordType) {
    case 'word':
      return 'Kata';
    case 'phrase':
      return 'Frasa';
    case 'expression':
      return 'Ungkapan';
    default:
      return capitalize(wordType);
  }
}

String relationTypeLabel(String relationType) {
  switch (relationType) {
    case 'synonym':
      return 'Sinonim';
    case 'antonym':
      return 'Antonim';
    case 'related':
      return 'Terkait';
    case 'derived':
      return 'Turunan';
    case 'variant':
      return 'Varian';
    case 'hypernym':
      return 'Hipernim';
    case 'hyponym':
      return 'Hiponim';
    default:
      return capitalize(relationType.replaceAll('_', ' '));
  }
}

String variantTypeLabel(String variantType) {
  switch (variantType) {
    case 'alternative':
      return 'Alternatif';
    case 'affixation':
      return 'Afiksasi';
    case 'abbreviation':
      return 'Singkatan';
    case 'dialectal':
      return 'Dialek';
    default:
      return capitalize(variantType.replaceAll('_', ' '));
  }
}

String usageLabelText(String label) => label.replaceAll('_', ' ');

String formatNumber(int value) =>
    NumberFormat.decimalPattern('id_ID').format(value);

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
  final mb = kb / 1024;
  return '${mb.toStringAsFixed(1)} MB';
}
