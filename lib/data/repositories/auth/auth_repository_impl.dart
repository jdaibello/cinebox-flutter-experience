import 'dart:developer';

import 'package:cinebox/core/result/result.dart';
import 'package:cinebox/data/exceptions/data_exception.dart';
import 'package:cinebox/data/services/auth/auth_service.dart';
import 'package:cinebox/data/services/google_signin/google_signin_service.dart';
import 'package:cinebox/data/services/local_storage/local_storage_service.dart';
import 'package:dio/dio.dart';

import './auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final LocalStorageService _localStorageService;
  final GoogleSignInService _googleSignInService;
  final AuthService _authService;

  AuthRepositoryImpl({
    required LocalStorageService localStorageService,
    required GoogleSignInService googleSignInService,
    required AuthService authService,
  }) : _localStorageService = localStorageService,
       _googleSignInService = googleSignInService,
       _authService = authService;

  @override
  Future<Result<bool>> isLoggedIn() async {
    final resultToken = await _localStorageService.getIdToken();

    return switch (resultToken) {
      Success<String>() => Success(true),
      Failure<String>() => Success(false),
    };
  }

  @override
  Future<Result<Unit>> signIn() async {
    final result = await _googleSignInService.signIn();

    switch (result) {
      case Success<String>(:final value):
        try {
          await _localStorageService.saveIdToken(value);
          await _authService.auth();

          return successOfUnit();
        } on DioException catch (e, s) {
          log(
            'Error when authentication the user with the backend',
            name: 'AuthRepository',
            error: e,
            stackTrace: s,
          );

          return Failure(DataException(message: 'Error when authentication the user with the backend'));
        }
      case Failure<String>(:final error):
        log(
          'Error when signin in with Google',
          name: 'AuthRepository',
          error: error,
        );

        return Failure(DataException(message: 'Error when signin in with Google'));
    }
  }

  @override
  Future<Result<Unit>> signOut() async {
    final result = await _googleSignInService.signOut();

    switch (result) {
      case Success<Unit>():
        final removeResult = await _localStorageService.removeIdToken();

        switch (removeResult) {
          case Success<Unit>():
            return successOfUnit();
          case Failure<Unit>(:final error):
            log(
              'Error when removing ID token',
              name: 'AuthRepository',
              error: error,
            );

            return Failure(error);
        }
      case Failure<Unit>(:final error):
        return Failure(error);
    }
  }
}
