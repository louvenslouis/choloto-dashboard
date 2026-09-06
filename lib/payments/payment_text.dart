import 'package:flutter/widgets.dart';
import '/flutter_flow/internationalization.dart';

// Shared labels, resolved through the application's existing localization API.
String paymentText(BuildContext context, String key) {
  final values = _labels[key]!;
  return _localized(context,
      frText: values[0], enText: values[1], crText: values[2]);
}

const _labels = <String, List<String>>{
  'title': ['Preuve de paiement', 'Payment proof', 'Prèv peman'],
  'menu': [
    'Abonnement par preuve de paiement',
    'Subscribe with payment proof',
    'Abònman ak prèv peman'
  ],
  'choose': ['Choisir une photo', 'Choose a photo', 'Chwazi yon foto'],
  'replace': ['Remplacer la photo', 'Replace photo', 'Ranplase foto a'],
  'imageError': [
    'Photo illisible ou trop volumineuse. Choisissez une image JPEG/PNG plus petite (24 mégapixels maximum).',
    'Unreadable or oversized photo. Choose a smaller JPEG/PNG image (up to 24 megapixels).',
    'Foto a pa lizib oswa li twò gwo. Chwazi yon imaj JPEG/PNG ki pi piti (24 megapiksèl maksimòm).'
  ],
  'amount': ['Montant payé', 'Amount paid', 'Montan ou peye'],
  'currency': ['Devise', 'Currency', 'Lajan'],
  'method': ['Moyen de paiement', 'Payment method', 'Fason ou peye'],
  'reference': ['Référence du paiement', 'Payment reference', 'Referans peman'],
  'note': ['Message (facultatif)', 'Message (optional)', 'Mesaj (si ou vle)'],
  'send': ['Envoyer', 'Send', 'Voye'],
  'sending': ['Envoi en cours…', 'Sending…', 'N ap voye…'],
  'sent': ['Photo envoyée.', 'Photo sent.', 'Foto a voye.'],
  'error': [
    'Opération impossible. Vérifiez votre connexion puis réessayez.',
    'Unable to complete this action. Check your connection and try again.',
    'Nou pa ka fini aksyon sa a. Verifye koneksyon ou epi eseye ankò.'
  ],
  'required': [
    'Complétez ce champ.',
    'Complete this field.',
    'Ranpli chan sa a.'
  ],
  'amountError': [
    'Saisissez un montant valide supérieur à zéro.',
    'Enter a valid amount greater than zero.',
    'Antre yon montan valid ki pi gran pase zewo.'
  ],
  'history': ['Mes demandes', 'My requests', 'Demann mwen yo'],
  'empty': [
    'Aucune demande pour le moment.',
    'No requests yet.',
    'Pa gen demann pou kounye a.'
  ],
  'pending': [
    'En attente de validation',
    'Awaiting review',
    'Ap tann verifikasyon'
  ],
  'approved': ['Paiement validé', 'Payment approved', 'Peman valide'],
  'rejected': ['Demande refusée', 'Request rejected', 'Demann refize'],
  'proof': ['Voir la preuve', 'View proof', 'Gade prèv la'],
  'close': ['Fermer', 'Close', 'Fèmen'],
  'retry': ['Réessayer', 'Retry', 'Eseye ankò'],
  'signin': [
    'Connectez-vous pour envoyer et consulter vos preuves de paiement.',
    'Sign in to submit and view your payment proofs.',
    'Konekte pou voye ak gade prèv peman ou yo.'
  ],
  'until': ['VIP jusqu’au', 'VIP until', 'VIP jiska'],
  'receipt': ['Reçu', 'Receipt', 'Resi'],
  'adminTitle': ['Preuves de paiement', 'Payment proofs', 'Prèv peman yo'],
  'all': ['Toutes les demandes', 'All requests', 'Tout demann yo'],
  'review': ['Examiner la demande', 'Review request', 'Egzamine demann lan'],
  'approve': [
    'Valider et enregistrer le paiement',
    'Approve and record payment',
    'Valide epi anrejistre peman an'
  ],
  'reject': ['Refuser la demande', 'Reject request', 'Refize demann lan'],
  'reason': ['Motif du refus', 'Rejection reason', 'Rezon refi a'],
  'reasonHelp': [
    'Le membre verra ce motif.',
    'The member will see this reason.',
    'Manm lan ap wè rezon sa a.'
  ],
  'end': [
    'Nouvelle échéance VIP',
    'New VIP expiration',
    'Nouvo dat ekspirasyon VIP'
  ],
  'endHelp': [
    'Vérifiez la preuve de transfert, puis renseignez le paiement et la nouvelle échéance.',
    'Check the transfer proof, then enter the payment details and new expiration.',
    'Verifye prèv transfè a, epi antre detay peman an ak nouvo dat ekspirasyon an.'
  ],
  'currentEnd': [
    'Échéance actuelle',
    'Current expiration',
    'Dat ekspirasyon aktyèl'
  ],
  'noPlan': ['Aucun plan actif', 'No active plan', 'Pa gen plan aktif'],
  'stale': [
    'Cette demande a déjà été traitée. Actualisez la liste.',
    'This request has already been processed. Refresh the list.',
    'Demann sa a deja trete. Rafrechi lis la.'
  ],
  'invalidEnd': [
    'Choisissez une échéance future qui prolonge l’abonnement actuel.',
    'Choose a future expiration that extends the current subscription.',
    'Chwazi yon dat nan lavni ki pwolonje abònman aktyèl la.'
  ],
  'missingProfile': [
    'Le profil de ce membre est introuvable. La demande peut être refusée, mais aucun paiement ne peut être validé.',
    'This member’s profile is missing. You can reject the request, but cannot approve a payment.',
    'Pwofil manm sa a pa la. Ou ka refize demann lan, men ou pa ka valide peman an.'
  ],
  'download': [
    'Télécharger le reçu PDF',
    'Download PDF receipt',
    'Telechaje resi PDF'
  ],
  'new': ['Nouvelle demande', 'New request', 'Nouvo demann'],
};

String paymentMethodLabel(BuildContext context, String method) =>
    switch (method) {
      'cash' => _localized(context,
          frText: 'Espèces', enText: 'Cash', crText: 'Lajan kach'),
      'virement' => _localized(context,
          frText: 'Virement bancaire',
          enText: 'Bank transfer',
          crText: 'Transfè labank'),
      'moncash' => 'MonCash',
      'natcash' => 'NatCash',
      'cashapp' => 'Cash App',
      'stripe' => 'Stripe',
      'zelle' => 'Zelle',
      _ => method,
    };

// The existing dashboard exposes only French in its localization API. Resolve
// the new module's optional translations from that same locale without changing
// the dashboard's global language contract.
String _localized(BuildContext context,
    {required String frText, required String enText, required String crText}) {
  final locale = FFLocalizations.of(context);
  return locale.getVariableText(
      frText: switch (locale.languageCode) {
    'en' => enText,
    'cr' => crText,
    _ => frText,
  });
}
