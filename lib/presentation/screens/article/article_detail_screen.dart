import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/article/article_bloc.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../data/models/article_model.dart';

class ArticleDetailScreen extends StatefulWidget {
  final String slug;

  const ArticleDetailScreen({super.key, required this.slug});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ArticleBloc>().add(ArticleLoadDetail(slug: widget.slug));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<ArticleBloc, ArticleState>(
        builder: (context, state) {
          if (state is ArticleDetailLoading) {
            return const LoadingWidget(message: 'Memuat berita...');
          }

          if (state is ArticleDetailError) {
            return Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
              ),
              body: AppErrorWidget(
                message: state.message,
                onRetry: () => context.read<ArticleBloc>().add(
                  ArticleLoadDetail(slug: widget.slug),
                ),
              ),
            );
          }

          if (state is ArticleDetailLoaded) {
            return _buildContent(context, state.article);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ArticleModel article) {
    return CustomScrollView(
      slivers: [
        // App Bar with image
        SliverAppBar(
          expandedHeight: article.featuredImage != null ? 250 : 0,
          pinned: true,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          flexibleSpace: article.featuredImage != null
              ? FlexibleSpaceBar(
                  background: Image.network(
                    article.featuredImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.background,
                      child: Icon(Icons.article_outlined, size: 64, color: AppColors.textMuted),
                    ),
                  ),
                )
              : null,
        ),
        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category
                if (article.category != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      article.category!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Title
                Text(
                  article.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),

                // Meta info
                Row(
                  children: [
                    if (article.author != null) ...[
                      Icon(Icons.person_outline, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        article.author!,
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (article.publishedAt != null) ...[
                      Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd MMMM yyyy').format(article.publishedAt!),
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

                // Content body
                if (article.content != null)
                  _buildHtmlContent(article.content!),

                // Attachments
                if (article.attachments != null && article.attachments!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Lampiran',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...article.attachments!.map((att) => _buildAttachment(att)),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHtmlContent(String content) {
    // Strip HTML tags for simple rendering
    final stripped = content
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'<p[^>]*>'), '')
        .replaceAll('</p>', '\n\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();

    return Text(
      stripped,
      style: TextStyle(
        fontSize: 15,
        color: AppColors.textPrimary,
        height: 1.7,
      ),
    );
  }

  Widget _buildAttachment(ArticleAttachment attachment) {
    final isImage = attachment.name != null &&
        RegExp(r'\.(jpg|jpeg|png|gif|webp)$', caseSensitive: false)
            .hasMatch(attachment.name!);

    if (isImage) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            attachment.url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.attach_file, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              attachment.name ?? 'Lampiran',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
