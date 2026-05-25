import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/screens/ticketscreen.dart';
import 'package:movieticket/services/tmdb_service.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/constants.dart';
import 'package:movieticket/utils/page_transitions.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:movieticket/widgets/common/app_button.dart';
import 'package:movieticket/widgets/common/app_appbar.dart';
import 'package:movieticket/widgets/common/app_card.dart';
import 'package:movieticket/widgets/common/empty_state.dart';
import 'package:movieticket/widgets/common/app_loader.dart';
import 'package:movieticket/widgets/common/section_header.dart';
import 'package:movieticket/widgets/common/shimmer_box.dart';
import 'package:movieticket/widgets/common/app_snackbar.dart';
import 'package:movieticket/widgets/common/gold_divider.dart';
import 'package:movieticket/widgets/ticket/ticket_detail_widget.dart';
import 'package:upi_pay/upi_pay.dart';
import 'package:uuid/uuid.dart';

class PaymentScreen extends StatefulWidget {
  final TmdbMovie movie;
  final List<String> seats;
  final String theatreName;
  final String date;
  final String time;
  final int amount;
  final String theatreAddress;
  final String theatreIcon;
  final String cinemaId;
  final String timingDocId;
  final String passengerName;
  final String passengerEmail;

  const PaymentScreen({
    super.key,
    required this.movie,
    required this.amount,
    required this.seats,
    required this.date,
    required this.theatreName,
    required this.time,
    required this.theatreAddress,
    required this.theatreIcon,
    required this.cinemaId,
    required this.timingDocId,
    this.passengerName = '',
    this.passengerEmail = '',
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TmdbService _tmdbService = TmdbService();
  final _upiPay = UpiPay();
  List<ApplicationMeta>? _apps;
  bool _isProcessing = false;
  late String _orderId;

  @override
  void initState() {
    super.initState();
    _orderId = const Uuid().v4().substring(0, 8).toUpperCase();
    if (!kIsWeb) _loadUpiApps();
  }

  void _loadUpiApps() {
    _upiPay
        .getInstalledUpiApplications(
      statusType: UpiApplicationDiscoveryAppStatusType.all,
    )
        .then((value) {
      debugPrint('UPI apps found: ${value.length}');
      for (final app in value) {
        debugPrint('UPI app: ${app.upiApplication.getAppName()}');
      }
      if (mounted) setState(() => _apps = value);
    }).catchError((err) {
      debugPrint('UPI error: $err');
      if (mounted) setState(() => _apps = []);
    });
  }

  Future<void> _initiatePayment(ApplicationMeta app) async {
    setState(() => _isProcessing = true);

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() => _isProcessing = false);

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: appthemecolor.withValues(alpha: 0.3),
          ),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: appthemecolor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: app.iconImage(40),
            ),
            const Gap(16),
            Text(
              app.upiApplication.getAppName(),
              style: TextStyle(
                color: secondaryColor,
                fontSize: R.sp(12),
              ),
            ),
            const Gap(8),
            Text(
              '₹${widget.amount}',
              style: TextStyle(
                color: appthemecolor,
                fontSize: R.sp(36),
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const Gap(4),
            Text(
              'FlixPoint • ${widget.movie.title}',
              style: TextStyle(
                color: secondaryColor,
                fontSize: R.sp(12),
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surfaceColor2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_rounded,
                    color: appthemecolor,
                    size: 16,
                  ),
                  const Gap(8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paying to',
                          style: TextStyle(
                            color: secondaryColor,
                            fontSize: R.sp(10),
                          ),
                        ),
                        Text(
                          'FlixPoint Cinemas',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: R.sp(13),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: successColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: successColor,
                          size: 12,
                        ),
                        const Gap(4),
                        Text(
                          'Verified',
                          style: TextStyle(
                            color: successColor,
                            fontSize: R.sp(10),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: surfaceColor2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: appthemecolor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Decline',
                          style: TextStyle(
                            color: errorColor,
                            fontSize: R.sp(14),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [appthemecolor, goldLight],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: appthemecolor.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Pay Now',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: R.sp(14),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (confirm != true) return;

    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    await _confirmBooking(
      'DEMO_${_orderId}_${app.upiApplication.getAppName()}',
    );
  }

  Future<void> _demoBooking() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    await _confirmBooking('DEMO_$_orderId');
  }

  Future<bool> _isTransactionUnique(String transactionId) async {
    if (transactionId.isEmpty) return true;
    try {
      final query = await FirebaseFirestore.instance
          .collection(colBookings)
          .where('transactionId', isEqualTo: transactionId)
          .get();
      return query.docs.isEmpty;
    } catch (_) {
      return true;
    }
  }

  Future<void> _confirmBooking(String transactionId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (userId.isEmpty) {
      _showError('Session expired. Please login again.');
      if (mounted) setState(() => _isProcessing = false);
      return;
    }

    final bookingId = const Uuid().v4();
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final timingRef = FirebaseFirestore.instance
            .collection(colTimings)
            .doc(widget.timingDocId);
        final timingDoc = await transaction.get(timingRef);
        final currentBooked = List<String>.from(
          timingDoc.data()?['booked'] ?? [],
        );

        for (final seat in widget.seats) {
          if (currentBooked.contains(seat)) {
            throw Exception(
              'Seat $seat was just booked by someone else. Please select different seats.',
            );
          }
        }

        final updates = <String, dynamic>{};
        for (final seat in widget.seats) {
          currentBooked.add(seat);
          updates['locked.$seat'] = FieldValue.delete();
        }
        updates['booked'] = currentBooked;
        transaction.set(timingRef, updates, SetOptions(merge: true));

        final bookingRef = FirebaseFirestore.instance
            .collection(colBookings)
            .doc(bookingId);
        transaction.set(bookingRef, {
          'bookingId': bookingId,
          'userId': userId,
          'movieId': widget.movie.id,
          'movieName': widget.movie.title,
          'moviePoster': _tmdbService.getPosterUrl(widget.movie.posterPath),
          'cinemaId': widget.cinemaId,
          'cinemaName': widget.theatreName,
          'cinemaAddress': widget.theatreAddress,
          'seats': widget.seats,
          'amount': widget.amount,
          'date': widget.date,
          'time': widget.time,
          'status': 'confirmed',
          'orderId': _orderId,
          'transactionId': transactionId,
          'passengerName': widget.passengerName,
          'passengerEmail': widget.passengerEmail,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        AppRoutes.slideUpRoute(
          TicketScreen(
            bookingId: bookingId,
            movie: widget.movie,
            seats: widget.seats,
            theatreName: widget.theatreName,
            theatreAddress: widget.theatreAddress,
            theatreIcon: widget.theatreIcon,
            date: widget.date,
            time: widget.time,
            amount: widget.amount,
            orderId: _orderId,
            passengerEmail: widget.passengerEmail,
          ),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    AppSnackbar.error(context, message);
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return PopScope(
      canPop: !_isProcessing,
      child: Scaffold(
        backgroundColor: mobileBackgroundColor,
        appBar: AppAppBar(
          title: 'Payment',
          showBackButton: !_isProcessing,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: R.maxWidth),
            child: _isProcessing
                ? _buildProcessing()
                : SingleChildScrollView(
                    padding: EdgeInsets.all(R.horizontalPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMovieCard(),
                        const Gap(16),
                        if (widget.passengerName.isNotEmpty)
                          _buildPassengerCard(),
                        if (widget.passengerName.isNotEmpty) const Gap(16),
                        _buildOrderDetails(),
                        const Gap(16),
                        _buildTotalSection(),
                        const Gap(24),
                        kIsWeb
                            ? _buildWebPayment()
                            : _buildPaymentMethods(),
                        const Gap(30),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessing() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: appthemecolor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: appthemecolor.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: appthemecolor.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(child: AppLoader.large()),
          ),
          const Gap(24),
          Text(
            'Processing Payment...',
            style: TextStyle(
              color: primaryColor,
              fontSize: R.sp(18),
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(8),
          Text(
            'Please do not close the app',
            style: TextStyle(
              color: secondaryColor,
              fontSize: R.sp(13),
            ),
          ),
          const Gap(8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_rounded, color: successColor, size: 14),
              const Gap(6),
              Text(
                'Your transaction is secure',
                style: TextStyle(
                  color: successColor,
                  fontSize: R.sp(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMovieCard() {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: CachedNetworkImage(
              imageUrl: _tmdbService.getPosterUrl(widget.movie.posterPath),
              width: R.isPhone ? 90 : 110,
              height: R.isPhone ? 130 : 150,
              fit: BoxFit.cover,
              placeholder: (_, __) => ShimmerBox(
                width: R.isPhone ? 90 : 110,
                height: R.isPhone ? 130 : 150,
                borderRadius: 0,
              ),
              errorWidget: (_, __, ___) => Container(
                width: R.isPhone ? 90 : 110,
                height: R.isPhone ? 130 : 150,
                color: surfaceColor2,
                child: const Icon(Icons.movie, color: appthemecolor),
              ),
            ),
          ),
          const Gap(14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.movie.title,
                    style: TextStyle(
                      color: appthemecolor,
                      fontSize: R.sp(15),
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(10),
                  TicketDetailWidget(
                    icon: Icons.theaters_rounded,
                    label: 'Cinema',
                    value: widget.theatreName,
                  ),
                  const Gap(5),
                  TicketDetailWidget(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: widget.date,
                  ),
                  const Gap(5),
                  TicketDetailWidget(
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value: widget.time,
                  ),
                  const Gap(5),
                  TicketDetailWidget(
                    icon: Icons.event_seat_rounded,
                    label: 'Seats',
                    value: widget.seats.join(', '),
                  ),
                ],
              ),
            ),
          ),
          const Gap(12),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildPassengerCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: appthemecolor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: appthemecolor,
                  size: 16,
                ),
              ),
              const Gap(10),
              Text(
                'Passenger Details',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: R.sp(14),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Gap(12),
          TicketDetailWidget(
            icon: Icons.badge_rounded,
            label: 'Name',
            value: widget.passengerName,
            layout: TicketDetailLayout.row,
          ),
          const Gap(8),
          TicketDetailWidget(
            icon: Icons.email_outlined,
            label: 'Email',
            value: widget.passengerEmail,
            layout: TicketDetailLayout.row,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms);
  }

  Widget _buildOrderDetails() {
    return AppCard(
      child: Column(
        children: [
          TicketDetailWidget(
            icon: Icons.tag_rounded,
            label: 'Order ID',
            value: '#$_orderId',
            layout: TicketDetailLayout.row,
          ),
          const GoldDivider(margin: EdgeInsets.symmetric(vertical: 8)),
          TicketDetailWidget(
            icon: Icons.event_seat_rounded,
            label: 'Seats',
            value: widget.seats.join(', '),
            layout: TicketDetailLayout.row,
          ),
          const GoldDivider(margin: EdgeInsets.symmetric(vertical: 8)),
          TicketDetailWidget(
            icon: Icons.confirmation_num_rounded,
            label: 'Tickets',
            value:
                '${widget.seats.length} ticket${widget.seats.length > 1 ? 's' : ''}',
            layout: TicketDetailLayout.row,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildTotalSection() {
    return AppCard(
      backgroundColor: appthemecolor.withValues(alpha: 0.05),
      borderColor: appthemecolor.withValues(alpha: 0.4),
      hasGlow: true,
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.currency_rupee_rounded,
                    color: secondaryColor,
                    size: 14,
                  ),
                  const Gap(4),
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      color: secondaryColor,
                      fontSize: R.sp(13),
                    ),
                  ),
                ],
              ),
              const Gap(4),
              Text(
                '${widget.seats.length} ticket${widget.seats.length > 1 ? 's' : ''}',
                style: TextStyle(color: hintColor, fontSize: R.sp(11)),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹',
                style: TextStyle(
                  color: appthemecolor,
                  fontSize: R.sp(20),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${widget.amount}',
                style: TextStyle(
                  color: appthemecolor,
                  fontSize: R.sp(32),
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Pay via UPI'),
        AppCard(child: _buildUpiApps()),
      ],
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }

  Widget _buildWebPayment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Complete Payment'),
        AppCard(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: warningColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: warningColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: warningColor,
                      size: 18,
                    ),
                    const Gap(10),
                    Expanded(
                      child: Text(
                        'UPI payments are available on '
                        'Android & iOS only. Use the '
                        'button below to complete your '
                        'booking on web.',
                        style: TextStyle(
                          color: warningColor,
                          fontSize: R.sp(12),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(16),
              AppButton(
                label: 'Confirm Booking',
                icon: Icons.check_circle_rounded,
                height: 56,
                onTap: _demoBooking,
              ),
              const Gap(10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded, color: hintColor, size: 12),
                  const Gap(6),
                  Text(
                    'This is a demo for portfolio purposes',
                    style: TextStyle(color: hintColor, fontSize: R.sp(11)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }

  Widget _buildUpiApps() {
    if (_apps == null) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: AppLoader()),
      );
    }
    if (_apps!.isEmpty) {
      return const EmptyState(
        icon: Icons.payment_rounded,
        title: 'No UPI apps found',
        subtitle: 'Please install GPay, PhonePe or Paytm',
      );
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _apps!
          .map(
            (app) => _UpiAppTile(
              app: app,
              onTap: () => _initiatePayment(app),
            ),
          )
          .toList(),
    );
  }
}

class _UpiAppTile extends StatelessWidget {
  final ApplicationMeta app;
  final VoidCallback onTap;

  const _UpiAppTile({
    required this.app,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: R.isPhone ? 75 : 90,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: surfaceColor2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: appthemecolor.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            app.iconImage(44),
            const Gap(6),
            Text(
              app.upiApplication.getAppName(),
              style: TextStyle(color: primaryColor, fontSize: R.sp(10)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}