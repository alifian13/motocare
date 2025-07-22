import 'dart:convert';

SparePart sparePartFromJson(String str) => SparePart.fromJson(json.decode(str));

String sparePartToJson(SparePart data) => json.encode(data.toJson());

class SparePart {
    final int partId;
    final String vehicleCode;
    final String serviceName;
    final String partName;
    final String partCode;
    final String? purchaseUrl;
    final String? description;

    SparePart({
        required this.partId,
        required this.vehicleCode,
        required this.serviceName,
        required this.partName,
        required this.partCode,
        this.purchaseUrl,
        this.description,
    });

    factory SparePart.fromJson(Map<String, dynamic> json) => SparePart(
        partId: json["part_id"],
        vehicleCode: json["vehicle_code"],
        serviceName: json["service_name"],
        partName: json["part_name"],
        partCode: json["part_code"],
        purchaseUrl: json["purchase_url"],
        description: json["description"],
    );

    Map<String, dynamic> toJson() => {
        "part_id": partId,
        "vehicle_code": vehicleCode,
        "service_name": serviceName,
        "part_name": partName,
        "part_code": partCode,
        "purchase_url": purchaseUrl,
        "description": description,
    };
}