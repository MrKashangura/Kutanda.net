import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// Sign up a user
Future<AuthResponse> signUpUser(String email, String password) async {
  final response = await supabase.auth.signUp(email: email, password: password);
  return response;
}

// Sign in a user
Future<AuthResponse> signInUser(String email, String password) async {
  final response = await supabase.auth.signInWithPassword(email: email, password: password);
  return response;
}

// Sign out
Future<void> signOutUser() async {
  await supabase.auth.signOut();
}
