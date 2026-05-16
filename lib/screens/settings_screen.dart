import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../services/settings_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (settings) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // ── Alert Radius ──────────────────────────────────────────────
            _SectionHeader(label: 'PROXIMITY ALERT', cs: cs, theme: theme),
            const SizedBox(height: 8),
            _SettingsCard(
              cs: cs,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.radar, size: 18, color: cs.primary),
                      const SizedBox(width: 10),
                      Text(
                        'Alert Radius',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${settings.alertRadiusKm.toStringAsFixed(0)} km',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Notify when an earthquake occurs within this distance',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  Slider(
                    value: settings.alertRadiusKm,
                    min: SettingsService.minRadiusKm,
                    max: SettingsService.maxRadiusKm,
                    divisions: 49,
                    onChanged: (val) => ref
                        .read(settingsProvider.notifier)
                        .setAlertRadius(val),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${SettingsService.minRadiusKm.toStringAsFixed(0)} km',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${SettingsService.maxRadiusKm.toStringAsFixed(0)} km',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Minimum Magnitude ─────────────────────────────────────────
            _SettingsCard(
              cs: cs,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.speed, size: 18, color: cs.primary),
                      const SizedBox(width: 10),
                      Text(
                        'Minimum Magnitude',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Only alert for earthquakes at or above this magnitude',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: SettingsService.magnitudeOptions.map((mag) {
                      final selected = settings.minMagnitude == mag;
                      final color = _magColor(mag);
                      return GestureDetector(
                        onTap: () => ref
                            .read(settingsProvider.notifier)
                            .setMinMagnitude(mag),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: selected
                                ? color.withValues(alpha: 0.2)
                                : cs.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? color
                                  : cs.outlineVariant.withValues(alpha: 0.4),
                              width: selected ? 2 : 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'M',
                                style: TextStyle(
                                  color: selected
                                      ? color
                                      : cs.onSurfaceVariant,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  height: 1,
                                ),
                              ),
                              Text(
                                mag.toStringAsFixed(0),
                                style: TextStyle(
                                  color: selected ? color : cs.onSurface,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Appearance ────────────────────────────────────────────────
            _SectionHeader(label: 'APPEARANCE', cs: cs, theme: theme),
            const SizedBox(height: 8),
            _SettingsCard(
              cs: cs,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette_outlined, size: 18, color: cs.primary),
                      const SizedBox(width: 10),
                      Text(
                        'Theme',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _ThemeOption(
                        icon: Icons.brightness_auto,
                        label: 'System',
                        selected: settings.themeMode == ThemeMode.system,
                        cs: cs,
                        theme: theme,
                        onTap: () => ref
                            .read(settingsProvider.notifier)
                            .setThemeMode(ThemeMode.system),
                      ),
                      const SizedBox(width: 8),
                      _ThemeOption(
                        icon: Icons.light_mode,
                        label: 'Light',
                        selected: settings.themeMode == ThemeMode.light,
                        cs: cs,
                        theme: theme,
                        onTap: () => ref
                            .read(settingsProvider.notifier)
                            .setThemeMode(ThemeMode.light),
                      ),
                      const SizedBox(width: 8),
                      _ThemeOption(
                        icon: Icons.dark_mode,
                        label: 'Dark',
                        selected: settings.themeMode == ThemeMode.dark,
                        cs: cs,
                        theme: theme,
                        onTap: () => ref
                            .read(settingsProvider.notifier)
                            .setThemeMode(ThemeMode.dark),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Offline Cache ─────────────────────────────────────────────
            _SectionHeader(label: 'OFFLINE CACHE', cs: cs, theme: theme),
            const SizedBox(height: 8),
            _SettingsCard(
              cs: cs,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.storage, size: 18, color: cs.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Earthquake Cache',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Stores up to 500 recent earthquakes in SQLite for offline viewing',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.check_circle,
                        size: 18,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── About ─────────────────────────────────────────────────────
            _SectionHeader(label: 'DATA SOURCES', cs: cs, theme: theme),
            const SizedBox(height: 8),
            _SettingsCard(
              cs: cs,
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.sensors,
                    label: 'Real-time',
                    value: 'p2pquake (JMA)',
                    cs: cs,
                    theme: theme,
                  ),
                  Divider(
                      height: 20,
                      color: cs.outlineVariant.withValues(alpha: 0.3)),
                  _InfoRow(
                    icon: Icons.history,
                    label: 'Historical',
                    value: 'USGS FDSN (global)',
                    cs: cs,
                    theme: theme,
                  ),
                  Divider(
                      height: 20,
                      color: cs.outlineVariant.withValues(alpha: 0.3)),
                  _InfoRow(
                    icon: Icons.storage_outlined,
                    label: 'Cache',
                    value: 'SQLite (offline)',
                    cs: cs,
                    theme: theme,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _magColor(double mag) {
    if (mag >= 6.0) return Colors.red;
    if (mag >= 4.0) return Colors.orange;
    return Colors.green;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.label, required this.cs, required this.theme});
  final String label;
  final ColorScheme cs;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: theme.textTheme.labelSmall?.copyWith(
        letterSpacing: 1.4,
        color: cs.onSurfaceVariant,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child, required this.cs});
  final Widget child;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: child,
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.cs,
    required this.theme,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final ColorScheme cs;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? cs.primaryContainer
                : cs.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? cs.primary
                  : cs.outlineVariant.withValues(alpha: 0.4),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
    required this.theme,
  });
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: 10),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}
