import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

String formatAuthError(
  Object err, {
  String fallbackMessage = 'Something went wrong. Please try again.',
}) {
  if (err is DioException) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      return 'Connection timed out. Check your internet and try again.';
    }
    if (err.type == DioExceptionType.connectionError) {
      return 'Cannot reach the server. Make sure the backend is running.';
    }
    final status = err.response?.statusCode;
    final data = err.response?.data;
    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is Map<String, dynamic> && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) {
          return first.first.toString();
        }
      }
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    if (status == 401 || status == 422) {
      return 'Invalid email or password.';
    }
  }
  return fallbackMessage;
}

/// Shared design tokens and minimalist UI primitives for auth/onboarding screens.
class AuthTheme {
  AuthTheme._();

  static const Color background = Color(0xFFFAF8F5);
  static const Color surface = Colors.white;
  static const Color primary = Color(0xFF1B8354);
  static const Color primaryTint = Color(0xFFECFDF5);
  static const Color ink = Color(0xFF0F172A);
  static const Color label = Color(0xFF334155);
  static const Color body = Color(0xFF475569);
  static const Color muted = Color(0xFF64748B);
  static const Color hint = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color errorBorder = Color(0xFFEF4444);
  static const Color errorBackground = Color(0xFFFEF2F2);
  static const Color errorBannerBorder = Color(0xFFFCA5A5);
  static const Color errorText = Color(0xFFDC2626);

  static const double inputRadius = 14;
  static const double buttonRadius = 16;
  static const double cardRadius = 20;
  static const double maxFormWidth = 440;

  static const TextStyle inputTextStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: Color(0xFF1E293B),
  );
}

InputDecoration authInputDecoration({
  required String hintText,
  IconData? prefixIcon,
  Widget? suffixIcon,
  EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 15,
  ),
}) {
  OutlineInputBorder outline(Color color, {double width = 1.5}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AuthTheme.inputRadius),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(
      color: AuthTheme.hint,
      fontSize: 15,
      fontWeight: FontWeight.w400,
    ),
    prefixIcon: prefixIcon != null
        ? Icon(prefixIcon, color: AuthTheme.muted, size: 20)
        : null,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AuthTheme.surface,
    contentPadding: contentPadding,
    border: outline(AuthTheme.border),
    enabledBorder: outline(AuthTheme.border),
    focusedBorder: outline(AuthTheme.primary, width: 1.8),
    errorBorder: outline(AuthTheme.errorBorder),
    focusedErrorBorder: outline(AuthTheme.errorBorder, width: 1.8),
  );
}

class AuthPageScaffold extends StatelessWidget {
  const AuthPageScaffold({
    super.key,
    required this.child,
    this.showBackButton = false,
    this.centerVertically = false,
    this.onBack,
  });

  final Widget child;
  final bool showBackButton;
  final bool centerVertically;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 380 ? 20.0 : 24.0;
            final minHeight = (constraints.maxHeight - 24).clamp(
              0.0,
              double.infinity,
            );

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 12,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: AuthTheme.maxFormWidth,
                    minHeight: minHeight,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: centerVertically && !showBackButton
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      if (showBackButton)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            tooltip: 'Back',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.chevron_left_rounded,
                              size: 32,
                              color: AuthTheme.ink,
                            ),
                            onPressed:
                                onBack ?? () => Navigator.of(context).maybePop(),
                          ),
                        ),
                      child,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AuthFieldGroup extends StatelessWidget {
  const AuthFieldGroup({
    super.key,
    required this.label,
    required this.child,
    this.isOptional = false,
  });

  final String label;
  final Widget child;
  final bool isOptional;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AuthTheme.label,
                ),
              ),
              if (isOptional) ...[
                const SizedBox(width: 6),
                const Text(
                  'Optional',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AuthTheme.hint,
                  ),
                ),
              ],
            ],
          ),
        ),
        child,
      ],
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AuthTheme.errorBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AuthTheme.errorBannerBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.error_outline_rounded,
              color: AuthTheme.errorText,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AuthTheme.errorText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AuthTheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AuthTheme.primary.withValues(alpha: 0.65),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AuthTheme.buttonRadius),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
      ),
    );
  }
}

class AuthSecondaryButton extends StatelessWidget {
  const AuthSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AuthTheme.surface,
          foregroundColor: AuthTheme.ink,
          side: const BorderSide(color: AuthTheme.border, width: 1.4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AuthTheme.buttonRadius),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}

class AuthFooterPrompt extends StatelessWidget {
  const AuthFooterPrompt({
    super.key,
    required this.prompt,
    required this.actionLabel,
    required this.onTap,
  });

  final String prompt;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '$prompt ',
          style: const TextStyle(
            fontSize: 14,
            color: AuthTheme.muted,
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: AuthTheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            actionLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
