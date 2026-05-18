import "dart:io";
import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:movieticket/utils/color.dart";
import "package:movieticket/utils/responsive.dart";
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class Ticket extends StatefulWidget {
  final dynamic snap;
  final String theatre;
  final String time;
  final String date;
  final int price;
  final List seat;
  final String theatreAdress;
  final String theatreicon;
  final String orderId;
  const Ticket({
    super.key,
    required this.date,
    required this.price,
    required this.snap,
    required this.theatre,
    required this.time,
    required this.seat,
    required this.theatreAdress,
    required this.theatreicon,
    required this.orderId,
  });

  @override
  State<Ticket> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<Ticket> {
  void download() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Text('Hello World!'),
        ),
      ),
    );

    final outPut = await getDownloadsDirectory();
    final bytes = await pdf.save(); // Await the result of pdf.save()
    String path = '${outPut!.path}/example.pdf';
    final file = File(path);
    await file.writeAsBytes(bytes); // Await the write operation
  }

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        title: const Text("My Ticket"),
        centerTitle: true,
        actions: [],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              Container(
                height: 680,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                widget.snap["Poster"],
                                height: 200,
                                fit: BoxFit.fill,
                              )),
                          SizedBox(
                            width: 20,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 30,
                              ),
                              Text(
                                widget.snap["moviename"],
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: R.sp(18),
                                    fontWeight: FontWeight.w600),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    "assets/clock.svg",
                                    colorFilter: const ColorFilter.mode(
                                      Colors.black,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Text(
                                      '${widget.snap["TimeInHours"]} hours ${widget.snap["TimeInMin"]} minutes',
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: R.sp(13),
                                          fontWeight: FontWeight.w400))
                                ],
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    "assets/video.svg",
                                    colorFilter: const ColorFilter.mode(
                                      Colors.black,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                        '${widget.snap["Type of movie"][0]}, ${widget.snap["Type of movie"][1]}',
                                        maxLines: 2,
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: R.sp(13),
                                            fontWeight: FontWeight.w400)),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 25,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  "assets/calendar.svg",
                                  colorFilter: const ColorFilter.mode(
                                    Color.fromARGB(255, 88, 87, 87),
                                    BlendMode.srcIn,
                                  ),
                                  height: 40,
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.time,
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: R.sp(14),
                                          fontWeight: FontWeight.w500),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      '${widget.date}.02.2024',
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: R.sp(14),
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  "assets/Seat Cinema.svg",
                                  height: 40,
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Screen 4",
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: R.sp(14),
                                          fontWeight: FontWeight.w500),
                                    ),
                                    SizedBox(
                                      height: 15,
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'Seat ',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: R.sp(14),
                                              fontWeight: FontWeight.w500),
                                        ),
                                        ...List.generate(
                                          widget.seat.length,
                                          (index) => Text(
                                            '${widget.seat[index]}, ',
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: R.sp(14),
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      const Divider(
                        color: Colors.black,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          SvgPicture.asset("assets/money-send.svg"),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            '₹${widget.price}.000',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: R.sp(16)),
                          )
                        ],
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SvgPicture.asset(
                            "assets/location.svg",
                            colorFilter: const ColorFilter.mode(
                              Colors.black,
                              BlendMode.srcIn,
                            ),
                            height: 25,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    widget.theatre,
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                        fontSize: R.sp(16)),
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Image.network(
                                    widget.theatreicon,
                                    height: 30,
                                    width: 40,
                                    fit: BoxFit.fill,
                                  )
                                ],
                              ),
                              Text(
                                widget.theatreAdress,
                                style: TextStyle(
                                    color: Colors.black, fontSize: R.sp(14)),
                              ),
                            ],
                          )
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SvgPicture.asset("assets/note.svg"),
                          SizedBox(
                            width: 10,
                          ),
                          const Expanded(
                              child: Text(
                            "Show this QR code to the ticket counter to recieve your ticket",
                            style: TextStyle(color: Colors.black),
                          ))
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      SvgPicture.asset("assets/dotted line.svg"),
                      SizedBox(
                        height: 10,
                      ),
                      Image.asset(
                        "assets/qr code.png",
                        height: 150,
                        width: 150,
                        fit: BoxFit.fill,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        'Order ID: ${widget.orderId}',
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w400),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
