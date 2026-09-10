import 'package:flutter/widgets.dart';
import '/flutter_flow/internationalization.dart';

String supportText(BuildContext context, String key) =>
    FFLocalizations.of(context).getVariableText(frText: _labels[key]!);

const _labels = {
  'audioMessage': 'Note vocale',
  'playAudio': 'Écouter la note vocale',
  'pauseAudio': 'Mettre en pause',
  'retry': 'Réessayer',
  'audioLoadError':
      'Lecture impossible. Vérifiez votre connexion puis réessayez.',
};

bool isSupportAudioPlaceholder(String text) =>
    const ['Note vocale', 'Voice message', 'Nòt vokal'].contains(text);
