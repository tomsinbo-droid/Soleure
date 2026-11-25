// Công dụng tệp: Tạo mã định danh.

/// Tạo mã request đơn giản cho yêu cầu và callable idempotency.
class IdHelper {
  /// Tạo mã định danh mới cho bản ghi.
  static String newId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
}
