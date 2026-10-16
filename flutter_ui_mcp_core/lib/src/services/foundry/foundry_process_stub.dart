/// Stub implementation for non-IO platforms (e.g. Flutter Web).
Future<List<String>> getFoundryCachedModels() async => [];

Future<String?> getFoundryActiveUrl() async => null;

Future<bool> loadFoundryModel(String model) async => false;
