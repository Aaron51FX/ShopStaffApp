import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shop_staff/application/auth/email_auth_usecase.dart';

class EmailLoginState {
  const EmailLoginState({
    this.email = '',
    this.verificationCode = '',
    this.sendingCode = false,
    this.loggingIn = false,
    this.countdown = 0,
    this.error,
  });

  final String email;
  final String verificationCode;
  final bool sendingCode;
  final bool loggingIn;
  final int countdown;
  final String? error;

  bool get hasValidEmail =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
  bool get canSendCode =>
      hasValidEmail && !sendingCode && !loggingIn && countdown == 0;
  bool get canLogin =>
      hasValidEmail &&
      verificationCode.trim().isNotEmpty &&
      !sendingCode &&
      !loggingIn;

  EmailLoginState copyWith({
    String? email,
    String? verificationCode,
    bool? sendingCode,
    bool? loggingIn,
    int? countdown,
    Object? error = _unset,
  }) {
    return EmailLoginState(
      email: email ?? this.email,
      verificationCode: verificationCode ?? this.verificationCode,
      sendingCode: sendingCode ?? this.sendingCode,
      loggingIn: loggingIn ?? this.loggingIn,
      countdown: countdown ?? this.countdown,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }

  static const Object _unset = Object();
}

class EmailLoginViewModel extends StateNotifier<EmailLoginState> {
  EmailLoginViewModel(this._auth) : super(const EmailLoginState()) {
    emailController.addListener(_onEmailChanged);
    verificationCodeController.addListener(_onVerificationCodeChanged);
    unawaited(_restoreLastEmail());
  }

  final EmailAuthUseCase _auth;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController verificationCodeController =
      TextEditingController();
  Timer? _countdownTimer;
  bool _disposed = false;

  Future<void> _restoreLastEmail() async {
    final email = await _auth.readLastEmail();
    if (_disposed || email == null || emailController.text.trim().isNotEmpty) {
      return;
    }
    emailController.text = email;
    emailController.selection = TextSelection.collapsed(offset: email.length);
  }

  void _onEmailChanged() {
    state = state.copyWith(email: emailController.text.trim(), error: null);
  }

  void _onVerificationCodeChanged() {
    state = state.copyWith(
      verificationCode: verificationCodeController.text.trim(),
      error: null,
    );
  }

  Future<void> sendVerificationCode() async {
    if (!state.canSendCode) return;
    state = state.copyWith(sendingCode: true, error: null);
    try {
      await _auth.sendVerificationCode(state.email);
      state = state.copyWith(sendingCode: false, countdown: 60);
      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final next = state.countdown - 1;
        if (next <= 0) {
          timer.cancel();
          state = state.copyWith(countdown: 0);
        } else {
          state = state.copyWith(countdown: next);
        }
      });
    } catch (error) {
      state = state.copyWith(sendingCode: false, error: error.toString());
    }
  }

  Future<void> login(BuildContext context) async {
    if (!state.canLogin) return;
    state = state.copyWith(loggingIn: true, error: null);
    try {
      final hasMachineCode = await _auth.login(
        email: state.email,
        verificationCode: state.verificationCode,
      );
      if (context.mounted) {
        context.go(hasMachineCode ? '/splash' : '/activate');
      }
    } catch (error) {
      state = state.copyWith(loggingIn: false, error: error.toString());
      return;
    }
    state = state.copyWith(loggingIn: false);
  }

  @override
  void dispose() {
    _disposed = true;
    _countdownTimer?.cancel();
    emailController
      ..removeListener(_onEmailChanged)
      ..dispose();
    verificationCodeController
      ..removeListener(_onVerificationCodeChanged)
      ..dispose();
    super.dispose();
  }
}

final emailLoginViewModelProvider =
    StateNotifierProvider.autoDispose<EmailLoginViewModel, EmailLoginState>((
      ref,
    ) {
      return EmailLoginViewModel(ref.watch(emailAuthUseCaseProvider));
    });
