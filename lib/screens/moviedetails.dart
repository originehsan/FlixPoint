import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/screens/seatselection.dart';
import 'package:movieticket/services/tmdb_service.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/constants.dart';
import 'package:movieticket/utils/pickimage.dart';
import 'package:readmore/readmore.dart';
import 'package:url_launcher/url_launcher.dart';

class MovieDetailsScreen extends StatefulWidget {
  final TmdbMovie movie;
  const MovieDetailsScreen({super.key, required this.movie});

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  final TmdbService _tmdbService = TmdbService();
  Map<String, dynamic>? _movieDetails;
  List<Map<String, dynamic>> _cast = [];
  String? _trailerKey;
  bool _isLoading = true;
  bool _theatreSelected = false;
  String _theatreName = '';
  String _theatreAddress = '';
  String _theatreIcon = '';
  String _selectedCinemaId = '';
  Map<String, dynamic>? _selectedCinemaData;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final details = await _tmdbService.getMovieDetails(widget.movie.id);
      final cast = await _tmdbService.getMovieCredits(widget.movie.id);
      final trailer = await _tmdbService.getMovieTrailer(widget.movie.id);
      if (mounted) {
        setState(() {
          _movieDetails = details;
          _cast = cast;
          _trailerKey = trailer;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _runtime {
    if (_movieDetails == null) return '';
    final runtime = _movieDetails!['runtime'] ?? 0;
    final hours = runtime ~/ 60;
    final minutes = runtime % 60;
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
    R.init(context);
    R.init(context);
    R.init(context);
    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMovieInfo(),
                _buildStoryline(),
                _buildCast(),
                _buildCinemaSection(),
                _buildBookButton(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
      ),
      backgroundColor: mobileBackgroundColor,
      pinned: true,
      stretch: true,
      expandedHeight: 400.h,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: surfaceColor.withValues(alpha: 0.8),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back_ios,
            color: appthemecolor,
            size: 16,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'movie_${widget.movie.id}',
              child: CachedNetworkImage(
                imageUrl:
                    _tmdbService.getBackdropUrl(widget.movie.backdropPath),
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: surfaceColor,
                ),
                errorWidget: (context, url, error) => Container(
                  color: surfaceColor,
                  child: const Icon(
                    Icons.movie,
                    color: appthemecolor,
                    size: 50,
                  ),
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: heroGradient,
              ),
            ),
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.movie.title,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: appthemecolor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: appthemecolor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: appthemecolor,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.movie.formattedRating,
                              style: TextStyle(
                                color: appthemecolor,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_runtime.isNotEmpty)
                        Text(
                          _runtime,
                          style: TextStyle(
                            color: secondaryColor,
                            fontSize: 12.sp,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        widget.movie.year,
                        style: TextStyle(
                          color: secondaryColor,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ...widget.movie.genreNames.map(
                        (genre) => Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: surfaceColor.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: appthemecolor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            genre,
                            style: TextStyle(
                              color: appthemecolor,
                              fontSize: 10.sp,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (_trailerKey != null)
                        GestureDetector(
                          onTap: () async {
                            final url = Uri.parse(
                              'https://www.youtube.com/watch?v=$_trailerKey',
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: appthemecolor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: appthemecolor.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.play_arrow,
                                  color: appthemecolor,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Trailer',
                                  style: TextStyle(
                                    color: appthemecolor,
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _infoChip(
            Icons.star,
            'Rating',
            widget.movie.formattedRating,
          ),
          const SizedBox(width: 12),
          if (_runtime.isNotEmpty)
            _infoChip(
              Icons.access_time,
              'Duration',
              _runtime,
            ),
          const SizedBox(width: 12),
          _infoChip(
            Icons.calendar_today,
            'Year',
            widget.movie.year,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _infoChip(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: appthemecolor.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: appthemecolor, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: primaryColor,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: secondaryColor,
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryline() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Storyline',
            style: TextStyle(
              color: primaryColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ReadMoreText(
            widget.movie.overview,
            textAlign: TextAlign.justify,
            trimLines: 4,
            trimCollapsedText: 'See more',
            trimExpandedText: 'See less',
            style: TextStyle(
              color: secondaryColor,
              fontSize: 13.sp,
              height: 1.6,
            ),
            moreStyle: const TextStyle(color: appthemecolor),
            lessStyle: const TextStyle(color: appthemecolor),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildCast() {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cast',
              style: TextStyle(
                color: primaryColor,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: CircularProgressIndicator(color: appthemecolor),
            ),
          ],
        ),
      );
    }
    if (_cast.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cast',
            style: TextStyle(
              color: primaryColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _cast.length,
              itemBuilder: (context, index) {
                final actor = _cast[index];
                final profilePath = actor['profile_path'];
                return Container(
                  width: 70.w,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: surfaceColor,
                        backgroundImage: profilePath != null
                            ? CachedNetworkImageProvider(
                                '$tmdbImageBase$profilePath',
                              )
                            : null,
                        child: profilePath == null
                            ? const Icon(
                                Icons.person,
                                color: appthemecolor,
                              )
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        actor['name'] ?? '',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 9.sp,
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ).animate().fadeIn(
                      delay: Duration(milliseconds: index * 50),
                    );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCinemaSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Cinema',
            style: TextStyle(
              color: primaryColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('cinema').get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: appthemecolor),
                );
              }
              if (snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: appthemecolor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: appthemecolor,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'No cinemas available for this movie',
                        style: TextStyle(
                          color: secondaryColor,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final cinema =
                      snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  final cinemaId = snapshot.data!.docs[index].id;
                  final isSelected = _selectedCinemaId == cinemaId;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCinemaId = cinemaId;
                        _selectedCinemaData = cinema;
                        _theatreName = cinema['name'] ?? '';
                        _theatreAddress = cinema['address'] ?? '';
                        _theatreIcon = cinema['logo'] ?? '';
                        _theatreSelected = true;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? appthemecolor.withValues(alpha: 0.1)
                            : surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? appthemecolor
                              : appthemecolor.withValues(alpha: 0.15),
                          width: isSelected ? 1.5 : 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: cinema['logo'] ?? '',
                              height: 40.h,
                              width: 50.w,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                height: 40.h,
                                width: 50.w,
                                color: surfaceColor2,
                                child: const Icon(
                                  Icons.movie,
                                  color: appthemecolor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cinema['name'] ?? '',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cinema['address'] ?? '',
                                  style: TextStyle(
                                    color: secondaryColor,
                                    fontSize: 11.sp,
                                  ),
                                ),
                                if (cinema['distance'] != null)
                                  Text(
                                    '${cinema['distance']} km away',
                                    style: TextStyle(
                                      color: appthemecolor,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: appthemecolor,
                            ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(
                        delay: Duration(milliseconds: index * 100),
                      );
                },
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          if (_theatreSelected) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SeatSelection(
                  movie: widget.movie,
                  theatreName: _theatreName,
                  theatreAddress: _theatreAddress,
                  theatreLogo: _theatreIcon,
                  cinemaId: _selectedCinemaId,
                ),
              ),
            );
          } else {
            showSnackBar('Please select a cinema first', context);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 55.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _theatreSelected ? appthemecolor : surfaceColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: appthemecolor,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.confirmation_num,
                color: _theatreSelected ? mobileBackgroundColor : appthemecolor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _theatreSelected ? 'Book Tickets' : 'Select Cinema First',
                style: TextStyle(
                  color:
                      _theatreSelected ? mobileBackgroundColor : appthemecolor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2);
  }
}
