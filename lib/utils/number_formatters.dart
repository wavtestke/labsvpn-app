import 'package:humanizer/humanizer.dart';

String _formatBytesRu(num bytes, {bool perSecond = false}) {
  const units = ['Б', 'КБ', 'МБ', 'ГБ', 'ТБ', 'ПБ'];
  double value = bytes.toDouble();
  int unitIdx = 0;
  while (value >= 1024 && unitIdx < units.length - 1) {
    value /= 1024;
    unitIdx++;
  }
  String numStr;
  if (unitIdx == 0 || value >= 100) {
    numStr = value.toStringAsFixed(0);
  } else if (value >= 10) {
    numStr = value.toStringAsFixed(1);
  } else {
    numStr = value.toStringAsFixed(2);
  }
  if (numStr.contains('.')) {
    numStr = numStr.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return '$numStr ${units[unitIdx]}${perSecond ? '/с' : ''}';
}

extension ByteFormatter on int {
  String size() => _formatBytesRu(this);

  static final _sizeOfFormat = InformationSizeFormat(permissibleValueUnits: {InformationUnit.gibibyte});

  String sizeGB() => _sizeOfFormat.format(bytes());

  String sizeOf(int total) => "${_formatBytesRu(this)} / ${_formatBytesRu(total)}";

  bool isInfinitSize() => bytes().terabytes.toDouble() > 10;

  String speed() => _formatBytesRu(this, perSecond: true);
}
