// ============================================================
// PINTARAJA — API CONSTANTS
// Endpoint disamakan dengan routes/api.php original
// ============================================================

class ApiConstants {
  ApiConstants._();

  // ==========================================================
  // BASE
  // ==========================================================

  static const String baseUrl = 'https://pintaraja.com/api';

  // ==========================================================
  // TRIPAY
  // ==========================================================

  static const String tripayApiKey = '6GaMeHd4kMtp9T3MV3bbVg2RpcDhabzKvcey1KiK';
  static const String tripayPrivateKey = '0NCKW-6RXt6-znZRJ-A9rzm-T59DV';
  static const String tripayMerchantCode = 'T38245';

  // URL untuk mendapatkan daftar channel pembayaran
  static const String tripayChannelsUrl =
      'https://tripay.co.id/api/merchant/payment-channel';

  // ==========================================================
  // AUTH
  // Backend:
// POST /login
// POST /register
// POST /verify-otp
// POST /resend-otp
// POST /forgot-password
// POST /new-password
  // ==========================================================

  static const String login = '$baseUrl/login';

  static const String loginGoogle = '$baseUrl/auth/google';

  static const String register = '$baseUrl/register';

  static const String verifyOtp = '$baseUrl/verify-otp';

  static const String resendOtp = '$baseUrl/resend-otp';

  static const String forgotPassword = '$baseUrl/forgot-password';

  static const String newPassword = '$baseUrl/new-password';

  static const String logout = '$baseUrl/logout';

  // ==========================================================
  // PROFILE
  // ==========================================================

  static const String profile = '$baseUrl/profiles';

  static const String user = '$baseUrl/profiles';

  static const String updateProfile = '$baseUrl/profiles';

  static const String changePassword = '$baseUrl/profiles/password';

  static const String redeemCoupon = '$baseUrl/profiles/redeem';

  // ==========================================================
  // CONVERSATIONS
  // ==========================================================

  static const String conversations = '$baseUrl/convers';

  // ==========================================================
  // CHAT / AI
  // ==========================================================

  static const String chats = '$baseUrl/chats';

  static const String chat = '$baseUrl/chats';

  static String conversationChats(
    int conversationId,
  ) {
    return '$chats/$conversationId';
  }

  static const String chatUpload = '$chats/upload';

  static const String chatDeleteFile = '$chats/delete';

  static const String chatGenerateFromFile = '$chats/gff';

  // ==========================================================
  // IMAGE / VIDEO
  // ==========================================================

  static const String imageGenerator = '$baseUrl/generate-image';

  static const String videoGenerator = '$baseUrl/generate-video';

  // ==========================================================
  // WRITER
  // ==========================================================

  static const String writer = '$baseUrl/writers';

  static const String writerFiles = '$baseUrl/writers/files';

  static const String writerUploadFile = '$baseUrl/writers/upload-file';

  static const String writerDeleteFile = '$baseUrl/writers/delete-file';

  // ==========================================================
  // PROMPTS
  // ==========================================================

  static const String prompts = '$baseUrl/prompts';

  // ==========================================================
  // WORKBOOKS
  // ==========================================================

  static const String workbooks = '$baseUrl/workbooks';

  // ==========================================================
  // DOCUMENTS
  // ==========================================================

  static const String documents = '$baseUrl/documents';

  static const String documentsDownload = '$baseUrl/documents/download';

  // ==========================================================
  // PARAPHRASE
  // ==========================================================

  static const String paraphrase = '$baseUrl/paraps';

  // ==========================================================
  // HUMANIZER
  // ==========================================================

  static const String humanizer = '$baseUrl/humans';

  // ==========================================================
  // TRANSCRIBE
  // ==========================================================

  static const String transcribes = '$baseUrl/transcribes';

  static const String transcribeActive = '$baseUrl/transcribes/active';

  static String transcribeStatus(
    int id,
  ) {
    return '$transcribes/$id/status';
  }

  // ==========================================================
  // PLAGIARISM
  // ==========================================================

  static const String plagiarism = '$baseUrl/plagiarism';

  static const String plagiarismPendingPayment =
      '$baseUrl/plagiarism/pending-payment';

  static const String plagiarismCancelPayment =
      '$baseUrl/plagiarism/cancel-payment';

  static String plagiarismDownload(
    int id,
  ) {
    return '$plagiarism/$id/download';
  }

  // ==========================================================
  // PAYMENTS
  // ==========================================================

  static const String payments = '$baseUrl/payments';

  static const String payment = '$baseUrl/payments';

  static const String topUp = '$baseUrl/payments/topup';

  static const String referralDiscount = '$baseUrl/payments/referral-discount';

  static const String checkDiscount = '$baseUrl/payments/check-discount';

  static String paymentByReference(
    String referenceId,
  ) {
    return '$baseUrl/payments/$referenceId';
  }

  // ==========================================================
  // PLANS
  // ==========================================================

  static const String plans = '$baseUrl/plans';

  // ==========================================================
  // COUPONS
  // ==========================================================

  static const String coupon = '$baseUrl/coupons';

  // ==========================================================
  // DISCOUNT COUPONS
  // ==========================================================

  static const String discountCoupons = '$baseUrl/discount-coupons';

  // ==========================================================
  // REFERRALS
  // ==========================================================

  static const String referrals = '$baseUrl/referrals';

  static const String activateReferral = '$baseUrl/referrals/activate';

  static const String claimFreeMonth = '$baseUrl/referrals/claim-free-month';

  // ==========================================================
  // AUTOCOMPLETE
  // ==========================================================

  static const String autocomplete = '$baseUrl/autocomplete';

  // ==========================================================
  // PUBLIC SETTINGS
  // ==========================================================

  static const String publicSettings = '$baseUrl/settings/public';

  // ==========================================================
  // BLOG
  // ==========================================================

  static const String blog = '$baseUrl/blog';

  // ==========================================================
  // PAPERS
  // ==========================================================

  static const String papers = '$baseUrl/papers';

  // ==========================================================
  // GOOGLE AUTH
  // ==========================================================

  static const String googleCallback = '$baseUrl/auth/google/callback';
}

// ============================================================
// APP CONSTANTS
// ============================================================

class AppConstants {
  AppConstants._();

  static const String appName = 'PintarAja';

  static const String appTagline = 'Solusi Mahasiswa, di Pintar Aja';

  static const String tokenKey = 'auth_token';

  static const String userKey = 'user_data';
}
