import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:eClassify/data/model/user/user_model.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class UserProfileState {}

class UserProfileInitial extends UserProfileState {}

class UserProfileLoading extends UserProfileState {}

class UserProfileSuccess extends UserProfileState {
  UserProfileSuccess({required this.user, this.message});
  final UserModel user;
  final String? message;
}

class UserProfileFailure extends UserProfileState {
  UserProfileFailure({required this.errorMessage});

  final String errorMessage;
}

class UserProfileCubit extends Cubit<UserProfileState> {
  UserProfileCubit() : super(UserProfileInitial());

  Future<void> getUserProfile() async {
    try {
      emit(UserProfileLoading());

      final response = await Api.get(url: Api.userProfile);

      final user = UserModel.fromJson(response['data'] as Map<String, dynamic>);
      HiveUtils.setUserData(response['data']);

      emit(UserProfileSuccess(user: user, message: response['message']));
    } on Exception catch (e, stack) {
      log(e.toString(), name: 'getUserProfile');
      log('$stack', name: 'getUserProfile');
      emit(UserProfileFailure(errorMessage: e.toString()));
    }
  }

  Future<void> updateUserProfile({
    String? name,
    String? email,
    String? address,
    String? profileImagePath,
    String? fcmToken,
    String? notification,
    String? mobile,
    String? phoneCode,
    String? regionCode,
    int? personalDetail,
  }) async {
    try {
      emit(UserProfileLoading());

      final parameters = {
        Api.name: name ?? '',
        Api.email: email ?? '',
        Api.address: address ?? '',
        Api.fcmId: fcmToken ?? '',
        Api.notification: notification,
        Api.mobile: mobile,
        Api.countryCode: phoneCode,
        Api.regionCode: regionCode,
        Api.personalDetail: personalDetail,
      };

      if (profileImagePath != null) {
        parameters['profile'] = await MultipartFile.fromFile(profileImagePath);
      }

      final response = await Api.post(
        url: Api.updateProfileApi,
        parameter: parameters,
      );

      HiveUtils.setUserData(response['data']);

      emit(
        UserProfileSuccess(
          user: UserModel.fromJson(response['data']),
          message: response['message'],
        ),
      );
    } on Exception catch (e, stack) {
      log(e.toString(), name: 'updateUserProfile');
      log('$stack', name: 'updateUserProfile');
      emit(UserProfileFailure(errorMessage: e.toString()));
    }
  }
}
