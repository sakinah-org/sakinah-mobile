import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sakinah/configurations/app_states.dart';
import 'package:sakinah/configurations/app_translation_keys.dart';
import 'package:sakinah/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:sakinah/handlers/translation_handler.dart';
import 'package:sakinah/shared/widgets/fields/text_input_field.dart';
import 'package:sakinah/shared/widgets/icon_handler.dart';
import 'package:sakinah/shared/widgets/status_snackbars.dart';
import 'package:sakinah/toolkit/extensions/context_extensions.dart';
import 'package:sakinah/utils/assets/app_icons_keys.dart';
import 'package:sakinah/utils/style/app_colors.dart';
import 'package:sakinah/utils/style/app_typography.dart';

import '../bloc/register_bloc.dart';
import '../bloc/register_event.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RegisterBloc(AuthRepositoryImpl()),
      child: Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: BlocConsumer<RegisterBloc, AppStates>(
            listener: (context, state) {
              if (state is SuccessState) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  StatusSnackBars.successSnackBar(
                    translator.word(TranslationKeys.authRegisterSuccessMessage),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      translator.word(TranslationKeys.authRegisterTitle),
                      style:
                          isDark ? AppTypography.h1Dark : AppTypography.h1Light,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      translator.word(TranslationKeys.authRegisterSubtitle),
                      style: isDark
                          ? AppTypography.body2Dark
                          : AppTypography.body2Light,
                    ),
                    const SizedBox(height: 24),
                    TextInputField(
                      controller: _nameController,
                      labelText: translator.word(TranslationKeys.authNameLabel),
                      keyboardType: TextInputType.name,
                      prefixIcon: drawSvgIcon(AppIcons.profile,
                          iconColor: textTertiary),
                    ),
                    TextInputField(
                      controller: _emailController,
                      labelText:
                          translator.word(TranslationKeys.authEmailLabel),
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: drawSvgIcon(AppIcons.emailOutlined,
                          iconColor: textTertiary),
                    ),
                    TextInputField(
                      controller: _passwordController,
                      labelText:
                          translator.word(TranslationKeys.authPasswordLabel),
                      keyboardType: TextInputType.visiblePassword,
                      prefixIcon: drawSvgIcon(AppIcons.password,
                          iconColor: textTertiary),
                    ),
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
                          : () => context.read<RegisterBloc>().add(
                                RegisterSubmittedEvent(
                                  name: _nameController.text.trim(),
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text,
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
                          : Text(
                              translator.word(TranslationKeys.authRegisterCta)),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          translator
                              .word(TranslationKeys.authHaveAccountPrompt),
                          style: isDark
                              ? AppTypography.body2Dark
                              : AppTypography.body2Light,
                        ),
                        TextButton(
                          onPressed:
                              isLoading ? null : () => Navigator.pop(context),
                          child: Text(
                              translator.word(TranslationKeys.authLoginLink)),
                        ),
                      ],
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
