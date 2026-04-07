class User {
  final int id;
  final String username;
  final String email;
  final String? fullName;
  final String? token;
  final String? refreshToken;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.token,
    this.refreshToken,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      fullName: json['full_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
    };
  }
}

class UserAuth {
  final String email;
  final String password;

  UserAuth({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class UserRegister {
  final String username;
  final String email;
  final String password;
  final String? fullName;

  UserRegister({
    required this.username,
    required this.email,
    required this.password,
    this.fullName,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'full_name': fullName,
    };
  }
}
