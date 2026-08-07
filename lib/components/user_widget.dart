import '/backend/backend.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'user_model.dart';
export 'user_model.dart';

class UserWidget extends StatefulWidget {
  const UserWidget({
    super.key,
    required this.infos,
  });

  final UserRecord? infos;

  @override
  State<UserWidget> createState() => _UserWidgetState();
}

class _UserWidgetState extends State<UserWidget> {
  late UserModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => UserModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final user = widget.infos;
    final name = user?.displayName.trim().isNotEmpty == true
        ? user!.displayName.trim()
        : 'Membre CHOLOTO';
    final email = user?.email.trim().isNotEmpty == true
        ? user!.email.trim()
        : 'E-mail non renseigné';
    final endDate = user?.endSub;
    final active = endDate != null && endDate.isAfter(DateTime.now());
    final initial = name.characters.first.toUpperCase();
    final avatar = Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: theme.accent1,
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.secondary.withValues(alpha: .35),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryText.withValues(alpha: .08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: user?.photoUrl.isNotEmpty == true
          ? Image.network(
              user!.photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _AvatarInitial(initial: initial),
            )
          : _AvatarInitial(initial: initial),
    );

    Widget identityDetails({required bool centered}) => Column(
          crossAxisAlignment:
              centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: centered ? TextAlign.center : TextAlign.start,
              style: theme.titleMedium.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: centered ? TextAlign.center : TextAlign.start,
              style: theme.bodySmall.copyWith(color: theme.secondaryText),
            ),
            const SizedBox(height: 9),
            AdminStatusPill(
              label: active ? 'ABONNEMENT ACTIF' : 'ABONNEMENT INACTIF',
              color: active ? theme.success : theme.warning,
              foregroundColor: active ? theme.success : theme.primaryText,
              compact: true,
            ),
          ],
        );

    return Padding(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 390 ? 18 : 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminDialogHeader(
            title: 'Profil du membre',
            subtitle: 'Informations et statut de l’abonnement',
            icon: Icons.person_rounded,
            onClose: () => Navigator.pop(context),
          ),
          const SizedBox(height: 22),
          AdminSurface(
            padding: const EdgeInsets.all(16),
            color: theme.primaryBackground,
            radius: 18,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 300;
                if (stacked) {
                  return Column(
                    children: [
                      avatar,
                      const SizedBox(height: 13),
                      identityDetails(centered: true),
                    ],
                  );
                }
                return Row(
                  children: [
                    avatar,
                    const SizedBox(width: 14),
                    Expanded(child: identityDetails(centered: false)),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 430 ? 2 : 1;
              const gap = 12.0;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              final items = [
                _UserInfoTile(
                  icon: Icons.calendar_month_rounded,
                  label: 'Mois actifs',
                  value: '${user?.memberTime ?? 0}',
                ),
                _UserInfoTile(
                  icon: Icons.pin_rounded,
                  label: 'Code personnel',
                  value: user?.codePersonnel.isNotEmpty == true
                      ? user!.codePersonnel
                      : 'Non renseigné',
                ),
                _UserInfoTile(
                  icon: Icons.event_available_rounded,
                  label: 'Fin de l’abonnement',
                  value: endDate == null
                      ? 'Non définie'
                      : DateFormat('d MMM y', 'fr').format(endDate),
                ),
                _UserInfoTile(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Paiement',
                  value: _paymentLabel(user?.method?.name),
                ),
              ];

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: items
                    .map((item) => SizedBox(width: width, child: item))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _paymentLabel(String? method) {
    switch (method) {
      case 'moncash':
        return 'MonCash';
      case 'cash':
        return 'Espèces';
      case 'stripe':
        return 'Carte / Stripe';
      default:
        return 'Non renseigné';
    }
  }
}

class _AvatarInitial extends StatelessWidget {
  const _AvatarInitial({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Center(
      child: Text(
        initial,
        style: theme.headlineSmall.copyWith(
          color: Theme.of(context).brightness == Brightness.dark
              ? theme.secondary
              : theme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _UserInfoTile extends StatelessWidget {
  const _UserInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 84),
      child: AdminSurface(
        padding: const EdgeInsets.all(14),
        radius: 16,
        child: Row(
          children: [
            AdminIconTile(
              icon: icon,
              color: Theme.of(context).brightness == Brightness.dark
                  ? theme.secondary
                  : theme.primary,
              size: 38,
              iconSize: 20,
              radius: 12,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: theme.labelSmall.copyWith(
                      color: theme.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
