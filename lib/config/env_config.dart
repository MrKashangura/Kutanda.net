import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get supabaseUrl => 
    dotenv.env['SUPABASE_URL'] ?? 'https://dcjycjiqelcftxbymley.supabase.co';
  
  static String get supabaseAnonKey => 
    dotenv.env['SUPABASE_ANON_KEY'] ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRjanljamlxZWxjZnR4YnltbGV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAyMTIwNTksImV4cCI6MjA1NTc4ODA1OX0.DmLByHHoWeRPusRD2EoYLxxk5F_soscl3jKg7mE4pPM';
    
  static String get oneSignalAppId => 
    dotenv.env['ONESIGNAL_APP_ID'] ?? '474b0ac4-c770-4050-b4b2-6b8cbef188a7';
  
  // Add other environment variables as needed
}