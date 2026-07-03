import 'package:flutter/widgets.dart';

import 'household_service.dart';

/// Exposes the current user + household to the widget tree, so screens (e.g.
/// the caregivers/invite screen) can manage sharing without threading these
/// through every constructor. Mirrors LocaleScope / HomeConfigScope.
class SessionScope extends InheritedWidget {
  final String uid;
  final String householdId;
  final HouseholdService households;

  /// Whether this device owns the household (the admin who created it). Owners
  /// can delete the shared baby's data; caregivers who joined via an invite can
  /// only leave and remove their own profile.
  final bool isOwner;

  /// Switches the whole app to a different household (e.g. after joining one
  /// via an invite code), rebuilding the event store live — no restart.
  final Future<void> Function(String newHouseholdId) switchHousehold;

  /// Removes this device's profile: for an owner this also wipes the shared
  /// baby's data; for a caregiver it only leaves the household. Either way the
  /// anonymous account is deleted and a fresh empty profile is created.
  final Future<void> Function() deleteProfile;

  const SessionScope({
    super.key,
    required this.uid,
    required this.householdId,
    required this.households,
    required this.isOwner,
    required this.switchHousehold,
    required this.deleteProfile,
    required super.child,
  });

  static SessionScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, 'No SessionScope found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(SessionScope old) =>
      uid != old.uid ||
      householdId != old.householdId ||
      isOwner != old.isOwner;
}
