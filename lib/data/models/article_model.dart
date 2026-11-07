class ArticleModel {
  final int id;
  final String title;
  final String slug;
  final String? excerpt;
  final String? content;
  final String? category;
  final String? author;
  final String? featuredImage;
  final String? featuredImageThumb;
  final List<ArticleAttachment>? attachments;
  final DateTime? publishedAt;
  final DateTime? createdAt;

  ArticleModel({
    required this.id,
    required this.title,
    required this.slug,
    this.excerpt,
    this.content,
    this.category,
    this.author,
    this.featuredImage,
    this.featuredImageThumb,
    this.attachments,
    this.publishedAt,
    this.createdAt,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      excerpt: json['excerpt'] as String?,
      content: json['content'] as String?,
      category: json['category'] as String?,
      author: json['author'] as String?,
      featuredImage: json['featured_image'] as String?,
      featuredImageThumb: json['featured_image_thumb'] as String?,
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
              .map((e) => ArticleAttachment.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

class ArticleAttachment {
  final int id;
  final String url;
  final String? thumb;
  final String? name;

  ArticleAttachment({
    required this.id,
    required this.url,
    this.thumb,
    this.name,
  });

  factory ArticleAttachment.fromJson(Map<String, dynamic> json) {
    return ArticleAttachment(
      id: json['id'] as int,
      url: json['url'] as String? ?? '',
      thumb: json['thumb'] as String?,
      name: json['name'] as String?,
    );
  }
}

class ArticleListResponse {
  final List<ArticleModel> articles;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  ArticleListResponse({
    required this.articles,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory ArticleListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] : json;
    return ArticleListResponse(
      articles: (data['data'] as List? ?? [])
          .map((e) => ArticleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: data['current_page'] as int? ?? 1,
      lastPage: data['last_page'] as int? ?? 1,
      perPage: data['per_page'] as int? ?? 10,
      total: data['total'] as int? ?? 0,
    );
  }

  bool get hasMorePages => currentPage < lastPage;
}
