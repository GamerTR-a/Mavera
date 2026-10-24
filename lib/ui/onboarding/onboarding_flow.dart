import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import '../l10n.dart';
import 'background_step.dart';
import 'contacts_step.dart';
import 'how_it_works_step.dart';
import 'pairing_step.dart';
import 'permissions_step.dart';
import 'ready_step.dart';
import 'rehearsal_step.dart';
import 'telegram_step.dart';
import 'welcome_step.dart';

/// Her adımın "Devam" butonunu açıp kapatabilmesi için ortak imza.
typedef StepBuilder = Widget Function(ValueChanged<bool> onCanContinue);

/// İlk kurulum (Ekran 1–8, Android'de 3b).
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key, this.initialStep = 0});
  final int initialStep;

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  late final PageController _pc = PageController(initialPage: widget.initialStep);
  late int _index = widget.initialStep;
  final Map<int, bool> _can = {};

  late final List<(StepBuilder, bool, String? Function(BuildContext))> _steps = [
    ((cb) => WelcomeStep(onStart: _next), true, (_) => null),
    ((cb) => const HowItWorksStep(), true, (_) => null),
    ((cb) => PermissionsStep(onCanContinue: cb), false, (_) => null),
    if (Platform.isAndroid) ((cb) => BackgroundStep(onCanContinue: cb), true, (c) => c.t.commonDone),
    ((cb) => PairingStep(onCanContinue: cb), false, (_) => null),
    ((cb) => TelegramStep(onCanContinue: cb), false, (_) => null),
    ((cb) => ContactsStep(onCanContinue: cb), true, (_) => null),
    ((cb) => RehearsalStep(onCanContinue: cb), false, (_) => null),
    ((cb) => const ReadyStep(), true, (_) => null),
  ];

  bool _canContinue(int i) => _can[i] ?? _steps[i].$2;

  void _next() {
    if (_index >= _steps.length - 1) return;
    unawaited(_pc.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut));
  }

  Future<void> _onContinue() async {
    if (_index == _contactsIndex && !await ContactsStep.confirmIfEmpty(context, ref)) return;
    _next();
  }

  int get _contactsIndex => Platform.isAndroid ? 6 : 5;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.colors;
    final last = _index == _steps.length - 1;
    final first = _index == 0;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index > 0) {
          unawaited(_pc.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut));
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pc,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _steps.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => _steps[i].$1((v) {
                    if (_can[i] == v) return;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _can[i] = v);
                    });
                  }),
                ),
              ),
              if (!first && !last)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(t.homeProtectionOffOnboarding, style: Theme.of(context).textTheme.bodySmall),
                ),
              const SizedBox(height: 8),
              Semantics(
                label: t.obStepOf(_index + 1, _steps.length),
                excludeSemantics: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _steps.length; i++)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _index ? c.accent : AppColors.tint(c.accent, 0.25),
                        ),
                      ),
                  ],
                ),
              ),
              if (!first && !last)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: _canContinue(_index) ? () => unawaited(_onContinue()) : null,
                    child: Text(_steps[_index].$3(context) ?? t.commonContinue),
                  ),
                )
              else
                const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
