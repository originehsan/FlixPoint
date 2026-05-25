import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/provider/booking_provider.dart';
import 'package:movieticket/screens/seatselection.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/constants.dart';
import 'package:movieticket/utils/page_transitions.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:movieticket/widgets/common/app_badge.dart';
import 'package:movieticket/widgets/common/app_button.dart';
import 'package:movieticket/widgets/common/app_appbar.dart';
import 'package:movieticket/widgets/common/app_card.dart';
import 'package:movieticket/widgets/common/time_chip.dart';
import 'package:movieticket/widgets/common/empty_state.dart';
import 'package:movieticket/widgets/common/shimmer_box.dart';
import 'package:movieticket/widgets/common/app_snackbar.dart';
import 'package:provider/provider.dart';

class CinemaSelectionScreen extends StatefulWidget {
  final TmdbMovie movie;

  const CinemaSelectionScreen({
    super.key,
    required this.movie,
  });

  @override
  State<CinemaSelectionScreen> createState() => _CinemaSelectionScreenState();
}

class _CinemaSelectionScreenState extends State<CinemaSelectionScreen> {
  String _selectedCinemaId = '';
  String _selectedTime = '';
  Map<String, dynamic>? _selectedCinema;
  bool _isProceedLoading = false;

  void _onTimeSelected(
    String cinemaId,
    Map<String, dynamic> cinema,
    String time,
  ) {
    setState(() {
      _selectedCinemaId = cinemaId;
      _selectedCinema = cinema;
      _selectedTime = time;
    });

    Provider.of<BookingProvider>(
      context,
      listen: false,
    ).setCinema(
      cinemaId: cinemaId,
      cinemaName: cinema['name'] ?? '',
      cinemaAddress: cinema['address'] ?? '',
      cinemaLogo: cinema['name'] ?? '',
    );
  }

  Future<void> _proceed() async {
    if (_selectedCinemaId.isEmpty || _selectedTime.isEmpty) {
      AppSnackbar.warning(
        context,
        'Please select a cinema and showtime',
      );
      return;
    }

    if (_isProceedLoading) return;
    setState(() => _isProceedLoading = true);

    Provider.of<BookingProvider>(
      context,
      listen: false,
    ).setMovie(widget.movie);

    await Navigator.push(
      context,
      AppRoutes.slideUpRoute(
        SeatSelection(
          movie: widget.movie,
          theatreName: _selectedCinema!['name'] ?? '',
          theatreAddress: _selectedCinema!['address'] ?? '',
          theatreLogo: _selectedCinema!['name'] ?? '',
          cinemaId: _selectedCinemaId,
          preSelectedTime: _selectedTime,
        ),
      ),
    );

    if (mounted) {
      setState(() => _isProceedLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      appBar: AppAppBar(
        title: 'Select Cinema',
        subtitle: widget.movie.title,
        showBackButton: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: R.maxWidth,
                ),
                child: FutureBuilder<QuerySnapshot>(
                  future:
                      FirebaseFirestore.instance.collection(colCinema).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildShimmer();
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const EmptyState(
                        icon: Icons.theaters_rounded,
                        title: 'No Cinemas Available',
                        subtitle: 'No cinemas found for this movie',
                      );
                    }
                    return ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        R.horizontalPadding,
                        12,
                        R.horizontalPadding,
                        100,
                      ),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final cinema = doc.data() as Map<String, dynamic>;
                        final cinemaId = doc.id;
                        return _CinemaCard(
                          cinema: cinema,
                          cinemaId: cinemaId,
                          selectedCinemaId: _selectedCinemaId,
                          selectedTime: _selectedTime,
                          index: index,
                          onTimeSelected: (time) => _onTimeSelected(
                            cinemaId,
                            cinema,
                            time,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: EdgeInsets.all(R.horizontalPadding),
      itemCount: 3,
      itemBuilder: (_, __) => ShimmerBox(
        width: double.infinity,
        height: 180,
        borderRadius: 20,
        margin: const EdgeInsets.only(bottom: 14),
      ),
    );
  }

  Widget _buildBottomBar() {
    final isReady = _selectedCinemaId.isNotEmpty && _selectedTime.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          top: BorderSide(
            color: appthemecolor.withValues(alpha: 0.15),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        R.horizontalPadding,
        12,
        R.horizontalPadding,
        R.isPhone ? 24 : 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isReady) ...[
            AppCard(
              backgroundColor: appthemecolor.withValues(alpha: 0.06),
              borderColor: appthemecolor.withValues(alpha: 0.2),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.theaters_rounded,
                    color: appthemecolor,
                    size: 16,
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      _selectedCinema?['name'] ?? '',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: R.sp(13),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AppBadge(
                    label: _selectedTime,
                    color: appthemecolor.withValues(alpha: 0.15),
                    textColor: appthemecolor,
                    hasGlow: false,
                  ),
                ],
              ),
            ),
            const Gap(12),
          ],
          AppButton(
            label: isReady
                ? 'Proceed to Seat Selection'
                : 'Select Cinema & Showtime',
            icon: isReady ? Icons.event_seat_rounded : null,
            isGradient: isReady,
            isOutlined: !isReady,
            isLoading: _isProceedLoading,
            onTap: isReady ? _proceed : null,
          ),
        ],
      ),
    );
  }
}

class _CinemaCard extends StatelessWidget {
  final Map<String, dynamic> cinema;
  final String cinemaId;
  final String selectedCinemaId;
  final String selectedTime;
  final int index;
  final Function(String time) onTimeSelected;

  const _CinemaCard({
    required this.cinema,
    required this.cinemaId,
    required this.selectedCinemaId,
    required this.selectedTime,
    required this.index,
    required this.onTimeSelected,
  });

  bool get _isSelected => selectedCinemaId == cinemaId;

  @override
  Widget build(BuildContext context) {
    R.init(context);
    final timings = List<String>.from(
      cinema['showTimings'] ?? [],
    );

    return AppCard(
      onTap: () {
        if (timings.isNotEmpty) {
          onTimeSelected(
            _isSelected ? selectedTime : timings.first,
          );
        }
      },
      borderRadius: 20,
      margin: const EdgeInsets.only(bottom: 14),
      borderColor:
          _isSelected ? appthemecolor : appthemecolor.withValues(alpha: 0.15),
      backgroundColor:
          _isSelected ? appthemecolor.withValues(alpha: 0.06) : surfaceColor,
      hasGlow: _isSelected,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Cinema initial avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: appthemecolor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: appthemecolor.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    (cinema['name'] ?? 'C')[0].toUpperCase(),
                    style: TextStyle(
                      color: appthemecolor,
                      fontSize: R.sp(22),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cinema['name'] ?? '',
                      style: TextStyle(
                        color: _isSelected ? appthemecolor : primaryColor,
                        fontSize: R.sp(15),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Gap(4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: secondaryColor,
                          size: R.sp(11),
                        ),
                        const Gap(3),
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
                    if (cinema['distance'] != null) ...[
                      const Gap(2),
                      Row(
                        children: [
                          const Icon(
                            Icons.directions_walk,
                            color: successColor,
                            size: 12,
                          ),
                          const Gap(3),
                          Text(
                            '${cinema['distance']} km away',
                            style: TextStyle(
                              color: successColor,
                              fontSize: R.sp(10),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (_isSelected)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: appthemecolor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.black,
                    size: 14,
                  ),
                ),
            ],
          ),
          const Gap(14),
          Container(
            height: 1,
            color: appthemecolor.withValues(alpha: 0.1),
          ),
          const Gap(14),
          Text(
            'Show Timings',
            style: TextStyle(
              color: secondaryColor,
              fontSize: R.sp(11),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: timings
                .map(
                  (time) => TimeChip(
                    time: time,
                    isSelected: _isSelected && selectedTime == time,
                    onTap: () => onTimeSelected(time),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    ).animate().fadeIn(
          delay: Duration(
            milliseconds: index * 80,
          ),
        );
  }
}
