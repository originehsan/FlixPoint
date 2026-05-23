import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/screens/payment.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/page_transitions.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:movieticket/widgets/common/app_button.dart';
import 'package:movieticket/widgets/common/appbar/app_appbar.dart';
import 'package:movieticket/widgets/common/cards/app_card.dart';
import 'package:movieticket/widgets/common/snackbars/app_snackbar.dart';
import 'package:movieticket/widgets/common/spacing/gold_divider.dart';
import 'package:movieticket/widgets/text_field.dart';
import 'package:movieticket/widgets/ticket/ticket_detail_widget.dart';

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
  State<PassengerDetailsScreen> createState() => _PassengerDetailsScreenState();
}

class _PassengerDetailsScreenState extends State<PassengerDetailsScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _proceed() {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      // AppSnackbar replaces ScaffoldMessenger
      AppSnackbar.error(
        context,
        'Please fill all fields',
      );
      return;
    }

    if (!_emailController.text.contains('@') ||
        !_emailController.text.contains('.')) {
      AppSnackbar.error(
        context,
        'Enter a valid email address',
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
      // AppAppBar replaces custom ShaderMask AppBar
      appBar: AppAppBar(
        title: 'Passenger Details',
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
                _buildBookingSummary(),
                Gap(R.px(20)),
                _buildInfoBanner(),
                Gap(R.px(28)),
                _buildFields(),
                Gap(R.px(32)),
                _buildProceedButton(),
                Gap(R.px(30)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingSummary() {
    // AppCard replaces custom Container
    return AppCard(
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
          // TicketDetailWidget replaces _summaryRow()
          TicketDetailWidget(
            icon: Icons.theaters_rounded,
            label: 'Cinema',
            value: widget.theatreName,
            layout: TicketDetailLayout.row,
          ),
          const GoldDivider(
            margin: EdgeInsets.symmetric(vertical: 6),
          ),
          TicketDetailWidget(
            icon: Icons.event_seat_rounded,
            label: 'Seats',
            value: widget.seats.join(', '),
            layout: TicketDetailLayout.row,
          ),
          const GoldDivider(
            margin: EdgeInsets.symmetric(vertical: 6),
          ),
          Row(
            children: [
              Expanded(
                child: TicketDetailWidget(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date',
                  value: widget.date,
                  layout: TicketDetailLayout.row,
                ),
              ),
              const Gap(16),
              Expanded(
                child: TicketDetailWidget(
                  icon: Icons.access_time_rounded,
                  label: 'Time',
                  value: widget.time,
                  layout: TicketDetailLayout.row,
                ),
              ),
            ],
          ),
          const GoldDivider(
            margin: EdgeInsets.symmetric(vertical: 6),
          ),
          // valueColor supported via updated
          // TicketDetailWidget
          TicketDetailWidget(
            icon: Icons.currency_rupee_rounded,
            label: 'Amount',
            value: '₹${widget.amount}',
            layout: TicketDetailLayout.row,
            valueColor: appthemecolor,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    // AppCard replaces custom Container
    return AppCard(
      backgroundColor: appthemecolor.withValues(alpha: 0.06),
      borderColor: appthemecolor.withValues(alpha: 0.2),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: appthemecolor,
            size: 18,
          ),
          const Gap(10),
          Expanded(
            child: Text(
              'Your booking confirmation will be sent '
              'to the email address below.',
              style: TextStyle(
                color: secondaryColor,
                fontSize: R.sp(12),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Full Name',
          style: TextStyle(
            color: secondaryColor,
            fontSize: R.sp(12),
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(R.px(8)),
        TextFieldInput(
          textEditingController: _nameController,
          hintText: 'Enter your full name',
          textInputType: TextInputType.name,
          prefixIcon: Icons.person_outline_rounded,
        ),
        Gap(R.px(16)),
        Text(
          'Email Address',
          style: TextStyle(
            color: secondaryColor,
            fontSize: R.sp(12),
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(R.px(8)),
        TextFieldInput(
          textEditingController: _emailController,
          hintText: 'Enter your email',
          textInputType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
        ),
      ],
    );
  }

  Widget _buildProceedButton() {
    // TweenAnimationBuilder kept for pulsing glow
    // AppButton used inside for consistency
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: appthemecolor.withValues(alpha: 0.4 * value),
                blurRadius: 20 * value,
                spreadRadius: 2 * value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: AppButton(
        label: 'Proceed to Payment',
        icon: Icons.confirmation_num_rounded,
        height: 56,
        onTap: _proceed,
      ),
    );
  }
}
