import 'dart:convert';

class SupportBotNode {
  const SupportBotNode(
      {required this.id,
      required this.parent,
      required this.label,
      required this.answer,
      this.requiresAuth = false,
      this.requestImage = false,
      this.requestPaymentProof = false,
      this.paymentMethodId = ''});
  final String id;
  final String parent;
  final String label;
  final String answer;
  final bool requiresAuth;
  final bool requestImage;
  final bool requestPaymentProof;
  bool get requestsImage => requestImage || requestPaymentProof;
  bool get requestsPaymentProof =>
      requestPaymentProof || (requestImage && paymentMethodId.isNotEmpty);
  final String paymentMethodId;
  Map<String, dynamic> toJson() => {
        'id': id,
        'parent': parent,
        'label': label,
        'answer': answer,
        'requiresAuth': requiresAuth,
        'requestImage': requestImage,
        'requestPaymentProof': requestPaymentProof,
        'paymentMethodId': paymentMethodId
      };
  factory SupportBotNode.fromJson(Map<String, dynamic> data) => SupportBotNode(
      id: data['id'] as String,
      parent: data['parent'] as String,
      label: data['label'] as String,
      answer: data['answer'] as String,
      requiresAuth: data['requiresAuth'] as bool? ?? false,
      requestImage: data['requestImage'] as bool? ?? false,
      requestPaymentProof: data['requestPaymentProof'] as bool? ??
          (data['requestImage'] == true &&
              (data['id'] == 'paid' || data['id'] == 'access_paid')),
      paymentMethodId: data['paymentMethodId'] as String? ?? '');
}

class SupportBotConfig {
  const SupportBotConfig(
      {required this.enabled,
      required this.greeting,
      required this.nodes,
      this.revision = 0,
      this.paymentMethods = const [],
      this.plans = const []});
  final bool enabled;
  final String greeting;
  final List<SupportBotNode> nodes;
  final int revision;
  final List<SupportBotPayment> paymentMethods;
  final List<SupportBotPlan> plans;
  SupportBotConfig synchronizedForPublication() {
    if (plans.isEmpty) return this;
    return SupportBotConfig(
      enabled: enabled,
      greeting: greeting,
      nodes: nodes,
      revision: revision,
      plans: plans,
      paymentMethods: [
        for (final method in paymentMethods)
          if (!method.enabled)
            method
          else
            method.withPlan(_legacyPlanFor(method)),
      ],
    );
  }

  SupportBotPlan _legacyPlanFor(SupportBotPayment method) {
    final matches = plans.where((p) => p.enabled).toList()
      ..sort((a, b) => a.months.compareTo(b.months));
    if (matches.isEmpty) {
      throw FormatException(
          'Ajoutez un plan actif en ${method.currency} pour ${method.name}.');
    }
    final shortest =
        matches.where((p) => p.months == matches.first.months).toList();
    final amounts = shortest.map((p) => p.amountFor(method.currency)).toSet();
    if (amounts.length > 1) {
      throw FormatException(
          'Harmonisez les plans ${method.currency} de ${matches.first.months} mois.');
    }
    return shortest.first;
  }

  List<SupportBotPlan> get availablePlans {
    if (plans.isNotEmpty) return plans;
    final grouped = <int, List<SupportBotPayment>>{};
    for (final payment in paymentMethods) {
      if (payment.amountMinor <= 0) continue;
      grouped.putIfAbsent(payment.months, () => []).add(payment);
    }
    return [
      for (final entry in grouped.entries)
        SupportBotPlan(
          id: 'legacy_${entry.key}',
          name: '${entry.key} mois',
          months: entry.key,
          amountHtgMinor: _legacyAmount(entry.value, 'HTG'),
          amountUsdMinor: _legacyAmount(entry.value, 'USD'),
          enabled: entry.value.any((p) => p.enabled) &&
              _legacyAmount(entry.value, 'HTG') > 0 &&
              _legacyAmount(entry.value, 'USD') > 0,
        ),
    ];
  }

  int _legacyAmount(List<SupportBotPayment> methods, String currency) {
    final amounts = methods
        .where((p) => p.enabled && p.currency == currency)
        .map((p) => p.amountMinor)
        .toSet();
    return amounts.length == 1 ? amounts.single : 0;
  }

  SupportBotPayment? payment(String id) {
    for (final method in paymentMethods) {
      if (method.id == id) return method;
    }
    return null;
  }

  List<SupportBotNode> children(String parent) =>
      nodes.where((n) => n.parent == parent).toList();
  SupportBotNode? node(String id) {
    for (final n in nodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'greeting': greeting,
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'revision': revision,
        'paymentMethods': paymentMethods.map((p) => p.toJson()).toList(),
        'plans': plans.map((p) => p.toJson()).toList()
      };
  factory SupportBotConfig.fromJson(Map<String, dynamic> data) {
    final config = SupportBotConfig(
        enabled: data['enabled'] as bool,
        greeting: data['greeting'] as String,
        revision: data['revision'] as int,
        paymentMethods: (data['paymentMethods'] as List? ?? [])
            .map((p) =>
                SupportBotPayment.fromJson(Map<String, dynamic>.from(p as Map)))
            .toList(),
        plans: (data['plans'] as List? ?? [])
            .map((p) =>
                SupportBotPlan.fromJson(Map<String, dynamic>.from(p as Map)))
            .toList(),
        nodes: (data['nodes'] as List)
            .map((n) =>
                SupportBotNode.fromJson(Map<String, dynamic>.from(n as Map)))
            .toList());
    config.validate();
    return config;
  }
  void validate() {
    if (greeting.trim().isEmpty ||
        greeting.length > 1000 ||
        nodes.isEmpty ||
        nodes.length > 80 ||
        revision < 0) {
      throw const FormatException(
          'Une question d’accueil et 1 à 80 choix sont nécessaires.');
    }
    if (paymentMethods.length > 20 ||
        paymentMethods.map((p) => p.id).toSet().length !=
            paymentMethods.length) {
      throw const FormatException(
          'Maximum 20 moyens de paiement, avec des identifiants uniques.');
    }
    for (final method in paymentMethods) {
      method.validate();
    }
    if (plans.length > 30 ||
        plans.map((p) => p.id).toSet().length != plans.length) {
      throw const FormatException(
          'Maximum 30 plans, avec des identifiants uniques.');
    }
    for (final plan in plans) {
      plan.validate();
    }
    final ids = nodes.map((n) => n.id).toSet();
    if (ids.length != nodes.length) {
      throw const FormatException('Identifiants dupliqués.');
    }
    for (final n in nodes) {
      if (n.paymentMethodId.isNotEmpty && payment(n.paymentMethodId) == null) {
        throw const FormatException(
            'Un choix est lié à un moyen de paiement introuvable.');
      }
      if (!RegExp(r'^[a-zA-Z0-9_-]{1,80}$').hasMatch(n.id) ||
          n.label.trim().isEmpty ||
          n.label.length > 100 ||
          n.answer.trim().isEmpty ||
          n.answer.length > 1500) {
        throw const FormatException(
            'Chaque choix doit avoir un titre (100 caractères maximum) et une réponse (1500 maximum).');
      }
      final visited = <String>{n.id};
      var parent = n.parent;
      while (parent.isNotEmpty) {
        if (!ids.contains(parent) ||
            !visited.add(parent) ||
            visited.length > 6) {
          throw const FormatException(
              'Arborescence invalide ou trop profonde (6 niveaux maximum).');
        }
        parent = node(parent)!.parent;
      }
    }
    if (utf8.encode(jsonEncode(toJson())).length > 180000) {
      throw const FormatException('Arborescence trop volumineuse.');
    }
  }

  static const initial = SupportBotConfig(
      enabled: true,
      greeting: 'Bonjou fanmi! Kijan nou ka ede ou?',
      paymentMethods: [
        SupportBotPayment(id: 'moncash', name: 'MonCash', currency: 'HTG'),
        SupportBotPayment(id: 'natcash', name: 'NatCash', currency: 'HTG'),
        SupportBotPayment(id: 'zelle', name: 'Zelle', currency: 'USD'),
      ],
      nodes: [
        SupportBotNode(
            id: 'vip',
            parent: '',
            label: 'Mwen vle antre nan VIP a',
            answer:
                'Byenveni! Kreye yon kont CHOLOTO oswa konekte sou kont ou deja genyen an. Nan ki peyi ou ye?'),
        SupportBotNode(
            id: 'vip_haiti',
            requiresAuth: true,
            parent: 'vip',
            label: 'Ayiti',
            answer: 'Ki mwayen peman ou vle itilize?'),
        SupportBotNode(
            id: 'vip_abroad',
            requiresAuth: true,
            parent: 'vip',
            label: 'Yon lòt peyi',
            answer:
                'Ou ka chwazi Zelle. Si ou bezwen yon lòt mwayen peman, pale ak ekip la.'),
        SupportBotNode(
            id: 'vip_mon',
            parent: 'vip_haiti',
            label: 'MonCash',
            answer:
                'Lè ou fin peye, peze bouton pou voye prèv peman an epi ranpli fòm nan. Ekip la ap verifye demann ou an.',
            paymentMethodId: 'moncash',
            requestImage: true),
        SupportBotNode(
            id: 'vip_nat',
            parent: 'vip_haiti',
            label: 'NatCash',
            answer:
                'Lè ou fin peye, peze bouton pou voye prèv peman an epi ranpli fòm nan. Ekip la ap verifye demann ou an.',
            paymentMethodId: 'natcash',
            requestImage: true),
        SupportBotNode(
            id: 'vip_zelle',
            parent: 'vip_abroad',
            label: 'Zelle',
            answer:
                'Lè ou fin peye, peze bouton pou voye prèv peman an epi ranpli fòm nan. Ekip la ap verifye demann ou an.',
            paymentMethodId: 'zelle',
            requestImage: true),
        SupportBotNode(
            id: 'renew',
            requiresAuth: true,
            parent: '',
            label: 'Mwen vle renouvle VIP mwen',
            answer:
                'Konekte sou kont CHOLOTO ki gen abònman ou a. Ki mwayen peman ou vle itilize?'),
        SupportBotNode(
            id: 'renew_mon',
            paymentMethodId: 'moncash',
            requestImage: true,
            parent: 'renew',
            label: 'MonCash',
            answer:
                'Lè ou fin peye, peze bouton pou voye prèv peman an epi ranpli fòm nan. Ekip la ap verifye demann ou an.'),
        SupportBotNode(
            id: 'renew_nat',
            paymentMethodId: 'natcash',
            requestImage: true,
            parent: 'renew',
            label: 'NatCash',
            answer:
                'Lè ou fin peye, peze bouton pou voye prèv peman an epi ranpli fòm nan. Ekip la ap verifye demann ou an.'),
        SupportBotNode(
            id: 'renew_zelle',
            paymentMethodId: 'zelle',
            requestImage: true,
            parent: 'renew',
            label: 'Zelle',
            answer:
                'Lè ou fin peye, peze bouton pou voye prèv peman an epi ranpli fòm nan. Ekip la ap verifye demann ou an.'),
        SupportBotNode(
            id: 'paid',
            requestPaymentProof: true,
            requestImage: true,
            requiresAuth: true,
            parent: '',
            label: 'Mwen deja peye',
            answer:
                'Peze bouton pou voye prèv peman an. Nan fòm nan, ajoute yon foto resi a kote montan, dat ak referans tranzaksyon an parèt klè. Ekip la ap verifye peman an anvan li konfime aktivasyon an.'),
        SupportBotNode(
            id: 'access',
            parent: '',
            label: 'VIP mwen bloke',
            answer: 'Ki pwoblèm ou genyen?'),
        SupportBotNode(
            id: 'access_paid',
            requestPaymentProof: true,
            requestImage: true,
            requiresAuth: true,
            parent: 'access',
            label: 'Mwen peye men VIP a pa aktive',
            answer:
                'Konekte sou kont ou te itilize pou abònman an. Si VIP a toujou bloke, peze bouton pou voye prèv peman an. Ou ka verifye tou si yon demann deja ap tann nan lis demann ou yo.'),
        SupportBotNode(
            id: 'access_error',
            requestImage: true,
            parent: 'access',
            label: 'Mwen wè yon mesaj erè',
            answer:
                'Voye mesaj erè a oswa yon kaptire ekran nan chat la. Di ekip la tou ki etap ou te fè anvan pwoblèm nan parèt.'),
        SupportBotNode(
            id: 'content',
            parent: '',
            label: 'Ki kote kontni VIP a ye?',
            answer:
                'Se sou kont CHOLOTO ou w ap jwenn kontni VIP a, tankou boul ak maryaj yo. Konekte sou kont ki gen abònman an.'),
      ]);
}

class SupportBotPlan {
  const SupportBotPlan({
    required this.id,
    required this.name,
    this.amountHtgMinor = 0,
    this.amountUsdMinor = 0,
    required this.months,
    this.enabled = true,
  });

  final String id;
  final String name;
  final int amountHtgMinor;
  final int amountUsdMinor;
  final int months;
  final bool enabled;

  int amountFor(String currency) => currency == 'HTG'
      ? amountHtgMinor
      : currency == 'USD'
          ? amountUsdMinor
          : 0;

  void validate() {
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,80}$').hasMatch(id) ||
        name.trim().isEmpty ||
        name.length > 60 ||
        amountHtgMinor < 0 ||
        amountHtgMinor > 100000000 ||
        amountUsdMinor < 0 ||
        amountUsdMinor > 100000000 ||
        (enabled && (amountHtgMinor == 0 || amountUsdMinor == 0)) ||
        months < 1 ||
        months > 36) {
      throw const FormatException('Plan tarifaire invalide.');
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amountHtgMinor': amountHtgMinor,
        'amountUsdMinor': amountUsdMinor,
        'months': months,
        'enabled': enabled,
      };

  factory SupportBotPlan.fromJson(Map<String, dynamic> data) => SupportBotPlan(
        id: data['id'] as String,
        name: data['name'] as String,
        amountHtgMinor: data['amountHtgMinor'] as int? ?? 0,
        amountUsdMinor: data['amountUsdMinor'] as int? ?? 0,
        months: data['months'] as int,
        enabled: data['enabled'] as bool? ?? true,
      );
}

class SupportBotPayment {
  const SupportBotPayment(
      {required this.id,
      required this.name,
      required this.currency,
      this.amountMinor = 0,
      this.months = 1,
      this.account = '',
      this.recipient = '',
      this.enabled = false});
  final String id;
  final String name;
  final String currency;
  final int amountMinor;
  final int months;
  final String account;
  final String recipient;
  final bool enabled;
  SupportBotPayment withPlan(SupportBotPlan plan) => SupportBotPayment(
        id: id,
        name: name,
        currency: currency,
        amountMinor: plan.amountFor(currency),
        months: plan.months,
        account: account,
        recipient: recipient,
        enabled: enabled,
      );
  static int? parseAmount(String text) {
    final normalized = text.trim().replaceAll(',', '.');
    if (!RegExp(r'^\d{1,7}(?:\.\d{1,2})?$').hasMatch(normalized)) return null;
    final parts = normalized.split('.');
    return int.parse(parts[0]) * 100 +
        (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
  }

  String get price => '${(amountMinor / 100).toStringAsFixed(2)} $currency';
  void validate() {
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,80}$').hasMatch(id) ||
        name.trim().isEmpty ||
        name.length > 60 ||
        !RegExp(r'^[A-Z]{3}$').hasMatch(currency) ||
        amountMinor < 0 ||
        amountMinor > 100000000 ||
        months < 1 ||
        months > 36 ||
        account.length > 180 ||
        recipient.length > 120 ||
        (enabled &&
            (amountMinor == 0 ||
                account.trim().isEmpty ||
                recipient.trim().isEmpty))) {
      throw const FormatException(
          'Complétez le prix, la devise, le compte et le bénéficiaire avant d’activer ce moyen de paiement.');
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'currency': currency,
        'amountMinor': amountMinor,
        'months': months,
        'account': account,
        'recipient': recipient,
        'enabled': enabled
      };
  factory SupportBotPayment.fromJson(Map<String, dynamic> data) =>
      SupportBotPayment(
          id: data['id'] as String,
          name: data['name'] as String,
          currency: data['currency'] as String,
          amountMinor: data['amountMinor'] as int,
          months: data['months'] as int,
          account: data['account'] as String,
          recipient: data['recipient'] as String,
          enabled: data['enabled'] as bool);
}
