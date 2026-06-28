import 'package:flutter/widgets.dart';

import 'household_service.dart';

/// Exposes the current user + household to the widget tree, so screens (e.g.
/// the caregivers/invite screen) can manage sharing without threading these
/// through every constructor. Mirrors LocaleScope / HomeConfigScope.
class SessionScope extends InheritedWidget {
  final String uid;
  final String householdId;
  final HouseholdService households;

  /// Switches the whole app to a different household (e.g. after joining one
  /// via an invite code), rebuilding the event store live — no restart.
  final Future<void> Function(String newHouseholdId) switchHousehold;

  const SessionScope({
    super.key,
    required this.uid,
    required this.householdId,
    required this.households,
    required this.switchHousehold,
    required super.child,
  });

  static SessionScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, 'No SessionScope found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(SessionScope old) =>
      uid != old.uid || householdId != old.householdId;
}
