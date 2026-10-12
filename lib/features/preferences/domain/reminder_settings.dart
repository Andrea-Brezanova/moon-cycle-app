/// Settings › Notifications. Reminders are scheduled on the phone only.
final class ReminderSettings {
  const ReminderSettings({
    this.enabled = false,
    this.phaseChange = true,
    this.beforePeriod = true,
  });

  /// The master switch. Off until the user turns reminders on.
  final bool enabled;

  /// On the morning of each new phase.
  final bool phaseChange;

  /// Two days before the next period is due.
  final bool beforePeriod;

  ReminderSettings copyWith({
    bool? enabled,
    bool? phaseChange,
    bool? beforePeriod,
  }) => ReminderSettings(
    enabled: enabled ?? this.enabled,
    phaseChange: phaseChange ?? this.phaseChange,
    beforePeriod: beforePeriod ?? this.beforePeriod,
  );

  @override
  bool operator ==(Object other) =>
      other is ReminderSettings &&
      other.enabled == enabled &&
      other.phaseChange == phaseChange &&
      other.beforePeriod == beforePeriod;

  @override
  int get hashCode => Object.hash(enabled, phaseChange, beforePeriod);
}
