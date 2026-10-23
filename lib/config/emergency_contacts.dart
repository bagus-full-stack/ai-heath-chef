/// Ressources d'urgence affichées par le filtre de sécurité du coach (voir
/// lib/utils/health_risk_filter.dart) quand un message évoque un risque
/// suicidaire/d'automutilation.
///
/// ATTENTION : les numéros ci-dessous n'ont pas été vérifiés par un tiers
/// dans le cadre de cet audit — à confirmer manuellement avant mise en
/// production :
/// - "3114" : numéro national de prévention du suicide (France), gratuit, 24/7.
/// - "15" : SAMU, urgences médicales (France).
/// - "112" : numéro d'urgence unique, valable dans toute l'Union européenne.
/// Aucun autre numéro n'est inventé ici : les locales hors FR reçoivent un
/// texte générique renvoyant vers le 112 (zone UE) plutôt qu'un numéro nommé
/// non vérifié pour leur pays.
class EmergencyContacts {
  EmergencyContacts._();

  static String lineFor(String languageCode) {
    switch (languageCode) {
      case 'fr':
        return 'En France : 3114 (numéro national de prévention du suicide, gratuit, 24/7) ou 15 (SAMU). Partout en Europe, en urgence vitale : 112.';
      default:
        return 'In the EU, call 112 for emergencies. Please also reach out to your local crisis line or a health professional as soon as you can.';
    }
  }
}
