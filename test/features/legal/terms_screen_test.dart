import 'package:build4all_manager/features/legal/data/services/terms_repository.dart';
import 'package:build4all_manager/features/legal/presentation/screens/terms_screen.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Registration must not be completable before the terms are read, so the rule
/// worth pinning down is when the accept button becomes usable at all.
void main() {
  Future<void> pumpTerms(
    WidgetTester tester, {
    required bool requireAcceptance,
    bool alreadyAccepted = false,
    void Function(bool?)? onResult,
  }) async {
    // Asset I/O does not complete inside the fake-async test zone, so warm the
    // repository cache before the screen asks for the document.
    await tester.runAsync(() => TermsRepository().load('en'));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => TermsScreen(
                        requireAcceptance: requireAcceptance,
                        alreadyAccepted: alreadyAccepted,
                      ),
                    ),
                  );
                  onResult?.call(result);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  AppButton acceptButton(WidgetTester tester) =>
      tester.widget<AppButton>(find.widgetWithText(AppButton, 'I Agree'));

  Future<void> readToTheEnd(WidgetTester tester) async {
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -100000),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the terms cannot be accepted before they are read',
      (tester) async {
    await pumpTerms(tester, requireAcceptance: true);

    expect(find.text('Terms & Conditions'), findsWidgets);
    expect(find.text('Scroll to the end to accept'), findsOneWidget);
    expect(acceptButton(tester).onPressed, isNull);
  });

  testWidgets('reaching the end of the document enables acceptance',
      (tester) async {
    bool? result;
    await pumpTerms(tester, requireAcceptance: true, onResult: (r) => result = r);

    await readToTheEnd(tester);

    expect(find.text('Scroll to the end to accept'), findsNothing);
    expect(acceptButton(tester).onPressed, isNotNull);

    await tester.tap(find.widgetWithText(AppButton, 'I Agree'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('leaving without agreeing reports no acceptance', (tester) async {
    bool? result;
    await pumpTerms(tester, requireAcceptance: true, onResult: (r) => result = r);

    await tester.tap(find.widgetWithText(AppButton, 'Not now'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets('re-opening already accepted terms does not ask to scroll again',
      (tester) async {
    await pumpTerms(tester, requireAcceptance: true, alreadyAccepted: true);

    expect(find.text('Scroll to the end to accept'), findsNothing);
    expect(acceptButton(tester).onPressed, isNotNull);
  });

  testWidgets('reading from the profile shows no acceptance bar',
      (tester) async {
    await pumpTerms(tester, requireAcceptance: false);

    expect(find.widgetWithText(AppButton, 'I Agree'), findsNothing);
    expect(find.widgetWithText(AppButton, 'Not now'), findsNothing);
    expect(find.text('Contents'), findsOneWidget);
  });
}
