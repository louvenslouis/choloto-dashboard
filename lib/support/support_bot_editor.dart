import 'package:flutter/material.dart';
import 'dart:math';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'support_bot.dart';
import 'support_bot_repository.dart';

class SupportBotEditor extends StatefulWidget {
  const SupportBotEditor({super.key, required this.repository});
  final SupportBotRepository repository;
  @override
  State<SupportBotEditor> createState() => _SupportBotEditorState();
}

class _SupportBotEditorState extends State<SupportBotEditor> {
  final _greeting = TextEditingController();
  List<SupportBotNode> _nodes = [];
  List<SupportBotPayment> _payments = [];
  List<SupportBotPlan> _plans = [];
  int _revision = 0;
  bool _enabled = true;
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  String? _error;
  String _previewParent = '';

  FlutterFlowTheme get _theme => FlutterFlowTheme.of(context);
  Color get _surface => _theme.secondaryBackground;
  Color get _muted => _theme.secondaryText;
  Color get _line => _theme.alternate;
  Color get _text => _theme.primaryText;

  Widget _badge(IconData icon, {double size = 40}) => AdminIconTile(
        icon: icon,
        size: size,
        iconSize: size * .52,
        radius: 12,
      );

  Widget _panel({required Widget child, EdgeInsetsGeometry? padding}) =>
      AdminSurface(
        padding: padding ?? const EdgeInsets.all(20),
        child: child,
      );

  Widget _sectionTitle(String title, IconData icon, {Widget? trailing}) =>
      Row(children: [
        _badge(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title,
              style: TextStyle(
                  color: _text, fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        if (trailing != null) trailing,
      ]);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _greeting.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final config = await widget.repository.load();
      if (!mounted) return;
      setState(() {
        _nodes = List.of(config.nodes);
        _payments = List.of(config.paymentMethods);
        _plans = List.of(config.availablePlans);
        _revision = config.revision;
        _enabled = config.enabled;
        _greeting.text = config.greeting;
        _dirty = false;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Impossible de charger le bot.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _publish() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.publish(SupportBotConfig(
              enabled: _enabled,
              greeting: _greeting.text.trim(),
              nodes: _nodes,
              paymentMethods: _payments,
              plans: _plans,
              revision: _revision)
          .synchronizedForPublication());
      if (!mounted) return;
      setState(() {
        _revision++;
        _dirty = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Bot publié')));
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is FormatException
            ? e.message
            : e is StateError
                ? e.message.toString()
                : 'Publication impossible. Réessayez.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<T?> _showEditorDialog<T>(WidgetBuilder builder) => showDialog<T>(
        context: context,
        builder: (_) => Theme(
          data: Theme.of(context),
          child: Builder(builder: builder),
        ),
      );

  Future<void> _edit({SupportBotNode? node, String parent = ''}) async {
    final label = TextEditingController(text: node?.label);
    final answer = TextEditingController(text: node?.answer);
    var requiresAuth = node?.requiresAuth ?? false;
    var requestImage = node?.requestImage ?? false;
    var requestPaymentProof = node?.requestPaymentProof ?? false;
    var paymentId = node?.paymentMethodId ?? '';
    final form = GlobalKey<FormState>();
    final result =
        await _showEditorDialog<SupportBotNode>((context) => StatefulBuilder(
            builder: (context, updateDialog) => AlertDialog(
                  title: Text(
                      node == null ? 'Ajouter un choix' : 'Modifier le choix'),
                  content: SizedBox(
                      width: 520,
                      child: SingleChildScrollView(
                          child: Form(
                              key: form,
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextFormField(
                                        controller: label,
                                        decoration: const InputDecoration(
                                            labelText: 'Choix'),
                                        maxLength: 100,
                                        validator: (v) =>
                                            v == null || v.trim().isEmpty
                                                ? 'Champ requis'
                                                : null),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                        controller: answer,
                                        decoration: const InputDecoration(
                                            labelText:
                                                'Réponse / question suivante'),
                                        minLines: 3,
                                        maxLines: 8,
                                        maxLength: 1500,
                                        validator: (v) =>
                                            v == null || v.trim().isEmpty
                                                ? 'Champ requis'
                                                : null),
                                    DropdownButtonFormField<String>(
                                      initialValue: paymentId,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                          labelText: 'Moyen de paiement lié'),
                                      items: [
                                        const DropdownMenuItem(
                                            value: '', child: Text('Aucun')),
                                        ..._payments.map((p) =>
                                            DropdownMenuItem(
                                                value: p.id,
                                                child: Text(p.name)))
                                      ],
                                      onChanged: (value) => updateDialog(() {
                                        paymentId = value ?? '';
                                        if (paymentId.isNotEmpty) {
                                          requiresAuth = true;
                                        }
                                      }),
                                    ),
                                    SwitchListTile(
                                        title:
                                            const Text('Connexion obligatoire'),
                                        value: requiresAuth,
                                        onChanged: (v) => updateDialog(
                                            () => requiresAuth = v)),
                                    SwitchListTile(
                                        title: const Text(
                                            'Demander une preuve de paiement'),
                                        value: requestPaymentProof,
                                        onChanged: (v) => updateDialog(() {
                                              requestPaymentProof = v;
                                              if (v) requiresAuth = true;
                                            })),
                                    SwitchListTile(
                                        title: const Text('Demander une image'),
                                        value: requestImage,
                                        onChanged: (v) => updateDialog(
                                            () => requestImage = v)),
                                  ])))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler')),
                    FilledButton(
                        onPressed: () {
                          if (form.currentState!.validate()) {
                            Navigator.pop(
                                context,
                                SupportBotNode(
                                    id: node?.id ??
                                        List.generate(
                                            16,
                                            (_) => Random.secure()
                                                .nextInt(256)
                                                .toRadixString(16)
                                                .padLeft(2, '0')).join(),
                                    parent: node?.parent ?? parent,
                                    label: label.text.trim(),
                                    answer: answer.text.trim(),
                                    requiresAuth: requiresAuth,
                                    requestImage: requestImage,
                                    requestPaymentProof: requestPaymentProof,
                                    paymentMethodId: paymentId));
                          }
                        },
                        child: const Text('Enregistrer'))
                  ],
                )));
    // Dialog controllers remain alive until its closing animation completes.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    label.dispose();
    answer.dispose();
    if (result == null || !mounted) return;
    setState(() {
      if (node == null) {
        _nodes.add(result);
      } else {
        _nodes[_nodes.indexOf(node)] = result;
      }
      _dirty = true;
    });
  }

  Future<void> _delete(SupportBotNode node) async {
    final ids = <String>{node.id};
    var previous = 0;
    while (previous != ids.length) {
      previous = ids.length;
      ids.addAll(_nodes.where((n) => ids.contains(n.parent)).map((n) => n.id));
    }
    final confirmed = await _showEditorDialog<bool>((context) => AlertDialog(
          title: const Text('Supprimer cette branche ?'),
          content:
              Text('${ids.length} choix seront supprimés à la publication.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Supprimer'))
          ],
        ));
    if (confirmed == true && mounted) {
      setState(() {
        _nodes.removeWhere((n) => ids.contains(n.id));
        _dirty = true;
      });
    }
  }

  void _move(SupportBotNode node, int offset) {
    final siblings = _nodes.where((n) => n.parent == node.parent).toList();
    final target = siblings.indexOf(node) + offset;
    if (target < 0 || target >= siblings.length) return;
    setState(() {
      final a = _nodes.indexOf(node), b = _nodes.indexOf(siblings[target]);
      _nodes[a] = siblings[target];
      _nodes[b] = node;
      _dirty = true;
    });
  }

  Widget _branch(SupportBotNode node, int depth) {
    final children = _nodes.where((n) => n.parent == node.id).toList();
    final siblings = _nodes.where((n) => n.parent == node.parent).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _panel(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          key: ValueKey(node.id),
          initiallyExpanded: depth == 0,
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding:
              EdgeInsets.symmetric(horizontal: depth > 1 ? 8 : 16, vertical: 4),
          leading: depth > 1
              ? null
              : Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: _theme.primary.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('${siblings.indexOf(node) + 1}'.padLeft(2, '0'),
                      style: TextStyle(
                          color: _theme.primary, fontWeight: FontWeight.w800)),
                ),
          title: Text(node.label,
              style: TextStyle(
                  color: _text, fontWeight: FontWeight.w600, fontSize: 14)),
          childrenPadding: EdgeInsets.fromLTRB(
              depth > 1 ? 8 : 16, 0, depth > 1 ? 8 : 16, 12),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _theme.primaryBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(node.answer,
                  style: TextStyle(color: _muted, height: 1.5, fontSize: 13)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(spacing: 2, children: [
                  IconButton(
                      tooltip: 'Modifier',
                      onPressed: () => _edit(node: node),
                      icon: const Icon(Icons.edit_outlined, size: 19)),
                  IconButton(
                      tooltip: 'Ajouter un sous-choix',
                      onPressed: depth >= 5 || _nodes.length >= 80
                          ? null
                          : () => _edit(parent: node.id),
                      icon: const Icon(Icons.add_circle_outline, size: 20)),
                  IconButton(
                      tooltip: 'Monter',
                      onPressed:
                          siblings.first == node ? null : () => _move(node, -1),
                      icon: const Icon(Icons.arrow_upward_rounded, size: 19)),
                  IconButton(
                      tooltip: 'Descendre',
                      onPressed:
                          siblings.last == node ? null : () => _move(node, 1),
                      icon: const Icon(Icons.arrow_downward_rounded, size: 19)),
                  IconButton(
                      tooltip: 'Supprimer',
                      onPressed: () => _delete(node),
                      icon: const Icon(Icons.delete_outline_rounded, size: 19)),
                ]),
              ),
            ),
            ...children.map((n) => _branch(n, depth + 1)),
          ],
        ),
      ),
    );
  }

  Future<bool> _discard() async =>
      !_dirty ||
      await _showEditorDialog<bool>((context) => AlertDialog(
                title: const Text('Quitter sans publier ?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Rester')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Quitter'))
                ],
              )) ==
          true;

  Widget _greetingSection() => _panel(
          child: Column(children: [
        _sectionTitle('Message d’accueil', Icons.waving_hand_outlined,
            trailing: Tooltip(
                message: 'Bot actif',
                child: Switch(
                  value: _enabled,
                  onChanged: (v) => setState(() {
                    _enabled = v;
                    _dirty = true;
                  }),
                ))),
        const SizedBox(height: 16),
        TextField(
          controller: _greeting,
          maxLength: 1000,
          minLines: 2,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'Message d’accueil',
            floatingLabelBehavior: FloatingLabelBehavior.never,
          ),
          onChanged: (_) => setState(() => _dirty = true),
        ),
      ]));

  Widget _preview() {
    SupportBotNode? selected;
    for (final node in _nodes) {
      if (node.id == _previewParent) selected = node;
    }
    final parent = selected?.id ?? '';
    final choices = _nodes.where((n) => n.parent == parent).toList();
    return _panel(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle('Aperçu des réponses', Icons.forum_outlined,
            trailing: IconButton(
              tooltip: 'Recommencer',
              onPressed: () => setState(() => _previewParent = ''),
              icon: const Icon(Icons.refresh_rounded, size: 20),
            )),
        const SizedBox(height: 24),
        Row(children: [
          _badge(Icons.smart_toy_rounded, size: 32),
          const SizedBox(width: 10),
          Expanded(
              child: Text('CHOLOTO',
                  style: TextStyle(
                      color: _text,
                      fontWeight: FontWeight.w800,
                      fontSize: 13))),
          Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _enabled ? _theme.success : _muted)),
          const SizedBox(width: 6),
          Text(_enabled ? 'Actif' : 'En pause',
              style: TextStyle(color: _muted, fontSize: 12)),
        ]),
        const SizedBox(height: 16),
        if (selected != null) ...[
          Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(left: 24, bottom: 12),
                decoration: BoxDecoration(
                    color: _theme.primary,
                    borderRadius: BorderRadius.circular(16)),
                child: Text(selected.label,
                    style: TextStyle(color: _theme.info, fontSize: 13)),
              )),
        ],
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _theme.primaryBackground,
              borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18)),
            ),
            child: Text(selected?.answer ?? _greeting.text,
                style: TextStyle(color: _text, height: 1.6, fontSize: 14)),
          ),
        ),
        const SizedBox(height: 16),
        ...choices.map((node) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                key: ValueKey('preview-${node.id}'),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  side: BorderSide(color: _line),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => setState(() => _previewParent = node.id),
                child: Row(children: [
                  Expanded(
                      child: Text(node.label,
                          style: const TextStyle(fontSize: 13))),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                ]),
              ),
            )),
        if (selected != null)
          Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    setState(() => _previewParent = selected!.parent),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Retour'),
              )),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_dirty && !_saving,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop || _saving) return;
          if (await _discard() && mounted) {
            setState(() => _dirty = false);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Navigator.pop(context);
            });
          }
        },
        child: Scaffold(
          backgroundColor: _theme.primaryBackground,
          appBar: AppBar(
            backgroundColor: _surface,
            foregroundColor: _text,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            shape: Border(bottom: BorderSide(color: _line)),
            title: const Text('Bot du service client',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed:
                      _loading || _saving || _nodes.isEmpty ? null : _publish,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.rocket_launch_outlined, size: 18),
                  label: Text(_saving ? 'Publication…' : 'Publier'),
                ),
              ),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : AbsorbPointer(
                  absorbing: _saving,
                  child: LayoutBuilder(builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 1050;
                    final editor = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _greetingSection(),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14, left: 4),
                          child: _sectionTitle(
                              'Le parcours', Icons.account_tree_outlined),
                        ),
                        ..._nodes
                            .where((n) => n.parent.isEmpty)
                            .map((n) => _branch(n, 0)),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(18),
                            side: BorderSide(color: _line),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _nodes.length >= 80 ? null : () => _edit(),
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          label: const Text('Ajouter un choix'),
                        ),
                        if (!wide) ...[
                          const SizedBox(height: 24),
                          _preview(),
                        ],
                      ],
                    );
                    return SingleChildScrollView(
                      padding:
                          EdgeInsets.all(constraints.maxWidth < 600 ? 16 : 28),
                      child: Center(
                          child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_error != null) ...[
                              _panel(
                                  child: Row(children: [
                                Icon(Icons.error_outline, color: _theme.error),
                                const SizedBox(width: 12),
                                Expanded(child: Text(_error!)),
                                if (_nodes.isEmpty)
                                  TextButton(
                                      onPressed: _load,
                                      child: const Text('Réessayer')),
                              ])),
                              const SizedBox(height: 16),
                            ],
                            if (_nodes.isNotEmpty || _dirty) ...[
                              if (wide)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 3, child: editor),
                                    const SizedBox(width: 24),
                                    Expanded(flex: 2, child: _preview()),
                                  ],
                                )
                              else
                                editor,
                            ],
                          ],
                        ),
                      )),
                    );
                  }),
                ),
        ),
      );
}
