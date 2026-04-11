import 'dart:convert';
import 'dart:io';

void main() async {
  final _midtransServerKey = "Mid-server-FZ8oEUkPIErJZDediEts1jQN";
  final authKey = base64Encode(utf8.encode("$_midtransServerKey:"));

  final requestUrl = Uri.parse('https://app.sandbox.midtrans.com/snap/v1/transactions');
  
  try {
    final client = HttpClient();
    final request = await client.postUrl(requestUrl);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    request.headers.set(HttpHeaders.authorizationHeader, 'Basic $authKey');

    final body = jsonEncode({
      "transaction_details": {
        "order_id": "TEST-123",
        "gross_amount": 10000
      }
    });

    request.write(body);
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print("Status Code: ${response.statusCode}");
    print("Response: $responseBody");
    client.close();
  } catch(e) {
    print("Error: $e");
  }
}
