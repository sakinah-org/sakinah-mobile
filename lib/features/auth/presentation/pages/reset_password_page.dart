import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sakinah/configurations/app_states.dart';
import 'package:sakinah/configurations/app_translation_keys.dart';
import 'package:sakinah/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:sakinah/handlers/translation_handler.dart';
import 'package:sakinah/navigation/app_routes.dart';
import 'package:sakinah/shared/widgets/fields/text_input_field.dart';
import 'package:sakinah/shared/widgets/icon_handler.dart';
import 'package:sakinah/shared/widgets/status_snackbars.dart';
import 'package:sakinah/toolkit/extensions/context_extensions.dart';
import 'package:sakinah/utils/assets/app_icons_keys.dart';
import 'package:sakinah/utils/style/app_colors.dart';
import 'package:sakinah/utils/style/app_typography.dart';

import '../bloc/reset_password_bloc.dart';
import '../bloc/reset_password_event.dart';
import '../widgets/password_rules_hint.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ResetPasswordBloc(AuthRepositoryImpl()),
      child: Scaffold(
        body: SafeArea(
          child: BlocConsumer<ResetPasswordBloc, AppStates>(
            listener: (context, state) {
              if (state is SuccessState) {
                Navigator.popUntil(
                    context, ModalRoute.withName(AppRoutes.login));
                ScaffoldMessenger.of(context).showSnackBar(
                  StatusSnackBars.successSnackBar(
                    translator
                        .word(TranslationKeys.authResetPasswordSuccessMessage),
                  ),
                );
              } else if (state is ErrorState) {
                context.showSnackBar(AppColors.error, state.errorMessage);
              }
            },
            builder: (context, state) {
              final isLoading = state is LoadingState;
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final textTertiary = isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary;
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      translator.word(TranslationKeys.authResetPasswordTitle),
                      style:
                          isDark ? AppTypography.h1Dark : AppTypography.h1Light,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      translator
                          .word(TranslationKeys.authResetPasswordSubtitle),
                      style: isDark
                          ? AppTypography.body2Dark
                          : AppTypography.body2Light,
                    ),
                    const SizedBox(height: 24),
                    TextInputField(
                      controller: _newPasswordController,
                      labelText:
                          translator.word(TranslationKeys.authNewPasswordLabel),
                      keyboardType: TextInputType.visiblePassword,
                      prefixIcon: drawSvgIcon(AppIcons.password,
                          iconColor: textTertiary),
                      withBottomPadding: false,
                    ),
                    const PasswordRulesHint(),
                    TextInputField(
                      controller: _confirmPasswordController,
                      labelText: translator
                          .word(TranslationKeys.authConfirmPasswordLabel),
                      keyboardType: TextInputType.visiblePassword,
                      prefixIcon: drawSvgIcon(AppIcons.password,
                          iconColor: textTertiary),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () => context.read<ResetPasswordBloc>().add(
                                ResetPasswordSubmittedEvent(
                                  newPassword: _newPasswordController.text,
                                  confirmPassword:
                                      _confirmPasswordController.text,
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
                          : Text(translator
                              .word(TranslationKeys.authSavePasswordCta)),
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
