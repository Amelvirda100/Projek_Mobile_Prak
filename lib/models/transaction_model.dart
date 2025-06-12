import 'package:budgetlisting/models/location_model.dart';

class TransactionModel {
  String? message;
  List<Transaction>? transactions;

  TransactionModel({this.message, this.transactions});

  TransactionModel.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    if (json['transactions'] != null) {
      transactions = <Transaction>[];
      json['transactions'].forEach((v) {
        transactions!.add(Transaction.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    if (transactions != null) {
      data['transactions'] = transactions!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Transaction {
  int? id;
  String? type;
  double? amount;
  String? category;
  String? note;
  String? date;
  String? currencyCode;
  double? currencyRate;
  String? timeZone;
  String? locationName;
  Location? locationId;
  String? createdAt;
  String? updatedAt;

  Transaction({
    this.id,
    this.type,
    this.amount,
    this.category,
    this.note,
    this.date,
    this.currencyCode,
    this.currencyRate,
    this.timeZone,
    this.locationName,
    this.locationId,
    this.createdAt,
    this.updatedAt,
  });

  Transaction.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    type = json['type'];
    amount = (json['amount'] as num?)?.toDouble();
    category = json['category'];
    note = json['note'];
    date = json['date'];
    currencyCode = json['currency_code'];
    currencyRate = (json['currency_rate'] as num?)?.toDouble();
    timeZone = json['time_zone'];
    locationName = json['location_name'];
    locationId =json['location'] != null ? Location.fromJson(json['location']) : null;
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['type'] = type;
    data['amount'] = amount;
    data['category'] = category;
    data['note'] = note;
    data['date'] = date;
    data['currency_code'] = currencyCode;
    data['currency_rate'] = currencyRate;
    data['time_zone'] = timeZone;
    data['location_name'] = locationName;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
