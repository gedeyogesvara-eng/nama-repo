/// Model data profil akun Google
class GoogleProfileData {
  final String email;
  final String displayName;
  final String googleId;
  final String? photoUrl;

  const GoogleProfileData({
    required this.email,
    required this.displayName,
    required this.googleId,
    this.photoUrl,
  });
}
