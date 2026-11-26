/// Speakaboo Playful Home Screen
///
/// Warm, confidence-building hub with greeting pill, rotating headline,
/// character presence, Start Speaking + Today's Mission CTAs, real user stats,
/// daily mission strip, 4 practice mode tiles, and companion explorer.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/character.dart';
import '../models/learning_models.dart';
import '../providers/auth_provider.dart';
import '../providers/conversation_provider.dart';
import '../services/api_service.dart';
import '../theme/speakaboo_theme.dart';
import '../widgets/playful/playful.dart';
import 'character_detail_screen.dart';
import 'scenarios_screen.dart';
import 'settings_screen.dart';
import 'shadowing_screen.dart';
import 'topics_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  LearningProgress? _progress;
  List<Mission> _missions = const [];
  List<Character> _characters = const [];
  bool _loading = true;
  CharacterMood _heroMood = CharacterMood.idle;
  late final AnimationController _floatCtrl;

  static const _headlines = [
    ('Your voice is ', 'stronger today!'),
    ('One brave ', 'sentence at a time!'),
    ('Speak with ', 'calm confidence!'),
  ];

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final api = context.read<ApiService>();
    final auth = context.read<AuthProvider>();
    try {
      final results = await Future.wait<Object>([
        api.getProgress(auth.userId).catchError((_) => LearningProgress(
              userId: auth.userId,
              level: 'beginner',
              xp: 0,
              totalWordsSpoken: 0,
              streakDays: 0,
              weeklyMinutes: 0.0,
              accuracyScore: 0.0,
            )),
        api.getMissions(auth.userId).catchError((_) => MissionsResponse(
              date: '',
              missions: const [],
              streak: 0,
              freezes: 0,
            )),
        api.getCharacters().catchError((_) => <Character>[]),
      ]);

      if (!mounted) return;
      final prog = results[0] as LearningProgress;
      final missionResp = results[1] as MissionsResponse;
      final chars = results[2] as List<Character>;

      setState(() {
        _progress = prog;
        _missions = missionResp.missions;
        _characters = chars;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[HomeScreen] load error: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _stagger(Widget child, int index, bool reduceMotion) {
    if (reduceMotion) return child;
    return child
        .animate()
        .fadeIn(duration: 280.ms, delay: (index * 60).ms, curve: Curves.easeOut)
        .slideY(
          begin: 0.06,
          end: 0,
          duration: 320.ms,
          delay: (index * 60).ms,
          curve: Curves.easeOutCubic,
        );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final auth = context.watch<AuthProvider>();
    final conv = context.watch<ConversationProvider>();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final name = auth.profile?.displayName ?? 'Learner';
    final headlineIndex = DateTime.now().day % _headlines.length;
    final (hPrefix, hHighlight) = _headlines[headlineIndex];

    final activeMission = _missions.isNotEmpty ? _missions.first : null;
    final missionProgress = activeMission == null
        ? 0.0
        : (activeMission.progress / (activeMission.target == 0 ? 1 : activeMission.target))
            .clamp(0.0, 1.0);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: c.primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              SpeakabooTheme.spacingMd,
              SpeakabooTheme.spacing12,
              SpeakabooTheme.spacingMd,
              SpeakabooTheme.spacingXl,
            ),
            children: [
              // 1. Friendly Greeting Header
              _stagger(
                PlayfulGreetingHeader(
                  name: name,
                  trailing: IconButton(
                    tooltip: 'Settings',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: c.surfaceWarm,
                      minimumSize: const Size(48, 48),
                    ),
                    icon: Icon(Icons.settings_rounded, color: c.textPrimary),
                  ),
                ),
                0,
                reduceMotion,
              ),
              const SizedBox(height: SpeakabooTheme.spacingMd),

              // 2. Hero Card (Headline + Character + Floating Props + Dual CTAs)
              _stagger(
                PlayfulCard(
                  backgroundColor: c.surfaceWarm,
                  padding: const EdgeInsets.all(SpeakabooTheme.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PlayfulMarkerText(
                                  prefix: hPrefix,
                                  highlighted: hHighlight,
                                  fontSize: 28,
                                ),
                                const SizedBox(height: SpeakabooTheme.spacingSm),
                                Text(
                                  'Friendly English practice at your own pace. Mistakes are always welcome here.',
                                  style: SpeakabooTheme.bodyStyle(
                                    color: c.textSecondary,
                                    size: SpeakabooTheme.baseFontSize,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: SpeakabooTheme.spacing12),
                          SizedBox(
                            width: 118,
                            height: 126,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _heroMood = _heroMood == CharacterMood.idle
                                          ? CharacterMood.celebrating
                                          : CharacterMood.idle;
                                    });
                                  },
                                  child: PlayfulCharacter(
                                    characterId: conv.currentCharacterId ?? 'rule_farmer',
                                    mood: _heroMood,
                                    size: 98,
                                  ),
                                ),
                                _FloatingBadge(
                                  controller: _floatCtrl,
                                  reduceMotion: reduceMotion,
                                  phaseOffset: 0.0,
                                  alignment: Alignment.topRight,
                                  emoji: '🌱',
                                  bg: c.pastelMint,
                                  onTap: () => setState(() => _heroMood = CharacterMood.encouraging),
                                ),
                                _FloatingBadge(
                                  controller: _floatCtrl,
                                  reduceMotion: reduceMotion,
                                  phaseOffset: 0.5,
                                  alignment: Alignment.bottomLeft,
                                  emoji: '✨',
                                  bg: c.pastelYellow,
                                  onTap: () => setState(() => _heroMood = CharacterMood.celebrating),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: SpeakabooTheme.spacingLg),
                      PlayfulButton(
                        label: 'Start Speaking',
                        icon: Icons.mic_rounded,
                        fullWidth: true,
                        onPressed: () => widget.onNavigateTab?.call(1),
                      ),
                      const SizedBox(height: SpeakabooTheme.spacing12),
                      PlayfulButton(
                        label: "Today's Mission",
                        icon: Icons.bolt_rounded,
                        variant: PlayfulButtonVariant.sunny,
                        fullWidth: true,
                        onPressed: () => widget.onNavigateTab?.call(3),
                      ),
                    ],
                  ),
                ),
                1,
                reduceMotion,
              ),
              const SizedBox(height: SpeakabooTheme.spacingMd),

              // 3. Three Big Numbers (User's own real progress)
              _stagger(
                Row(
                  children: [
                    Expanded(
                      child: PlayfulStatChip(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: c.coral,
                        washColor: c.pastelPink,
                        value: _progress?.streakDays ?? 0,
                        suffix: 'd',
                        label: 'Streak',
                      ),
                    ),
                    const SizedBox(width: SpeakabooTheme.spacingSm),
                    Expanded(
                      child: PlayfulStatChip(
                        icon: Icons.star_rounded,
                        iconColor: c.sunnyEdge,
                        washColor: c.pastelYellow,
                        value: _progress?.xp ?? 0,
                        label: 'XP',
                      ),
                    ),
                    const SizedBox(width: SpeakabooTheme.spacingSm),
                    Expanded(
                      child: PlayfulStatChip(
                        icon: Icons.schedule_rounded,
                        iconColor: c.skyEdge,
                        washColor: c.pastelSky,
                        value: (_progress?.weeklyMinutes ?? 0).round(),
                        suffix: 'm',
                        label: 'This Week',
                      ),
                    ),
                  ],
                ),
                2,
                reduceMotion,
              ),
              const SizedBox(height: SpeakabooTheme.spacingMd),

              // 4. Daily Mission Strip
              _stagger(
                PlayfulMissionBar(
                  title: activeMission?.title ?? 'Complete 1 speaking session today',
                  rewardLabel: '+${activeMission?.xpReward ?? 30} XP',
                  progress: missionProgress,
                  onTap: () => widget.onNavigateTab?.call(3),
                ),
                3,
                reduceMotion,
              ),
              const SizedBox(height: SpeakabooTheme.spacingLg),

              // 5. Four Practice Modes
              _stagger(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ways to Practice',
                      style: SpeakabooTheme.displayStyle(
                        color: c.textPrimary,
                        size: SpeakabooTheme.headingSize,
                      ),
                    ),
                    const SizedBox(height: SpeakabooTheme.spacing12),
                    GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: SpeakabooTheme.spacing12,
                      crossAxisSpacing: SpeakabooTheme.spacing12,
                      childAspectRatio: 2.05,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        PlayfulModeTile(
                          icon: Icons.chat_bubble_rounded,
                          title: 'Free Talk',
                          subtitle: 'Chat naturally',
                          washColor: c.pastelLavender,
                          iconColor: c.primary,
                          onTap: () => widget.onNavigateTab?.call(1),
                        ),
                        PlayfulModeTile(
                          icon: Icons.theater_comedy_rounded,
                          title: 'Scenarios',
                          subtitle: 'Real-life roles',
                          washColor: c.pastelPink,
                          iconColor: c.coralEdge,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ScenariosScreen()),
                          ),
                        ),
                        PlayfulModeTile(
                          icon: Icons.explore_rounded,
                          title: 'Topics',
                          subtitle: 'Pick a theme',
                          washColor: c.pastelMint,
                          iconColor: c.mintEdge,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TopicsScreen()),
                          ),
                        ),
                        PlayfulModeTile(
                          icon: Icons.record_voice_over_rounded,
                          title: 'Shadowing',
                          subtitle: 'Echo & flow',
                          washColor: c.pastelSky,
                          iconColor: c.skyEdge,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ShadowingScreen()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                4,
                reduceMotion,
              ),
              const SizedBox(height: SpeakabooTheme.spacingLg),

              // 6. Explore Companions (or designed loading/empty state)
              _stagger(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Meet Your Companions',
                          style: SpeakabooTheme.displayStyle(
                            color: c.textPrimary,
                            size: SpeakabooTheme.headingSize,
                          ),
                        ),
                        TextButton(
                          onPressed: () => widget.onNavigateTab?.call(2),
                          child: Text(
                            'See all',
                            style: SpeakabooTheme.bodyStyle(
                              color: c.primary,
                              weight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: SpeakabooTheme.spacingSm),
                    if (_loading)
                      const PlayfulCard(
                        child: PlayfulLoadingState(message: 'Calling your companions...'),
                      )
                    else if (_characters.isEmpty)
                      PlayfulEmptyState(
                        title: 'Companions are on the way!',
                        message: 'Connect to the backend or start talking with Farmer Reggie right away.',
                        actionLabel: 'Start Speaking',
                        onAction: () => widget.onNavigateTab?.call(1),
                      )
                    else
                      SizedBox(
                        height: 176,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _characters.length,
                          separatorBuilder: (_, _) => const SizedBox(width: SpeakabooTheme.spacing12),
                          itemBuilder: (context, index) {
                            final ch = _characters[index];
                            final washes = [c.pastelMint, c.pastelSky, c.pastelLavender, c.pastelPink];
                            final bg = washes[index % washes.length];
                            return SizedBox(
                              width: 150,
                              child: PlayfulCard(
                                backgroundColor: bg,
                                padding: const EdgeInsets.all(SpeakabooTheme.spacing12),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CharacterDetailScreen(character: ch),
                                    ),
                                  );
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    PlayfulCharacter(
                                      characterId: ch.id,
                                      mood: CharacterMood.idle,
                                      size: 74,
                                    ),
                                    const SizedBox(height: SpeakabooTheme.spacingSm),
                                    Text(
                                      ch.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: SpeakabooTheme.displayStyle(
                                        color: c.textPrimary,
                                        size: SpeakabooTheme.baseFontSize,
                                      ),
                                    ),
                                    Text(
                                      ch.isFree ? 'Ready to talk' : '${ch.priceBdt} BDT',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: SpeakabooTheme.bodyStyle(
                                        color: c.textSecondary,
                                        size: SpeakabooTheme.captionSize,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
                5,
                reduceMotion,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  final AnimationController controller;
  final bool reduceMotion;
  final double phaseOffset;
  final Alignment alignment;
  final String emoji;
  final Color bg;
  final VoidCallback? onTap;

  const _FloatingBadge({
    required this.controller,
    required this.reduceMotion,
    required this.phaseOffset,
    required this.alignment,
    required this.emoji,
    required this.bg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final raw = (controller.value + phaseOffset) % 1.0;
            final wave = raw < 0.5 ? raw * 2 : (1.0 - raw) * 2;
            final dy = reduceMotion ? 0.0 : (wave - 0.5) * 8.0;
            return Transform.translate(offset: Offset(0, dy), child: child);
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(color: context.colors.borderSubtle),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 14)),
          ),
        ),
      ),
    );
  }
}
