import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/screens/payment.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/page_transitions.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:movieticket/widgets/text_field.dart';

class PassengerDetailsScreen extends StatefulWidget {
  final TmdbMovie movie;
  final List<String> seats;
  final String theatreName;
  final String theatreAddress;
  final String theatreIcon;
  final String date;
  final String time;
  final int amount;
  final String cinemaId;
  final String timingDocId;

  const PassengerDetailsScreen({
    super.key,
    required this.movie,
    required this.seats,
    required this.theatreName,
    required this.theatreAddress,
    required this.theatreIcon,
    required this.date,
    required this.time,
    required this.amount,
    required this.cinemaId,
    required this.timingDocId,
  });

  @override
  State<PassengerDetailsScreen> createState() =>
      _PassengerDetailsScreenState();
}

class _PassengerDetailsScreenState
    extends State<PassengerDetailsScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _proceed() {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all fields'),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // Basic email validation
    if (!_emailController.text.contains('@') ||
        !_emailController.text.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter a valid email address'),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      AppRoutes.slideUpRoute(
        PaymentScreen(
          movie: widget.movie,
          amount: widget.amount,
          seats: widget.seats,
          date: widget.date,
          time: widget.time,
          theatreName: widget.theatreName,
          theatreAddress: widget.theatreAddress,
          theatreIcon: widget.theatreIcon,
          cinemaId: widget.cinemaId,
          timingDocId: widget.timingDocId,
          passengerName: _nameController.text.trim(),
          passengerEmail: _emailController.text.trim(),
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
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
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
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [appthemecolor, goldLight],
          ).createShader(bounds),
          child: Text(
            'Passenger Details',
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
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: R.horizontalPadding,
            ),
            child: Column(
              children: [
                Gap(R.px(24)),

                // Booking summary card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: appthemecolor.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: appthemecolor
                            .withValues(alpha: 0.08),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.movie.title,
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: R.sp(15),
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(12),
                      _summaryRow(
                        Icons.theaters_rounded,
                        'Cinema',
                        widget.theatreName,
                      ),
                      const Gap(8),
                      _summaryRow(
                        Icons.event_seat_rounded,
                        'Seats',
                        widget.seats.join(', '),
                      ),
                      const Gap(8),
                      Row(
                        children: [
                          Expanded(
                            child: _summaryRow(
                              Icons.calendar_today_rounded,
                              'Date',
                              widget.date,
                            ),
                          ),
                          const Gap(16),
                          Expanded(
                            child: _summaryRow(
                              Icons.access_time_rounded,
                              'Time',
                              widget.time,
                            ),
                          ),
                        ],
                      ),
                      const Gap(8),
                      _summaryRow(
                        Icons.currency_rupee_rounded,
                        'Amount',
                        '₹${widget.amount}',
                        valueColor: appthemecolor,
                      ),
                    ],
                  ),
                ),

                Gap(R.px(20)),

                // Info banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: appthemecolor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: appthemecolor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: appthemecolor,
                        size: 18,
                      ),
                      const Gap(10),
                      Expanded(
                        child: Text(
                          'Your booking confirmation will be sent to the email address below.',
                          style: TextStyle(
                            color: secondaryColor,
                            fontSize: R.sp(12),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Gap(R.px(28)),

                // Name field
                _fieldLabel('Full Name'),
                Gap(R.px(8)),
                TextFieldInput(
                  textEditingController: _nameController,
                  hintText: 'Enter your full name',
                  textInputType: TextInputType.name,
                  prefixIcon: Icons.person_outline_rounded,
                ),

                Gap(R.px(16)),

                // Email field
                _fieldLabel('Email Address'),
                Gap(R.px(8)),
                TextFieldInput(
                  textEditingController: _emailController,
                  hintText: 'Enter your email',
                  textInputType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                ),

                Gap(R.px(32)),

                // Proceed button
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.3, end: 1.0),
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: appthemecolor
                                .withValues(alpha: 0.4 * value),
                            blurRadius: 20 * value,
                            spreadRadius: 2 * value,
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: GestureDetector(
                    onTap: _proceed,
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
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.confirmation_num_rounded,
                            color: Colors.black,
                            size: 20,
                          ),
                          const Gap(10),
                          Text(
                            'Proceed to Payment',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: R.sp(16),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Gap(R.px(30)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: appthemecolor, size: R.sp(14)),
        const Gap(8),
        Text(
          '$label: ',
          style: TextStyle(
            color: secondaryColor,
            fontSize: R.sp(12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? primaryColor,
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

  Widget _fieldLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: TextStyle(
          color: secondaryColor,
          fontSize: R.sp(12),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}