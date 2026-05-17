import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    {'name': 'All', 'icon': Icons.apps_rounded},
    {'name': 'Sports', 'icon': Icons.sports_cricket_rounded},
    {'name': 'Parties', 'icon': Icons.celebration_rounded},
    {'name': 'Concerts', 'icon': Icons.music_note_rounded},
    {'name': 'Comedy', 'icon': Icons.theater_comedy_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    R.init(context);
    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: R.maxWidth),
          child: CustomScrollView(
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
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: mobileBackgroundColor,
      floating: true,
      snap: true,
      elevation: 0,
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [appthemecolor, goldLight],
        ).createShader(bounds),
        child: Text(
          'Live Events',
          style: TextStyle(
            color: Colors.white,
            fontSize: R.sp(20),
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: R.horizontalPadding,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategory == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 8),
              padding: EdgeInsets.symmetric(
                horizontal: R.px(14),
              ),
              decoration: BoxDecoration(
                color: isSelected ? appthemecolor : surfaceColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? appthemecolor
                      : appthemecolor.withValues(alpha: 0.2),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: appthemecolor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _categories[index]['icon'] as IconData,
                    size: R.sp(14),
                    color: isSelected
                        ? mobileBackgroundColor
                        : secondaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _categories[index]['name'] as String,
                    style: TextStyle(
                      color: isSelected
                          ? mobileBackgroundColor
                          : secondaryColor,
                      fontSize: R.sp(12),
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        R.horizontalPadding, 16,
        R.horizontalPadding, 10,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: appthemecolor,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: appthemecolor.withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: primaryColor,
              fontSize: R.sp(18),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedEvents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Featured Events'),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(colEvents)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return _buildShimmer();
            }
            if (!snapshot.hasData ||
                snapshot.data!.docs.isEmpty) {
              return _buildEmptyState('No featured events');
            }
            return SizedBox(
              height: R.isPhone ? 200 : 250,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(
                  horizontal: R.horizontalPadding,
                ),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final data = snapshot.data!.docs[index].data()
                      as Map<String, dynamic>;
                  return _buildFeaturedCard(data, index);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeaturedCard(
      Map<String, dynamic> data, int index) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: R.isPhone ? 260 : 320,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(R.cardRadius),
          border: Border.all(
            color: appthemecolor.withValues(alpha: 0.3),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(R.cardRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              data['logo'] != null
                  ? Image.network(
                      data['logo'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
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
                decoration: const BoxDecoration(
                  gradient: heroGradient,
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: appthemecolor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: appthemecolor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: mobileBackgroundColor,
                          fontSize: R.sp(9),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
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
                        fontSize: R.sp(16),
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: appthemecolor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: appthemecolor
                                    .withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Text(
                            'Book Now',
                            style: TextStyle(
                              color: mobileBackgroundColor,
                              fontSize: R.sp(11),
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
      ).animate().fadeIn(
            delay: Duration(milliseconds: index * 100),
          ),
    );
  }

  Widget _buildAllEvents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('All Events'),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(colEvents)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return _buildListShimmer();
            }
            if (!snapshot.hasData ||
                snapshot.data!.docs.isEmpty) {
              return _buildEmptyState('No events available');
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: R.horizontalPadding,
              ),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final data = snapshot.data!.docs[index].data()
                    as Map<String, dynamic>;
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
          borderRadius: BorderRadius.circular(R.cardRadius),
          border: Border.all(
            color: appthemecolor.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(R.cardRadius),
                bottomLeft: Radius.circular(R.cardRadius),
              ),
              child: data['logo'] != null
                  ? Image.network(
                      data['logo'],
                      width: R.isPhone ? 90 : 110,
                      height: R.isPhone ? 100 : 120,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                        width: R.isPhone ? 90 : 110,
                        height: R.isPhone ? 100 : 120,
                        color: surfaceColor2,
                        child: const Icon(
                          Icons.event,
                          color: appthemecolor,
                        ),
                      ),
                    )
                  : Container(
                      width: R.isPhone ? 90 : 110,
                      height: R.isPhone ? 100 : 120,
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
                        fontSize: R.sp(14),
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
                            Icons.calendar_today_rounded,
                            color: appthemecolor,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            data['date'].toString(),
                            style: TextStyle(
                              color: secondaryColor,
                              fontSize: R.sp(11),
                            ),
                          ),
                        ],
                      ),
                    if (data['venue'] != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: appthemecolor,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              data['venue'].toString(),
                              style: TextStyle(
                                color: secondaryColor,
                                fontSize: R.sp(11),
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
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            appthemecolor.withValues(alpha: 0.2),
                            appthemecolor.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: appthemecolor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        'Book Now',
                        style: TextStyle(
                          color: appthemecolor,
                          fontSize: R.sp(10),
                          fontWeight: FontWeight.w700,
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
      ).animate().fadeIn(
            delay: Duration(milliseconds: index * 100),
          ),
    );
  }

  Widget _buildShimmer() {
    return SizedBox(
      height: R.isPhone ? 200 : 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: R.horizontalPadding,
        ),
        itemCount: 3,
        itemBuilder: (context, index) => Container(
          width: R.isPhone ? 260 : 320,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(R.cardRadius),
          ),
        ),
      ),
    );
  }

  Widget _buildListShimmer() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: R.horizontalPadding,
      ),
      itemCount: 3,
      itemBuilder: (context, index) => Container(
        height: R.isPhone ? 100 : 120,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(R.cardRadius),
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: appthemecolor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: appthemecolor.withValues(alpha: 0.2),
                ),
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                color: appthemecolor,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: secondaryColor,
                fontSize: R.sp(14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}