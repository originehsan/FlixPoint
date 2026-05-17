import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:movieticket/models/tmdb_movie.dart';
import 'package:movieticket/services/tmdb_service.dart';
import 'package:movieticket/utils/color.dart';
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
      duration: const Duration(seconds: 3),
    );
    // Start confetti after slight delay
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
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.amber),
                borderRadius: const pw.BorderRadius.all(
                  pw.Radius.circular(12),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'FlixPoint',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.amber,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Movie Ticket',
                    style: pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.grey,
                    ),
                  ),
                  pw.Divider(color: PdfColors.amber),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    widget.movie.title,
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 16),
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
                        '₹${widget.amount}',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.amber,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Center(
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: widget.bookingId,
                      width: 120,
                      height: 120,
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

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My FlixPoint ticket for ${widget.movie.title}',
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
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
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
    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        automaticallyImplyLeading: false,
        title: Text(
          'Booking Confirmed',
          style: TextStyle(
            color: appthemecolor,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: appthemecolor),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Confetti
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
              numberOfParticles: 30,
              gravity: 0.3,
            ),
          ),

          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Success icon
                _buildSuccessHeader(),
                const SizedBox(height: 20),

                // Ticket card
                _buildTicketCard(),
                const SizedBox(height: 20),

                // Download button
                _buildDownloadButton(),
                const SizedBox(height: 12),

                // Home button
                _buildHomeButton(),
                const SizedBox(height: 30),
              ],
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
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: successColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: successColor, width: 2),
          ),
          child: const Icon(
            Icons.check,
            color: successColor,
            size: 40,
          ),
        )
            .animate()
            .scale(
              duration: 500.ms,
              curve: Curves.elasticOut,
            )
            .fadeIn(),
        const SizedBox(height: 12),
        Text(
          'Booking Confirmed!',
          style: TextStyle(
            color: primaryColor,
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
          ),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 4),
        Text(
          'Your ticket is ready',
          style: TextStyle(
            color: secondaryColor,
            fontSize: 13.sp,
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
      ),
      child: Column(
        children: [
          // Movie poster section
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: _tmdbService
                      .getBackdropUrl(widget.movie.backdropPath),
                  width: double.infinity,
                  height: 160.h,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    height: 160.h,
                    color: surfaceColor2,
                    child: const Icon(
                      Icons.movie,
                      color: appthemecolor,
                      size: 50,
                    ),
                  ),
                ),
                Container(
                  height: 160.h,
                  decoration: const BoxDecoration(
                    gradient: heroGradient,
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 16,
                  child: Text(
                    widget.movie.title,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Dashed divider
          _buildDashedDivider(),

          // Ticket details
          Padding(
            padding: const EdgeInsets.all(16),
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
                        '₹${widget.amount}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Dashed divider
          _buildDashedDivider(),

          // QR Code
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Scan at Cinema',
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 12.sp,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: appthemecolor,
                      width: 2,
                    ),
                  ),
                  child: QrImageView(
                    data: widget.bookingId,
                    version: QrVersions.auto,
                    size: 140,
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
                const SizedBox(height: 8),
                Text(
                  widget.bookingId,
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 10.sp,
                    letterSpacing: 1,
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
          duration: 500.ms,
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
            Icon(icon, color: appthemecolor, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: secondaryColor,
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: primaryColor,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
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
          30,
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
        height: 55.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: appthemecolor,
          borderRadius: BorderRadius.circular(30),
        ),
        alignment: Alignment.center,
        child: _isDownloading
            ? const CircularProgressIndicator(
                color: Colors.black,
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.download,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Download & Share Ticket',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildHomeButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: Container(
        height: 55.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.transparent,
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
            const Icon(
              Icons.home,
              color: appthemecolor,
            ),
            const SizedBox(width: 8),
            Text(
              'Back to Home',
              style: TextStyle(
                color: appthemecolor,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 700.ms);
  }
}