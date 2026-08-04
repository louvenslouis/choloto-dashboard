import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/main.dart';
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
      body: Stack(
        children: [
          Positioned(
            top: -140,
            right: -90,
            child: _AmbientCircle(
              size: 360,
              color: theme.secondary.withValues(alpha: .11),
            ),
          ),
          Positioned(
            bottom: -180,
            left: -120,
            child: _AmbientCircle(
              size: 420,
              color: theme.tertiary.withValues(alpha: .08),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 40 : 20,
                    vertical: wide ? 36 : 24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - (wide ? 72 : 48),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1080),
                        child: wide
                            ? IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Expanded(
                                      flex: 11,
                                      child: _ConnexionBrandPanel(),
                                    ),
                                    Expanded(
                                      flex: 9,
                                      child: _ConnexionCard(
                                        signingIn: _signingIn,
                                        onSignIn: _signInWithGoogle,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : _ConnexionCard(
                                signingIn: _signingIn,
                                onSignIn: _signInWithGoogle,
                                showBrand: true,
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: IconButton(
                  tooltip: Theme.of(context).brightness == Brightness.dark
                      ? 'Activer le mode clair'
                      : 'Activer le mode sombre',
                  onPressed: () => MyApp.of(context).setThemeMode(
                    Theme.of(context).brightness == Brightness.dark
                        ? ThemeMode.light
                        : ThemeMode.dark,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        theme.secondaryBackground.withValues(alpha: .92),
                    foregroundColor: theme.primaryText,
                    side: BorderSide(
                      color: theme.alternate.withValues(alpha: .8),
                    ),
                  ),
                  icon: Icon(
                    Theme.of(context).brightness == Brightness.dark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnexionBrandPanel extends StatelessWidget {
  const _ConnexionBrandPanel();

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(52),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF17334F), Color(0xFF0E2135)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.horizontal(left: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BrandLockup(compact: false),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.secondary.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: theme.secondary.withValues(alpha: .24),
              ),
            ),
            child: Text(
              'CENTRE DE CONTRÔLE',
              style: theme.labelSmall.copyWith(
                color: theme.secondary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Tout CHOLOTO,\nau même endroit.',
            style: theme.displaySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.1,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Supervisez les tirages, les publications et votre communauté '
            'depuis un espace de travail clair et sécurisé.',
            style: theme.bodyLarge.copyWith(
              color: Colors.white.withValues(alpha: .72),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 34),
          const Wrap(
            spacing: 20,
            runSpacing: 12,
            children: [
              _TrustPoint(icon: Icons.shield_outlined, label: 'Accès sécurisé'),
              _TrustPoint(icon: Icons.bolt_rounded, label: 'Gestion rapide'),
            ],
          ),
          const Spacer(),
          Text(
            '© ${DateTime.now().year} CHOLOTO • Administration',
            style: theme.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: .38),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnexionCard extends StatelessWidget {
  const _ConnexionCard({
    required this.signingIn,
    required this.onSignIn,
    this.showBrand = false,
  });

  final bool signingIn;
  final VoidCallback onSignIn;
  final bool showBrand;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showBrand ? 26 : 52,
        vertical: showBrand ? 34 : 52,
      ),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: showBrand
            ? BorderRadius.circular(28)
            : const BorderRadius.horizontal(right: Radius.circular(30)),
        border: Border.all(color: theme.alternate.withValues(alpha: .78)),
        boxShadow: [
          BoxShadow(
            color: theme.primaryText.withValues(alpha: .07),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBrand) ...[
            const _BrandLockup(compact: true),
            const SizedBox(height: 46),
          ],
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.accent1,
              borderRadius: BorderRadius.circular(15),
            ),
            child:
                Icon(Icons.lock_open_rounded, color: theme.primary, size: 23),
          ),
          const SizedBox(height: 22),
          Text(
            'Heureux de vous revoir',
            style: theme.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -.65,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Connectez-vous avec le compte Google autorisé pour accéder à '
            'l’espace d’administration.',
            style: theme.bodyMedium.copyWith(
              color: theme.secondaryText,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 30),
          FilledButton.icon(
            onPressed: signingIn ? null : onSignIn,
            icon: signingIn
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF12263F),
                    ),
                  )
                : const Icon(Icons.login_rounded, size: 20),
            label: Text(
              signingIn ? 'Connexion en cours…' : 'Continuer avec Google',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: theme.secondary,
              foregroundColor: const Color(0xFF12263F),
              disabledBackgroundColor: theme.secondary.withValues(alpha: .62),
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              textStyle: theme.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: theme.secondaryText,
                size: 17,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'L’accès est réservé aux administrateurs autorisés.',
                  style: theme.labelSmall.copyWith(
                    color: theme.secondaryText,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      children: [
        Container(
          width: compact ? 44 : 48,
          height: compact ? 44 : 48,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/Logo_Choloto_509.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CHOLOTO',
              style: theme.titleMedium.copyWith(
                color: compact ? theme.primaryText : Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -.35,
              ),
            ),
            Text(
              'ADMINISTRATION',
              style: theme.labelSmall.copyWith(
                color: compact
                    ? theme.secondaryText
                    : Colors.white.withValues(alpha: .52),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrustPoint extends StatelessWidget {
  const _TrustPoint({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: theme.secondary, size: 18),
        const SizedBox(width: 7),
        Text(
          label,
          style: theme.labelMedium.copyWith(
            color: Colors.white.withValues(alpha: .74),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AmbientCircle extends StatelessWidget {
  const _AmbientCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
