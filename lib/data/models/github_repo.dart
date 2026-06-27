import 'package:equatable/equatable.dart';

class GithubRepo extends Equatable {
  final String id;
  final String fullName;
  final String description;
  final String url;
  final String? language;
  final int stars;
  final int forks;
  final int starsThisWeek;
  final String? readmeExcerpt;
  final DateTime? lastCommit;

  const GithubRepo({
    required this.id,
    required this.fullName,
    required this.description,
    required this.url,
    this.language,
    this.stars = 0,
    this.forks = 0,
    this.starsThisWeek = 0,
    this.readmeExcerpt,
    this.lastCommit,
  });

  @override
  List<Object?> get props => [id, fullName];
}
