import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakaboo/screens/debug_gallery_screen.dart';
import 'package:speakaboo/theme/speakaboo_theme.dart';
import 'package:speakaboo/theme/theme_controller.dart';
import 'package:speakaboo/widgets/playful/playful.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('ThemeController persists Light, Dark, and System selections', () async {
    final ctrl = ThemeController();
    await ctrl.load();
    expect(ctrl.themeMode, ThemeMode.system);

    await ctrl.setTheme('dark');
    expect(ctrl.themeMode, ThemeMode.dark);

    final reloaded = ThemeController();
    await reloaded.load();
    expect(reloaded.themeMode, ThemeMode.dark);

    await reloaded.setTheme('light');
    expect(reloaded.themeMode, ThemeMode.light);
  });

  testWidgets('DebugGalleryScreen renders all components in light and dark themes',
      (WidgetTester tester) async {
    final ctrl = ThemeController();

    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeController>.value(
        value: ctrl,
        child: Consumer<ThemeController>(
          builder: (context, themeCtrl, _) {
            return MaterialApp(
              theme: SpeakabooTheme.theme,
              darkTheme: SpeakabooTheme.darkTheme,
              themeMode: themeCtrl.themeMode,
              home: const DebugGalleryScreen(),
            );
          },
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Playful Component Gallery'), findsOneWidget);
    expect(find.text('Start Speaking'), findsOneWidget);
    expect(find.text("Today's Mission"), findsOneWidget);
    final listScrollable = find.byType(Scrollable).first;
    expect(find.byType(PlayfulStatChip), findsNWidgets(3));
    await tester.scrollUntilVisible(find.byType(PlayfulMissionBar), 200, scrollable: listScrollable);
    expect(find.byType(PlayfulMissionBar), findsOneWidget);
    await tester.scrollUntilVisible(find.byType(PlayfulModeTile).first, 200, scrollable: listScrollable);
    expect(find.byType(PlayfulModeTile), findsNWidgets(4));

    // Toggle theme via AppBar action
    await tester.tap(find.byTooltip('Toggle Light/Dark'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(ctrl.selection, isNot('system'));

    await tester.pumpWidget(const SizedBox());
  });
}
