import 'package:flutter/material.dart';

/// Couleurs de marque Fodli (logo : assets/icon/icon.png) et jetons clair/sombre.
///
/// shortcut: [dark] est un drapeau statique posé par `main.dart` à chaque
/// changement de luminosité (l'arbre est reconstruit via une `Key`), ce qui
/// évite de passer un `BuildContext` à chaque couleur ; à remplacer par une
/// `ThemeExtension` si le thème devient réglable par écran.
class AppColors {
  AppColors._();

  static bool dark = false;

  static Color _p(Color light, Color darkColor) => dark ? darkColor : light;

  /// Vert forêt du logo : couleur d'action (boutons, onglet actif, liens).
  /// En sombre : vert moyen, lisible sur fond noir et assez foncé pour du texte blanc dessus.
  static Color get brand => _p(const Color(0xFF134E3F), const Color(0xFF2F8A6B));

  /// Citron du logo : accent sur fonds sombres.
  static const lime = Color(0xFFC4F26A);

  static Color get brandTint => _p(const Color(0xFFEAF3EC), const Color(0xFF1B2E26));
  static Color get brandTintSoft => _p(const Color(0xFFF3F8F4), const Color(0xFF16231D));

  // Surfaces
  static Color get bg => _p(const Color(0xFFFBF7EC), const Color(0xFF101312));
  static Color get surface => _p(const Color(0xFFFFFEFB), const Color(0xFF1A1D1C));

  // Échelle de gris : même nom que Material, inversée en sombre.
  static Color get grey50 => _p(const Color(0xFFFAFAFA), const Color(0xFF1E2120));
  static Color get grey100 => _p(const Color(0xFFF5F5F5), const Color(0xFF242827));
  static Color get grey200 => _p(const Color(0xFFEEEEEE), const Color(0xFF2E3231));
  static Color get grey300 => _p(const Color(0xFFE0E0E0), const Color(0xFF3B4140));
  static Color get grey400 => _p(const Color(0xFFBDBDBD), const Color(0xFF5E6563));
  static Color get grey => _p(const Color(0xFF9E9E9E), const Color(0xFF858C8A));
  static Color get grey500 => _p(const Color(0xFF9E9E9E), const Color(0xFF858C8A));
  static Color get grey600 => _p(const Color(0xFF757575), const Color(0xFFA3AAA8));
  static Color get grey700 => _p(const Color(0xFF616161), const Color(0xFFBCC2C0));

  // Texte
  static Color get ink => _p(Colors.black, const Color(0xFFF2F4F3));
  static Color get ink87 => _p(Colors.black87, const Color(0xDEF2F4F3));
  static Color get ink54 => _p(Colors.black54, const Color(0x8AF2F4F3));
  static Color get ink45 => _p(Colors.black45, const Color(0x73F2F4F3));
  static Color get ink38 => _p(Colors.black38, const Color(0x61F2F4F3));

  // Encarts d'avertissement (ambre) et pastille rose du coach
  static Color get warnBg => _p(const Color(0xFFFFF4E5), const Color(0xFF2E2414));
  static Color get warnBorder => _p(const Color(0xFFFFD9A0), const Color(0xFF5C4520));
  static Color get warnIcon => _p(const Color(0xFFB8791A), const Color(0xFFE5A94A));
  static Color get warnText => _p(const Color(0xFF7A5310), const Color(0xFFF0CD8E));
  static Color get pinkBg => _p(const Color(0xFFEAF3EC), const Color(0xFF1B2E26));
  static Color get pinkBorder => _p(const Color(0xFFCFE3D6), const Color(0xFF2F5A47));

  // Macros : trois teintes de la marque (vert, citron, terre cuite) au lieu de bleu/orange/rose.
  static Color get protein => _p(const Color(0xFF2F7D63), const Color(0xFF4FB38F));
  static Color get carbs => _p(const Color(0xFF8DB82E), const Color(0xFFC4F26A));
  static Color get fat => _p(const Color(0xFFD9694A), const Color(0xFFE88A70));
}
