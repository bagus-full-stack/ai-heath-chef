import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/l10n_extensions.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/meal_suggestions_provider.dart';
import '../providers/profile_provider.dart';
import '../utils/nutrition_targets.dart';
import '../widgets/animated_async_value.dart';
import '../widgets/meal_suggestion_card.dart';
import '../widgets/staggered_entrance.dart';

const Color kCoachPrimaryColor = Color(0xFF6B66FF);

class CoachScreen extends ConsumerWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openCoachChatSheet(context),
        backgroundColor: kCoachPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        label: Text(context.l10n.coachTitle),
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
                    Text(
                      context.l10n.coachNextMealIdeasTitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/meal_suggestions'),
                      child: Text(
                        context.l10n.coachSeeAllButton,
                        style: const TextStyle(
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
                child: _MealSuggestionsRow(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              sliver: SliverToBoxAdapter(
                child: _CoachTipCard(
                  title: context.l10n.coachTipTitle,
                  text: context.l10n.coachTipFatLossText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ouvre la feuille de chat du Coach IA. Public pour être réutilisable
/// depuis d'autres écrans (ex: l'écran "Idées repas").
void openCoachChatSheet(BuildContext context, {String? presetMessage}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _CoachChatSheet(presetMessage: presetMessage);
    },
  );
}

/// Ligne horizontale d'idées de repas générées par l'IA (aperçu limité),
/// utilisée sur l'écran d'accueil du Coach.
class _MealSuggestionsRow extends ConsumerWidget {
  const _MealSuggestionsRow();

  static const int _previewCount = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(mealSuggestionsProvider);

    return SizedBox(
      height: 285,
      child: suggestionsAsync.animatedWhen(
        loading: () => const Center(
          child: CircularProgressIndicator(color: kCoachPrimaryColor),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  context.l10n.coachMealSuggestionsErrorText,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.invalidate(mealSuggestionsProvider),
                  child: Text(context.l10n.coachRetryButton),
                ),
              ],
            ),
          ),
        ),
        data: (suggestions) {
          if (suggestions.isEmpty) {
            return Center(
              child: Text(
                context.l10n.coachMealSuggestionsEmptyText,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            );
          }

          final preview = suggestions.take(_previewCount).toList();
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: preview.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final suggestion = preview[index];
              return StaggeredEntrance(
                delay: Duration(milliseconds: 60 * index),
                child: SizedBox(
                  width: 280,
                  child: MealSuggestionCard(
                    suggestion: suggestion,
                    onAdd: () => openCoachChatSheet(
                      context,
                      presetMessage: context.l10n.coachAdjustMealPresetMessage(suggestion.title),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final avatarUrl = profileAsync.maybeWhen(
      data: (profile) => profile?.avatarUrl,
      orElse: () => null,
    );

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
        Expanded(
          child: Text(
            context.l10n.coachHeaderTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Icon(Icons.person, color: Colors.grey.shade500, size: 20)
                  : null,
            ),
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                padding: const EdgeInsets.all(1.5),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const _PulsingDot(color: Colors.greenAccent, size: 10),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _PulsingDot(color: Color(0xFFF06B9E), size: 10),
            const SizedBox(width: 10),
            Text(
              context.l10n.coachRealtimeBannerLabel,
              style: const TextStyle(
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

/// Point qui pulse en continu (opacité) pour signaler une activité "en
/// direct" — utilisé sur les indicateurs qui prétendent montrer du temps
/// réel mais qui, sans ça, restent visuellement figés.
class _PulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  const _PulsingDot({required this.color, required this.size});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

class _DailyObjectiveCard extends ConsumerWidget {
  const _DailyObjectiveCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final mealsAsync = ref.watch(todayMealsProvider);

    final targets = profileAsync.maybeWhen(
      data: computeNutritionTargets,
      orElse: () => NutritionTargets.fallback,
    );
    final goalLabel = profileAsync.maybeWhen(
      data: (profile) => profile?.goalLabel(context) ?? context.l10n.coachGoalMaintainLabel,
      orElse: () => context.l10n.coachGoalMaintainLabel,
    );
    final totalKcal = mealsAsync.maybeWhen(
      data: (meals) => meals.fold<int>(0, (sum, meal) => sum + meal.totalKcal),
      orElse: () => 0,
    );

    var remainingKcal = targets.kcal - totalKcal;
    if (remainingKcal < 0) remainingKcal = 0;

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
          Text(
            context.l10n.coachDailyObjectiveTitle,
            style: const TextStyle(
              color: Color(0xFF6F7688),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(fontWeight: FontWeight.w900),
              children: [
                TextSpan(
                  text: '$remainingKcal',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 52,
                    height: 1,
                  ),
                ),
                TextSpan(
                  text: context.l10n.coachKcalUnitLabel,
                  style: const TextStyle(
                    color: Color(0xFFF06B9E),
                    fontSize: 28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.coachRemainingKcalText(remainingKcal, goalLabel),
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

class _NeedsCard extends ConsumerWidget {
  const _NeedsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final mealsAsync = ref.watch(todayMealsProvider);

    final targets = profileAsync.maybeWhen(
      data: computeNutritionTargets,
      orElse: () => NutritionTargets.fallback,
    );

    double totalProt = 0;
    double totalGluc = 0;
    double totalLip = 0;
    mealsAsync.whenData((meals) {
      for (final meal in meals) {
        totalProt += meal.totalProt;
        totalGluc += meal.totalGluc;
        totalLip += meal.totalLip;
      }
    });

    double progressOf(double value, double target) {
      if (target <= 0) return 0;
      final progress = value / target;
      return progress > 1 ? 1 : progress;
    }

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
              Expanded(
                child: Text(
                  context.l10n.coachNeedsTitle,
                  style: const TextStyle(
                    color: kCoachPrimaryColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _NeedRow(
            icon: Icons.fitness_center,
            iconColor: const Color(0xFF6B66FF),
            label: context.l10n.coachProteinLabel,
            value: context.l10n.coachNeedValueGrams(totalProt.toInt(), targets.protein.toInt()),
            progress: progressOf(totalProt, targets.protein),
          ),
          const SizedBox(height: 14),
          _NeedRow(
            icon: Icons.grain_rounded,
            iconColor: const Color(0xFFF06B9E),
            label: context.l10n.coachCarbsLabel,
            value: context.l10n.coachNeedValueGrams(totalGluc.toInt(), targets.carbs.toInt()),
            progress: progressOf(totalGluc, targets.carbs),
          ),
          const SizedBox(height: 14),
          _NeedRow(
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFFFB54A),
            label: context.l10n.coachFatLabel,
            value: context.l10n.coachNeedValueGrams(totalLip.toInt(), targets.fat.toInt()),
            progress: progressOf(totalLip, targets.fat),
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
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  tween: Tween<double>(begin: 0, end: progress),
                  builder: (context, animatedProgress, child) => LinearProgressIndicator(
                    value: animatedProgress,
                    minHeight: 6,
                    backgroundColor: iconColor.withValues(alpha: 0.16),
                    color: iconColor,
                  ),
                ),
              ),
            ],
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

class _CoachChatSheet extends ConsumerStatefulWidget {
  final String? presetMessage;

  const _CoachChatSheet({this.presetMessage});

  @override
  ConsumerState<_CoachChatSheet> createState() => _CoachChatSheetState();
}

class _CoachChatSheetState extends ConsumerState<_CoachChatSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

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
    if (text.isEmpty || _isSending) {
      return;
    }
    _textController.clear();
    setState(() => _isSending = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
    try {
      await ref.read(chatProvider.notifier).sendMessage(text);
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
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

  Future<void> _resetConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.coachResetDialogTitle),
        content: Text(context.l10n.coachResetDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.coachCancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.coachResetButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    _textController.clear();
    await ref.read(chatProvider.notifier).resetConversation();
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.coachTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              context.l10n.coachSheetSubtitle,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _resetConversation,
                        icon: const Icon(Icons.refresh_rounded),
                        tooltip: context.l10n.coachResetTooltip,
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
                        label: context.l10n.coachPromptIdeasLabel,
                        onTap: () {
                          _textController.text = context.l10n.coachPromptIdeasMessage;
                        },
                      ),
                      _PromptChip(
                        label: context.l10n.coachPromptPostWorkoutLabel,
                        onTap: () {
                          _textController.text = context.l10n.coachPromptPostWorkoutMessage;
                        },
                      ),
                      _PromptChip(
                        label: context.l10n.coachPromptFatLossLabel,
                        onTap: () {
                          _textController.text = context.l10n.coachPromptFatLossMessage;
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
                          itemCount: messages.length + (_isSending ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == messages.length) {
                              return const StaggeredEntrance(
                                key: ValueKey('typing_indicator'),
                                child: _TypingBubble(),
                              );
                            }
                            final message = messages[index];
                            return StaggeredEntrance(
                              key: ValueKey(message.id),
                              child: _ChatBubble(message: message),
                            );
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
                              hintText: context.l10n.coachInputHint,
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
                          onTap: _isSending ? null : _sendMessage,
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: _isSending
                                  ? primaryColor.withValues(alpha: 0.5)
                                  : primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _isSending
                                  ? const SizedBox(
                                      key: ValueKey('sending'),
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(Colors.white),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send_rounded,
                                      key: ValueKey('send'),
                                      color: Colors.white,
                                      size: 20,
                                    ),
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

/// Bulle "le coach écrit..." affichée à la place de la réponse pendant
/// l'attente de l'IA — sans ça l'utilisateur n'a aucun retour entre l'envoi
/// du message et l'arrivée de la réponse (qui peut prendre plusieurs
/// secondes, surtout en IA locale).
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final t = (_controller.value - index * 0.2) % 1.0;
                final bounce = t < 0.5 ? t * 2 : (1 - t) * 2;
                return Padding(
                  padding: EdgeInsets.only(right: index < 2 ? 5 : 0),
                  child: Transform.translate(
                    offset: Offset(0, -4 * bounce),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: kCoachPrimaryColor.withValues(alpha: 0.5 + bounce * 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
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
