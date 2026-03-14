import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_color_scheme.dart';
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
    final c = context.colors;
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              c.background,
              const Color(0xFF111E1A), // Deep Forest undertone
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // ── Decorative background circles ──
            Positioned(
              top: -100,
              left: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.deepForest.withValues(alpha: 0.45),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c.passive.withValues(alpha: 0.12),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 180,
              right: -20,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.chat.withValues(alpha: 0.08),
                ),
              ),
            ),

            // ── Main content ──
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Logo with concentric rings ──
                        Center(
                          child: SizedBox(
                            width: 160,
                            height: 160,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer ring
                                Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: c.primary.withValues(
                                        alpha: 0.15,
                                      ),
                                    ),
                                  ),
                                ),
                                // Middle ring
                                Container(
                                  width: 115,
                                  height: 115,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: c.primary.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                  ),
                                ),
                                // Inner circle
                                Container(
                                  width: 74,
                                  height: 74,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: c.deepForest,
                                    border: Border.all(
                                      color: c.primary.withValues(
                                        alpha: 0.35,
                                      ),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.mic_rounded,
                                    size: 32,
                                    color: c.primary,
                                  ),
                                ),
                                // Small decorative dots
                                Positioned(
                                  top: 15,
                                  right: 22,
                                  child: Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: c.primary.withValues(
                                        alpha: 0.45,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 20,
                                  left: 18,
                                  child: Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: c.passive.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
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
                        const SizedBox(height: 48),

                        // Name field (sign up only)
                        if (_isSignUp) ...[
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Full Name',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(999),
                                borderSide: BorderSide(
                                  color: c.divider,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(999),
                                borderSide: BorderSide(
                                  color: c.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: AppDimensions.paddingM),
                        ],

                        // Email field (pill)
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: AppStrings.email,
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(999),
                              borderSide: BorderSide(
                                color: c.divider,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(999),
                              borderSide: BorderSide(
                                color: c.primary,
                                width: 1.5,
                              ),
                            ),
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

                        // Password field (pill)
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
                                  () =>
                                      _obscurePassword = !_obscurePassword,
                                );
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(999),
                              borderSide: BorderSide(
                                color: c.divider,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(999),
                              borderSide: BorderSide(
                                color: c.primary,
                                width: 1.5,
                              ),
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

                        // Face ID toggle
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: c.surface,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: c.deepForest.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                child: Icon(
                                  Icons.face,
                                  color: c.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  AppStrings.enableFaceId,
                                  style: TextStyle(
                                    color: c.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _enableFaceId,
                                onChanged: loginState.isLoading
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _enableFaceId = value;
                                        });
                                      },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.paddingL),

                        // Sign In / Sign Up button (pill)
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed:
                                loginState.isLoading ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c.primary,
                              foregroundColor: c.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              elevation: 0,
                            ),
                            child: loginState.isLoading
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: c.onPrimary,
                                    ),
                                  )
                                : Text(
                                    _isSignUp
                                        ? AppStrings.signUp
                                        : AppStrings.login,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
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
                            style: TextStyle(color: c.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
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
