import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_exception.dart';
import '../state/session_controller.dart';
import '../state/session_scope.dart';
import '../theme/app_colors.dart';

/// First-launch screen: take a mobile number (no OTP) and build a session.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _error;
  bool _prefilled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Prefill the saved number (shows it was persisted, even though login is
    // forced for testing).
    if (!_prefilled) {
      _prefilled = true;
      final saved = SessionScope.of(context).savedPhone;
      // A dummy number can be injected only with TESTING_DUMMY_PHONE.
      final initial = saved.isNotEmpty
          ? saved
          : (kForceLoginOnLaunch ? kTestingDummyPhone : '');
      if (initial.isNotEmpty) _controller.text = initial;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final digits = _controller.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      setState(() => _error = '१० अंकों का सही नंबर डालें');
      return;
    }
    setState(() => _error = null);
    try {
      await SessionScope.of(context).signIn(digits);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'लॉगिन नहीं हो पाया। कृपया फिर कोशिश करें।');
    }
    // The go_router redirect handles navigation from here.
  }

  @override
  Widget build(BuildContext context) {
    final busy = SessionScope.of(context).busy;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🕉️', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 6),
                const Text(
                  'शान्ति',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: AppColors.maroon,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'अपना मोबाइल नंबर डालें',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'हम आपका खाता इसी नंबर से बनाएँगे',
                  style: TextStyle(fontSize: 13, color: AppColors.inkMuted),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  style: const TextStyle(fontSize: 22, letterSpacing: 2),
                  decoration: InputDecoration(
                    prefixText: '+91  ',
                    prefixStyle: const TextStyle(
                      fontSize: 22,
                      color: AppColors.ink,
                    ),
                    counterText: '',
                    hintText: '00000 00000',
                    errorText: _error,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.saffron,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: busy ? null : _submit,
                    child: busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'जारी रखें',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'OTP की ज़रूरत नहीं · आपका नंबर सुरक्षित है 🙏',
                  style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
