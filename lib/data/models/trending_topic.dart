import 'package:equatable/equatable.dart';

class TrendingTopic extends Equatable {
  final String id;
  final String name;
  final String description;
  final int articleCount;
  final double growthPercent;
  final String? imageUrl;

  const TrendingTopic({
    required this.id,
    required this.name,
    required this.description,
    this.articleCount = 0,
    this.growthPercent = 0,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [id, name];
}

class FundingEvent extends Equatable {
  final String id;
  final String companyName;
  final String? logoUrl;
  final String round;
  final double amountUsd;
  final List<String> investors;
  final String? description;
  final DateTime announcedAt;

  const FundingEvent({
    required this.id,
    required this.companyName,
    this.logoUrl,
    required this.round,
    required this.amountUsd,
    this.investors = const [],
    this.description,
    required this.announcedAt,
  });

  @override
  List<Object?> get props => [id, companyName];
}
