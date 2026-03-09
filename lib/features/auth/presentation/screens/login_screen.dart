import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/gradients.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isSignUp = false;
  bool _autoBiometricAttempted = false;
  bool _enableFaceId = false;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBiometricState();
      _maybeAutoSignInWithBiometrics();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);

    ref.listen<LoginState>(loginProvider, (_, state) {
      if (state.isAuthenticated) {
        context.go('/dashboard');
      }
      if (state.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.error!)));
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.backgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo / Title
                    const Icon(
                      Icons.mic_rounded,
                      size: 64,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: AppDimensions.paddingM),
                    Text(
                      AppStrings.appName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: AppDimensions.paddingS),
                    Text(
                      'Voice-First AI for Field Workers',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppDimensions.paddingXXL),

                    // Name field (sign up only)
                    if (_isSignUp) ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppDimensions.paddingM),
                    ],

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        hintText: AppStrings.email,
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email is required';
                        }
                        if (!value.contains('@')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.paddingM),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        hintText: AppStrings.password,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.paddingL),

                    CheckboxListTile(
                      value: _enableFaceId,
                      onChanged: loginState.isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _enableFaceId = value ?? false;
                              });
                            },
                      title: const Text(AppStrings.enableFaceId),
                      subtitle: const Text(
                        'Same device preference as the Face ID setting in Settings',
                      ),
                      activeColor: AppColors.primary,
                      checkColor: AppColors.background,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: AppDimensions.paddingM),

                    // Sign In / Sign Up button
                    GradientButton(
                      label: _isSignUp ? AppStrings.signUp : AppStrings.login,
                      isLoading: loginState.isLoading,
                      onPressed: loginState.isLoading ? null : _handleSubmit,
                    ),
                    const SizedBox(height: AppDimensions.paddingM),

                    // Toggle sign in / sign up
                    TextButton(
                      onPressed: () {
                        setState(() => _isSignUp = !_isSignUp);
                        ref.read(loginProvider.notifier).clearError();
                      },
                      child: Text(
                        _isSignUp
                            ? 'Already have an account? Sign In'
                            : "Don't have an account? Sign Up",
                        style: const TextStyle(color: AppColors.primaryLight),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(loginProvider.notifier);
    if (_isSignUp) {
      notifier.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        enableBiometric: _enableFaceId,
      );
    } else {
      notifier.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        enableBiometric: _enableFaceId,
      );
    }
  }

  Future<void> _loadBiometricState() async {
    if (!mounted) return;

    final secureStorage = ref.read(secureStorageServiceProvider);
    final isEnabled = await secureStorage.isBiometricEnabled();

    if (!mounted) return;
    setState(() {
      _enableFaceId = isEnabled;
    });
  }

  Future<void> _maybeAutoSignInWithBiometrics() async {
    if (!mounted || _autoBiometricAttempted || _isSignUp) return;
    _autoBiometricAttempted = true;

    final suppressed = await ref
        .read(secureStorageServiceProvider)
        .consumeBiometricPromptSuppression();
    if (suppressed) return;

    final hasSession = ref.read(authRepositoryProvider).currentSession != null;
    if (hasSession) return;

    await ref.read(loginProvider.notifier).maybeAutoSignInWithBiometrics();
  }
}
