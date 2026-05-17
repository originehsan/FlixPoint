import 'package:flutter/material.dart';

// Royal Noir Theme - FlixPoint
// Background colors
const mobileBackgroundColor = Color(0xFF080808);  // Pure cinema black
const webBackgroundColor = Color(0xFF080808);
const surfaceColor = Color(0xFF141414);           // Card surface
const surfaceColor2 = Color(0xFF1C1C1C);          // Elevated surface

// Primary - Royal Gold
const appthemecolor = Color(0xFFC9A84C);          // Royal gold
const goldLight = Color(0xFFE8C97A);              // Light gold
const goldDark = Color(0xFF8B6914);               // Dark gold

// Text colors
const primaryColor = Color(0xFFE8E8E8);           // Silver white
const secondaryColor = Color(0xFF888888);         // Muted grey
const hintColor = Color(0xFF444444);              // Hint text

// Semantic colors
const successColor = Color(0xFF4CAF50);           // Booking confirmed
const errorColor = Color(0xFFFF5252);             // Seat unavailable
const warningColor = Color(0xFFFFB703);           // Warning

// Seat colors
const seatAvailable = Color(0xFF2A2A2A);          // Available seat
const seatSelected = Color(0xFFC9A84C);           // Selected seat (gold)
const seatBooked = Color(0xFF3A3A3A);             // Booked seat
const seatLocked = Color(0xFF555555);             // Temporarily locked
const seatClassic = Color(0xFF1E3A5F);            // Classic tier
const seatPremium = Color(0xFF2D1B69);            // Premium tier
const seatVip = Color(0xFF4A1942);                // VIP tier

// Search bar
const mobileSearchColor = Color(0xFF141414);

// Legacy (kept for compatibility)
const blueColor = Color(0xFFC9A84C);
const greycolorshade1 = Color(0xFF141414);

// Gradients
const goldGradient = LinearGradient(
  colors: [Color(0xFFC9A84C), Color(0xFF8B6914)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const darkGradient = LinearGradient(
  colors: [Color(0xFF080808), Color(0xFF141414)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

const heroGradient = LinearGradient(
  colors: [Colors.transparent, Color(0xFF080808)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);