import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Bottom sheet that asks for a single growth measurement (weight in grams,
/// length/head in cm). Resolves to the entered value as a normalized string
/// (decimal point, no trailing separator) or null if cancelled.
class MeasurementSheet extends StatefulWidget {
  final String title;
  final String unit;
  final Color accent;
  final bool allowDecimal;

  const MeasurementSheet({
    super.key,
    required this.title,
    required this.unit,
    required this.accent,
    this.allowDecimal = false,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String unit,
    required Color accent,
    bool allowDecimal = false,
  }) {
    return showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => MeasurementSheet(
        title: title,
        unit: unit,
        accent: accent,
        allowDecimal: allowDecimal,
      ),
    );
  }

  @override
  State<MeasurementSheet> createState() => _MeasurementSheetState();
}

class _MeasurementSheetState extends State<MeasurementSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Normalizes the raw text to a storable value (decimal point, trimmed).
  String get _normalized => _controller.text.trim().replaceAll(',', '.');

  bool get _valid {
    final n = double.tryParse(_normalized);
    return n != null && n > 0;
  }

  void _save() {
    if (!_valid) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(_normalized);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final accent = widget.accent;

    // Grams are whole numbers; cm allows a single decimal.
    final formatters = <TextInputFormatter>[
      FilteringTextInputFormatter.allow(
        widget.allowDecimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
      ),
      LengthLimitingTextInputFormatter(widget.allowDecimal ? 5 : 5),
    ];

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
                      child: Text(widget.title, style: AppText.headline),
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
                child: CupertinoTextField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: widget.allowDecimal,
                  ),
                  inputFormatters: formatters,
                  placeholder: widget.allowDecimal ? '55' : '4250',
                  style: AppText.timerLarge.copyWith(
                    fontSize: 34,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  suffix: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(widget.unit, style: AppText.subhead),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _save(),
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
                      s.save,
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
