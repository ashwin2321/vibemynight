/// Response of POST /auth/login.
class LoginResult {
  final String accessToken;
  final String tokenType;
  final int userId;
  final String name;
  final String email;
  final String role;

  const LoginResult({
    required this.accessToken,
    required this.tokenType,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) => LoginResult(
        accessToken: json['accessToken'] as String,
        tokenType: json['tokenType'] as String,
        userId: json['userId'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
      );
}
