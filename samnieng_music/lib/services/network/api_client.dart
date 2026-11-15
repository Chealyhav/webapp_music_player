import 'package:http/http.dart' as http;

class ApiClient {
  final http.Client client = http.Client();

  Future<http.Response> get(String url) async {
    return await client.get(Uri.parse(url));
  }
}
