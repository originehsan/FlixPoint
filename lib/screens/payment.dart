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
import 'package:upi_india/upi_india.dart';
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
  final UpiIndia _upiIndia = UpiIndia();
  final TmdbService _tmdbService = TmdbService();
  List<UpiApp>? _apps;
  bool _isProcessing = false;
  late String _orderId;

  @override
  void initState() {
    super.initState();
    _orderId = const Uuid().v4().substring(0, 8).toUpperCase();
    if (!kIsWeb) _loadUpiApps();
  }

  void _loadUpiApps() {
    _upiIndia.getAllUpiApps(mandatoryTransactionId: false).then((value) {
      if (mounted) setState(() => _apps = value);
    }).catchError((err) {
      if (mounted) setState(() => _apps = []);
    });
  }

  Future<void> _initiatePayment(UpiApp app) async {
    setState(() => _isProcessing = true);
    try {
      final response = await _upiIndia.startTransaction(
        app: app,
        receiverUpiId: upiId,
        receiverName: upiName,
        transactionRefId:
            'FP_${_orderId}_${DateTime.now().millisecondsSinceEpoch}',
        transactionNote: 'FlixPoint - ${widget.movie.title}',
        amount: widget.amount.toDouble(),
      );
      if (!mounted) return;
      if (response.status == UpiPaymentStatus.SUCCESS) {
        final isUnique = await _isTransactionUnique(
          response.transactionId ?? '',
        );
        if (isUnique) {
          await _confirmBooking(response.transactionId ?? '');
        } else {
          _showError('Duplicate transaction detected');
        }
      } else if (response.status == UpiPaymentStatus.FAILURE) {
        _showError('Payment failed. Please try again.');
      } else {
        _showError('Payment status unknown. Contact support.');
      }
    } catch (e) {
      if (mounted) _showError('Payment error: ${e.toString()}');
    }
    if (mounted) setState(() => _isProcessing = false);
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
    } catch (e) {
      return true;
    }
  }

  Future<void> _confirmBooking(String transactionId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
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
            throw Exception('Seat $seat already booked');
          }
        }
        final updates = <String, dynamic>{};
        for (final seat in widget.seats) {
          currentBooked.add(seat);
          updates['locked.$seat'] = FieldValue.delete();
        }
        updates['booked'] = currentBooked;
        transaction.set(
          timingRef,
          updates,
          SetOptions(merge: true),
        );
        final bookingRef =
            FirebaseFirestore.instance.collection(colBookings).doc(bookingId);
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
      Navigator.pushReplacement(
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
      );
    } catch (e) {
      if (mounted) _showError('Booking failed: ${e.toString()}');
    }
    if (mounted) setState(() => _isProcessing = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: appthemecolor.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: appthemecolor,
                size: 16,
              ),
            ),
          ),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [appthemecolor, goldLight],
          ).createShader(bounds),
          child: Text(
            'Payment',
            style: TextStyle(
              color: Colors.white,
              fontSize: R.sp(18),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        centerTitle: true,
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
                      kIsWeb ? _buildWebPayment() : _buildPaymentMethods(),
                      const Gap(30),
                    ],
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
            child: const CircularProgressIndicator(
              color: appthemecolor,
              strokeWidth: 2,
            ),
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
              const Icon(
                Icons.lock_rounded,
                color: successColor,
                size: 14,
              ),
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
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: appthemecolor.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: appthemecolor.withValues(alpha: 0.05),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
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
              errorWidget: (context, url, error) => Container(
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
                  _detailRow(Icons.theaters_rounded, widget.theatreName),
                  const Gap(5),
                  _detailRow(Icons.calendar_today_rounded, widget.date),
                  const Gap(5),
                  _detailRow(Icons.access_time_rounded, widget.time),
                  const Gap(5),
                  _detailRow(
                    Icons.event_seat_rounded,
                    widget.seats.join(', '),
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

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: appthemecolor, size: R.sp(13)),
        const Gap(6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: secondaryColor,
              fontSize: R.sp(11),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPassengerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: appthemecolor.withValues(alpha: 0.2),
        ),
      ),
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
          _passengerRow(Icons.badge_rounded, 'Name', widget.passengerName),
          const Gap(8),
          _passengerRow(Icons.email_outlined, 'Email', widget.passengerEmail),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms);
  }

  Widget _passengerRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: secondaryColor, size: R.sp(14)),
        const Gap(8),
        Text(
          '$label:',
          style: TextStyle(
            color: secondaryColor,
            fontSize: R.sp(12),
          ),
        ),
        const Gap(8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: primaryColor,
              fontSize: R.sp(12),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: appthemecolor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          _orderRow(Icons.tag_rounded, 'Order ID', '#$_orderId'),
          Divider(
            color: appthemecolor.withValues(alpha: 0.1),
            height: 20,
          ),
          _orderRow(
            Icons.event_seat_rounded,
            'Seats',
            widget.seats.join(', '),
          ),
          Divider(
            color: appthemecolor.withValues(alpha: 0.1),
            height: 20,
          ),
          _orderRow(
            Icons.confirmation_num_rounded,
            'Tickets',
            '${widget.seats.length} ticket${widget.seats.length > 1 ? 's' : ''}',
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _orderRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: appthemecolor, size: R.sp(14)),
        const Gap(8),
        Text(
          label,
          style: TextStyle(
            color: secondaryColor,
            fontSize: R.sp(13),
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: primaryColor,
              fontSize: R.sp(13),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            appthemecolor.withValues(alpha: 0.15),
            appthemecolor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: appthemecolor.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: appthemecolor.withValues(alpha: 0.1),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
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
                style: TextStyle(
                  color: hintColor,
                  fontSize: R.sp(11),
                ),
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
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: appthemecolor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(10),
            Text(
              'Pay via UPI',
              style: TextStyle(
                color: primaryColor,
                fontSize: R.sp(16),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Gap(12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: appthemecolor.withValues(alpha: 0.15),
            ),
          ),
          child: _buildUpiApps(),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }

  Widget _buildWebPayment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: appthemecolor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(10),
            Text(
              'Complete Payment',
              style: TextStyle(
                color: primaryColor,
                fontSize: R.sp(16),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Gap(12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: appthemecolor.withValues(alpha: 0.2),
            ),
          ),
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
                        'UPI payments are available on Android & iOS only. Use the button below to complete your booking on web.',
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
              GestureDetector(
                onTap: _demoBooking,
                child: Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [appthemecolor, goldDark],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: appthemecolor.withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.black,
                        size: 20,
                      ),
                      const Gap(10),
                      Text(
                        'Confirm Booking',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: R.sp(15),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_rounded,
                    color: hintColor,
                    size: 12,
                  ),
                  const Gap(6),
                  Text(
                    'This is a demo for portfolio purposes',
                    style: TextStyle(
                      color: hintColor,
                      fontSize: R.sp(11),
                    ),
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: appthemecolor),
        ),
      );
    }
    if (_apps!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: appthemecolor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.payment_rounded,
                  color: appthemecolor,
                  size: 36,
                ),
              ),
              const Gap(12),
              Text(
                'No UPI apps found',
                style: TextStyle(
                  color: secondaryColor,
                  fontSize: R.sp(14),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(6),
              Text(
                'Please install GPay, PhonePe or Paytm',
                style: TextStyle(
                  color: hintColor,
                  fontSize: R.sp(11),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _apps!.map((app) {
        return GestureDetector(
          onTap: () => _initiatePayment(app),
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
                Image.memory(app.icon, height: 44, width: 44),
                const Gap(6),
                Text(
                  app.name,
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: R.sp(10),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
