import 'package:flutter/material.dart';

class CoachScreen extends StatelessWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6B66FF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(padding: const EdgeInsets.all(8.0), child: Container(decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.bolt, color: Colors.white))),
        title: const Text('COACH NUTRITION', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Objectif Kcal
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.pink.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: const Text('ANALYSE EN TEMPS RÉEL', style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(height: 20),
            const Text('OBJECTIF QUOTIDIEN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: const [
                Text('500', style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold)),
                Text(' kcal', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.pink)),
              ],
            ),
            const SizedBox(height: 8),
            RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                style: TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  TextSpan(text: 'Il vous reste '),
                  TextSpan(text: '500 kcal', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: ' pour atteindre votre\nobjectif de '),
                  TextSpan(text: 'Perte de Gras.', style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Besoins (Barres)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, spreadRadius: 1)]),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('VOS BESOINS', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12)), Text('Mis à jour il y a 2 min', style: TextStyle(color: Colors.grey.shade500, fontSize: 12))]),
                  const SizedBox(height: 16),
                  _buildProgressMacro('PROTÉINES', '112g', 0.8, primaryColor),
                  _buildProgressMacro('GLUCIDES', '180g', 0.6, Colors.orange),
                  _buildProgressMacro('LIPIDES', '45g', 0.4, Colors.pink),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Conseil IA
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: primaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: primaryColor.withOpacity(0.2), style: BorderStyle.solid)),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.bolt, color: primaryColor)),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('Conseil du Chef AI', style: TextStyle(fontWeight: FontWeight.bold)), SizedBox(height: 4), Text('"Pour optimiser votre perte de gras, privilégiez des protéines maigres..."', style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic, fontSize: 13))])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressMacro(String label, String value, double percent, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Icon(Icons.circle, size: 8, color: color), const SizedBox(width: 8), Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))]), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: percent, backgroundColor: color.withOpacity(0.2), color: color, minHeight: 6, borderRadius: BorderRadius.circular(4)),
        ],
      ),
    );
  }
}