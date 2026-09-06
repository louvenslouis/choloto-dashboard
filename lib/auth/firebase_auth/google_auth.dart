import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

const googleAnalyticsReadonlyScope =
    'https://www.googleapis.com/auth/analytics.readonly';

final _googleSignIn = GoogleSignIn(
  scopes: ['profile', 'email', googleAnalyticsReadonlyScope],
);
String? _googleAnalyticsAccessToken;

String? get cachedGoogleAnalyticsAccessToken =>
    _googleAnalyticsAccessToken?.trim().isNotEmpty == true
        ? _googleAnalyticsAccessToken
        : null;

GoogleAuthProvider _googleProvider({required bool includeAnalytics}) {
  final provider = GoogleAuthProvider();
  if (includeAnalytics) {
    provider.addScope(googleAnalyticsReadonlyScope);
  }
  return provider;
}

void _rememberAccessToken(UserCredential credential) {
  final oauthCredential = credential.credential;
  final accessToken = oauthCredential is OAuthCredential
      ? oauthCredential.accessToken?.trim()
      : null;
  if (accessToken != null && accessToken.isNotEmpty) {
    _googleAnalyticsAccessToken = accessToken;
  }
}

Future<UserCredential?> googleSignInFunc() async {
  if (kIsWeb) {
    final credential = await FirebaseAuth.instance.signInWithPopup(
      _googleProvider(includeAnalytics: true),
    );
    _rememberAccessToken(credential);
    return credential;
  }

  await signOutWithGoogle().catchError((_) => null);
  final auth = await (await _googleSignIn.signIn())?.authentication;
  if (auth == null) {
    return null;
  }
  _googleAnalyticsAccessToken = auth.accessToken;
  final credential = GoogleAuthProvider.credential(
      idToken: auth.idToken, accessToken: auth.accessToken);
  return FirebaseAuth.instance.signInWithCredential(credential);
}

Future<String?> authorizeGoogleAnalyticsAccess() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return null;

  if (kIsWeb) {
    final credential = await currentUser.reauthenticateWithPopup(
      _googleProvider(includeAnalytics: true),
    );
    _rememberAccessToken(credential);
    return cachedGoogleAnalyticsAccessToken;
  }

  var account = _googleSignIn.currentUser;
  account ??= await _googleSignIn.signInSilently();
  account ??= await _googleSignIn.signIn();
  if (account == null) return null;

  final scopesGranted = await _googleSignIn.requestScopes([
    googleAnalyticsReadonlyScope,
  ]);
  if (!scopesGranted) return null;

  final auth = await account.authentication;
  _googleAnalyticsAccessToken = auth.accessToken;
  return cachedGoogleAnalyticsAccessToken;
}

void clearGoogleAnalyticsAccessToken() {
  _googleAnalyticsAccessToken = null;
}

Future signOutWithGoogle() async {
  clearGoogleAnalyticsAccessToken();
  await _googleSignIn.signOut();
}
