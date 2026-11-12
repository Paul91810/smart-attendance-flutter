/// Environment and network configuration.
class AppConfig {
  final bool useMock;
  final String baseUrl;

  const AppConfig({
    this.useMock = true,
    this.baseUrl = 'https://api.smartattendance.local/v1',
  });
}
