import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/models/claim.dart';

class OrynDatabase {
  static Isar? _instance;

  static Future<Isar> getInstance() async {
    if (_instance != null) return _instance!;

    final dir = await getApplicationDocumentsDirectory();

    _instance = await Isar.open(
      [ClaimSchema],  // Only ClaimSchema, NOT ClaimLinkSchema
      directory: dir.path,
      name: 'oryn_db',
    );

    return _instance!;
  }

  static Future<void> close() async {
    await _instance?.close();
    _instance = null;
  }
}