import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spookymoove/features/persona/domain/persona_tier.dart';
import 'package:spookymoove/features/persona/presentation/persona_tier_controller.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> haptics;
  late ProviderContainer container;

  setUp(() {
    haptics = [];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments as String);
        }
        return null;
      },
    );
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  PersonaTierController controller() =>
      container.read(personaTierProvider.notifier);

  test('no tier is selected at game start', () {
    expect(container.read(personaTierProvider), isNull);
  });

  test('selecting a tier sets it with a selectionClick', () {
    controller().select(PersonaTier.soft);

    expect(container.read(personaTierProvider), PersonaTier.soft);
    expect(haptics, ['HapticFeedbackType.selectionClick']);
  });

  test('selecting the selected tier again changes nothing', () {
    controller().select(PersonaTier.soft);
    var notifications = 0;
    container.listen(personaTierProvider, (_, _) => notifications++);

    controller().select(PersonaTier.soft);

    expect(notifications, 0);
    expect(haptics, hasLength(1));
  });

  test('rapid taps across tiers keep only the last one', () {
    for (final tier in [PersonaTier.god, PersonaTier.baby, PersonaTier.even]) {
      controller().select(tier);
    }
    expect(container.read(personaTierProvider), PersonaTier.even);
  });

  test('reset goes back to no tier for a new game', () {
    controller()
      ..select(PersonaTier.god)
      ..reset();
    expect(container.read(personaTierProvider), isNull);
  });

  test('reset sets the tier picked for a new game without a haptic', () {
    controller().reset(PersonaTier.even);

    expect(container.read(personaTierProvider), PersonaTier.even);
    expect(haptics, isEmpty);
  });
}
