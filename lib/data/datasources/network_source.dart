import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../models/update_metadata.dart';
import '../../utils/constants.dart';

/// Error jaringan yang ramah pengguna.
class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);

  @override
  String toString() => message;
}

/// Sumber data jaringan untuk metadata rilis kamus.
class NetworkSource {
  final http.Client _client;
  final Duration timeout;
  final String metadataUrl;

  NetworkSource({
    http.Client? client,
    this.timeout = AppConstants.httpTimeout,
    this.metadataUrl = AppConstants.activeMetadataUrl,
  }) : _client = client ?? http.Client();

  /// Ambil metadata rilis aktif (`metadata/active.json`).
  Future<UpdateMetadata> fetchActiveMetadata() async {
    try {
      final response = await _client
          .get(
            Uri.parse(metadataUrl),
            headers: const {'Cache-Control': 'no-cache'},
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw NetworkException(
          'Server mengembalikan status ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const NetworkException('Format metadata tidak valid.');
      }

      try {
        return UpdateMetadata.fromJson(decoded);
      } on FormatException {
        throw const NetworkException('Format metadata tidak lengkap.');
      } on TypeError {
        throw const NetworkException('Format metadata tidak sesuai.');
      }
    } on TimeoutException {
      throw const NetworkException(
        'Koneksi habis waktu. Periksa koneksi internet Anda.',
      );
    } on SocketException {
      throw const NetworkException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet.',
      );
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException('Gagal mengambil metadata pembaruan: $e');
    }
  }

  /// Unduh file (artifact rilis) ke [destination] sambil melaporkan progres.
  Future<void> downloadFile({
    required Uri uri,
    required File destination,
    void Function(int received, int? total)? onProgress,
  }) async {
    IOSink? sink;
    try {
      final request = http.Request('GET', uri);
      final response = await _client.send(request).timeout(timeout);

      if (response.statusCode != 200) {
        await response.stream.drain<void>();
        throw NetworkException(
          'Server mengembalikan status ${response.statusCode}.',
        );
      }

      final total = response.contentLength;
      var received = 0;
      sink = destination.openWrite();

      await for (final chunk in response.stream.timeout(timeout)) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }

      await sink.flush();
      await sink.close();
      sink = null;

      if (total != null && total > 0 && received != total) {
        throw const NetworkException(
          'Unduhan tidak lengkap. Coba lagi dengan koneksi yang stabil.',
        );
      }
    } on TimeoutException {
      throw const NetworkException(
        'Koneksi habis waktu saat mengunduh database.',
      );
    } on SocketException {
      throw const NetworkException('Koneksi terputus saat mengunduh database.');
    } on NetworkException {
      rethrow;
    } on HttpException catch (e) {
      throw NetworkException('Gagal mengunduh database: ${e.message}');
    } catch (e) {
      throw NetworkException('Gagal mengunduh database: $e');
    } finally {
      if (sink != null) {
        try {
          await sink.close();
        } catch (_) {
          // Abaikan kegagalan menutup stream saat error.
        }
      }
    }
  }

  void dispose() => _client.close();
}
