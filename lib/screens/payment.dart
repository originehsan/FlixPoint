import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/screens/ticketscreen.dart';
import 'package:movieticket/services/tmdb_service.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/constants.dart';
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
    _loadUpiApps();
  }

  void _loadUpiApps() {
    _upiIndia
        .getAllUpiApps(mandatoryTransactionId: false)
        .then((value) {
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
        final isUnique =
            await _isTransactionUnique(response.transactionId ?? '');
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
      await FirebaseFirestore.instance
          .runTransaction((transaction) async {
        final timingRef = FirebaseFirestore.instance
            .collection(colTimings)
            .doc(widget.timingDocId);
        final timingDoc = await transaction.get(timingRef);
        final currentBooked =
            List<String>.from(timingDoc.data()?['booked'] ?? []);
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
        transaction.set(timingRef, updates, SetOptions(merge: true));
        final bookingRef = FirebaseFirestore.instance
            .collection(colBookings)
            .doc(bookingId);
        transaction.set(bookingRef, {
          'bookingId': bookingId,
          'userId': userId,
          'movieId': widget.movie.id,
          'movieName': widget.movie.title,
          'moviePoster':
              _tmdbService.getPosterUrl(widget.movie.posterPath),
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
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TicketScreen(
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
          ),
        ),
      );
    } catch (e) {
      if (mounted) _showError('Booking failed: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: errorColor,
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
        title: Text(
          'Payment',
          style: TextStyle(
            color: primaryColor,
            fontSize: R.sp(18),
            fontWeight: FontWeight.w700,
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
                      const SizedBox(height: 16),
                      _buildOrderDetails(),
                      const SizedBox(height: 16),
                      _buildTotalSection(),
                      const SizedBox(height: 20),
                      _buildPaymentMethods(),
                      const SizedBox(height: 30),
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: appthemecolor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: appthemecolor.withValues(alpha: 0.3),
              ),
            ),
            child: const CircularProgressIndicator(
              color: appthemecolor,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Processing Payment...',
            style: TextStyle(
              color: primaryColor,
              fontSize: R.sp(18),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please do not close the app',
            style: TextStyle(
              color: secondaryColor,
              fontSize: R.sp(13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieCard() {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(R.cardRadius),
        border: Border.all(
          color: appthemecolor.withValues(alpha: 0.2),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(R.cardRadius),
              bottomLeft: Radius.circular(R.cardRadius),
            ),
            child: CachedNetworkImage(
              imageUrl:
                  _tmdbService.getPosterUrl(widget.movie.posterPath),
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
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.movie.title,
                    style: TextStyle(
                      color: appthemecolor,
                      fontSize: R.sp(16),
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  _detailRow(Icons.location_on, widget.theatreName),
                  const SizedBox(height: 5),
                  _detailRow(Icons.calendar_today, widget.date),
                  const SizedBox(height: 5),
                  _detailRow(Icons.access_time, widget.time),
                  const SizedBox(height: 5),
                  _detailRow(
                    Icons.event_seat,
                    widget.seats.join(', '),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: appthemecolor, size: R.sp(14)),
        const SizedBox(width: 6),
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

  Widget _buildOrderDetails() {
    return Container(
      padding: EdgeInsets.all(R.px(16)),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(R.cardRadius),
        border: Border.all(
          color: appthemecolor.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          _orderRow('Order ID', '#$_orderId'),
          Divider(
            color: appthemecolor.withValues(alpha: 0.1),
            height: 20,
          ),
          _orderRow('Seats', widget.seats.join(', ')),
          Divider(
            color: appthemecolor.withValues(alpha: 0.1),
            height: 20,
          ),
          _orderRow(
            'Tickets',
            '${widget.seats.length} ticket${widget.seats.length > 1 ? 's' : ''}',
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _orderRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: secondaryColor,
            fontSize: R.sp(13),
          ),
        ),
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
      padding: EdgeInsets.all(R.px(16)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            appthemecolor.withValues(alpha: 0.15),
            appthemecolor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(R.cardRadius),
        border: Border.all(
          color: appthemecolor.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: appthemecolor.withValues(alpha: 0.1),
            blurRadius: 12,
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
              Text(
                'Total Amount',
                style: TextStyle(
                  color: secondaryColor,
                  fontSize: R.sp(13),
                ),
              ),
              const SizedBox(height: 4),
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
            children: [
              Text(
                '\u20B9',
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
                  fontSize: R.sp(28),
                  fontWeight: FontWeight.w800,
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
            const SizedBox(width: 10),
            Text(
              'Pay via UPI',
              style: TextStyle(
                color: primaryColor,
                fontSize: R.sp(18),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(R.px(16)),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(R.cardRadius),
            border: Border.all(
              color: appthemecolor.withValues(alpha: 0.15),
              width: 0.5,
            ),
          ),
          child: _buildUpiApps(),
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
                  Icons.payment,
                  color: appthemecolor,
                  size: 40,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No UPI apps found',
                style: TextStyle(
                  color: secondaryColor,
                  fontSize: R.sp(14),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Please install a UPI app like GPay or PhonePe',
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
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                Image.memory(
                  app.icon,
                  height: 44,
                  width: 44,
                ),
                const SizedBox(height: 6),
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