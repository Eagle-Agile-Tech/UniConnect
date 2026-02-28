import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpForm extends StatefulWidget {
  const OtpForm({super.key, required this.onOtpChanged});
  final void Function(String otp) onOtpChanged;
  @override
  State<OtpForm> createState() => _OtpFormState();
}

class _OtpFormState extends State<OtpForm> {
  final GlobalKey<FormState> _otpFormKey = GlobalKey<FormState>();
  final List<TextEditingController> otpControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );

  @override
  void dispose(){
    for (var controller in otpControllers){
      controller.dispose();
    }
    super.dispose();
  }
  
  void _updateOtp(){
    final otp = otpControllers.map((c) => c.text).join();
    widget.onOtpChanged(otp);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _otpFormKey,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ...List.generate(4, (index){
            return SizedBox(
              width: 64,
              height: 68,
              child: TextFormField(
                controller: otpControllers[index],
                onChanged: (value) {
                  if (value.length == 1) {
                    FocusScope.of(context).nextFocus();
                  }
                  _updateOtp();
                },
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(1),
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
            );
          })
        ],
      ),
    );
  }
}
