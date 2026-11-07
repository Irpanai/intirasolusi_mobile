import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../../blocs/article/article_bloc.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/gradient_header.dart';
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

  String? _resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    // Normalize localhost / 127.0.0.1 port 80 to port 8000
    if (url.contains('localhost/storage')) {
      return url.replaceFirst('localhost/storage', '127.0.0.1:8000/storage');
    }
    if (url.contains('127.0.0.1/storage') && !url.contains(':8000')) {
      return url.replaceFirst('127.0.0.1/storage', '127.0.0.1:8000/storage');
    }
    return url;
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
              backgroundColor: AppColors.background,
              body: Column(
                children: [
                  GradientHeader(
                    showBackButton: true,
                    child: const GradientHeaderTitle(title: 'Detail Artikel'),
                  ),
                  Expanded(
                    child: AppErrorWidget(
                      message: state.message,
                      onRetry: () => context.read<ArticleBloc>().add(
                        ArticleLoadDetail(slug: widget.slug),
                      ),
                    ),
                  ),
                ],
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
    final resolvedImage = _resolveImageUrl(article.featuredImage);
    final wordCount = article.content?.split(RegExp(r'\s+')).length ?? 100;
    final readTime = (wordCount / 180).ceil().clamp(1, 15);

    return CustomScrollView(
      slivers: [
        // App Bar with image or gradient
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          backgroundColor: const Color(0xFF14532D),
          foregroundColor: Colors.white,
          leadingWidth: 104,
          leading: Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 13,
                        color: Color(0xFF14532D),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Kembali',
                        style: TextStyle(
                          color: Color(0xFF14532D),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (resolvedImage != null)
                  Image.network(
                    resolvedImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                  )
                else
                  _buildPlaceholderImage(),
                // Bottom & top gradient protection
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.45),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Meta: Category badge & Read Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (article.category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Text(
                          article.category!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$readTime menit baca',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  article.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),

                // Author & Date Meta Row
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0FDF4),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.person, size: 15, color: Color(0xFF15803D)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      article.author ?? 'Tim Intira',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('•', style: TextStyle(color: Color(0xFFCBD5E1))),
                    const SizedBox(width: 12),
                    const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 5),
                    Text(
                      article.publishedAt != null
                          ? DateFormat('dd MMMM yyyy').format(article.publishedAt!)
                          : '-',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(color: Color(0xFFE2E8F0), thickness: 1),
                const SizedBox(height: 14),

                // Content body parsed from HTML
                if (article.content != null && article.content!.isNotEmpty)
                  _buildHtmlContent(article.content!)
                else
                  Text(
                    article.excerpt ?? 'Tidak ada konten berita.',
                    style: const TextStyle(fontSize: 15, color: Color(0xFF334155), height: 1.68),
                  ),

                // Attachments
                if (article.attachments != null && article.attachments!.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  const Text(
                    'Lampiran',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
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

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF14532D), // Pine green
            Color(0xFF15803D), // Emerald green
            Color(0xFF166534),
          ],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.newspaper_rounded,
            size: 44,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ── HTML Content Parser & Renderer ──────────────────────────────────────────

  Widget _buildHtmlContent(String htmlContent) {
    if (htmlContent.isEmpty) return const SizedBox.shrink();

    final fragment = html_parser.parseFragment(htmlContent);
    final widgets = <Widget>[];

    for (final node in fragment.nodes) {
      final widget = _renderHtmlNode(node);
      if (widget != null) {
        widgets.add(widget);
      }
    }

    if (widgets.isEmpty) {
      return Text(
        htmlContent,
        style: const TextStyle(fontSize: 15, color: Color(0xFF334155), height: 1.68),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget? _renderHtmlNode(dom.Node node) {
    if (node is dom.Text) {
      final text = node.text.trim();
      if (text.isEmpty) return null;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          text,
          style: const TextStyle(fontSize: 15, color: Color(0xFF334155), height: 1.68),
        ),
      );
    }

    if (node is! dom.Element) return null;
    final element = node;
    final tag = element.localName?.toLowerCase() ?? '';

    switch (tag) {
      case 'h1':
      case 'h2':
        return Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF15803D),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  element.text.trim(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        );

      case 'h3':
      case 'h4':
        return Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8),
          child: Text(
            element.text.trim(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
              letterSpacing: -0.2,
              height: 1.35,
            ),
          ),
        );

      case 'p':
        final text = element.text.trim();
        if (text.isEmpty) return null;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text.rich(
            TextSpan(children: _parseInlineSpans(element)),
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF334155),
              height: 1.68,
            ),
          ),
        );

      case 'table':
        return _buildTableWidget(element);

      case 'ol':
        return _buildOrderedList(element);

      case 'ul':
        return _buildUnorderedList(element);

      case 'blockquote':
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(10),
            border: const Border(
              left: BorderSide(color: Color(0xFF15803D), width: 4),
            ),
          ),
          child: Text.rich(
            TextSpan(children: _parseInlineSpans(element)),
            style: const TextStyle(
              fontSize: 14.5,
              fontStyle: FontStyle.italic,
              color: Color(0xFF166534),
              height: 1.55,
            ),
          ),
        );

      case 'hr':
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(color: Color(0xFFE2E8F0)),
        );

      default:
        final text = element.text.trim();
        if (text.isEmpty) return null;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text.rich(
            TextSpan(children: _parseInlineSpans(element)),
            style: const TextStyle(fontSize: 15, color: Color(0xFF334155), height: 1.68),
          ),
        );
    }
  }

  Widget _buildTableWidget(dom.Element tableElement) {
    final trElements = tableElement.querySelectorAll('tr');
    if (trElements.isEmpty) return const SizedBox.shrink();

    final tableRows = <TableRow>[];

    for (int rowIndex = 0; rowIndex < trElements.length; rowIndex++) {
      final tr = trElements[rowIndex];
      final thCells = tr.querySelectorAll('th');
      final tdCells = tr.querySelectorAll('td');
      final isHeader = thCells.isNotEmpty;
      final cells = isHeader ? thCells : tdCells;

      if (cells.isEmpty) continue;

      tableRows.add(
        TableRow(
          decoration: BoxDecoration(
            color: isHeader
                ? const Color(0xFFF1F5F9)
                : (rowIndex % 2 == 1 ? Colors.white : const Color(0xFFF8FAFC)),
          ),
          children: cells.map((cell) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Text(
                cell.text.trim(),
                style: TextStyle(
                  fontSize: isHeader ? 13.5 : 13.5,
                  fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,
                  color: isHeader ? const Color(0xFF0F172A) : const Color(0xFF334155),
                  height: 1.4,
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.2),
          1: FlexColumnWidth(1.0),
        },
        border: const TableBorder(
          horizontalInside: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        children: tableRows,
      ),
    );
  }

  Widget _buildOrderedList(dom.Element olElement) {
    final liElements = olElement.querySelectorAll('li');
    if (liElements.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(liElements.length, (index) {
          final li = liElements[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 2, right: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(children: _parseInlineSpans(li)),
                    style: const TextStyle(
                      fontSize: 14.5,
                      height: 1.6,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildUnorderedList(dom.Element ulElement) {
    final liElements = ulElement.querySelectorAll('li');
    if (liElements.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: liElements.map((li) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, right: 10),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF15803D),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(children: _parseInlineSpans(li)),
                    style: const TextStyle(
                      fontSize: 14.5,
                      height: 1.6,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  List<InlineSpan> _parseInlineSpans(dom.Node parent) {
    final spans = <InlineSpan>[];

    for (final child in parent.nodes) {
      if (child is dom.Text) {
        spans.add(TextSpan(text: child.text));
      } else if (child is dom.Element) {
        final tag = child.localName?.toLowerCase() ?? '';
        final childSpans = _parseInlineSpans(child);

        switch (tag) {
          case 'strong':
          case 'b':
            spans.add(TextSpan(
              text: child.nodes.isEmpty ? child.text : null,
              children: child.nodes.isNotEmpty ? childSpans : null,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ));
            break;
          case 'em':
          case 'i':
            spans.add(TextSpan(
              text: child.nodes.isEmpty ? child.text : null,
              children: child.nodes.isNotEmpty ? childSpans : null,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ));
            break;
          case 'u':
            spans.add(TextSpan(
              text: child.nodes.isEmpty ? child.text : null,
              children: child.nodes.isNotEmpty ? childSpans : null,
              style: const TextStyle(decoration: TextDecoration.underline),
            ));
            break;
          case 'a':
            spans.add(TextSpan(
              text: child.nodes.isEmpty ? child.text : null,
              children: child.nodes.isNotEmpty ? childSpans : null,
              style: const TextStyle(
                color: Color(0xFF15803D),
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ));
            break;
          case 'br':
            spans.add(const TextSpan(text: '\n'));
            break;
          default:
            spans.addAll(childSpans);
            break;
        }
      }
    }

    return spans;
  }

  Widget _buildAttachment(ArticleAttachment attachment) {
    final isImage = attachment.name != null &&
        RegExp(r'\.(jpg|jpeg|png|gif|webp)$', caseSensitive: false)
            .hasMatch(attachment.name!);

    final resolvedUrl = _resolveImageUrl(attachment.url) ?? attachment.url;

    if (isImage) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            resolvedUrl,
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
