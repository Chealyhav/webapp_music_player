class Artist {
  final String id;
  final String name;
  final String? imageUrl;
  final String? bio;

  const Artist({
    required this.id,
    required this.name,
    this.imageUrl,
    this.bio,
  });
}
