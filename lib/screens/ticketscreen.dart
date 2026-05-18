import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/services/tmdb_service.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/responsive.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
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
  });

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  final TmdbService _tmdbService = TmdbService();
  late ConfettiController _confettiController;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _downloadTicket() async {
    setState(() => _isDownloading = true);
    try {
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
                borderRadius: const pw.BorderRadius.all(
                  pw.Radius.circular(12),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'FlixPoint',
                            style: pw.TextStyle(
                              fontSize: 32,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.amber,
                            ),
                          ),
                          pw.Text(
                            'Movie Ticket',
                            style: pw.TextStyle(
                              fontSize: 14,
                              color: PdfColors.grey,
                            ),
                          ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.amber,
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(6),
                          ),
                        ),
                        child: pw.Text(
                          'CONFIRMED',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
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
                  _pdfRow('Order ID', '#${widget.orderId}'),
                  _pdfRow('Cinema', widget.theatreName),
                  _pdfRow('Address', widget.theatreAddress),
                  _pdfRow('Date', widget.date),
                  _pdfRow('Time', widget.time),
                  _pdfRow('Seats', widget.seats.join(', ')),
                  _pdfRow(
                    'Tickets',
                    '${widget.seats.length} ticket${widget.seats.length > 1 ? 's' : ''}',
                  ),
                  pw.Divider(color: PdfColors.amber),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Total Amount',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '\u20B9${widget.amount}',
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
                      style: pw.TextStyle(
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
          text: 'My FlixPoint ticket for ${widget.movie.title}',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
    if (mounted) setState(() => _isDownloading = false);
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
              style: pw.TextStyle(
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
    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [appthemecolor, goldLight],
          ).createShader(bounds),
          child: Text(
            'Booking Confirmed',
            style: TextStyle(
              color: Colors.white,
              fontSize: R.sp(18),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: appthemecolor.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.home,
                color: appthemecolor,
                size: 18,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [
                appthemecolor,
                goldLight,
                Colors.white,
                goldDark,
              ],
              numberOfParticles: R.isPhone ? 25 : 40,
              gravity: 0.25,
              emissionFrequency: 0.05,
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: R.maxWidth),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(R.horizontalPadding),
                child: Column(
                  children: [
                    _buildSuccessHeader(),
                    const SizedBox(height: 24),
                    _buildTicketCard(),
                    const SizedBox(height: 20),
                    _buildDownloadButton(),
                    const SizedBox(height: 12),
                    _buildHomeButton(),
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

  Widget _buildSuccessHeader() {
    return Column(
      children: [
        Container(
          width: R.isPhone ? 80 : 100,
          height: R.isPhone ? 80 : 100,
          decoration: BoxDecoration(
            color: successColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: successColor,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: successColor.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.check_rounded,
            color: successColor,
            size: R.isPhone ? 40 : 50,
          ),
        )
            .animate()
            .scale(
              duration: 600.ms,
              curve: Curves.elasticOut,
            )
            .fadeIn(),
        const SizedBox(height: 16),
        Text(
          'Booking Confirmed!',
          style: TextStyle(
            color: primaryColor,
            fontSize: R.sp(24),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
        const SizedBox(height: 6),
        Text(
          'Your ticket is ready to use',
          style: TextStyle(
            color: secondaryColor,
            fontSize: R.sp(14),
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildTicketCard() {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: appthemecolor.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: appthemecolor.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl:
                      _tmdbService.getBackdropUrl(widget.movie.backdropPath),
                  width: double.infinity,
                  height: R.isPhone ? 160 : 200,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
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
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: successColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Confirmed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: R.sp(10),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
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
          _buildDashedDivider(),
          Padding(
            padding: EdgeInsets.all(R.px(16)),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ticketDetail(
                        Icons.location_on,
                        'Cinema',
                        widget.theatreName,
                      ),
                    ),
                    Expanded(
                      child: _ticketDetail(
                        Icons.calendar_today,
                        'Date',
                        widget.date,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ticketDetail(
                        Icons.access_time,
                        'Time',
                        widget.time,
                      ),
                    ),
                    Expanded(
                      child: _ticketDetail(
                        Icons.event_seat,
                        'Seats',
                        widget.seats.join(', '),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ticketDetail(
                        Icons.confirmation_num,
                        'Order ID',
                        '#${widget.orderId}',
                      ),
                    ),
                    Expanded(
                      child: _ticketDetail(
                        Icons.payment,
                        'Amount',
                        '\u20B9${widget.amount}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildDashedDivider(),
          Padding(
            padding: EdgeInsets.all(R.px(16)),
            child: Column(
              children: [
                Text(
                  'Scan QR at Cinema Entry',
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: R.sp(12),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
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
                        color: appthemecolor.withValues(alpha: 0.3),
                        blurRadius: 16,
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
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.bookingId,
                  style: TextStyle(
                    color: hintColor,
                    fontSize: R.sp(10),
                    letterSpacing: 2,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .slideY(
          begin: 0.3,
          duration: 600.ms,
          curve: Curves.easeOut,
        )
        .fadeIn(delay: 200.ms);
  }

  Widget _ticketDetail(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: appthemecolor, size: R.sp(12)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: secondaryColor,
                fontSize: R.sp(10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: primaryColor,
            fontSize: R.sp(12),
            fontWeight: FontWeight.w700,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDashedDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(
          40,
          (index) => Expanded(
            child: Container(
              height: 1,
              color: index % 2 == 0
                  ? appthemecolor.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadButton() {
    return GestureDetector(
      onTap: _isDownloading ? null : _downloadTicket,
      child: Container(
        height: 58,
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
        child: _isDownloading
            ? const CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 2,
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.download_rounded,
                    color: Colors.black,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Download & Share Ticket',
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
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2);
  }

  Widget _buildHomeButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: Container(
        height: 58,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: appthemecolor,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.home_rounded,
              color: appthemecolor,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Back to Home',
              style: TextStyle(
                color: appthemecolor,
                fontSize: R.sp(15),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2);
  }
}
