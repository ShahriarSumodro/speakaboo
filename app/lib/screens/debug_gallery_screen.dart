/// Debug Gallery showcasing every Speakaboo Playful Design System component.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/speakaboo_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/playful/playful.dart';

class DebugGalleryScreen extends StatefulWidget {
  const DebugGalleryScreen({super.key});

  @override
  State<DebugGalleryScreen> createState() => _DebugGalleryScreenState();
}

class _DebugGalleryScreenState extends State<DebugGalleryScreen> {
  CharacterMood _mood = CharacterMood.idle;
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final themeCtrl = context.watch<ThemeController?>();
    final currentTheme = themeCtrl?.selection ?? (context.isDarkMode ? 'dark' : 'light');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playful Component Gallery'),
        actions: [
          IconButton(
            tooltip: 'Toggle Light/Dark',
            icon: Icon(context.isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round),
            onPressed: () {
              final next = context.isDarkMode ? 'light' : 'dark';
              themeCtrl?.setTheme(next);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
        children: [
          PlayfulGreetingHeader(
            name: 'Arafat',
            trailing: Chip(
              label: Text(currentTheme.toUpperCase()),
              backgroundColor: c.pastelLavender,
            ),
          ),
          const SizedBox(height: SpeakabooTheme.spacingMd),
          const PlayfulMarkerText(
            prefix: 'Speak with ',
            highlighted: 'Big Joy!',
          ),
          const SizedBox(height: SpeakabooTheme.spacingMd),

          // Buttons
          _SectionTitle('Buttons'),
          PlayfulButton(
            label: 'Start Speaking',
            icon: Icons.mic_rounded,
            fullWidth: true,
            onPressed: () {},
          ),
          const SizedBox(height: SpeakabooTheme.spacing12),
          Row(
            children: [
              Expanded(
                child: PlayfulButton(
                  label: "Today's Mission",
                  icon: Icons.bolt_rounded,
                  variant: PlayfulButtonVariant.sunny,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: SpeakabooTheme.spacing12),
              Expanded(
                child: PlayfulButton(
                  label: 'Record',
                  icon: Icons.graphic_eq_rounded,
                  variant: PlayfulButtonVariant.coral,
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: SpeakabooTheme.spacing12),
          Row(
            children: [
              Expanded(
                child: PlayfulButton(
                  label: 'Success',
                  variant: PlayfulButtonVariant.mint,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: SpeakabooTheme.spacing12),
              Expanded(
                child: PlayfulButton(
                  label: 'Explore',
                  variant: PlayfulButtonVariant.secondary,
                  onPressed: () {},
                ),
              ),
            ],
          ),

          const SizedBox(height: SpeakabooTheme.spacingLg),
          _SectionTitle('Stat Chips & Mission Bar'),
          Row(
            children: [
              Expanded(
                child: PlayfulStatChip(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: c.coral,
                  washColor: c.pastelPink,
                  value: 7,
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
                  value: 420,
                  label: 'XP',
                ),
              ),
              const SizedBox(width: SpeakabooTheme.spacingSm),
              Expanded(
                child: PlayfulStatChip(
                  icon: Icons.schedule_rounded,
                  iconColor: c.skyEdge,
                  washColor: c.pastelSky,
                  value: 18,
                  suffix: 'm',
                  label: 'Spoken',
                ),
              ),
            ],
          ),
          const SizedBox(height: SpeakabooTheme.spacing12),
          PlayfulMissionBar(
            title: 'Speak 3 sentences about food',
            rewardLabel: '+50 XP',
            progress: 0.66,
            onTap: () {},
          ),

          const SizedBox(height: SpeakabooTheme.spacingLg),
          _SectionTitle('Practice Mode Tiles'),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: SpeakabooTheme.spacing12,
            crossAxisSpacing: SpeakabooTheme.spacing12,
            childAspectRatio: 2.1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              PlayfulModeTile(
                icon: Icons.chat_bubble_rounded,
                title: 'Free Talk',
                subtitle: 'Chat naturally',
                washColor: c.pastelLavender,
                iconColor: c.primary,
                onTap: () {},
              ),
              PlayfulModeTile(
                icon: Icons.theater_comedy_rounded,
                title: 'Scenarios',
                subtitle: 'Real-life roles',
                washColor: c.pastelPink,
                iconColor: c.coralEdge,
                onTap: () {},
              ),
              PlayfulModeTile(
                icon: Icons.explore_rounded,
                title: 'Topics',
                subtitle: 'Pick a theme',
                washColor: c.pastelMint,
                iconColor: c.mintEdge,
                onTap: () {},
              ),
              PlayfulModeTile(
                icon: Icons.record_voice_over_rounded,
                title: 'Shadowing',
                subtitle: 'Echo & flow',
                washColor: c.pastelSky,
                iconColor: c.skyEdge,
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: SpeakabooTheme.spacingLg),
          _SectionTitle('Character Widget & Moods'),
          PlayfulCard(
            child: Column(
              children: [
                PlayfulCharacter(
                  characterId: 'rule_farmer',
                  mood: _mood,
                  size: 140,
                ),
                const SizedBox(height: SpeakabooTheme.spacing12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: CharacterMood.values.map((m) {
                    final selected = m == _mood;
                    return ChoiceChip(
                      label: Text(m.name),
                      selected: selected,
                      onSelected: (_) => setState(() => _mood = m),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: SpeakabooTheme.spacingLg),
          _SectionTitle('Input, Sheet & Dialog'),
          const PlayfulInput(
            hintText: 'Search topics, words, or characters...',
            prefixIcon: Icons.search_rounded,
          ),
          const SizedBox(height: SpeakabooTheme.spacing12),
          Row(
            children: [
              Expanded(
                child: PlayfulButton(
                  label: 'Open Sheet',
                  variant: PlayfulButtonVariant.sky,
                  onPressed: () {
                    PlayfulBottomSheet.show(
                      context: context,
                      title: 'Warm Bottom Sheet',
                      child: const Text('Smooth rounded 24px sheet with drag handle.'),
                    );
                  },
                ),
              ),
              const SizedBox(width: SpeakabooTheme.spacing12),
              Expanded(
                child: PlayfulButton(
                  label: 'Open Dialog',
                  variant: PlayfulButtonVariant.secondary,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => PlayfulDialog(
                        title: 'Great Progress!',
                        message: 'You completed your daily speaking goal.',
                        primaryLabel: 'Awesome',
                        onPrimary: () => Navigator.pop(ctx),
                        secondaryLabel: 'Close',
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: SpeakabooTheme.spacingLg),
          _SectionTitle('Empty, Loading & Error States'),
          PlayfulEmptyState(
            title: 'Being stocked!',
            message: 'Start a quick chat with Farmer Reggie to collect your first words.',
            actionLabel: 'Start Speaking',
            onAction: () {},
          ),
          const SizedBox(height: SpeakabooTheme.spacing12),
          const PlayfulCard(
            child: PlayfulLoadingState(message: 'Warming up your companion...'),
          ),
          const SizedBox(height: SpeakabooTheme.spacing12),
          PlayfulErrorState(
            message: 'We could not reach the server right now. Check USB or Wi-Fi and try again.',
            onRetry: () {},
          ),
          const SizedBox(height: SpeakabooTheme.spacingLg),
        ],
      ),
      bottomNavigationBar: PlayfulBottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        items: const [
          PlayfulNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
          PlayfulNavItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Talk'),
          PlayfulNavItem(icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded, label: 'Friends'),
          PlayfulNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpeakabooTheme.spacingSm),
      child: Text(
        text,
        style: SpeakabooTheme.displayStyle(
          color: context.colors.textPrimary,
          size: SpeakabooTheme.subheadingSize,
        ),
      ),
    );
  }
}
