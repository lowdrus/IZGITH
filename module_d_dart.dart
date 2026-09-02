
// module_d_dart.dart
// CLI: Baixar CRX/ZIP de extensão dado uma URL do Chrome Web Store (ou link direto).
// Uso: dart run module_d_dart.dart --url https://chromewebstore.google.com/detail/... --out D:\...\ext.crx

import 'dart:io';
import 'dart:convert';

void main(List<String> args) async {
  final urlArg = _argValue(args, '--url');
  final outArg = _argValue(args, '--out') ?? 'download.crx';
  if (urlArg == null) {
    stderr.writeln('Uso: --url <URL da extensão> [--out <arquivo>]');
    exit(2);
  }
  stdout.writeln('[INFO] Baixando: $urlArg');
  try {
    final client = HttpClient();
    final uri = Uri.parse(urlArg);
    final req = await client.getUrl(uri);
    final resp = await req.close();
    if (resp.statusCode != 200) {
      stderr.writeln('[ERR] HTTP ${resp.statusCode}');
      exit(1);
    }
    final file = File(outArg).openWrite();
    await resp.pipe(file);
    await file.close();
    stdout.writeln('[OK] Salvo em $outArg');
  } catch (e) {
    stderr.writeln('[ERR] $e');
    exit(1);
  }
}

String? _argValue(List<String> args, String key) {
  final i = args.indexOf(key);
  if (i >= 0 && i + 1 < args.length) return args[i + 1];
  return null;
}
