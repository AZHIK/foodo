import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_pos/constants/app_strings.dart';
import 'package:restaurant_pos/l10n/l10n.dart';
import 'package:restaurant_pos/providers/preferences_provider.dart';

void main() {
  setUp(() => L10n.useForTests('en'));
  tearDown(() => L10n.useForTests('en'));

  test('toggling AppLanguage flips L10n and all AppStrings getters', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(appLanguageProvider), AppLanguage.english);
    expect(AppStrings.save, 'Save');

    container.read(appLanguageProvider.notifier).set(AppLanguage.swahili);

    expect(L10n.isSw, isTrue);
    expect(L10n.localeCode, 'sw');
    expect(AppStrings.save, 'Hifadhi');
    expect(AppStrings.cancel, 'Ghairi');
    expect(AppStrings.navDashboard, 'Dashibodi');

    container.read(appLanguageProvider.notifier).set(AppLanguage.english);

    expect(L10n.isSw, isFalse);
    expect(AppStrings.save, 'Save');
  });

  test('missing Swahili keys fall back to English', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(appLanguageProvider.notifier).set(AppLanguage.swahili);
    // weekday lists are intentionally untranslated consts.
    expect(AppStrings.weekdayNames.first, 'Monday');
  });
}
