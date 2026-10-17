import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaamfast/core/theme/app_theme.dart';

class OtpBoxes extends StatefulWidget {
  const OtpBoxes({
    super.key,
    this.length = 6,
    this.initialValue,
    this.onChanged,
    this.onCompleted,
  });

  final int length;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  @override
  State<OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<OtpBoxes> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _nodes = List.generate(widget.length, (_) => FocusNode());
    final seed = widget.initialValue?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (seed.isNotEmpty) {
      for (var i = 0; i < widget.length && i < seed.length; i++) {
        _controllers[i].text = seed[i];
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final firstEmpty = _controllers.indexWhere((c) => c.text.isEmpty);
      _nodes[firstEmpty < 0 ? widget.length - 1 : firstEmpty].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _notify() {
    final code = _code;
    widget.onChanged?.call(code);
    if (code.length == widget.length) {
      widget.onCompleted?.call(code);
    }
  }

  void _applyDigits(String raw, int from) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      _controllers[from].clear();
      if (from > 0) _nodes[from - 1].requestFocus();
      _notify();
      return;
    }
    for (var i = 0; i < digits.length && from + i < widget.length; i++) {
      _controllers[from + i].text = digits[i];
    }
    final next = (from + digits.length).clamp(0, widget.length - 1);
    _nodes[next].requestFocus();
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(widget.length, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == widget.length - 1 ? 0 : 8),
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                if (event is! KeyDownEvent) return;
                if (event.logicalKey != LogicalKeyboardKey.backspace) return;
                if (_controllers[i].text.isNotEmpty || i == 0) return;
                _controllers[i - 1].clear();
                _nodes[i - 1].requestFocus();
                _notify();
              },
              child: TextField(
                controller: _controllers[i],
                focusNode: _nodes[i],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.mist,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.accentOrange, width: 1.6),
                  ),
                ),
                onChanged: (value) => _applyDigits(value, i),
                onTap: () => _controllers[i].selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _controllers[i].text.length,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
