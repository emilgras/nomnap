import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Bottom sheet that asks for a feed amount in ml. Resolves to the entered
/// amount (digits only, e.g. "120") or null if cancelled.
class FeedAmountSheet extends StatefulWidget {
  final Color accent;
  const FeedAmountSheet({super.key, required this.accent});

  static Future<String?> show(BuildContext context, {required Color accent}) {
    return showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => FeedAmountSheet(accent: accent),
    );
  }

  @override
  State<FeedAmountSheet> createState() => _FeedAmountSheetState();
}

class _FeedAmountSheetState extends State<FeedAmountSheet> {
  static const _presets = [30, 60, 90, 120, 150];
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _valid {
    final n = int.tryParse(_controller.text.trim());
    return n != null && n > 0;
  }

  void _save() {
    if (!_valid) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final accent = widget.accent;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(s.feedAmount, style: AppText.headline),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(44, 44),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        s.cancel,
                        style: AppText.callout.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoTextField(
                        controller: _controller,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        placeholder: '120',
                        style: AppText.timerLarge.copyWith(
                          fontSize: 34,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        suffix: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Text(s.ml, style: AppText.subhead),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _save(),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final p in _presets)
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        minimumSize: const Size(0, 0),
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        color: accent.withValues(alpha: 0.12),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _controller.text = '$p';
                            _controller.selection = TextSelection.collapsed(
                                offset: _controller.text.length);
                          });
                        },
                        child: Text(
                          s.amountMl('$p'),
                          style: AppText.callout.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    color: accent,
                    disabledColor: accent.withValues(alpha: 0.4),
                    onPressed: _valid ? _save : null,
                    child: Text(
                      s.logFeed,
                      style: AppText.callout.copyWith(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
