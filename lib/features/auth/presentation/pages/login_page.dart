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

import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginBloc(AuthRepositoryImpl()),
      child: Scaffold(
        body: SafeArea(
          child: BlocConsumer<LoginBloc, AppStates>(
            listener: (context, state) {
              if (state is LoadedState) {
                Navigator.pop(context);
              } else if (state is ErrorState) {
                context.showSnackBar(AppColors.error, state.errorMessage);
              }
            },
            builder: (context, state) {
              final isLoading = state is LoadingState;
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24 , vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    Text(
                      "سكينة",
                      style: AppTypography.appNameRegular,
                      textAlign: TextAlign.center

                    ),
                    const SizedBox(height: 8),
                    Text(
                      translator.word(TranslationKeys.authWelcomeBack),
                      textAlign: TextAlign.center,
                      style: AppTypography.h1Light,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      translator.word(TranslationKeys.authLoginSubtitle),
                      textAlign: TextAlign.center,
                      style: AppTypography.body2Light,
                    ),
                    const SizedBox(height: 24),
                    TextInputField(
                      controller: _emailController,
                      labelText:
                          translator.word(TranslationKeys.authEmailLabel),
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: drawSvgIcon(AppIcons.emailOutlined,
                          iconColor: AppColors.lightTextTertiary),
                    ),
                    TextInputField(
                      controller: _passwordController,
                      labelText:
                          translator.word(TranslationKeys.authPasswordLabel),
                      keyboardType: TextInputType.visiblePassword,
                      prefixIcon: drawSvgIcon(AppIcons.password,
                          iconColor: AppColors.lightTextTertiary),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        onPressed: isLoading
                            ? null
                            : () => Navigator.pushNamed(
                                context, AppRoutes.forgotPassword),
                        child: Text(translator
                            .word(TranslationKeys.authForgotPassword)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () => context.read<LoginBloc>().add(
                                LoginSubmittedEvent(
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text,
                                ),
                              ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                    AppColors.lightOnBrand),
                              ),
                            )
                          : Text(translator.word(TranslationKeys.authLoginCta)),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          translator.word(TranslationKeys.authNoAccountPrompt),
                          style: AppTypography.body2Light,
                        ),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => Navigator.pushNamed(
                                  context, AppRoutes.register),
                          child: Text(translator
                              .word(TranslationKeys.authCreateAccountLink)),
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
