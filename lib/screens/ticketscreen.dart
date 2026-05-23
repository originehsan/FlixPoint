import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:lottie/lottie.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/services/tmdb_service.dart';
import 'package:movieticket/utils/booking_utils.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:movieticket/widgets/common/app_badge.dart';
import 'package:movieticket/widgets/common/app_button.dart';
import 'package:movieticket/widgets/common/appbar/app_appbar.dart';
import 'package:movieticket/widgets/common/cards/app_card.dart';
import 'package:movieticket/widgets/common/shimmer_box.dart';
import 'package:movieticket/widgets/common/snackbars/app_snackbar.dart';
import 'package:movieticket/widgets/ticket/dashed_divider.dart';
import 'package:movieticket/widgets/ticket/ticket_detail_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class TicketScreen extends StatefulWidget {
  final String bookingId;
  final TmdbMovie movie;
  final List<String> seats;
  final String theatreName;
  final String theatreAddress;
  final String theatreIcon;
  final String date;
  final String time;
  final int amount;
  final String orderId;
  final Map<String, String> seatPassengers;
  final String passengerEmail;

  const TicketScreen({
    super.key,
    required this.bookingId,
    required this.movie,
    required this.seats,
    required this.theatreName,
    required this.theatreAddress,
    required this.theatreIcon,
    required this.date,
    required this.time,
    required this.amount,
    required this.orderId,
    this.seatPassengers = const {},
    this.passengerEmail = '',
  });

  @override
  State<TicketScreen> createState() =>
      _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  final TmdbService _tmdbService = TmdbService();
  bool _isSharing = false;
  bool _lottieComplete = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(
      const Duration(milliseconds: 2800),
      () {
        if (mounted) {
          setState(() => _lottieComplete = true);
        }
      },
    );
  }

  Future<void> _shareTicket() async {
    setState(() => _isSharing = true);
    try {
      final passengersText = widget.seatPassengers.entries
          .map((e) => '  ${e.key} → ${e.value}')
          .join('\n');

      final shareText =
          'FlixPoint Ticket — ${widget.movie.title}\n\n'
          'Cinema: ${widget.theatreName}\n'
          'Date: ${widget.date}\n'
          'Time: ${widget.time}\n'
          'Seats: ${widget.seats.join(', ')}\n'
          '${passengersText.isNotEmpty ? 'Passengers:\n$passengersText\n' : ''}'
          'Order ID: #${widget.orderId}\n'
          'Amount: ₹${widget.amount}';

      if (kIsWeb) {
        await SharePlus.instance.share(
          ShareParams(text: shareText),
        );
      } else {
        final pdf = pw.Document();
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Container(
                padding: const pw.EdgeInsets.all(24),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.amber,
                    width: 2,
                  ),
                  borderRadius:
                      const pw.BorderRadius.all(
                    pw.Radius.circular(12),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment:
                      pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment:
                          pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment:
                              pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'FlixPoint',
                              style: pw.TextStyle(
                                fontSize: 32,
                                fontWeight:
                                    pw.FontWeight.bold,
                                color: PdfColors.amber,
                              ),
                            ),
                            pw.Text(
                              'Movie Ticket',
                              style: const pw.TextStyle(
                                fontSize: 14,
                                color: PdfColors.grey,
                              ),
                            ),
                          ],
                        ),
                        pw.Container(
                          padding:
                              const pw.EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.green,
                            borderRadius:
                                const pw.BorderRadius.all(
                              pw.Radius.circular(6),
                            ),
                          ),
                          child: pw.Text(
                            'CONFIRMED',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.Divider(color: PdfColors.amber),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      widget.movie.title,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    _pdfRow(
                      'Order ID',
                      '#${widget.orderId}',
                    ),
                    _pdfRow('Cinema', widget.theatreName),
                    _pdfRow(
                        'Address', widget.theatreAddress),
                    _pdfRow('Date', widget.date),
                    _pdfRow('Time', widget.time),
                    _pdfRow(
                      'Seats',
                      widget.seats.join(', '),
                    ),
                    if (widget
                        .seatPassengers.isNotEmpty) ...[
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Passengers:',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      ...widget.seatPassengers.entries
                          .map(
                            (e) => pw.Padding(
                              padding:
                                  const pw.EdgeInsets.only(
                                bottom: 4,
                                left: 8,
                              ),
                              child: pw.Text(
                                '${e.key}  →  ${e.value}',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ],
                    if (widget.passengerEmail.isNotEmpty)
                      _pdfRow('Email', widget.passengerEmail),
                    pw.Divider(color: PdfColors.amber),
                    pw.Row(
                      mainAxisAlignment:
                          pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Total Amount',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          '₹${widget.amount}',
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.amber,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 24),
                    pw.Center(
                      child: pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: widget.bookingId,
                        width: 140,
                        height: 140,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Center(
                      child: pw.Text(
                        'Booking ID: ${widget.bookingId}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Center(
                      child: pw.Text(
                        'Thank you for choosing FlixPoint!',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.amber,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );

        final dir = await getTemporaryDirectory();
        final file = File(
          '${dir.path}/FlixPoint_${widget.orderId}.pdf',
        );
        await file.writeAsBytes(await pdf.save());
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: shareText,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // AppSnackbar replaces ScaffoldMessenger
        AppSnackbar.error(
          context,
          'Error sharing ticket: ${e.toString()}',
        );
      }
    }
    if (mounted) setState(() => _isSharing = false);
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style: const pw.TextStyle(
                color: PdfColors.grey,
                fontSize: 12,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);

    final status = BookingUtils.getStatus(
      widget.date,
      widget.time,
    );
    final statusColor =
        BookingUtils.getStatusColor(status);
    final statusIcon =
        BookingUtils.getStatusIcon(status);
    final isExpired = status == BookingStatus.expired;
    final isToday = status == BookingStatus.today;
    final remaining = BookingUtils.timeRemaining(
      widget.date,
      widget.time,
    );

    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      // AppAppBar replaces custom ShaderMask AppBar
      appBar: AppAppBar(
        title: 'Booking Confirmed',
        showBackButton: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: R.maxWidth),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(R.horizontalPadding),
            child: Column(
              children: [
                _buildLottieHeader(),
                AnimatedOpacity(
                  duration:
                      const Duration(milliseconds: 600),
                  opacity: _lottieComplete ? 1.0 : 0.0,
                  child: AnimatedSlide(
                    duration:
                        const Duration(milliseconds: 600),
                    offset: _lottieComplete
                        ? Offset.zero
                        : const Offset(0, 0.3),
                    curve: Curves.easeOut,
                    child: Column(
                      children: [
                        _buildTicketCard(
                          statusColor,
                          statusIcon,
                          isExpired,
                          isToday,
                          remaining,
                        ),
                        const Gap(24),
                        _buildActionButtons(),
                        const Gap(30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLottieHeader() {
    return Column(
      children: [
        SizedBox(
          height: R.isPhone ? 180 : 220,
          child: Lottie.asset(
            'assets/lottie/success.json',
            repeat: false,
          ),
        ),
        Text(
          'Booking Confirmed!',
          style: TextStyle(
            color: primaryColor,
            fontSize: R.sp(24),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ).animate().fadeIn(delay: 600.ms).slideY(
              begin: 0.2,
            ),
        const Gap(6),
        Text(
          'Enjoy your movie experience',
          style: TextStyle(
            color: secondaryColor,
            fontSize: R.sp(14),
          ),
        ).animate().fadeIn(delay: 700.ms),
        const Gap(24),
      ],
    );
  }

  Widget _buildTicketCard(
    Color statusColor,
    IconData statusIcon,
    bool isExpired,
    bool isToday,
    String remaining,
  ) {
    // AppCard replaces custom Container
    return AppCard(
      borderRadius: 20,
      padding: EdgeInsets.zero,
      hasGlow: true,
      child: Column(
        children: [
          // Movie backdrop
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: _tmdbService.getBackdropUrl(
                    widget.movie.backdropPath,
                  ),
                  width: double.infinity,
                  height: R.isPhone ? 160 : 200,
                  fit: BoxFit.cover,
                  // ShimmerBox replaces plain Container placeholder
                  placeholder: (_, __) => ShimmerBox(
                    width: double.infinity,
                    height: R.isPhone ? 160 : 200,
                    borderRadius: 0,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: R.isPhone ? 160 : 200,
                    color: surfaceColor2,
                    child: const Icon(
                      Icons.movie,
                      color: appthemecolor,
                      size: 50,
                    ),
                  ),
                ),
                Container(
                  height: R.isPhone ? 160 : 200,
                  decoration: const BoxDecoration(
                    gradient: heroGradient,
                  ),
                ),
                // AppBadge replaces Confirmed badge Container
                Positioned(
                  top: 12,
                  right: 12,
                  child: AppBadge(
                    label: 'Confirmed',
                    icon: Icons.check_circle_rounded,
                    color: successColor,
                    hasGlow: true,
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 16,
                  right: 16,
                  child: Text(
                    widget.movie.title,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: R.sp(20),
                      fontWeight: FontWeight.w800,
                      shadows: const [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const DashedDivider(),

          Padding(
            padding: EdgeInsets.all(R.px(16)),
            child: Column(
              children: [
                // Cinema name section
                AppCard(
                  backgroundColor: appthemecolor
                      .withValues(alpha: 0.06),
                  borderColor: appthemecolor
                      .withValues(alpha: 0.2),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.theaters_rounded,
                        color: appthemecolor,
                        size: 18,
                      ),
                      const Gap(10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.theatreName,
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: R.sp(14),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (widget.theatreAddress
                                .isNotEmpty)
                              Text(
                                widget.theatreAddress,
                                style: TextStyle(
                                  color: secondaryColor,
                                  fontSize: R.sp(10),
                                ),
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Gap(14),

                // Date and time using TicketDetailWidget
                Row(
                  children: [
                    Expanded(
                      child: TicketDetailWidget(
                        icon: Icons.calendar_today_rounded,
                        label: 'Date',
                        value: widget.date,
                      ),
                    ),
                    Expanded(
                      child: TicketDetailWidget(
                        icon: Icons.access_time_rounded,
                        label: 'Time',
                        value: widget.time,
                      ),
                    ),
                  ],
                ),

                const Gap(14),

                // Order ID and amount
                Row(
                  children: [
                    Expanded(
                      child: TicketDetailWidget(
                        icon:
                            Icons.confirmation_num_rounded,
                        label: 'Order ID',
                        value: '#${widget.orderId}',
                      ),
                    ),
                    Expanded(
                      child: TicketDetailWidget(
                        icon: Icons.currency_rupee_rounded,
                        label: 'Amount',
                        value: '₹${widget.amount}',
                      ),
                    ),
                  ],
                ),

                const Gap(14),

                // Passengers section
                if (widget.seatPassengers.isNotEmpty) ...[
                  AppCard(
                    backgroundColor: appthemecolor
                        .withValues(alpha: 0.06),
                    borderColor: appthemecolor
                        .withValues(alpha: 0.15),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.people_rounded,
                              color: appthemecolor,
                              size: 14,
                            ),
                            const Gap(6),
                            Text(
                              'Passengers',
                              style: TextStyle(
                                color: secondaryColor,
                                fontSize: R.sp(11),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Gap(10),
                        ...widget.seatPassengers.entries
                            .map(
                              (entry) => Padding(
                                padding:
                                    const EdgeInsets.only(
                                  bottom: 6,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration:
                                          BoxDecoration(
                                        color: appthemecolor
                                            .withValues(
                                                alpha: 0.15),
                                        borderRadius:
                                            BorderRadius
                                                .circular(6),
                                        border: Border.all(
                                          color: appthemecolor
                                              .withValues(
                                                  alpha: 0.3),
                                        ),
                                      ),
                                      child: Text(
                                        entry.key,
                                        style: TextStyle(
                                          color:
                                              appthemecolor,
                                          fontSize: R.sp(10),
                                          fontWeight:
                                              FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const Gap(8),
                                    const Icon(
                                      Icons
                                          .arrow_forward_rounded,
                                      color: secondaryColor,
                                      size: 12,
                                    ),
                                    const Gap(8),
                                    Expanded(
                                      child: Text(
                                        entry.value,
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: R.sp(12),
                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        if (widget.passengerEmail
                            .isNotEmpty) ...[
                          Divider(
                            color: appthemecolor
                                .withValues(alpha: 0.1),
                            height: 12,
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.email_outlined,
                                color: secondaryColor,
                                size: 12,
                              ),
                              const Gap(6),
                              Text(
                                widget.passengerEmail,
                                style: TextStyle(
                                  color: secondaryColor,
                                  fontSize: R.sp(11),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Gap(14),
                ],
              ],
            ),
          ),

          const DashedDivider(),

          // QR code section
          Padding(
            padding: EdgeInsets.all(R.px(16)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: appthemecolor,
                      size: 16,
                    ),
                    const Gap(8),
                    Text(
                      'Scan QR at Cinema Entry',
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: R.sp(12),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: appthemecolor,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: appthemecolor
                            .withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: widget.bookingId,
                    version: QrVersions.auto,
                    size: R.isPhone ? 140 : 180,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.black,
                    ),
                    dataModuleStyle:
                        const QrDataModuleStyle(
                      dataModuleShape:
                          QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                  ),
                ),
                const Gap(10),
                Text(
                  widget.bookingId,
                  style: TextStyle(
                    color: hintColor,
                    fontSize: R.sp(10),
                    letterSpacing: 2,
                    fontFamily: 'monospace',
                  ),
                ),
                const Gap(10),
                // AppBadge replaces status badge Container
                AppBadge(
                  label: isExpired
                      ? 'Show has ended'
                      : isToday
                          ? 'Show today — $remaining'
                          : 'Show $remaining',
                  icon: statusIcon,
                  color: statusColor,
                  hasGlow: !isExpired,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // AppButton replaces Share GestureDetector+Container
        Expanded(
          child: AppButton(
            label: 'Share Ticket',
            icon: Icons.share_rounded,
            isLoading: _isSharing,
            height: 56,
            onTap: _shareTicket,
          ),
        ),
        const Gap(12),
        // AppButton replaces Done GestureDetector+Container
        Expanded(
          child: AppButton(
            label: 'Done',
            icon: Icons.check_circle_rounded,
            isGradient: false,
            isOutlined: true,
            height: 56,
            onTap: () => Navigator.of(context)
                .popUntil((route) => route.isFirst),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2);
  }
}