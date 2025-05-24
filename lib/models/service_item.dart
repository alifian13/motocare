import 'package:flutter/material.dart';

class ServiceItem {
  final String title;
  final String date;
  final String odometer;
  final String plateNumber;
  final IconData icon;
  final String? status;

  ServiceItem({
    required this.title,
    required this.date,
    required this.odometer,
    required this.plateNumber,
    required this.icon,
    this.status,
  });
}