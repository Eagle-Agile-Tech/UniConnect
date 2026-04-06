import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpForm extends StatefulWidget {
  const OtpForm({super.key, required this.onOtpChanged});

  final void Function(String otp) onOtpChanged;

  @override
  State<OtpForm> createState() => _OtpFormState();
}

class _OtpFormState extends State<OtpForm> {
  final List<TextEditingController> otpControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );

  final List<FocusNode> focusNodes = List.generate(4, (index) => FocusNode());

  @override
  void dispose() {
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _updateOtp() {
    final otp = otpControllers.map((c) => c.text).join();
    widget.onOtpChanged(otp);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(4, (index) {
        return SizedBox(
          width: 64,
          height: 68,
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (value) {
              if (value is KeyDownEvent &&
                      value.logicalKey == LogicalKeyboardKey.backspace ||
                  value.logicalKey == LogicalKeyboardKey.delete) {
                if (otpControllers[index].text.isEmpty && index > 0) {
                  focusNodes[index - 1].requestFocus();
                }
              }
            },
            child: TextFormField(
              controller: otpControllers[index],
              focusNode: focusNodes[index],
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
              keyboardType: TextInputType.number,
              inputFormatters: [
                LengthLimitingTextInputFormatter(1),
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (value) {
                if (value.isNotEmpty && index < 3) {
                  focusNodes[index + 1].requestFocus();
                }
                _updateOtp();
              },
            ),
          ),
        );
      }),
    );
  }
}
