import 'package:flutter/material.dart';

/// Fait apparaître [child] avec un fondu + léger glissement vers le haut, au
/// lieu d'apparaître d'un coup. [delay] permet de décaler plusieurs entrées
/// entre elles (ex. `Duration(milliseconds: 60 * index)` pour une liste),
/// laisse à `Duration.zero` pour une simple entrée en douceur sans effet
/// décalé (ex. une bulle de chat qui arrive seule).
///
/// L'animation ne se rejoue qu'à la création du widget (nouvel élément dans
/// une liste) — un item déjà affiché ne "re-rentre" pas à chaque
/// reconstruction tant que sa position dans l'arbre ne change pas.
class StaggeredEntrance extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const StaggeredEntrance({super.key, required this.child, this.delay = Duration.zero});

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    // Toujours différé (même avec delay: zero) pour que le premier build se
    // fasse à opacité 0 : sans ça, AnimatedOpacity démarrerait déjà à 1 et
    // aucune transition ne serait visible.
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.08),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
