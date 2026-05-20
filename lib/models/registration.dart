class UserDetails {
  final String name;
  final String email;
  final String city;

  UserDetails({
    required this.email,
    required this.name,
    this.city = '',
  });

  Map<String, dynamic> toJson() => {
    "username": name,
    "email": email,
    "city": city,
  };
}