/// Configuração definida na compilação.
///
/// Sem `--dart-define=ZELO_API_URL=...`, o aplicativo roda em modo de
/// demonstração: autenticação simulada, medicamentos em memória e nenhuma
/// consulta de pontos. Com a URL, usa a API Zelo.
class AppConfig {
  const AppConfig({this.apiBaseUrl});

  factory AppConfig.fromEnvironment() {
    const url = String.fromEnvironment('ZELO_API_URL');
    return AppConfig(apiBaseUrl: url.trim().isEmpty ? null : Uri.parse(url));
  }

  final Uri? apiBaseUrl;

  bool get isConnected => apiBaseUrl != null;
}
