import '/backend/backend.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';

Future<bool> showBingoEditDialog({
  required BuildContext context,
  required BingoRecord publication,
}) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _BingoEditDialog(publication: publication),
      ) ??
      false;
}

Future<bool> showCroixEditDialog({
  required BuildContext context,
  required CroixRecord publication,
}) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _CroixEditDialog(publication: publication),
      ) ??
      false;
}

Future<bool> showPredictionEditDialog({
  required BuildContext context,
  required PredictionRecord publication,
}) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _PredictionEditDialog(publication: publication),
      ) ??
      false;
}

class _BingoEditDialog extends StatefulWidget {
  const _BingoEditDialog({required this.publication});

  final BingoRecord publication;

  @override
  State<_BingoEditDialog> createState() => _BingoEditDialogState();
}

class _BingoEditDialogState extends State<_BingoEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final List<_BingoResultDraft> _results;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _results =
        widget.publication.dataStack.map(_BingoResultDraft.fromResult).toList();
    if (_results.isEmpty) {
      _results.add(_BingoResultDraft.empty());
    }
  }

  @override
  void dispose() {
    for (final result in _results) {
      result.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await widget.publication.reference.update({
        'dataStack': _results
            .map(
              (result) => {
                'valeur': result.valeur.text.trim(),
                'tirage': result.tirage.text.trim(),
                'boul': result.boul.text.trim(),
                'periode': result.periode.text.trim(),
              },
            )
            .toList(),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage =
            'Modification impossible pour le moment. Veuillez réessayer.';
      });
    }
  }

  void _addResult() {
    setState(() => _results.add(_BingoResultDraft.empty()));
  }

  void _removeResult(int index) {
    if (_results.length == 1) return;
    final removed = _results.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return AdminDialogFrame(
      maxWidth: 720.0,
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminDialogHeader(
                title: 'Modifier le BINGO',
                subtitle:
                    'Les valeurs de la publication sont déjà préremplies.',
                icon: Icons.edit_rounded,
                onClose: _saving ? () {} : () => Navigator.pop(context),
              ),
              const SizedBox(height: 20.0),
              for (var index = 0; index < _results.length; index++) ...[
                _BingoResultEditor(
                  index: index,
                  draft: _results[index],
                  canRemove: _results.length > 1,
                  onRemove: () => _removeResult(index),
                ),
                if (index < _results.length - 1) const SizedBox(height: 12.0),
              ],
              const SizedBox(height: 14.0),
              OutlinedButton.icon(
                onPressed: _saving ? null : _addResult,
                icon: const Icon(Icons.add_rounded, size: 18.0),
                label: const Text('Ajouter un résultat'),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 14.0),
                _EditErrorMessage(message: _errorMessage!),
              ],
              const SizedBox(height: 22.0),
              _EditDialogActions(
                saving: _saving,
                onCancel: () => Navigator.pop(context),
                onSave: _save,
              ),
              const SizedBox(height: 2.0),
              Text(
                'La date et l’expiration d’origine seront conservées.',
                textAlign: TextAlign.center,
                style: theme.labelSmall.copyWith(color: theme.secondaryText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BingoResultDraft {
  _BingoResultDraft({
    required this.valeur,
    required this.tirage,
    required this.boul,
    required this.periode,
  });

  factory _BingoResultDraft.fromResult(DataStackStruct result) {
    return _BingoResultDraft(
      valeur: TextEditingController(text: result.valeur),
      tirage: TextEditingController(text: result.tirage),
      boul: TextEditingController(text: result.boul),
      periode: TextEditingController(text: result.periode),
    );
  }

  factory _BingoResultDraft.empty() {
    return _BingoResultDraft.fromResult(DataStackStruct());
  }

  final TextEditingController valeur;
  final TextEditingController tirage;
  final TextEditingController boul;
  final TextEditingController periode;

  void dispose() {
    valeur.dispose();
    tirage.dispose();
    boul.dispose();
    periode.dispose();
  }
}

class _BingoResultEditor extends StatelessWidget {
  const _BingoResultEditor({
    required this.index,
    required this.draft,
    required this.canRemove,
    required this.onRemove,
  });

  final int index;
  final _BingoResultDraft draft;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return AdminSurface(
      padding: const EdgeInsets.all(14.0),
      color: theme.primaryBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Résultat ${index + 1}',
                  style: theme.titleSmall.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (canRemove)
                IconButton(
                  tooltip: 'Retirer ce résultat',
                  onPressed: onRemove,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  color: theme.error,
                ),
            ],
          ),
          const SizedBox(height: 8.0),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 520.0;
              final width = twoColumns
                  ? (constraints.maxWidth - 12.0) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 12.0,
                runSpacing: 12.0,
                children: [
                  _EditTextField(
                    width: width,
                    controller: draft.boul,
                    label: 'Numéro du BINGO',
                    keyboardType: TextInputType.number,
                    required: true,
                  ),
                  _EditTextField(
                    width: width,
                    controller: draft.valeur,
                    label: 'Valeur',
                    hint: 'Ex. 1er lot',
                  ),
                  _EditTextField(
                    width: width,
                    controller: draft.tirage,
                    label: 'Nom du tirage',
                    hint: 'Ex. NEW YORK',
                  ),
                  _EditTextField(
                    width: width,
                    controller: draft.periode,
                    label: 'Période',
                    hint: 'Midi ou Soir',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CroixEditDialog extends StatefulWidget {
  const _CroixEditDialog({required this.publication});

  final CroixRecord publication;

  @override
  State<_CroixEditDialog> createState() => _CroixEditDialogState();
}

class _CroixEditDialogState extends State<_CroixEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final List<TextEditingController> _controllers;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final values = List<String>.generate(
      9,
      (index) => index < widget.publication.numeros.length
          ? widget.publication.numeros[index]
          : index == 4
              ? '0'
              : '',
    );
    _controllers = List.generate(
      9,
      (index) => TextEditingController(text: values[index]),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await widget.publication.reference.update({
        'numeros': List<String>.generate(
          9,
          (index) => index == 4 ? '0' : _controllers[index].text.trim(),
        ),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage =
            'Modification impossible pour le moment. Veuillez réessayer.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return AdminDialogFrame(
      maxWidth: 620.0,
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminDialogHeader(
                title: 'Modifier la Croix de la Chance',
                subtitle: 'Les numéros de cette entrée sont déjà préremplis.',
                icon: Icons.edit_rounded,
                onClose: _saving ? () {} : () => Navigator.pop(context),
              ),
              const SizedBox(height: 20.0),
              AdminSurface(
                padding: const EdgeInsets.all(14.0),
                color: theme.primaryBackground,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 500.0 ? 3 : 2;
                    const spacing = 10.0;
                    final width =
                        (constraints.maxWidth - spacing * (columns - 1)) /
                            columns;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: List.generate(9, (index) {
                        if (index == 4) {
                          return SizedBox(
                            width: width,
                            child: TextFormField(
                              initialValue: '0',
                              readOnly: true,
                              textAlign: TextAlign.center,
                              decoration: _inputDecoration(
                                context,
                                label: 'Centre',
                              ),
                            ),
                          );
                        }
                        return _EditTextField(
                          width: width,
                          controller: _controllers[index],
                          label: 'Position ${index + 1}',
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          required: true,
                        );
                      }),
                    );
                  },
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 14.0),
                _EditErrorMessage(message: _errorMessage!),
              ],
              const SizedBox(height: 22.0),
              _EditDialogActions(
                saving: _saving,
                onCancel: () => Navigator.pop(context),
                onSave: _save,
              ),
              const SizedBox(height: 2.0),
              Text(
                'La date d’origine sera conservée.',
                textAlign: TextAlign.center,
                style: theme.labelSmall.copyWith(color: theme.secondaryText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PredictionEditDialog extends StatefulWidget {
  const _PredictionEditDialog({required this.publication});

  final PredictionRecord publication;

  @override
  State<_PredictionEditDialog> createState() => _PredictionEditDialogState();
}

class _PredictionEditDialogState extends State<_PredictionEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final List<_PredictionDraft> _categories;
  late final TextEditingController _percentageController;
  String? _period;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _period =
        widget.publication.periode.isEmpty ? null : widget.publication.periode;
    _percentageController = TextEditingController(
      text: widget.publication.hasPourcentage()
          ? widget.publication.pourcentage.toString()
          : '',
    );
    _categories = [
      _PredictionDraft('FAVORI', widget.publication.favori),
      _PredictionDraft('SOUTNI', widget.publication.soutni),
      _PredictionDraft('BOLOTO', widget.publication.boloto),
      _PredictionDraft('MARIAGE', widget.publication.mariage),
      _PredictionDraft('3 CHIFFRES', widget.publication.chif3),
      _PredictionDraft('4 CHIFFRES', widget.publication.chif4),
      _PredictionDraft('EXTRA', widget.publication.extra),
    ];
  }

  @override
  void dispose() {
    _percentageController.dispose();
    for (final category in _categories) {
      category.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final percentageText = _percentageController.text.trim();
    final updates = <String, dynamic>{
      'favori': _categories[0].toFirestoreMap(),
      'soutni': _categories[1].toFirestoreMap(),
      'boloto': _categories[2].toFirestoreMap(),
      'mariage': _categories[3].toFirestoreMap(),
      'chif3': _categories[4].toFirestoreMap(),
      'chif4': _categories[5].toFirestoreMap(),
      'extra': _categories[6].toFirestoreMap(),
      if (_period != null) 'periode': _period,
      if (percentageText.isNotEmpty) 'pourcentage': int.parse(percentageText),
    };

    try {
      await widget.publication.reference.update(updates);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage =
            'Modification impossible pour le moment. Veuillez réessayer.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final periodOptions = <String>{
      if (_period != null) _period!,
      'Matin',
      'Midi',
      'Soir',
    }.toList();

    return AdminDialogFrame(
      maxWidth: 720.0,
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminDialogHeader(
                title: 'Modifier les prédictions',
                subtitle: 'Les anciennes sélections sont déjà préremplies.',
                icon: Icons.edit_rounded,
                onClose: _saving ? () {} : () => Navigator.pop(context),
              ),
              const SizedBox(height: 20.0),
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoColumns = constraints.maxWidth >= 520.0;
                  final width = twoColumns
                      ? (constraints.maxWidth - 12.0) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 12.0,
                    runSpacing: 12.0,
                    children: [
                      SizedBox(
                        width: width,
                        child: DropdownButtonFormField<String>(
                          initialValue: _period,
                          decoration:
                              _inputDecoration(context, label: 'Période'),
                          items: periodOptions
                              .map(
                                (period) => DropdownMenuItem(
                                  value: period,
                                  child: Text(period),
                                ),
                              )
                              .toList(),
                          onChanged: _saving
                              ? null
                              : (value) => setState(() => _period = value),
                        ),
                      ),
                      _EditTextField(
                        width: width,
                        controller: _percentageController,
                        label: 'Pourcentage',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return null;
                          final percentage = int.tryParse(text);
                          if (percentage == null ||
                              percentage < 0 ||
                              percentage > 100) {
                            return 'Entrez un nombre entre 0 et 100.';
                          }
                          return null;
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14.0),
              for (var index = 0; index < _categories.length; index++) ...[
                _PredictionCategoryEditor(draft: _categories[index]),
                if (index < _categories.length - 1)
                  const SizedBox(height: 10.0),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 14.0),
                _EditErrorMessage(message: _errorMessage!),
              ],
              const SizedBox(height: 22.0),
              _EditDialogActions(
                saving: _saving,
                onCancel: () => Navigator.pop(context),
                onSave: _save,
              ),
              const SizedBox(height: 2.0),
              Text(
                'Séparez les numéros par une virgule. La date d’origine sera conservée.',
                textAlign: TextAlign.center,
                style: theme.labelSmall.copyWith(color: theme.secondaryText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PredictionDraft {
  _PredictionDraft(this.fallbackName, this.source)
      : controller = TextEditingController(text: source.boul.join(', '));

  final String fallbackName;
  final PredictionsStruct source;
  final TextEditingController controller;

  String get displayName => source.name.isEmpty ? fallbackName : source.name;

  Map<String, dynamic> toFirestoreMap() {
    return {
      'name': displayName,
      if (source.hasStars()) 'stars': source.stars,
      'boul': controller.text
          .split(RegExp(r'[,;\s]+'))
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(),
    };
  }

  void dispose() => controller.dispose();
}

class _PredictionCategoryEditor extends StatelessWidget {
  const _PredictionCategoryEditor({required this.draft});

  final _PredictionDraft draft;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return AdminSurface(
      padding: const EdgeInsets.all(12.0),
      color: theme.primaryBackground,
      child: _EditTextField(
        controller: draft.controller,
        label: draft.displayName,
        hint: 'Ex. 12, 24, 36, 48',
        keyboardType: TextInputType.text,
      ),
    );
  }
}

class _EditTextField extends StatelessWidget {
  const _EditTextField({
    this.width,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.textAlign = TextAlign.start,
    this.required = false,
    this.validator,
  });

  final double? width;
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final TextAlign textAlign;
  final bool required;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textAlign: textAlign,
        decoration: _inputDecoration(context, label: label, hint: hint),
        validator: validator ??
            (required
                ? (value) => value == null || value.trim().isEmpty
                    ? 'Ce champ est obligatoire.'
                    : null
                : null),
      ),
    );
  }
}

class _EditDialogActions extends StatelessWidget {
  const _EditDialogActions({
    required this.saving,
    required this.onCancel,
    required this.onSave,
  });

  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 360.0;
        final cancel = OutlinedButton.icon(
          onPressed: saving ? null : onCancel,
          icon: const Icon(Icons.close_rounded, size: 18.0),
          label: const Text('Annuler'),
        );
        final save = FilledButton.icon(
          onPressed: saving ? null : onSave,
          icon: saving
              ? const SizedBox(
                  width: 18.0,
                  height: 18.0,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                )
              : const Icon(Icons.save_rounded, size: 18.0),
          label: Text(saving ? 'Enregistrement…' : 'Enregistrer'),
        );

        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [save, const SizedBox(height: 10.0), cancel],
          );
        }
        return Row(
          children: [
            Expanded(child: cancel),
            const SizedBox(width: 12.0),
            Expanded(child: save),
          ],
        );
      },
    );
  }
}

class _EditErrorMessage extends StatelessWidget {
  const _EditErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: theme.error, size: 20.0),
          const SizedBox(width: 9.0),
          Expanded(
            child: Text(
              message,
              style: theme.bodySmall.copyWith(color: theme.error),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration(
  BuildContext context, {
  required String label,
  String? hint,
}) {
  final theme = FlutterFlowTheme.of(context);
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: theme.secondaryBackground,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(color: theme.alternate),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(color: theme.alternate),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(color: theme.primary, width: 1.5),
    ),
  );
}
