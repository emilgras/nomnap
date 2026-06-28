import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../services/household_service.dart';
import '../services/session_scope.dart';
import '../theme/app_theme.dart';

/// Manage who shares this baby: generate an invite code, see current
/// caregivers (remove them), or join another caregiver's household with a code.
class CaregiversScreen extends StatefulWidget {
  const CaregiversScreen({super.key});

  @override
  State<CaregiversScreen> createState() => _CaregiversScreenState();
}

class _CaregiversScreenState extends State<CaregiversScreen> {
  String? _inviteCode;
  bool _generating = false;
  final _joinController = TextEditingController();
  bool _joining = false;

  @override
  void dispose() {
    _joinController.dispose();
    super.dispose();
  }

  Future<void> _generateInvite(SessionScope session) async {
    final s = S.of(context);
    setState(() => _generating = true);
    try {
      final code =
          await session.households.createInvite(session.householdId, session.uid);
      if (mounted) setState(() => _inviteCode = code);
    } catch (_) {
      _toast(s.errCreateInvite);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _shareInvite() async {
    final code = _inviteCode;
    if (code == null) return;
    final s = S.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    await Share.share(
      s.shareInviteText(code),
      subject: s.shareInviteSubject,
      sharePositionOrigin: origin,
    );
  }

  Future<void> _copyInvite() async {
    final code = _inviteCode;
    if (code == null) return;
    final s = S.of(context);
    await Clipboard.setData(ClipboardData(text: code));
    _toast(s.codeCopied);
  }

  Future<void> _join(SessionScope session) async {
    final code = _joinController.text.trim();
    if (code.isEmpty) return;
    final s = S.of(context);
    setState(() => _joining = true);
    try {
      final newHid = await session.households.joinWithCode(session.uid, code);
      // Swap the whole app over to the joined household — data appears live.
      await session.switchHousehold(newHid);
      if (!mounted) return;
      _joinController.clear();
      Navigator.of(context).pop(); // back to the tracker, now showing shared data
    } on InviteException catch (e) {
      if (mounted) setState(() => _joining = false);
      _toast(s.inviteError(e.code));
    } catch (_) {
      if (mounted) setState(() => _joining = false);
      _toast(s.errJoin);
    }
  }

  Future<void> _confirmRemove(SessionScope session, Member m) async {
    final s = S.of(context);
    final isSelf = m.uid == session.uid;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(isSelf ? s.leaveHouseholdTitle : s.removeCaregiverTitle),
        content: Text(isSelf ? s.leaveHouseholdMsg : s.removeCaregiverMsg),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isSelf ? s.leave : s.remove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await session.households.removeMember(session.householdId, m.uid);
    } catch (_) {
      _toast(s.errUpdate);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.of(context).ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final session = SessionScope.of(context);
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(s.caregivers),
        backgroundColor: AppColors.surface,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            _sectionLabel(s.inviteSectionTitle),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.inviteIntro,
                    style: AppText.body.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  if (_inviteCode == null)
                    CupertinoButton.filled(
                      onPressed:
                          _generating ? null : () => _generateInvite(session),
                      child: _generating
                          ? const CupertinoActivityIndicator()
                          : Text(s.createInviteCode),
                    )
                  else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _inviteCode!,
                        style: AppText.largeTitle.copyWith(letterSpacing: 4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CupertinoButton(
                            color: AppColors.surface,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            onPressed: _copyInvite,
                            child: Text(s.copy,
                                style: const TextStyle(color: AppColors.sleepAccent)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CupertinoButton.filled(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            onPressed: _shareInvite,
                            child: Text(s.share),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionLabel(s.caregiversSectionTitle),
            _card(
              child: StreamBuilder<List<Member>>(
                stream: session.households.watchMembers(session.householdId),
                builder: (context, snap) {
                  final members = snap.data;
                  if (members == null) {
                    return const Padding(
                      padding: EdgeInsets.all(8),
                      child: Center(child: CupertinoActivityIndicator()),
                    );
                  }
                  return Column(
                    children: [
                      for (var i = 0; i < members.length; i++) ...[
                        if (i > 0)
                          const SizedBox(
                            height: 1,
                            child: ColoredBox(color: AppColors.background),
                          ),
                        _memberRow(session, members[i]),
                      ],
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            _sectionLabel(s.joinSectionTitle),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.joinIntro,
                    style: AppText.body.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: _joinController,
                    placeholder: s.joinCodePlaceholder,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    padding: const EdgeInsets.all(14),
                    style: AppText.body.copyWith(letterSpacing: 2),
                  ),
                  const SizedBox(height: 12),
                  CupertinoButton.filled(
                    onPressed: _joining ? null : () => _join(session),
                    child: _joining
                        ? const CupertinoActivityIndicator()
                        : Text(s.join),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _memberRow(SessionScope session, Member m) {
    final s = S.of(context);
    final isSelf = m.uid == session.uid;
    final isOwner = m.role == 'owner';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: [
          Icon(
            isOwner ? CupertinoIcons.star_fill : CupertinoIcons.person_fill,
            size: 18,
            color: AppColors.sleepAccent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isSelf
                  ? (isOwner ? s.meSelfOwner : s.meSelf)
                  : (isOwner ? s.roleOwner : s.roleCaregiver),
              style: AppText.body,
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(36, 36),
            onPressed: () => _confirmRemove(session, m),
            child: Icon(
              isSelf ? CupertinoIcons.square_arrow_right : CupertinoIcons.minus_circle,
              size: 20,
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Text(
          text,
          style: AppText.body.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      );
}
