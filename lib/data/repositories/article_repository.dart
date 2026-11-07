import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/errors/exceptions.dart';
import '../models/article_model.dart';

class ArticleRepository {
  final ApiClient _apiClient;

  ArticleRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<ArticleListResponse> getArticles({
    String? search,
    String? category,
    int perPage = 10,
    int page = 1,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.articles,
        queryParams: {
          'per_page': perPage,
          'page': page,
          if (search != null && search.isNotEmpty) 'search': search,
          if (category != null && category.isNotEmpty) 'category': category,
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          return ArticleListResponse.fromJson(responseData);
        }
        throw ServerException(message: 'Format response tidak valid');
      } else {
        throw ServerException(
          message: 'Gagal memuat berita',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      if (e is DioException) {
        final message = e.response?.data?['message'] ?? e.message ?? 'Network error';
        throw ServerException(message: message, statusCode: e.response?.statusCode);
      }
      throw ServerException(message: 'Gagal memuat berita');
    }
  }

  Future<ArticleModel> getArticleDetail(String slug) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.articleDetail(slug));

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          final data = responseData['data'] ?? responseData;
          return ArticleModel.fromJson(data as Map<String, dynamic>);
        }
        throw ServerException(message: 'Format response tidak valid');
      } else {
        throw ServerException(
          message: 'Gagal memuat detail berita',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      if (e is DioException) {
        final message = e.response?.data?['message'] ?? e.message ?? 'Network error';
        throw ServerException(message: message, statusCode: e.response?.statusCode);
      }
      throw ServerException(message: 'Gagal memuat detail berita');
    }
  }
}
