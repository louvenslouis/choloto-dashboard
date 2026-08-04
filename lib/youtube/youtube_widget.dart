import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/sidenav/sidenav_widget.dart';
import 'package:flutter/material.dart';
import 'youtube_model.dart';
export 'youtube_model.dart';

class YoutubeWidget extends StatefulWidget {
  const YoutubeWidget({super.key});

  static String routeName = 'youtube';
  static String routePath = '/youtube';

  @override
  State<YoutubeWidget> createState() => _YoutubeWidgetState();
}

class _YoutubeWidgetState extends State<YoutubeWidget> {
  late YoutubeModel _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => YoutubeModel());
    logFirebaseEvent('screen_view', parameters: {'screen_name': 'youtube'});
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width >= 992;

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar:
          isDesktop ? null : const AdminMobileAppBar(title: 'Chaîne YouTube'),
      drawer: isDesktop
          ? null
          : const Drawer(
              width: 264,
              child: SidenavWidget(forceVisible: true),
            ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            wrapWithModel(
              model: _model.sidenavModel,
              updateCallback: () => safeSetState(() {}),
              child: const SidenavWidget(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 970),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AdminSectionHeader(
                          title: 'Chaîne YouTube',
                          description:
                              'Accédez aux outils de publication vidéo et '
                              'suivez l’évolution de ce module.',
                          icon: Icons.play_circle_fill_rounded,
                        ),
                        _YoutubeEmptyState(
                          onOpenStudio: () =>
                              launchURL('https://studio.youtube.com'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YoutubeEmptyState extends StatelessWidget {
  const _YoutubeEmptyState({required this.onOpenStudio});

  final VoidCallback onOpenStudio;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFFF0033).withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Color(0xFFFF0033),
              size: 40,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: theme.secondary.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              'MODULE EN PRÉPARATION',
              style: theme.labelSmall.copyWith(
                color: theme.primaryText,
                fontWeight: FontWeight.w800,
                letterSpacing: .8,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'La gestion vidéo arrive bientôt',
            textAlign: TextAlign.center,
            style: theme.headlineSmall.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              'La publication directe n’est pas encore configurée dans ce '
              'tableau de bord. En attendant, utilisez YouTube Studio pour '
              'gérer les vidéos de la chaîne.',
              textAlign: TextAlign.center,
              style: theme.bodyMedium.copyWith(
                color: theme.secondaryText,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onOpenStudio,
            icon: const Icon(Icons.open_in_new_rounded, size: 19),
            label: const Text('Ouvrir YouTube Studio'),
          ),
        ],
      ),
    );
  }
}
