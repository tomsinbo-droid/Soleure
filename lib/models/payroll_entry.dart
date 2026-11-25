// Công dụng tệp: Biểu diễn một dòng bảng lương.

class PayrollEntry {
  const PayrollEntry({
    required this.staffName,
    required this.hours,
    required this.hourlyPay,
    required this.commission,
    required this.adjustments,
    required this.status,
    this.wageOverride,
  });

  final String staffName;
  final double hours;
  final double hourlyPay;
  final double commission;
  final double adjustments;
  final String status;
  // Để các ca trong kỳ có thể có mức lương giờ khác nhau.
  final double? wageOverride;

  double get wage => wageOverride ?? hours * hourlyPay;
  double get total => wage + commission + adjustments;
}
