import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:movieticket/utils/color.dart';
import 'package:movieticket/utils/constants.dart';
import 'package:movieticket/utils/responsive.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  int _selectedCategory = 0;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.apps},
    {'name': 'Sports', 'icon': Icons.sports_cricket},
    {'name': 'Parties', 'icon': Icons.celebration},
    {'name': 'Concerts', 'icon': Icons.music_note},
    {'name': 'Comedy', 'icon': Icons.theater_comedy},
  ];

  @override
  Widget build(BuildContext context) {
    R.init(context);
    R.init(context);
    R.init(context);
    R.init(context);
    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategoryFilter(),
                _buildFeaturedEvents(),
                _buildAllEvents(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: mobileBackgroundColor,
      floating: true,
      snap: true,
      title: Text(
        'Live Events',
        style: TextStyle(
          color: appthemecolor,
          fontSize: 20.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 45.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategory == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? appthemecolor : surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? appthemecolor
                      : appthemecolor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _categories[index]['icon'] as IconData,
                    size: 14,
                    color: isSelected ? mobileBackgroundColor : secondaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _categories[index]['name'] as String,
                    style: TextStyle(
                      color:
                          isSelected ? mobileBackgroundColor : secondaryColor,
                      fontSize: 12.sp,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildFeaturedEvents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Featured Events',
            style: TextStyle(
              color: primaryColor,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection(colEvents).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildShimmer();
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState('No featured events');
            }
            return SizedBox(
              height: 200.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final data =
                      snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  return _buildFeaturedCard(data, index);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeaturedCard(Map<String, dynamic> data, int index) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 260.w,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: appthemecolor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              data['logo'] != null
                  ? Image.network(
                      data['logo'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: surfaceColor,
                        child: const Icon(
                          Icons.event,
                          color: appthemecolor,
                          size: 40,
                        ),
                      ),
                    )
                  : Container(
                      color: surfaceColor,
                      child: const Icon(
                        Icons.event,
                        color: appthemecolor,
                        size: 40,
                      ),
                    ),
              Container(
                decoration: const BoxDecoration(gradient: heroGradient),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: appthemecolor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'LIVE',
                    style: TextStyle(
                      color: mobileBackgroundColor,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['logoname'] ?? '',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: appthemecolor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Book Now',
                            style: TextStyle(
                              color: mobileBackgroundColor,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: index * 100)),
    );
  }

  Widget _buildAllEvents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'All Events',
            style: TextStyle(
              color: primaryColor,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection(colEvents).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildListShimmer();
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState('No events available');
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final data =
                    snapshot.data!.docs[index].data() as Map<String, dynamic>;
                return _buildEventCard(data, index);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildEventCard(Map<String, dynamic> data, int index) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: appthemecolor.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: data['logo'] != null
                  ? Image.network(
                      data['logo'],
                      width: 90.w,
                      height: 100.h,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 90.w,
                        height: 100.h,
                        color: surfaceColor2,
                        child: const Icon(
                          Icons.event,
                          color: appthemecolor,
                        ),
                      ),
                    )
                  : Container(
                      width: 90.w,
                      height: 100.h,
                      color: surfaceColor2,
                      child: const Icon(
                        Icons.event,
                        color: appthemecolor,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['logoname'] ?? 'Event',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    if (data['date'] != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: appthemecolor,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            data['date'].toString(),
                            style: TextStyle(
                              color: secondaryColor,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                    if (data['venue'] != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: appthemecolor,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              data['venue'].toString(),
                              style: TextStyle(
                                color: secondaryColor,
                                fontSize: 11.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: appthemecolor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: appthemecolor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'Book Now',
                        style: TextStyle(
                          color: appthemecolor,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: index * 100)),
    );
  }

  Widget _buildShimmer() {
    return SizedBox(
      height: 200.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 3,
        itemBuilder: (context, index) => Container(
          width: 260.w,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildListShimmer() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) => Container(
        height: 100.h,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(
              Icons.event_busy,
              color: appthemecolor,
              size: 50,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: secondaryColor,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}




