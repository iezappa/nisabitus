class ServerAccount {
  const ServerAccount({
    required this.baseUrl,
    required this.username,
    required this.token,
  });

  final String baseUrl;
  final String username;
  final String token;

  bool get isConnected => baseUrl.isNotEmpty && token.isNotEmpty;
}
