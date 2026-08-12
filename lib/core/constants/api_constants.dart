// ============================================================
// APP CONSTANTS — API URLs & Keys
// ============================================================

class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://pintaraja.com/api';

  // ── AUTH ──────────────────────────────────────────────────
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String logout = '$baseUrl/auth/logout';
  static const String user = '$baseUrl/auth/user';
  static const String forgotPassword = '$baseUrl/auth/forgot-password';

  // ── GOOGLE AUTH ───────────────────────────────────────────
  static const String googleCallback = '$baseUrl/auth/google/callback';

  // ── CHAT ──────────────────────────────────────────────────
  static const String conversations = '$baseUrl/conversations';
  static const String chat = '$baseUrl/chat';

  // ── WRITER ────────────────────────────────────────────────
  static const String writer = '$baseUrl/writer';
  static const String paraphrase = '$baseUrl/paraphrase';
  static const String humanizer = '$baseUrl/humanizer';

  // ── TOOLS ─────────────────────────────────────────────────
  static const String plagiarism = '$baseUrl/plagiarism';
  static const String transcribe = '$baseUrl/transcribe';
  static const String imageGenerator = '$baseUrl/image-generator';
  static const String videoGenerator = '$baseUrl/video-generator';
  static const String autocomplete = '$baseUrl/autocomplete';

  // ── DOCUMENTS ─────────────────────────────────────────────
  static const String documents = '$baseUrl/documents';
  static const String papers = '$baseUrl/papers';
  static const String workbooks = '$baseUrl/workbooks';

  // ── PLANS & PAYMENT ───────────────────────────────────────
  static const String plans = '$baseUrl/plans';
  static const String payment = '$baseUrl/payment';
  static const String coupon = '$baseUrl/coupon';

  // ── PROFILE ───────────────────────────────────────────────
  static const String profile = '$baseUrl/profile';
  static const String referral = '$baseUrl/referral';

  // ── SETTINGS ──────────────────────────────────────────────
  static const String publicSettings = '$baseUrl/settings/public';
  static const String blog = '$baseUrl/blog';
}

class AppConstants {
  AppConstants._();

  static const String appName = 'PintaRaja';
  static const String appTagline = 'Solusi Mahasiswa, di Pintar Aja';
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
}
