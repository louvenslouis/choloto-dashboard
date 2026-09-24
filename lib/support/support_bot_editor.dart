import 'package:flutter/material.dart';
import 'dart:math';
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
  int _revision = 0;
  bool _enabled = true;
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  String? _error;

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
          revision: _revision));
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

  Future<void> _edit({SupportBotNode? node, String parent = ''}) async {
    final label = TextEditingController(text: node?.label);
    final answer = TextEditingController(text: node?.answer);
    var requiresAuth = node?.requiresAuth ?? false;
    var requestImage = node?.requestImage ?? false;
    final form = GlobalKey<FormState>();
    final result = await showDialog<SupportBotNode>(
        context: context,
        builder: (context) => StatefulBuilder(
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
                                    SwitchListTile(
                                        title:
                                            const Text('Connexion obligatoire'),
                                        value: requiresAuth,
                                        onChanged: (v) => updateDialog(
                                            () => requiresAuth = v)),
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
                                    requestImage: requestImage));
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
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Supprimer cette branche ?'),
              content: Text(
                  '${ids.length} choix seront supprimés à la publication.'),
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
    return Card(
        child: ExpansionTile(
            key: ValueKey(node.id),
            initiallyExpanded: depth == 0,
            title: Text(node.label),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            children: [
          Align(alignment: Alignment.centerLeft, child: Text(node.answer)),
          Wrap(children: [
            IconButton(
                tooltip: 'Modifier',
                onPressed: () => _edit(node: node),
                icon: const Icon(Icons.edit_outlined)),
            IconButton(
                tooltip: 'Ajouter un sous-choix',
                onPressed: depth >= 5 || _nodes.length >= 80
                    ? null
                    : () => _edit(parent: node.id),
                icon: const Icon(Icons.add)),
            IconButton(
                tooltip: 'Monter',
                onPressed:
                    siblings.first == node ? null : () => _move(node, -1),
                icon: const Icon(Icons.arrow_upward)),
            IconButton(
                tooltip: 'Descendre',
                onPressed: siblings.last == node ? null : () => _move(node, 1),
                icon: const Icon(Icons.arrow_downward)),
            IconButton(
                tooltip: 'Supprimer',
                onPressed: () => _delete(node),
                icon: const Icon(Icons.delete_outline)),
          ]),
          ...children.map((n) => _branch(n, depth + 1)),
        ]));
  }

  Future<bool> _discard() async =>
      !_dirty ||
      await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
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
            appBar:
                AppBar(title: const Text('Bot du service client'), actions: [
              TextButton(
                  onPressed:
                      _loading || _saving || _nodes.isEmpty ? null : _publish,
                  child: Text(_saving ? 'Publication…' : 'Publier')),
            ]),
            body: _loading
                ? const Center(child: CircularProgressIndicator())
                : AbsorbPointer(
                    absorbing: _saving,
                    child: Center(
                        child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (_error != null) ...[
                              Text(_error!,
                                  style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.error)),
                              if (_nodes.isEmpty)
                                TextButton(
                                    onPressed: _load,
                                    child: const Text('Réessayer'))
                            ],
                            if (_nodes.isNotEmpty || _dirty) ...[
                              SwitchListTile(
                                  title: const Text('Bot actif'),
                                  value: _enabled,
                                  onChanged: (v) => setState(() {
                                        _enabled = v;
                                        _dirty = true;
                                      })),
                              TextField(
                                  controller: _greeting,
                                  maxLength: 1000,
                                  maxLines: null,
                                  decoration: const InputDecoration(
                                      labelText: 'Message d’accueil'),
                                  onChanged: (_) =>
                                      setState(() => _dirty = true)),
                              ..._nodes
                                  .where((n) => n.parent.isEmpty)
                                  .map((n) => _branch(n, 0)),
                              OutlinedButton.icon(
                                  onPressed: _nodes.length >= 80
                                      ? null
                                      : () => _edit(),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Ajouter un choix')),
                            ],
                          ]),
                    )),
                  )),
      );
}
