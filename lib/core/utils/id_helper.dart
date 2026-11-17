/// Tạo mã request đơn giản cho yêu cầu và callable idempotency.
class IdHelper {
  static String newId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
}
