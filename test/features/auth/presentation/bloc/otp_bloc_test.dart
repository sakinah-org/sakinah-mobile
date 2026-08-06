import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sakinah/configurations/app_errors.dart';
import 'package:sakinah/features/auth/domain/repositories/auth_repository.dart';
import 'package:sakinah/features/auth/presentation/bloc/otp_bloc.dart';
import 'package:sakinah/features/auth/presentation/bloc/otp_event.dart';
import 'package:sakinah/features/auth/presentation/bloc/otp_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;
  late DateTime fakeNow;

  setUp(() {
    authRepository = MockAuthRepository();
    fakeNow = DateTime(2026, 1, 1, 12, 0, 0);
  });

  OtpBloc buildBloc() =>
      OtpBloc(authRepository, email: 'user@example.com', clock: () => fakeNow);

  blocTest<OtpBloc, OtpState>(
    'starts with a 60s cooldown and resend disabled',
    build: buildBloc,
    verify: (bloc) {
      expect(bloc.state.secondsRemaining, 60);
      expect(bloc.state.canResend, isFalse);
    },
  );

  blocTest<OtpBloc, OtpState>(
    'correct code verifies and marks the state as verified',
    setUp: () {
      when(() => authRepository.verifyOtp(
            email: any(named: 'email'),
            otp: any(named: 'otp'),
          )).thenAnswer((_) async {});
    },
    build: buildBloc,
    act: (bloc) => bloc.add(VerifyOtpSubmittedEvent(code: '123456')),
    expect: () => [
      isA<OtpState>().having((s) => s.isVerifying, 'isVerifying', true),
      isA<OtpState>().having((s) => s.verified, 'verified', true),
    ],
  );

  blocTest<OtpBloc, OtpState>(
    'stops the countdown timer once verified — regression test for '
    'repeated navigation caused by the timer re-emitting a still-verified '
    'state every second after success',
    setUp: () {
      when(() => authRepository.verifyOtp(
            email: any(named: 'email'),
            otp: any(named: 'otp'),
          )).thenAnswer((_) async {});
    },
    build: buildBloc,
    act: (bloc) => bloc.add(VerifyOtpSubmittedEvent(code: '123456')),
    // Give the real periodic Timer more than one tick's worth of wall-clock
    // time to fire if it were still running — it must not emit anything
    // beyond the two states from the verify call itself.
    wait: const Duration(seconds: 2),
    expect: () => [
      isA<OtpState>().having((s) => s.isVerifying, 'isVerifying', true),
      isA<OtpState>().having((s) => s.verified, 'verified', true),
    ],
  );

  blocTest<OtpBloc, OtpState>(
    'incorrect code errors and stays unverified',
    setUp: () {
      when(() => authRepository.verifyOtp(
            email: any(named: 'email'),
            otp: any(named: 'otp'),
          )).thenThrow(UnauthorizedFailure('Invalid or expired code'));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(VerifyOtpSubmittedEvent(code: '000000')),
    expect: () => [
      isA<OtpState>().having((s) => s.isVerifying, 'isVerifying', true),
      isA<OtpState>()
          .having((s) => s.verified, 'verified', false)
          .having((s) => s.errorMessage, 'errorMessage', isNotNull),
    ],
  );

  blocTest<OtpBloc, OtpState>(
    'too-short code errors without calling the repository',
    build: buildBloc,
    act: (bloc) => bloc.add(VerifyOtpSubmittedEvent(code: '123')),
    expect: () => [
      isA<OtpState>().having((s) => s.errorMessage, 'errorMessage', isNotNull),
    ],
    verify: (_) {
      verifyNever(() => authRepository.verifyOtp(
            email: any(named: 'email'),
            otp: any(named: 'otp'),
          ));
    },
  );

  blocTest<OtpBloc, OtpState>(
    'resend is ignored while the cooldown is still running',
    build: buildBloc,
    act: (bloc) => bloc.add(ResendOtpRequestedEvent()),
    expect: () => [],
    verify: (_) {
      verifyNever(() => authRepository.resendOtp(email: any(named: 'email')));
    },
  );

  blocTest<OtpBloc, OtpState>(
    'countdown reflects real elapsed time, including a backgrounding gap, '
    'and resend restarts a fresh 60s once it reaches zero',
    setUp: () {
      when(() => authRepository.resendOtp(email: any(named: 'email')))
          .thenAnswer((_) async {});
    },
    build: buildBloc,
    act: (bloc) async {
      // Simulate 45s of real elapsed time passing in one jump (e.g. the app
      // was backgrounded), then a tick — the countdown must reflect the
      // real gap, not decrement by 1.
      fakeNow = fakeNow.add(const Duration(seconds: 45));
      bloc.add(OtpCountdownTickedEvent());
      await Future<void>.delayed(Duration.zero);

      // Advance past the full cooldown; resend should now be allowed.
      fakeNow = fakeNow.add(const Duration(seconds: 20));
      bloc.add(OtpCountdownTickedEvent());
      await Future<void>.delayed(Duration.zero);

      bloc.add(ResendOtpRequestedEvent());
    },
    expect: () => [
      isA<OtpState>().having((s) => s.secondsRemaining, 'secondsRemaining', 15),
      isA<OtpState>().having((s) => s.secondsRemaining, 'secondsRemaining', 0),
      isA<OtpState>().having((s) => s.isResending, 'isResending', true),
      isA<OtpState>()
          .having((s) => s.secondsRemaining, 'secondsRemaining', 60)
          .having((s) => s.isResending, 'isResending', false),
    ],
  );
}
