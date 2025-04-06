// lib/models/business_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessModel {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final String? logoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, String> reviewLinks;
  
  const BusinessModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.logoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.reviewLinks = const {},
  });
  
  factory BusinessModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return BusinessModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      logoUrl: data['logoUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      reviewLinks: Map<String, String>.from(data['reviewLinks'] ?? {}),
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'reviewLinks': reviewLinks,
    };
  }
  
  BusinessModel copyWith({
    String? name,
    String? description,
    String? logoUrl,
    Map<String, String>? reviewLinks,
    DateTime? updatedAt,
  }) {
    return BusinessModel(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      reviewLinks: reviewLinks ?? this.reviewLinks,
    );
  }
}