// lib/services/auth_phone.dart
import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for handling phone authentication with Supabase
class PhoneAuthService {
  final SupabaseClient supabase = Supabase.instance.client;

  /// Start the phone verification process
  /// 
  /// [phoneNumber] must be in international format: +1234567890
  Future<void> startPhoneVerification(String phoneNumber) async {
    try {
      await supabase.auth.signInWithOtp(
        phone: phoneNumber,
        shouldCreateUser: true,
      );
      log('✅ Verification code sent to $phoneNumber');
    } catch (e) {
      log('❌ Error sending verification code: $e');
      rethrow;
    }
  }

  /// Verify the phone number with the OTP code
  /// 
  /// [phoneNumber] must be the same number used in startPhoneVerification
  /// [verificationCode] is the OTP code sent to the user's phone
  Future<AuthResponse> verifyPhoneNumber(String phoneNumber, String verificationCode) async {
    try {
      final AuthResponse response = await supabase.auth.verifyOTP(
        type: OtpType.sms,
        phone: phoneNumber,
        token: verificationCode,
      );
      
      log('✅ Phone verification successful for $phoneNumber');
      return response;
    } catch (e) {
      log('❌ Error verifying phone number: $e');
      rethrow;
    }
  }

  /// Resend the verification code
  /// 
  /// Use this when the user didn't receive the code
  Future<void> resendVerificationCode(String phoneNumber) async {
    try {
      await supabase.auth.signInWithOtp(
        phone: phoneNumber,
        shouldCreateUser: true,
      );
      log('✅ Verification code resent to $phoneNumber');
    } catch (e) {
      log('❌ Error resending verification code: $e');
      rethrow;
    }
  }

  /// Link phone number to an existing account
  /// 
  /// The user must be authenticated already
  Future<void> linkPhoneToAccount(String phoneNumber) async {
    try {
      final Session? session = supabase.auth.currentSession;
      if (session == null) {
        throw Exception('No active session. User must be logged in first.');
      }

      // Start the phone verification process
      await startPhoneVerification(phoneNumber);
      log('✅ Started linking phone number to account');
    } catch (e) {
      log('❌ Error linking phone to account: $e');
      rethrow;
    }
  }

  /// Complete linking phone number to an existing account
  /// 
  /// The user must be authenticated already
  Future<void> completePhoneLinking(String phoneNumber, String verificationCode) async {
    try {
      final Session? session = supabase.auth.currentSession;
      if (session == null) {
        throw Exception('No active session. User must be logged in first.');
      }

      // Verify the OTP code
      await verifyPhoneNumber(phoneNumber, verificationCode);
      log('✅ Phone number linked to account successfully');
    } catch (e) {
      log('❌ Error completing phone linking: $e');
      rethrow;
    }
  }

  /// Check if the current user has a phone number linked
  Future<bool> hasPhoneLinked() async {
    try {
      final User? user = supabase.auth.currentUser;
      return user?.phone != null;
    } catch (e) {
      log('❌ Error checking phone linking status: $e');
      return false;
    }
  }
}