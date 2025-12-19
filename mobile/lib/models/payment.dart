class Payment {
  final String id;
  final int amount;
  final String currency;
  final String status;
  final String providerOrderId;

  Payment({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.providerOrderId,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      amount: json['amount'],
      currency: json['currency'],
      status: json['status'],
      providerOrderId: json['providerOrderId'],
    );
  }
}
