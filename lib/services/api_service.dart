import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String base = 'http://127.0.0.1:8000';

  static Future<Map<String, dynamic>> checkHealth() async {
    final r = await http.get(Uri.parse('$base/health'));
    if (r.statusCode != 200) throw Exception('Backend health check failed (${r.statusCode})');
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> modelInfo() async {
    final r = await http.get(Uri.parse('$base/model-info'));
    if (r.statusCode != 200) {
      throw Exception('Backend error ${r.statusCode}: ${r.body}');
    }
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> predict(
    String path, {
    double? pixelSize,
    List<int>? bytes,
    String? filename,
  }) async {
    final uri = Uri.parse('$base/predict');
    final req = http.MultipartRequest('POST', uri);

    if (bytes != null && bytes.isNotEmpty) {
      final fname = (filename != null && filename.isNotEmpty) ? filename : 'patch.nc';
      req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fname));
    } else if (path.isNotEmpty) {
      req.files.add(await http.MultipartFile.fromPath('file', path));
    } else {
      throw Exception('No file data provided');
    }

    if (pixelSize != null) {
      req.fields['pixel_size_m'] = pixelSize.toString();
    }

    final streamRes = await req.send();
    final res = await http.Response.fromStream(streamRes);
    final body = jsonDecode(res.body);

    if (res.statusCode != 200) {
      final msg = body is Map && body.containsKey('detail') ? body['detail'] : 'Prediction failed';
      throw Exception(msg);
    }
    return body as Map<String, dynamic>;
  }
}
