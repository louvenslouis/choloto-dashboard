import '/auth/firebase_auth/auth_util.dart';
import '/components/admin_ui.dart';
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

      await showAdminNoticeDialog(
        context: context,
        title: 'Accès administrateur requis',
        message:
            'Ce compte Google ne dispose pas des autorisations nécessaires. '
            'Utilisez le compte administrateur CHOLOTO.',
        icon: Icons.lock_person_rounded,
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
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Positioned(
                top: -90,
                right: -70,
                child: Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    color: theme.secondary.withValues(alpha: .13),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -120,
                left: -100,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: .07),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 52,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(
                          MediaQuery.sizeOf(context).width < 390 ? 24 : 30,
                        ),
                        decoration: BoxDecoration(
                          color: theme.secondaryBackground,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: theme.alternate),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryText.withValues(alpha: .07),
                              blurRadius: 32,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 78,
                              height: 78,
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: theme.alternate),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.primaryText
                                        .withValues(alpha: .08),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(19),
                                child: Image.asset(
                                  'assets/images/Logo_Choloto_509.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.secondary.withValues(alpha: .16),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                'ESPACE ADMINISTRATEUR',
                                style: theme.labelSmall.copyWith(
                                  color: theme.primaryText,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .9,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Bienvenue sur CHOLOTO',
                              textAlign: TextAlign.center,
                              style: theme.headlineMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.6,
                                height: 1.12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Connectez-vous pour gérer les tirages, les '
                              'prédictions et la communauté.',
                              textAlign: TextAlign.center,
                              style: theme.bodyMedium.copyWith(
                                color: theme.secondaryText,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 26),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed:
                                    _signingIn ? null : _signInWithGoogle,
                                icon: _signingIn
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF12263F),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.login_rounded,
                                        size: 20,
                                      ),
                                label: Text(
                                  _signingIn
                                      ? 'Connexion en cours…'
                                      : 'Continuer avec Google',
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: theme.secondary,
                                  foregroundColor: const Color(0xFF12263F),
                                  disabledBackgroundColor:
                                      theme.secondary.withValues(alpha: .62),
                                  minimumSize: const Size.fromHeight(56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  textStyle: theme.titleSmall.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.verified_user_outlined,
                                  size: 17,
                                  color: theme.secondaryText,
                                ),
                                const SizedBox(width: 7),
                                Flexible(
                                  child: Text(
                                    'Accès sécurisé réservé à l’équipe',
                                    style: theme.bodySmall.copyWith(
                                      color: theme.secondaryText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
