import 'dart:io';

Future<String?> readEnvFromDisk() async {
  try {
    var file = File('.env');
    if (!await file.exists()) {
      file = File('../../.env');
    }
    if (await file.exists()) {
      return await file.readAsString();
    }
  } catch (_) {}
  return null;
}
