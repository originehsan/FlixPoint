import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/screens/seatselection.dart';
import 'package:movieticket/services/tmdb_service.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/constants.dart';
import 'package:movieticket/utils/pickimage.dart';
import 'package:readmore/readmore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:movieticket/provider/booking_provider.dart';
import 'package:provider/provider.dart';

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
    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: R.maxWidth),
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
      backgroundColor: Colors.transparent,
      pinned: true,
      stretch: true,
      expandedHeight: R.featuredHeight + 120,
      leading: Padding(
        padding: EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: mobileBackgroundColor.withValues(alpha: 0.7),
              shape: BoxShape.circle,
              border: Border.all(
                color: appthemecolor.withValues(alpha: 0.5),
              ),
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: appthemecolor,
              size: 18,
            ),
          ),
        ),
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
                imageUrl: _tmdbService.getBackdropUrl(
                  widget.movie.backdropPath,
                ),
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: surfaceColor,
                ),
                errorWidget: (context, url, error) => Container(
                  color: surfaceColor,
                  child: Icon(
                    Icons.movie,
                    color: appthemecolor,
                    size: 50,
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    mobileBackgroundColor.withValues(alpha: 0.5),
                    mobileBackgroundColor,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.3, 0.7, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: R.horizontalPadding,
              right: R.horizontalPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.movie.title,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: R.sp(24),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: appthemecolor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              color: mobileBackgroundColor,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              widget.movie.formattedRating,
                              style: TextStyle(
                                color: mobileBackgroundColor,
                                fontSize: R.sp(12),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      if (_runtime.isNotEmpty)
                        _infoBadge(Icons.access_time, _runtime),
                      SizedBox(width: 8),
                      _infoBadge(Icons.calendar_today, widget.movie.year),
                    ],
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.movie.genreNames
                        .map(
                          (genre) => Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: surfaceColor.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: appthemecolor.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              genre,
                              style: TextStyle(
                                color: appthemecolor,
                                fontSize: R.sp(10),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: appthemecolor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: appthemecolor, size: 12),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: primaryColor,
              fontSize: R.sp(11),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: appthemecolor,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: appthemecolor.withValues(alpha: 0.5),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: primaryColor,
            fontSize: R.sp(18),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMovieInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: R.horizontalPadding,
        vertical: 12,
      ),
      child: Row(
        children: [
          _infoChip(Icons.star_rounded, 'Rating', widget.movie.formattedRating,
              appthemecolor),
          SizedBox(width: 10),
          if (_runtime.isNotEmpty)
            _infoChip(Icons.access_time_rounded, 'Duration', _runtime,
                secondaryColor),
          SizedBox(width: 10),
          _infoChip(Icons.calendar_month_rounded, 'Year', widget.movie.year,
              secondaryColor),
          if (_trailerKey != null) ...[
            SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final url = Uri.parse(
                    'https://www.youtube.com/watch?v=$_trailerKey',
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF0000).withValues(alpha: 0.8),
                        const Color(0xFFCC0000),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Trailer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: R.sp(12),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _infoChip(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: R.sp(18)),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: primaryColor,
                fontSize: R.sp(13),
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: secondaryColor,
                fontSize: R.sp(10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryline() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: R.horizontalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Storyline'),
          SizedBox(height: 10),
          ReadMoreText(
            widget.movie.overview,
            textAlign: TextAlign.justify,
            trimLines: 4,
            trimCollapsedText: 'Read more',
            trimExpandedText: 'Read less',
            style: TextStyle(
              color: secondaryColor,
              fontSize: R.sp(14),
              height: 1.7,
            ),
            moreStyle: TextStyle(
              color: appthemecolor,
              fontWeight: FontWeight.w600,
            ),
            lessStyle: TextStyle(
              color: appthemecolor,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildCast() {
    if (_isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: R.horizontalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Cast'),
            SizedBox(height: 12),
            Center(
              child: CircularProgressIndicator(
                color: appthemecolor,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      );
    }
    if (_cast.isEmpty) return SizedBox();
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: R.horizontalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Cast'),
          SizedBox(height: 12),
          SizedBox(
            height: R.castCardHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _cast.length,
              itemBuilder: (context, index) {
                final actor = _cast[index];
                final profilePath = actor['profile_path'];
                return Container(
                  width: R.castCardWidth,
                  margin: EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: appthemecolor.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: R.circleAvatarRadius,
                          backgroundColor: surfaceColor,
                          backgroundImage: profilePath != null
                              ? CachedNetworkImageProvider(
                                  '$tmdbImageBase$profilePath',
                                )
                              : null,
                          child: profilePath == null
                              ? Icon(
                                  Icons.person,
                                  color: appthemecolor,
                                  size: R.circleAvatarRadius,
                                )
                              : null,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        actor['name'] ?? '',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: R.sp(10),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (actor['character'] != null)
                        Text(
                          actor['character'],
                          style: TextStyle(
                            color: secondaryColor,
                            fontSize: R.sp(9),
                          ),
                          maxLines: 1,
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
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCinemaSection() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: R.horizontalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Select Cinema'),
          SizedBox(height: 12),
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('cinema').get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(
                    color: appthemecolor,
                    strokeWidth: 2,
                  ),
                );
              }
              if (snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: errorColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: secondaryColor),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No cinemas available',
                          style: TextStyle(
                            color: secondaryColor,
                            fontSize: R.sp(13),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
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
                        _theatreSelected = true;
                      });

                      final bookingProvider = Provider.of<BookingProvider>(
                        context,
                        listen: false,
                      );
                      bookingProvider.setCinema(
                        cinemaId: cinemaId,
                        cinemaName: cinema['name'] ?? '',
                        cinemaAddress: cinema['address'] ?? '',
                        cinemaLogo: cinema['logo'] ?? '',
                      );
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      margin: EdgeInsets.only(bottom: 10),
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? appthemecolor.withValues(alpha: 0.1)
                            : surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? appthemecolor
                              : appthemecolor.withValues(alpha: 0.15),
                          width: isSelected ? 1.5 : 0.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: appthemecolor.withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: cinema['logo'] ?? '',
                              height: 45,
                              width: 60,
                              fit: BoxFit.contain,
                              errorWidget: (context, url, error) => Container(
                                height: 45,
                                width: 60,
                                color: surfaceColor2,
                                child: Icon(
                                  Icons.movie,
                                  color: appthemecolor,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cinema['name'] ?? '',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: R.sp(14),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: appthemecolor,
                                      size: 12,
                                    ),
                                    SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        cinema['address'] ?? '',
                                        style: TextStyle(
                                          color: secondaryColor,
                                          fontSize: R.sp(11),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (cinema['distance'] != null)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.directions_walk,
                                        color: successColor,
                                        size: 12,
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        '${cinema['distance']} km away',
                                        style: TextStyle(
                                          color: successColor,
                                          fontSize: R.sp(10),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: appthemecolor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                color: mobileBackgroundColor,
                                size: 14,
                              ),
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
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        R.horizontalPadding,
        0,
        R.horizontalPadding,
        30,
      ),
      child: GestureDetector(
        onTap: () {
          if (_theatreSelected) {
            final bookingProvider = Provider.of<BookingProvider>(
              context,
              listen: false,
            );
            bookingProvider.setMovie(widget.movie);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SeatSelection(
                  movie: widget.movie,
                  theatreName: bookingProvider.cinemaName,
                  theatreAddress: bookingProvider.cinemaAddress,
                  theatreLogo: bookingProvider.cinemaLogo,
                  cinemaId: bookingProvider.cinemaId,
                ),
              ),
            );
          } else {
            showSnackBar('Please select a cinema first', context);
          }
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          height: 58,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: _theatreSelected
                ? LinearGradient(
                    colors: [appthemecolor, goldDark],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: _theatreSelected ? null : surfaceColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: appthemecolor,
              width: 1.5,
            ),
            boxShadow: _theatreSelected
                ? [
                    BoxShadow(
                      color: appthemecolor.withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.confirmation_num_rounded,
                color: _theatreSelected ? mobileBackgroundColor : appthemecolor,
                size: R.sp(22),
              ),
              SizedBox(width: 10),
              Text(
                _theatreSelected ? 'Book Tickets Now' : 'Select a Cinema First',
                style: TextStyle(
                  color:
                      _theatreSelected ? mobileBackgroundColor : appthemecolor,
                  fontSize: R.sp(16),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2);
  }
}
