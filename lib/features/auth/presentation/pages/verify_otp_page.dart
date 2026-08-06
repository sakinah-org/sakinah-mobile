import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';
import 'package:sakinah/configurations/app_translation_keys.dart';
import 'package:sakinah/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:sakinah/handlers/translation_handler.dart';
import 'package:sakinah/navigation/app_routes.dart';
import 'package:sakinah/toolkit/extensions/context_extensions.dart';
import 'package:sakinah/utils/style/app_colors.dart';
import 'package:sakinah/utils/style/app_typography.dart';

import '../bloc/otp_bloc.dart';
import '../bloc/otp_event.dart';
import '../bloc/otp_state.dart';

const _otpLength = 6;

String _maskEmail(String email) {
  final atIndex = email.indexOf('@');
  if (atIndex <= 2) return email;
  return '${email.substring(0, 2)}••••${email.substring(atIndex)}';
}

class VerifyOtpPage extends StatefulWidget {
  const VerifyOtpPage({super.key});

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final _pinController = TextEditingController();
  String _code = '';

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = ModalRoute.of(context)!.settings.arguments as String;

    final defaultPinTheme = PinTheme(
      width: 42,
      height: 52,
      textStyle: AppTypography.h2Light,
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.lightBorder, width: 1.5),
      ),
    );
    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppColors.lightBrandPrimary, width: 1.5),
      ),
    );
    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppColors.error, width: 1.5),
      ),
    );

    return BlocProvider(
      create: (_) => OtpBloc(AuthRepositoryImpl(), email: email),
      child: Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: BlocConsumer<OtpBloc, OtpState>(
            // Guard against reacting to the same outcome more than once —
            // e.g. a stray countdown tick that re-emits a still-`verified`
            // state must never trigger a second navigation.
            listenWhen: (previous, current) =>
                previous.verified != current.verified ||
                (current.errorMessage != null &&
                    previous.errorMessage != current.errorMessage),
            listener: (context, state) {
              if (state.verified) {
                Navigator.pushNamed(
                  context,
                  AppRoutes.resetPassword,
                  arguments: email,
                );
              } else if (state.errorMessage != null) {
                context.showSnackBar(AppColors.error, state.errorMessage!);
              }
            },
            builder: (context, state) {
              final minutes = state.secondsRemaining ~/ 60;
              final seconds = state.secondsRemaining % 60;
              final countdownText =
                  '$minutes:${seconds.toString().padLeft(2, '0')}';

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      translator.word(TranslationKeys.authOtpTitle),
                      style: AppTypography.h1Light,
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        style: AppTypography.body2Light,
                        children: [
                          TextSpan(
                              text:
                                  '${translator.word(TranslationKeys.authOtpSubtitlePrefix)} '),
                          TextSpan(
                            text: _maskEmail(email),
                            style: AppTypography.body2Light
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Pinput(
                      length: _otpLength,
                      controller: _pinController,
                      enabled: !state.isVerifying,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: focusedPinTheme,
                      submittedPinTheme: defaultPinTheme,
                      errorPinTheme: errorPinTheme,
                      forceErrorState: state.errorMessage != null,
                      pinAnimationType: PinAnimationType.scale,
                      onChanged: (code) => setState(() => _code = code),
                      onCompleted: (code) => setState(() => _code = code),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: state.canResend
                          ? TextButton(
                              onPressed: () => context
                                  .read<OtpBloc>()
                                  .add(ResendOtpRequestedEvent()),
                              child: Text(translator
                                  .word(TranslationKeys.authOtpResendAction)),
                            )
                          : Text(
                              '${translator.word(TranslationKeys.authOtpResendPrompt)} '
                              '${translator.word(TranslationKeys.authOtpResendCountdown)} $countdownText',
                              style: AppTypography.body2Light,
                            ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: state.isVerifying
                          ? null
                          : () => context
                              .read<OtpBloc>()
                              .add(VerifyOtpSubmittedEvent(code: _code)),
                      child: state.isVerifying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                    AppColors.lightOnBrand),
                              ),
                            )
                          : Text(translator
                              .word(TranslationKeys.authOtpVerifyCta)),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(translator
                            .word(TranslationKeys.authOtpChangeEmail)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
