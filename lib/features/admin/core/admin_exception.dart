/// Friendly, user-displayable error thrown by the admin data layer.
class AdminException implements Exception {
  AdminException(this.message);
  final String message;

  @override
  String toString() => message;
}
