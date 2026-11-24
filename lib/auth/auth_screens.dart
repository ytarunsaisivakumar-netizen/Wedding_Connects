import 'package:flutter/material.dart';

import '../theme.dart';
import 'auth_service.dart';

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class AuthShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Navigator.canPop(context) ? AppBar() : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: lightPink,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.favorite, color: maroon, size: 30),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: const TextStyle(
                      color: maroon,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: Colors.black54, fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ContactToggle extends StatelessWidget {
  final ContactType value;
  final ValueChanged<ContactType> onChanged;

  const ContactToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<ContactType>(
        segments: const [
          ButtonSegment(
              value: ContactType.email,
              icon: Icon(Icons.email_outlined),
              label: Text('Email')),
          ButtonSegment(
              value: ContactType.phone,
              icon: Icon(Icons.phone_outlined),
              label: Text('Phone')),
        ],
        selected: {value},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}

class ContactField extends StatelessWidget {
  final ContactType type;
  final TextEditingController controller;
  final String? label;

  const ContactField({
    super.key,
    required this.type,
    required this.controller,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isEmail = type == ContactType.email;
    return TextFormField(
      controller: controller,
      keyboardType:
          isEmail ? TextInputType.emailAddress : TextInputType.phone,
      autofillHints: [isEmail ? AutofillHints.email : AutofillHints.telephoneNumber],
      decoration: InputDecoration(
        labelText: label ?? (isEmail ? 'Email address' : 'Mobile number'),
        hintText: isEmail ? 'you@example.com' : '+91 98765 43210',
        prefixIcon: Icon(isEmail ? Icons.email_outlined : Icons.phone_outlined),
        border: const OutlineInputBorder(),
      ),
      validator: (v) => AuthService.validateContact(type, v),
    );
  }
}

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.validator,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _hidden,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(_hidden ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _hidden = !_hidden),
        ),
      ),
      validator: widget.validator ??
          (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        style: FilledButton.styleFrom(backgroundColor: maroon),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

class ErrorText extends StatelessWidget {
  final String? message;
  const ErrorText(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(message!,
          style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
    );
  }
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

// ---------------------------------------------------------------------------
// Login
// ---------------------------------------------------------------------------

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _contact = TextEditingController();
  final _password = TextEditingController();
  ContactType _type = ContactType.email;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _contact.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final err =
        await authService.login(_type, _contact.text, _password.text);
    if (!mounted) return;
    // On success the auth gate swaps this screen for the home screen.
    setState(() {
      _loading = false;
      _error = err;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Welcome back',
      subtitle: 'Log in to Wedding Connects with your email or mobile number.',
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ContactToggle(
                value: _type,
                onChanged: (t) => setState(() {
                  _type = t;
                  _contact.clear();
                  _error = null;
                }),
              ),
              const SizedBox(height: 16),
              ContactField(type: _type, controller: _contact),
              const SizedBox(height: 14),
              PasswordField(controller: _password),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen()),
                  ),
                  child: const Text('Forgot password?'),
                ),
              ),
              ErrorText(_error),
              PrimaryButton(label: 'Log in', loading: _loading, onPressed: _submit),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Don't have an account?"),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignUpScreen()),
              ),
              child: const Text('Sign up'),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sign up (details -> OTP -> set password)
// ---------------------------------------------------------------------------

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _contact = TextEditingController();
  ContactType _type = ContactType.email;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_form.currentState!.validate()) return;
    if (authService.accountExists(_type, _contact.text)) {
      setState(() => _error =
          'An account with this ${_type == ContactType.email ? 'email' : 'number'} already exists. Please log in.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OtpScreen(type: _type, contact: _contact.text),
      ),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (verified != true) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SetPasswordScreen(
          title: 'Create your password',
          subtitle: 'You will use it with your '
              '${_type == ContactType.email ? 'email' : 'mobile number'} to log in.',
          buttonLabel: 'Create account',
          onSubmit: (pw) => authService.signUp(
            name: _name.text,
            type: _type,
            contact: _contact.text,
            password: pw,
          ),
          successMessage: 'Welcome to Wedding Connects!',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Create account',
      subtitle:
          'Choose where we should send your one-time password (OTP) to verify you.',
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Enter your name'
                    : null,
              ),
              const SizedBox(height: 16),
              ContactToggle(
                value: _type,
                onChanged: (t) => setState(() {
                  _type = t;
                  _contact.clear();
                  _error = null;
                }),
              ),
              const SizedBox(height: 16),
              ContactField(type: _type, controller: _contact),
              const SizedBox(height: 18),
              ErrorText(_error),
              PrimaryButton(
                  label: 'Send OTP', loading: _loading, onPressed: _continue),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// OTP entry. Pops with `true` when verified.
// ---------------------------------------------------------------------------

class OtpScreen extends StatefulWidget {
  final ContactType type;
  final String contact;

  const OtpScreen({super.key, required this.type, required this.contact});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _code = TextEditingController();
  bool _sending = true;
  bool _verifying = false;
  String? _error;
  String? _demoOtp;

  @override
  void initState() {
    super.initState();
    _send();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    final otp = await authService.sendOtp(widget.type, widget.contact);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _demoOtp = otp;
    });
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });
    final ok = await authService.verifyOtp(widget.type, widget.contact, code);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _verifying = false;
        _error = 'Incorrect code. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmail = widget.type == ContactType.email;
    final shown = AuthService.normalize(widget.type, widget.contact);
    return AuthShell(
      title: 'Verify your ${isEmail ? 'email' : 'number'}',
      subtitle: 'We sent a 6-digit code to $shown.',
      children: [
        if (_demoOtp != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Text(
              'DEMO MODE: no ${isEmail ? 'email' : 'SMS'} is really sent. '
              'Use code $_demoOtp.',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        TextField(
          controller: _code,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, letterSpacing: 10),
          decoration: const InputDecoration(
            counterText: '',
            hintText: '------',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _verify(),
        ),
        const SizedBox(height: 14),
        ErrorText(_error),
        PrimaryButton(
          label: 'Verify',
          loading: _verifying || _sending,
          onPressed: _verify,
        ),
        Center(
          child: TextButton(
            onPressed: _sending || _verifying ? null : _send,
            child: const Text('Resend code'),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Set password (used for sign-up and password reset)
// ---------------------------------------------------------------------------

class SetPasswordScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String buttonLabel;
  final String successMessage;
  final Future<String?> Function(String password) onSubmit;

  const SetPasswordScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.successMessage,
    required this.onSubmit,
  });

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await widget.onSubmit(_password.text);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _loading = false;
        _error = err;
      });
      return;
    }
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    navigator.popUntil((r) => r.isFirst);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(widget.successMessage)));
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: widget.title,
      subtitle: widget.subtitle,
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PasswordField(
                controller: _password,
                label: 'Password',
                validator: AuthService.validatePassword,
              ),
              const SizedBox(height: 14),
              PasswordField(
                controller: _confirm,
                label: 'Confirm password',
                validator: (v) =>
                    v != _password.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 6),
              const Text(
                'At least 8 characters, with letters and numbers.',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 18),
              ErrorText(_error),
              PrimaryButton(
                label: widget.buttonLabel,
                loading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Forgot password (contact -> OTP -> new password)
// ---------------------------------------------------------------------------

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _contact = TextEditingController();
  ContactType _type = ContactType.email;
  String? _error;

  @override
  void dispose() {
    _contact.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_form.currentState!.validate()) return;
    if (!authService.accountExists(_type, _contact.text)) {
      setState(() => _error = 'No account found with these details.');
      return;
    }
    setState(() => _error = null);
    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OtpScreen(type: _type, contact: _contact.text),
      ),
    );
    if (!mounted || verified != true) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SetPasswordScreen(
          title: 'Reset your password',
          subtitle: 'Choose a new password for your account.',
          buttonLabel: 'Reset password',
          onSubmit: (pw) =>
              authService.resetPassword(_type, _contact.text, pw),
          successMessage: 'Password updated. Please log in.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Forgot password',
      subtitle: 'We will send an OTP to verify it is you.',
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ContactToggle(
                value: _type,
                onChanged: (t) => setState(() {
                  _type = t;
                  _contact.clear();
                  _error = null;
                }),
              ),
              const SizedBox(height: 16),
              ContactField(type: _type, controller: _contact),
              const SizedBox(height: 18),
              ErrorText(_error),
              PrimaryButton(label: 'Send OTP', onPressed: _continue),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Edit profile
// ---------------------------------------------------------------------------

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final u = authService.currentUser!;
    _name = TextEditingController(text: u.name);
    _email = TextEditingController(text: u.email ?? '');
    _phone = TextEditingController(text: u.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  String? _optionalContact(ContactType t, String? v) =>
      (v == null || v.trim().isEmpty) ? null : AuthService.validateContact(t, v);

  Future<bool> _verifyIfChanged(
      ContactType t, String newValue, String? oldValue) async {
    if (newValue.trim().isEmpty) return true;
    if (AuthService.normalize(t, newValue) == oldValue) return true;
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => OtpScreen(type: t, contact: newValue)),
    );
    return ok == true;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final me = authService.currentUser!;
    if (_email.text.trim().isEmpty && _phone.text.trim().isEmpty) {
      setState(() => _error = 'Keep at least an email or a mobile number.');
      return;
    }
    for (final entry in {
      ContactType.email: _email.text,
      ContactType.phone: _phone.text,
    }.entries) {
      final v = entry.value;
      final old = entry.key == ContactType.email ? me.email : me.phone;
      if (v.trim().isNotEmpty &&
          AuthService.normalize(entry.key, v) != old &&
          authService.isContactTaken(entry.key, v, excludeUserId: me.id)) {
        setState(() => _error =
            'That ${entry.key == ContactType.email ? 'email' : 'number'} is used by another account.');
        return;
      }
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final emailOk = await _verifyIfChanged(ContactType.email, _email.text, me.email);
    if (!mounted) return;
    final phoneOk =
        emailOk && await _verifyIfChanged(ContactType.phone, _phone.text, me.phone);
    if (!mounted) return;
    if (!emailOk || !phoneOk) {
      setState(() {
        _saving = false;
        _error = 'Changes not saved: verification was not completed.';
      });
      return;
    }
    final err = await authService.updateProfile(
      name: _name.text,
      email: _email.text,
      phone: _phone.text,
    );
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _saving = false;
        _error = err;
      });
      return;
    }
    _toast(context, 'Profile updated.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Edit profile',
      subtitle:
          'Changing your email or mobile number needs a new OTP verification.',
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Enter your name'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email address (optional)',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => _optionalContact(ContactType.email, v),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile number (optional)',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => _optionalContact(ContactType.phone, v),
              ),
              const SizedBox(height: 18),
              ErrorText(_error),
              PrimaryButton(
                  label: 'Save changes', loading: _saving, onPressed: _save),
            ],
          ),
        ),
      ],
    );
  }
}
