import 'package:uuid/uuid.dart';

/// Helper class to provide a singleton Uuid instance
/// This avoids the LateInitializationError that can occur with `const Uuid()`
class UuidHelper {
  static final Uuid _uuid = Uuid();
  
  /// Generate a new v4 UUID
  static String generateV4() => _uuid.v4();
}
