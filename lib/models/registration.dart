class UserDetails {
  final String name;
  final String email;
  final String city;

  UserDetails({
    required this.city,
    required this.email,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
    "username": name,
    "email": email,
    "city": city,
    // password REMOVED - never store passwords in Firestore
  };
}