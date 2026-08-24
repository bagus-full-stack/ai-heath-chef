import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message.dart';
import '../providers/chat_provider.dart';

const Color kCoachPrimaryColor = Color(0xFF6B66FF);

class CoachScreen extends ConsumerWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openChatSheet(context),
        backgroundColor: kCoachPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        label: const Text('Coach IA'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              sliver: SliverToBoxAdapter(
                child: _Header(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: _RealtimeBanner(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _DailyObjectiveCard(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _NeedsCard(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Idées Prochain Repas',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _openChatSheet(context),
                      child: const Text(
                        'Tout voir',
                        style: TextStyle(
                          color: kCoachPrimaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: 275,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _mealSuggestions.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      return _MealSuggestionCard(
                        suggestion: _mealSuggestions[index],
                        onAdd: () => _openChatSheet(
                          context,
                          presetMessage: 'Ajuste ce repas pour mon objectif: ${_mealSuggestions[index].title}',
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              sliver: SliverToBoxAdapter(
                child: _CoachTipCard(
                  title: 'Conseil du Chef IA',
                  text:
                      'Pour optimiser votre perte de gras, privilégiez des sources de protéines maigres comme le blanc de poulet ou le tofu pour votre prochain repas.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChatSheet(BuildContext context, {String? presetMessage}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _CoachChatSheet(presetMessage: presetMessage);
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.bolt, color: Colors.white, size: 22),
        ),
        const Expanded(
          child: Text(
            'COACH NUTRITION',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=120&q=80',
              ),
            ),
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RealtimeBanner extends StatelessWidget {
  const _RealtimeBanner();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFCE8EF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFF7C6D6)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: Color(0xFFF06B9E), size: 10),
            SizedBox(width: 10),
            Text(
              'ANALYSE EN TEMPS RÉEL',
              style: TextStyle(
                color: Color(0xFFF06B9E),
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyObjectiveCard extends StatelessWidget {
  const _DailyObjectiveCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'OBJECTIF QUOTIDIEN',
            style: TextStyle(
              color: Color(0xFF6F7688),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(fontWeight: FontWeight.w900),
              children: [
                TextSpan(
                  text: '500',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 52,
                    height: 1,
                  ),
                ),
                TextSpan(
                  text: ' kcal',
                  style: TextStyle(
                    color: Color(0xFFF06B9E),
                    fontSize: 28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Il vous reste 500 kcal pour atteindre votre objectif de '
            'Perte de Gras.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _NeedsCard extends StatelessWidget {
  const _NeedsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: kCoachPrimaryColor),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'VOS BESOINS',
                  style: TextStyle(
                    color: kCoachPrimaryColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Text(
                'Mis à jour il y a 2 min',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _NeedRow(
            icon: Icons.fitness_center,
            iconColor: Color(0xFF6B66FF),
            label: 'PROTÉINES',
            value: '112g',
            progress: 0.72,
          ),
          const SizedBox(height: 14),
          const _NeedRow(
            icon: Icons.grain_rounded,
            iconColor: Color(0xFFF06B9E),
            label: 'GLUCIDES',
            value: '180g',
            progress: 0.84,
          ),
          const SizedBox(height: 14),
          const _NeedRow(
            icon: Icons.local_fire_department_rounded,
            iconColor: Color(0xFFFFB54A),
            label: 'LIPIDES',
            value: '45g',
            progress: 0.66,
          ),
        ],
      ),
    );
  }
}

class _NeedRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final double progress;

  const _NeedRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF556070),
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF202733),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: iconColor.withValues(alpha: 0.16),
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MealSuggestion {
  final String timeSlot;
  final String title;
  final String kcal;
  final String prot;
  final String gluc;
  final String lip;
  final String imageUrl;

  const _MealSuggestion({
    required this.timeSlot,
    required this.title,
    required this.kcal,
    required this.prot,
    required this.gluc,
    required this.lip,
    required this.imageUrl,
  });
}

class _MealSuggestionCard extends StatelessWidget {
  final _MealSuggestion suggestion;
  final VoidCallback onAdd;

  const _MealSuggestionCard({
    required this.suggestion,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Image.network(
                suggestion.imageUrl,
                height: 165,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    suggestion.timeSlot,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department_outlined,
                      size: 16,
                      color: kCoachPrimaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      suggestion.kcal,
                      style: const TextStyle(
                        color: kCoachPrimaryColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _MacroMini(label: 'PROT', value: suggestion.prot),
                    _MacroMini(label: 'GLUC', value: suggestion.gluc),
                    _MacroMini(label: 'LIP', value: suggestion.lip),
                    GestureDetector(
                      onTap: onAdd,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: kCoachPrimaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroMini extends StatelessWidget {
  final String label;
  final String value;

  const _MacroMini({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _CoachTipCard extends StatelessWidget {
  final String title;
  final String text;

  const _CoachTipCard({
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: kCoachPrimaryColor.withValues(alpha: 0.18),
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.flash_on_rounded,
              color: kCoachPrimaryColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final List<_MealSuggestion> _mealSuggestions = [
  _MealSuggestion(
    timeSlot: 'Déjeuner',
    title: 'Salade de Quinoa & Saumon',
    kcal: '380 kcal',
    prot: '32g',
    gluc: '25g',
    lip: '18g',
    imageUrl:
        'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?auto=format&fit=crop&w=800&q=80',
  ),
  _MealSuggestion(
    timeSlot: 'Dîner',
    title: 'Bowl de Poulet & Riz',
    kcal: '420 kcal',
    prot: '38g',
    gluc: '41g',
    lip: '12g',
    imageUrl:
        'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=800&q=80',
  ),
  _MealSuggestion(
    timeSlot: 'Collation',
    title: 'Skyr, fruits rouges & noix',
    kcal: '210 kcal',
    prot: '20g',
    gluc: '16g',
    lip: '8g',
    imageUrl:
        'https://images.unsplash.com/photo-1490474418585-ba9bad8fd0ea?auto=format&fit=crop&w=800&q=80',
  ),
];

class _CoachChatSheet extends ConsumerStatefulWidget {
  final String? presetMessage;

  const _CoachChatSheet({this.presetMessage});

  @override
  ConsumerState<_CoachChatSheet> createState() => _CoachChatSheetState();
}

class _CoachChatSheetState extends ConsumerState<_CoachChatSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.presetMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _textController.text = widget.presetMessage!;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      return;
    }
    await ref.read(chatProvider.notifier).sendMessage(text);
    _textController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = kCoachPrimaryColor;
    final messagesAsync = ref.watch(chatProvider);
    final messages = messagesAsync.value ?? const <ChatMessage>[];

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Coach IA',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Pose une question sur tes repas',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PromptChip(
                        label: 'Idées repas',
                        onTap: () {
                          _textController.text = 'Donne-moi une idée de repas riche en protéines.';
                        },
                      ),
                      _PromptChip(
                        label: 'Après sport',
                        onTap: () {
                          _textController.text = 'Que manger après ma séance pour récupérer ?';
                        },
                      ),
                      _PromptChip(
                        label: 'Perte de gras',
                        onTap: () {
                          _textController.text = 'Comment optimiser ma perte de gras aujourd’hui ?';
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: messagesAsync.isLoading && messages.isEmpty
                      ? Center(
                          child: CircularProgressIndicator(
                            color: primaryColor,
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            return _ChatBubble(message: message);
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                            decoration: InputDecoration(
                              hintText: 'Écris ta question...',
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: _sendMessage,
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PromptChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PromptChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      backgroundColor: const Color(0xFFF5F2FF),
      label: Text(
        label,
        style: const TextStyle(
          color: kCoachPrimaryColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? kCoachPrimaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
