import 'dart:convert';

class SupportBotNode {
  const SupportBotNode(
      {required this.id,
      required this.parent,
      required this.label,
      required this.answer,
      this.requiresAuth = false,
      this.requestImage = false});
  final String id;
  final String parent;
  final String label;
  final String answer;
  final bool requiresAuth;
  final bool requestImage;
  Map<String, dynamic> toJson() => {
        'id': id,
        'parent': parent,
        'label': label,
        'answer': answer,
        'requiresAuth': requiresAuth,
        'requestImage': requestImage
      };
  factory SupportBotNode.fromJson(Map<String, dynamic> data) => SupportBotNode(
      id: data['id'] as String,
      parent: data['parent'] as String,
      label: data['label'] as String,
      answer: data['answer'] as String,
      requiresAuth: data['requiresAuth'] as bool? ?? false,
      requestImage: data['requestImage'] as bool? ?? false);
}

class SupportBotConfig {
  const SupportBotConfig(
      {required this.enabled,
      required this.greeting,
      required this.nodes,
      this.revision = 0});
  final bool enabled;
  final String greeting;
  final List<SupportBotNode> nodes;
  final int revision;
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
        'revision': revision
      };
  factory SupportBotConfig.fromJson(Map<String, dynamic> data) {
    final config = SupportBotConfig(
        enabled: data['enabled'] as bool,
        greeting: data['greeting'] as String,
        revision: data['revision'] as int,
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
    final ids = nodes.map((n) => n.id).toSet();
    if (ids.length != nodes.length) {
      throw const FormatException('Identifiants dupliqués.');
    }
    for (final n in nodes) {
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
            answer:
                'Ou ka mande ekip la pri aktyèl la ak enfòmasyon pou peye pa MonCash oswa NatCash. Chwazi pale ak ekip la pou nou konfime yo anvan ou voye kòb la.'),
        SupportBotNode(
            id: 'vip_abroad',
            requiresAuth: true,
            parent: 'vip',
            label: 'Yon lòt peyi',
            answer:
                'Di ekip la nan ki peyi ou ye pou nou konfime pri a ak mwayen peman ki disponib pou ou.'),
        SupportBotNode(
            id: 'renew',
            requiresAuth: true,
            parent: '',
            label: 'Mwen vle renouvle VIP mwen',
            answer:
                'Konekte sou kont CHOLOTO ki gen abònman ou a. Ki mwayen peman ou vle itilize?'),
        SupportBotNode(
            id: 'renew_mon',
            parent: 'renew',
            label: 'MonCash',
            answer:
                'Mande ekip la konfime montan, nimewo MonCash la ak non moun k ap resevwa peman an anvan ou voye kòb la.'),
        SupportBotNode(
            id: 'renew_nat',
            parent: 'renew',
            label: 'NatCash',
            answer:
                'Mande ekip la konfime montan, nimewo NatCash la ak non moun k ap resevwa peman an anvan ou voye kòb la.'),
        SupportBotNode(
            id: 'renew_zelle',
            parent: 'renew',
            label: 'Zelle',
            answer:
                'Mande ekip la konfime montan ak enfòmasyon Zelle yo anvan ou voye kòb la.'),
        SupportBotNode(
            id: 'paid',
            requestImage: true,
            requiresAuth: true,
            parent: '',
            label: 'Mwen deja peye',
            answer:
                'Voye yon foto oswa yon kaptire ekran resi a nan chat la. Fòk montan, dat ak referans tranzaksyon an parèt klè. Ekip la ap verifye peman an anvan li konfime aktivasyon an.'),
        SupportBotNode(
            id: 'access',
            parent: '',
            label: 'VIP mwen bloke',
            answer: 'Ki pwoblèm ou genyen?'),
        SupportBotNode(
            id: 'access_paid',
            requestImage: true,
            requiresAuth: true,
            parent: 'access',
            label: 'Mwen peye men VIP a pa aktive',
            answer:
                'Konekte sou kont ou te itilize pou abònman an. Si VIP a toujou bloke, voye resi peman an ak yon kaptire ekran nan chat la pou ekip la verifye.'),
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
