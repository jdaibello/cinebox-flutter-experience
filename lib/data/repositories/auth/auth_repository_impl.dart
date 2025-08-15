import 'dart:developer';

import 'package:cinebox/core/result/result.dart';
import 'package:cinebox/data/exceptions/data_exception.dart';
import 'package:cinebox/data/services/google_signin/google_signin_service.dart';
import 'package:cinebox/data/services/local_storage/local_storage_service.dart';

import './auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final LocalStorageService _localStorageService;
  final GoogleSignInService _googleSignInService;

  AuthRepositoryImpl({
    required LocalStorageService localStorageService,
    required GoogleSignInService googleSignInService,
  }) : _localStorageService = localStorageService,
       _googleSignInService = googleSignInService;

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
        await _localStorageService.saveIdToken(value);

        //! Login in with the backend

        return successOfUnit();
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
