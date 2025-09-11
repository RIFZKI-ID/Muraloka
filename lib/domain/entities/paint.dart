import 'dart:ui';

import 'package:equatable/equatable.dart';

class Paint extends Equatable {
  Paint({
    required this.id,
    required this.title,
    required this.description,
    required this.previewImage,
    required this.rating,
    required this.type,
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  final int id;
  final String? title;
  final String? description;
  final int? previewImage;
  final int? rating;
  final String type;
  final List<Offset> points;
  final int color;
  final double strokeWidth;

  @override
  List<Object?> get props => [id];
}
