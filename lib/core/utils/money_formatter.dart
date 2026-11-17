String formatVnd(num value) {
  final sign = value < 0 ? '-' : '';
  final digits = value.abs().round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '$sign${buffer.toString()} đ';
}
