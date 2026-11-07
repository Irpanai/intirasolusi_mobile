import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/article_model.dart';
import '../../../data/repositories/article_repository.dart';

// Events
abstract class ArticleEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ArticleLoadList extends ArticleEvent {
  final String? search;
  final String? category;

  ArticleLoadList({this.search, this.category});

  @override
  List<Object?> get props => [search, category];
}

class ArticleLoadMore extends ArticleEvent {}

class ArticleLoadDetail extends ArticleEvent {
  final String slug;

  ArticleLoadDetail({required this.slug});

  @override
  List<Object?> get props => [slug];
}

class ArticleLoadLatest extends ArticleEvent {
  final int count;

  ArticleLoadLatest({this.count = 3});

  @override
  List<Object?> get props => [count];
}

// States
abstract class ArticleState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ArticleInitial extends ArticleState {}

class ArticleListLoading extends ArticleState {}

class ArticleListLoaded extends ArticleState {
  final List<ArticleModel> articles;
  final bool hasMore;
  final int currentPage;
  final String? currentSearch;
  final String? currentCategory;
  final bool isLoadingMore;

  ArticleListLoaded({
    required this.articles,
    required this.hasMore,
    required this.currentPage,
    this.currentSearch,
    this.currentCategory,
    this.isLoadingMore = false,
  });

  @override
  List<Object?> get props => [articles, hasMore, currentPage, currentSearch, currentCategory, isLoadingMore];

  ArticleListLoaded copyWith({
    List<ArticleModel>? articles,
    bool? hasMore,
    int? currentPage,
    String? currentSearch,
    String? currentCategory,
    bool? isLoadingMore,
  }) {
    return ArticleListLoaded(
      articles: articles ?? this.articles,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      currentSearch: currentSearch ?? this.currentSearch,
      currentCategory: currentCategory ?? this.currentCategory,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class ArticleListError extends ArticleState {
  final String message;

  ArticleListError({required this.message});

  @override
  List<Object?> get props => [message];
}

class ArticleDetailLoading extends ArticleState {}

class ArticleDetailLoaded extends ArticleState {
  final ArticleModel article;

  ArticleDetailLoaded({required this.article});

  @override
  List<Object?> get props => [article];
}

class ArticleDetailError extends ArticleState {
  final String message;

  ArticleDetailError({required this.message});

  @override
  List<Object?> get props => [message];
}

class ArticleLatestLoaded extends ArticleState {
  final List<ArticleModel> articles;

  ArticleLatestLoaded({required this.articles});

  @override
  List<Object?> get props => [articles];
}

// BLoC
class ArticleBloc extends Bloc<ArticleEvent, ArticleState> {
  final ArticleRepository _repository;

  ArticleBloc({ArticleRepository? repository})
      : _repository = repository ?? ArticleRepository(),
        super(ArticleInitial()) {
    on<ArticleLoadList>(_onLoadList);
    on<ArticleLoadMore>(_onLoadMore);
    on<ArticleLoadDetail>(_onLoadDetail);
    on<ArticleLoadLatest>(_onLoadLatest);
  }

  Future<void> _onLoadList(
    ArticleLoadList event,
    Emitter<ArticleState> emit,
  ) async {
    emit(ArticleListLoading());
    try {
      final response = await _repository.getArticles(
        search: event.search,
        category: event.category,
      );
      emit(ArticleListLoaded(
        articles: response.articles,
        hasMore: response.hasMorePages,
        currentPage: response.currentPage,
        currentSearch: event.search,
        currentCategory: event.category,
      ));
    } catch (e) {
      emit(ArticleListError(message: e.toString()));
    }
  }

  Future<void> _onLoadMore(
    ArticleLoadMore event,
    Emitter<ArticleState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ArticleListLoaded || !currentState.hasMore || currentState.isLoadingMore) return;

    emit(currentState.copyWith(isLoadingMore: true));
    try {
      final response = await _repository.getArticles(
        search: currentState.currentSearch,
        category: currentState.currentCategory,
        page: currentState.currentPage + 1,
      );
      emit(ArticleListLoaded(
        articles: [...currentState.articles, ...response.articles],
        hasMore: response.hasMorePages,
        currentPage: response.currentPage,
        currentSearch: currentState.currentSearch,
        currentCategory: currentState.currentCategory,
      ));
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onLoadDetail(
    ArticleLoadDetail event,
    Emitter<ArticleState> emit,
  ) async {
    emit(ArticleDetailLoading());
    try {
      final article = await _repository.getArticleDetail(event.slug);
      emit(ArticleDetailLoaded(article: article));
    } catch (e) {
      emit(ArticleDetailError(message: e.toString()));
    }
  }

  Future<void> _onLoadLatest(
    ArticleLoadLatest event,
    Emitter<ArticleState> emit,
  ) async {
    try {
      final response = await _repository.getArticles(perPage: event.count);
      emit(ArticleLatestLoaded(articles: response.articles));
    } catch (_) {
      emit(ArticleLatestLoaded(articles: []));
    }
  }
}
