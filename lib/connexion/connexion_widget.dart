import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'connexion_model.dart';
export 'connexion_model.dart';

class ConnexionWidget extends StatefulWidget {
  const ConnexionWidget({super.key});

  static String routeName = 'connexion';
  static String routePath = '/connexion';

  @override
  State<ConnexionWidget> createState() => _ConnexionWidgetState();
}

class _ConnexionWidgetState extends State<ConnexionWidget> {
  late ConnexionModel _model;
  bool _signingIn = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ConnexionModel());
    logFirebaseEvent('screen_view', parameters: {'screen_name': 'connexion'});
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    if (_signingIn) return;
    setState(() => _signingIn = true);

    try {
      logFirebaseEvent('CONNEXION_PAGE_CONNECT_BTN_ON_TAP');
      GoRouter.of(context).prepareAuthEvent();
      final user = await authManager.signInWithGoogle(context);
      if (user == null || !mounted) return;

      final allowedEmail = FFAppState().mail.trim().toLowerCase();
      final signedInEmail = currentUserEmail.trim().toLowerCase();
      if (allowedEmail.isNotEmpty && allowedEmail == signedInEmail) {
        context.goNamedAuth(UsersWidget.routeName, context.mounted);
        return;
      }

      GoRouter.of(context).prepareAuthEvent();
      await authManager.signOut();
      if (!mounted) return;
      GoRouter.of(context).clearRedirectLocation();

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.lock_person_rounded),
          title: const Text('Accès administrateur requis'),
          content: const Text(
            'Ce compte Google ne dispose pas des autorisations nécessaires. '
            'Utilisez le compte administrateur CHOLOTO.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Compris'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Connexion impossible pour le moment. Vérifiez votre connexion '
              'et réessayez.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: FilledButton.icon(
                onPressed: _signingIn ? null : _signInWithGoogle,
                icon: _signingIn
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF102A43),
                        ),
                      )
                    : const Icon(Icons.login_rounded),
                label: Text(
                  _signingIn ? 'Connexion en cours…' : 'Continuer avec Google',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.secondary,
                  foregroundColor: const Color(0xFF102A43),
                  disabledBackgroundColor:
                      theme.secondary.withValues(alpha: .62),
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  textStyle: theme.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
