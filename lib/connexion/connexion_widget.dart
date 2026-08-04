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
      GoRouter.of(context).clearRedirectLocation();
      if (!mounted) return;

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

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: theme.primaryBackground,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showBrandPanel = constraints.maxWidth >= 900;
              return Row(
                children: [
                  if (showBrandPanel)
                    const Expanded(
                      flex: 11,
                      child: _BrandPanel(),
                    ),
                  Expanded(
                    flex: showBrandPanel ? 9 : 1,
                    child: _LoginPanel(
                      onSignIn: _signInWithGoogle,
                      signingIn: _signingIn,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      height: double.infinity,
      margin: const EdgeInsets.all(18),
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -90,
            top: -90,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: const Color(0xFFFFC928).withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 80,
            bottom: -150,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: .06),
                  width: 44,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/Logo_Choloto_509.png',
                      width: 58,
                      height: 58,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHOLOTO',
                        style: theme.headlineSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.4,
                        ),
                      ),
                      Text(
                        'ESPACE ADMINISTRATION',
                        style: theme.labelSmall.copyWith(
                          color: Colors.white.withValues(alpha: .55),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .10),
                  ),
                ),
                child: Text(
                  'TIRAGES • PUBLICATIONS • COMMUNAUTÉ',
                  style: theme.labelSmall.copyWith(
                    color: const Color(0xFFFFD447),
                    fontWeight: FontWeight.w800,
                    letterSpacing: .9,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Toute votre activité,\nau même endroit.',
                style: theme.displaySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.08,
                  letterSpacing: -1.1,
                ),
              ),
              const SizedBox(height: 18),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  'Gérez les tirages, les prédictions, les publications et '
                  'votre communauté depuis un espace clair et sécurisé.',
                  style: theme.bodyLarge.copyWith(
                    color: Colors.white.withValues(alpha: .68),
                    height: 1.55,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    color: Color(0xFFFFD447),
                    size: 20,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'Accès privé réservé à l’équipe CHOLOTO',
                    style: theme.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: .62),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.onSignIn,
    required this.signingIn,
  });

  final Future<void> Function() onSignIn;
  final bool signingIn;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (MediaQuery.sizeOf(context).width < 900) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/images/Logo_Choloto_509.png',
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'CHOLOTO',
                        style: theme.titleLarge.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ],
              Text(
                'Bon retour parmi nous',
                style: theme.headlineMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Connectez-vous avec le compte Google autorisé pour accéder '
                'au tableau de bord.',
                style: theme.bodyLarge.copyWith(
                  color: theme.secondaryText,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: signingIn ? null : onSignIn,
                icon: signingIn
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
                  signingIn ? 'Connexion en cours…' : 'Continuer avec Google',
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
              const SizedBox(height: 18),
              Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 17,
                    color: theme.secondaryText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Votre session est protégée par Google et Firebase.',
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
    );
  }
}
