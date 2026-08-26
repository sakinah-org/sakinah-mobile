import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sakinah/configurations/app_states.dart';
import 'package:sakinah/configurations/app_translation_keys.dart';
import 'package:sakinah/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:sakinah/handlers/translation_handler.dart';
import 'package:sakinah/navigation/app_routes.dart';
import 'package:sakinah/shared/widgets/fields/text_input_field.dart';
import 'package:sakinah/shared/widgets/icon_handler.dart';
import 'package:sakinah/toolkit/extensions/context_extensions.dart';
import 'package:sakinah/utils/assets/app_icons_keys.dart';
import 'package:sakinah/utils/style/app_colors.dart';
import 'package:sakinah/utils/style/app_typography.dart';

import '../bloc/forgot_password_bloc.dart';
import '../bloc/forgot_password_event.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ForgotPasswordBloc(AuthRepositoryImpl()),
      child: Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: BlocConsumer<ForgotPasswordBloc, AppStates>(
            listener: (context, state) {
              if (state is LoadedState) {
                Navigator.pushNamed(
                  context,
                  AppRoutes.verifyOtp,
                  arguments: state.data as String,
                );
              } else if (state is ErrorState) {
                context.showSnackBar(AppColors.error, state.errorMessage);
              }
            },
            builder: (context, state) {
              final isLoading = state is LoadingState;
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      translator.word(TranslationKeys.authForgotPasswordTitle),
                      style:
                          isDark ? AppTypography.h1Dark : AppTypography.h1Light,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      translator
                          .word(TranslationKeys.authForgotPasswordSubtitle),
                      style: isDark
                          ? AppTypography.body2Dark
                          : AppTypography.body2Light,
                    ),
                    const SizedBox(height: 24),
                    TextInputField(
                      controller: _emailController,
                      labelText:
                          translator.word(TranslationKeys.authEmailLabel),
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: drawSvgIcon(AppIcons.emailOutlined,
                          iconColor: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () => context.read<ForgotPasswordBloc>().add(
                                SendOtpRequestedEvent(
                                  email: _emailController.text.trim(),
                                ),
                              ),
                      child: isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(isDark
                                    ? AppColors.darkOnBrand
                                    : AppColors.lightOnBrand),
                              ),
                            )
                          : Text(
                              translator.word(TranslationKeys.authSendCodeCta)),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed:
                            isLoading ? null : () => Navigator.pop(context),
                        child: Text(translator.word(
                            TranslationKeys.authRememberedPasswordPrompt)),
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
