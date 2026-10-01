class ServerAccount {
  const ServerAccount({
    required this.baseUrl,
    required this.username,
    required this.token,
    required this.isAdmin,
  });

  final String baseUrl;
  final String username;
  final String token;
  final bool isAdmin;

  bool get isConnected => baseUrl.isNotEmpty && token.isNotEmpty;
}
