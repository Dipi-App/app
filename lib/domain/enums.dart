enum WageType {
  fixed('ثابت'),
  variable('متغیر');

  const WageType(this.label);

  final String label;

  static WageType fromName(String? name) => WageType.values.firstWhere(
    (type) => type.name == name,
    orElse: () => WageType.fixed,
  );
}

enum PaymentType {
  wage('پرداخت دستمزد'),
  advance('علی‌الحساب'),
  expenseRefund('بازپرداخت هزینه');

  const PaymentType(this.label);

  final String label;

  static PaymentType fromName(String? name) => PaymentType.values.firstWhere(
    (type) => type.name == name,
    orElse: () => PaymentType.wage,
  );
}

enum ThemeChoice {
  system('هماهنگ با سیستم'),
  light('روشن'),
  dark('تیره');

  const ThemeChoice(this.label);

  final String label;

  static ThemeChoice fromName(String? name) => ThemeChoice.values.firstWhere(
    (choice) => choice.name == name,
    orElse: () => ThemeChoice.system,
  );
}

enum SettlementState {
  creditor('طلبکار'),
  debtor('بدهکار'),
  settled('تسویه');

  const SettlementState(this.label);

  final String label;
}
