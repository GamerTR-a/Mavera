import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings_repository.dart';
import '../../providers/providers.dart';
import '../../services/ring/simulated_ring_transport.dart';
import '../l10n.dart';

/// Simüle yüzük paneli (yalnızca debug).
class SimulatorPanel extends ConsumerStatefulWidget {
  const SimulatorPanel({super.key});

  @override
  ConsumerState<SimulatorPanel> createState() => _SimulatorPanelState();
}

class _SimulatorPanelState extends ConsumerState<SimulatorPanel> {
  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final core = ref.watch(appCoreProvider);
    final s = ref.watch(settingsProvider);
    ref.watch(coreViewProvider);
    final sim = core.simulator;
    if (sim == null) return Scaffold(appBar: AppBar(title: Text(t.helpSimPanel)));
    return Scaffold(
      appBar: AppBar(title: Text(t.helpSimPanel)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<SimMotion>(
              segments: [
                ButtonSegment(value: SimMotion.active, label: Text(t.simActive)),
                ButtonSegment(value: SimMotion.calm, label: Text(t.simCalm)),
                ButtonSegment(value: SimMotion.still, label: Text(t.simStill)),
              ],
              selected: {sim.motion},
              onSelectionChanged: (v) => setState(() => sim.motion = v.first),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: sim.sendSos, child: Text(t.simSos)),
            const SizedBox(height: 8),
            FilledButton.tonal(onPressed: sim.sendTremor, child: Text(t.simTremor)),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => setState(() => sim.connected ? sim.disconnect() : sim.connect()),
              child: Text(sim.connected ? t.simDisconnect : t.simConnect),
            ),
            const SizedBox(height: 16),
            Text(t.simBattery(sim.batteryPct)),
            Slider(
              value: sim.batteryPct.toDouble(),
              max: 100,
              divisions: 20,
              onChanged: (v) => setState(() => sim.batteryPct = v.round()),
            ),
            SwitchListTile(
              title: Text(t.simFast),
              value: s.simFast,
              onChanged: (v) => unawaited(ref.read(settingsProvider.notifier).update((x) => x.copyWith(simFast: v))),
            ),
          ],
        ),
      ),
    );
  }
}
