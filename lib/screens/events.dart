import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/models/news_article_model.dart';
import 'package:movieticket/services/news_service.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:movieticket/widgets/common/app_badge.dart';
import 'package:movieticket/widgets/common/app_button.dart';
import 'package:movieticket/widgets/common/cards/app_card.dart';
import 'package:movieticket/widgets/common/empty_state.dart';
import 'package:movieticket/widgets/common/section_header.dart';
import 'package:movieticket/widgets/common/shimmer_box.dart';
import 'package:url_launcher/url_launcher.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() =>
      _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final NewsService _newsService = NewsService();

  int _selectedCategory = 0;
  int _carouselIndex = 0;
  List<NewsArticle> _allArticles = [];
  List<NewsArticle> _filteredArticles = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  int _currentPage = 1;

  final List<String> _categories = [
    'All',
    'Bollywood',
    'Hollywood',
    'Reviews',
    'Trailers',
    'Awards',
  ];

  final List<IconData> _categoryIcons = [
    Icons.apps_rounded,
    Icons.movie_rounded,
    Icons.local_movies_rounded,
    Icons.star_rounded,
    Icons.play_circle_rounded,
    Icons.emoji_events_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews({
    bool forceRefresh = false,
  }) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final articles = await _newsService.fetchAllNews(
      forceRefresh: forceRefresh,
    );

    if (mounted) {
      setState(() {
        _allArticles = articles;
        _filteredArticles = articles;
        _isLoading = false;
        _hasError = articles.isEmpty;
      });
    }
  }

  Future<void> _filterByCategory(
    String category,
  ) async {
    setState(() => _isLoading = true);
    final filtered =
        await _newsService.getNewsByCategory(category);
    if (mounted) {
      setState(() {
        _filteredArticles = filtered;
        _isLoading = false;
        _currentPage = 1;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    _currentPage++;
    final more = await _newsService.loadMore(
      _categories[_selectedCategory],
      _currentPage,
    );
    if (mounted) {
      setState(() {
        _filteredArticles.addAll(more);
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _openArticle(
    NewsArticle article,
  ) async {
    final uri = Uri.parse(article.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  String? _getBadge(NewsArticle article) {
    try {
      final published =
          DateTime.parse(article.publishedAt);
      final diff =
          DateTime.now().difference(published);
      if (diff.inHours < 2) return 'BREAKING';
      if (diff.inHours < 6) return 'NEW';
      return null;
    } catch (_) {
      return null;
    }
  }

  Color _getBadgeColor(String badge) =>
      badge == 'BREAKING' ? errorColor : successColor;

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: R.maxWidth),
          child: RefreshIndicator(
            color: appthemecolor,
            backgroundColor: surfaceColor,
            onRefresh: () =>
                _loadNews(forceRefresh: true),
            child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Gap(8),
                      _buildCategoryFilter(),
                      const Gap(12),
                      if (_hasError)
                        // EmptyState replaces
                        // _buildErrorState()
                        EmptyState(
                          icon: Icons.wifi_off_rounded,
                          title: 'Failed to load news',
                          subtitle:
                              'Pull down to refresh',
                          iconColor: errorColor,
                          actionLabel: 'Retry',
                          onAction: () => _loadNews(
                            forceRefresh: true,
                          ),
                        )
                      else if (_isLoading)
                        _buildShimmer()
                      else if (_filteredArticles.isEmpty)
                        // EmptyState replaces
                        // _buildEmptyState()
                        const EmptyState(
                          icon:
                              Icons.newspaper_rounded,
                          title: 'No news found',
                          subtitle:
                              'Try a different category',
                        )
                      else ...[
                        _buildCarousel(),
                        const Gap(8),
                        // SectionHeader replaces
                        // _buildSectionHeader()
                        SectionHeader(
                          title: 'Latest News',
                          subtitle:
                              '${_filteredArticles.length > 5 ? _filteredArticles.length - 5 : _filteredArticles.length - 1} articles',
                        ),
                        _buildNewsList(),
                        _buildLoadMore(),
                      ],
                      const Gap(30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: mobileBackgroundColor,
      floating: true,
      snap: true,
      elevation: 0,
      title: ShaderMask(
        shaderCallback: (bounds) =>
            const LinearGradient(
          colors: [appthemecolor, goldLight],
        ).createShader(bounds),
        child: Text(
          'Movie News',
          style: TextStyle(
            color: Colors.white,
            fontSize: R.sp(20),
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: R.horizontalPadding,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected =
              _selectedCategory == index;
          return GestureDetector(
            onTap: () {
              if (_selectedCategory != index) {
                setState(
                  () => _selectedCategory = index,
                );
                _filterByCategory(
                  _categories[index],
                );
              }
            },
            child: AnimatedContainer(
              duration: const Duration(
                milliseconds: 300,
              ),
              margin:
                  const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? appthemecolor
                    : surfaceColor,
                borderRadius:
                    BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? appthemecolor
                      : appthemecolor
                          .withValues(alpha: 0.2),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: appthemecolor
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _categoryIcons[index],
                    size: R.sp(13),
                    color: isSelected
                        ? Colors.black
                        : secondaryColor,
                  ),
                  const Gap(5),
                  Text(
                    _categories[index],
                    style: TextStyle(
                      color: isSelected
                          ? Colors.black
                          : secondaryColor,
                      fontSize: R.sp(11),
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // ═══════════════════════════════════
  // CAROUSEL
  // First 5 articles
  // Image + source badge ONLY on card
  // Zero text on image
  // ═══════════════════════════════════
  Widget _buildCarousel() {
    final featured =
        _filteredArticles.take(5).toList();
    if (featured.isEmpty) return const SizedBox();

    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: R.isPhone ? 220 : 280,
            autoPlay: true,
            autoPlayInterval:
                const Duration(seconds: 5),
            autoPlayAnimationDuration:
                const Duration(milliseconds: 600),
            enlargeCenterPage: true,
            enlargeFactor: 0.1,
            viewportFraction: 0.92,
            onPageChanged: (index, _) => setState(
              () => _carouselIndex = index,
            ),
          ),
          items: featured
              .map(
                (article) => _CarouselCard(
                  article: article,
                  onTap: () =>
                      _openArticle(article),
                ),
              )
              .toList(),
        ),
        const Gap(10),
        // Gold dot indicators
        Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: List.generate(
            featured.length,
            (index) => AnimatedContainer(
              duration: const Duration(
                milliseconds: 300,
              ),
              margin: const EdgeInsets.symmetric(
                horizontal: 3,
              ),
              width:
                  _carouselIndex == index ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _carouselIndex == index
                    ? appthemecolor
                    : secondaryColor
                        .withValues(alpha: 0.3),
                borderRadius:
                    BorderRadius.circular(3),
                boxShadow:
                    _carouselIndex == index
                        ? [
                            BoxShadow(
                              color: appthemecolor
                                  .withValues(
                                      alpha: 0.5),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  // News list skips first 5 (in carousel)
  Widget _buildNewsList() {
    final articles =
        _filteredArticles.skip(5).toList();
    if (articles.isEmpty) return const SizedBox();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: R.horizontalPadding,
      ),
      itemCount: articles.length,
      itemBuilder: (context, index) => _NewsCard(
        article: articles[index],
        index: index,
        onTap: () => _openArticle(articles[index]),
        badge: _getBadge(articles[index]),
        getBadgeColor: _getBadgeColor,
      ),
    );
  }

  Widget _buildLoadMore() {
    if (_filteredArticles.isEmpty) {
      return const SizedBox();
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
        R.horizontalPadding,
        8,
        R.horizontalPadding,
        0,
      ),
      // AppButton replaces GestureDetector+Container
      // isLoading handles CPI internally
      child: AppButton(
        label: 'Load More News',
        icon: Icons.expand_more_rounded,
        isGradient: false,
        isOutlined: true,
        height: 48,
        isLoading: _isLoadingMore,
        onTap: _loadMore,
      ),
    );
  }

  // ShimmerBox replaces Shimmer.fromColors
  Widget _buildShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Carousel shimmer
        ShimmerBox(
          width: double.infinity,
          height: R.isPhone ? 220 : 280,
          borderRadius: 20,
          margin: EdgeInsets.symmetric(
            horizontal: R.horizontalPadding,
          ),
        ),
        const Gap(24),
        // Section header shimmer
        ShimmerBox(
          width: 140,
          height: 20,
          borderRadius: 4,
          margin: EdgeInsets.symmetric(
            horizontal: R.horizontalPadding,
          ),
        ),
        const Gap(16),
        // List card shimmers matching card layout
        ...List.generate(
          4,
          (_) => Row(
            children: [
              ShimmerBox(
                width: R.isPhone ? 100 : 120,
                height: R.isPhone ? 110 : 130,
                borderRadius: 0,
                margin: EdgeInsets.only(
                  left: R.horizontalPadding,
                  bottom: 12,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: R.horizontalPadding,
                    bottom: 12,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(
                        width: 60,
                        height: 12,
                        borderRadius: 4,
                        margin: const EdgeInsets
                            .only(bottom: 6),
                      ),
                      ShimmerBox(
                        width: double.infinity,
                        height: 12,
                        borderRadius: 4,
                        margin: const EdgeInsets
                            .only(bottom: 5),
                      ),
                      ShimmerBox(
                        width: double.infinity,
                        height: 12,
                        borderRadius: 4,
                        margin: const EdgeInsets
                            .only(bottom: 5),
                      ),
                      ShimmerBox(
                        width: 100,
                        height: 12,
                        borderRadius: 4,
                        margin: const EdgeInsets
                            .only(bottom: 8),
                      ),
                      ShimmerBox(
                        width: 70,
                        height: 10,
                        borderRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════
// CAROUSEL CARD
// Image only + source badge top left
// Zero text on image — confirmed
// ═══════════════════════════════════
class _CarouselCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback onTap;

  const _CarouselCard({
    required this.article,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 4,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                appthemecolor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: appthemecolor
                  .withValues(alpha: 0.1),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Clean image — zero text on it
              article.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: article.imageUrl!,
                      fit: BoxFit.cover,
                      // ShimmerBox replaces
                      // Container placeholder
                      placeholder: (_, __) =>
                          const ShimmerBox(
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: 20,
                      ),
                      errorWidget: (_, __, ___) =>
                          Container(
                        color: surfaceColor,
                        child: const Center(
                          child: Icon(
                            Icons.newspaper_rounded,
                            color: appthemecolor,
                            size: 50,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: surfaceColor,
                      child: const Center(
                        child: Icon(
                          Icons.newspaper_rounded,
                          color: appthemecolor,
                          size: 50,
                        ),
                      ),
                    ),

              // Source badge top left ONLY
              // AppBadge replaces custom Container
              Positioned(
                top: 12,
                left: 12,
                child: AppBadge(
                  label: article.sourceName,
                  color: Colors.black
                      .withValues(alpha: 0.65),
                  hasGlow: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════
// NEWS LIST CARD
// AppCard + ShimmerBox + AppBadge
// Previous list design kept
// ═══════════════════════════════════
class _NewsCard extends StatelessWidget {
  final NewsArticle article;
  final int index;
  final VoidCallback onTap;
  final String? badge;
  final Color Function(String) getBadgeColor;

  const _NewsCard({
    required this.article,
    required this.index,
    required this.onTap,
    required this.badge,
    required this.getBadgeColor,
  });

  @override
  Widget build(BuildContext context) {
    R.init(context);
    // AppCard replaces GestureDetector+Container
    return AppCard(
      onTap: onTap,
      borderRadius: 16,
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      borderColor: badge == 'BREAKING'
          ? errorColor.withValues(alpha: 0.3)
          : appthemecolor.withValues(alpha: 0.12),
      child: Row(
        children: [
          // Image section
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: Stack(
              children: [
                article.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl:
                            article.imageUrl!,
                        width:
                            R.isPhone ? 100 : 120,
                        height:
                            R.isPhone ? 110 : 130,
                        fit: BoxFit.cover,
                        // ShimmerBox replaces
                        // Container placeholder
                        placeholder: (_, __) =>
                            ShimmerBox(
                          width: R.isPhone
                              ? 100
                              : 120,
                          height: R.isPhone
                              ? 110
                              : 130,
                          borderRadius: 0,
                        ),
                        errorWidget:
                            (_, __, ___) =>
                                Container(
                          width: R.isPhone
                              ? 100
                              : 120,
                          height: R.isPhone
                              ? 110
                              : 130,
                          color: surfaceColor2,
                          child: const Icon(
                            Icons.newspaper_rounded,
                            color: appthemecolor,
                            size: 28,
                          ),
                        ),
                      )
                    : Container(
                        width:
                            R.isPhone ? 100 : 120,
                        height:
                            R.isPhone ? 110 : 130,
                        color: surfaceColor2,
                        child: const Icon(
                          Icons.newspaper_rounded,
                          color: appthemecolor,
                          size: 28,
                        ),
                      ),
                // AppBadge replaces badge Container
                if (badge != null)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: AppBadge(
                      label: badge!,
                      color: getBadgeColor(badge!),
                      hasGlow: false,
                    ),
                  ),
              ],
            ),
          ),
          const Gap(12),
          // Text section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 12,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // Source badge
                  // textColor added to AppBadge
                  // so text visible on light bg
                  AppBadge(
                    label: article.sourceName,
                    color: appthemecolor
                        .withValues(alpha: 0.12),
                    textColor: appthemecolor,
                    hasGlow: false,
                  ),
                  const Gap(6),
                  Text(
                    article.title,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: R.sp(12),
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: secondaryColor,
                        size: 11,
                      ),
                      const Gap(3),
                      Text(
                        article.timeAgo,
                        style: TextStyle(
                          color: secondaryColor,
                          fontSize: R.sp(9),
                        ),
                      ),
                      const Gap(6),
                      Text(
                        '•',
                        style: TextStyle(
                          color: secondaryColor,
                          fontSize: R.sp(9),
                        ),
                      ),
                      const Gap(6),
                      Text(
                        article.readingTime,
                        style: TextStyle(
                          color: secondaryColor,
                          fontSize: R.sp(9),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons
                            .arrow_forward_ios_rounded,
                        color: appthemecolor,
                        size: 12,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Gap(10),
        ],
      ),
    ).animate().fadeIn(
          delay: Duration(
            milliseconds: index * 50,
          ),
        );
  }
}