import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/article/article_bloc.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../data/models/article_model.dart';

class ArticleListScreen extends StatefulWidget {
  const ArticleListScreen({super.key});

  @override
  State<ArticleListScreen> createState() => _ArticleListScreenState();
}

class _ArticleListScreenState extends State<ArticleListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;

  static const List<String> _categories = [
    'Promo',
    'Edukasi',
    'Info',
    'Berita',
    'Tips',
  ];

  @override
  void initState() {
    super.initState();
    context.read<ArticleBloc>().add(ArticleLoadList());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ArticleBloc>().add(ArticleLoadMore());
    }
  }

  void _onSearch(String query) {
    context.read<ArticleBloc>().add(ArticleLoadList(
      search: query.isNotEmpty ? query : null,
      category: _selectedCategory,
    ));
  }

  void _onCategorySelected(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    context.read<ArticleBloc>().add(ArticleLoadList(
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      category: category,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Berita'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: BlocBuilder<ArticleBloc, ArticleState>(
              builder: (context, state) {
                if (state is ArticleListLoading) {
                  return const LoadingWidget(message: 'Memuat berita...');
                }

                if (state is ArticleListError) {
                  return AppErrorWidget(
                    message: state.message,
                    onRetry: () => context.read<ArticleBloc>().add(
                      ArticleLoadList(
                        search: _searchController.text.isNotEmpty ? _searchController.text : null,
                        category: _selectedCategory,
                      ),
                    ),
                  );
                }

                if (state is ArticleListLoaded) {
                  if (state.articles.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.article_outlined, size: 64, color: AppColors.textMuted),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada berita',
                            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<ArticleBloc>().add(ArticleLoadList(
                        search: _searchController.text.isNotEmpty ? _searchController.text : null,
                        category: _selectedCategory,
                      ));
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.articles.length + (state.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.articles.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return _buildArticleCard(context, state.articles[index]);
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          // Search
          TextField(
            controller: _searchController,
            onSubmitted: _onSearch,
            decoration: InputDecoration(
              hintText: 'Cari berita...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _onSearch('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Category filter chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('Semua', null),
                const SizedBox(width: 8),
                ..._categories.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(cat, cat),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? category) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => _onCategorySelected(category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.textMuted.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, ArticleModel article) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/articles/${article.slug}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: 110,
                height: 100,
                child: article.featuredImageThumb != null
                    ? Image.network(
                        article.featuredImageThumb!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (article.category != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          article.category!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      article.publishedAt != null
                          ? DateFormat('dd MMM yyyy').format(article.publishedAt!)
                          : '',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.background,
      child: Icon(Icons.article_outlined, color: AppColors.textMuted, size: 32),
    );
  }
}
