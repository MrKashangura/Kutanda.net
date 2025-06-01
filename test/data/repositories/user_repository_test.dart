import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:kutanda/lib/data/models/user_model.dart';
import 'package:kutanda/lib/data/repositories/user_repository.dart';
import 'package:kutanda/lib/services/api_service.dart';

// Generate mocks by running `flutter pub run build_runner build`
@GenerateMocks([ApiService])
import 'user_repository_test.mocks.dart'; // This file will be generated

void main() {
  late UserRepository userRepository;
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
    userRepository = UserRepository(apiService: mockApiService);
  });

  // Helper for creating a dummy UserModel
  final testUser = UserModel(
    uid: 'test_uid',
    email: 'test@example.com',
    phone: '1234567890',
    activeRole: 'buyer',
    // Add other necessary fields if your UserModel has them
  );
  final testUserMap = {
    'uid': testUser.uid,
    'email': testUser.email,
    'phone': testUser.phone,
    'role': testUser.activeRole,
  };
  final List<Map<String, dynamic>> testUserListMap = [testUserMap];

  group('UserRepository Tests', () {
    group('getUserById', () {
      const userId = 'test_uid';
      test('returns UserModel on success', () async {
        when(mockApiService.get('users?id=eq.$userId&limit=1'))
            .thenAnswer((_) async => {'data': testUserListMap}); // API returns a list

        final result = await userRepository.getUserById(userId);

        expect(result, isA<UserModel>());
        expect(result!.uid, userId);
      });

      test('returns null if user not found (empty list from API)', () async {
        when(mockApiService.get('users?id=eq.$userId&limit=1'))
            .thenAnswer((_) async => {'data': []});
        final result = await userRepository.getUserById(userId);
        expect(result, isNull);
      });

      test('returns null when ApiService returns null', () async {
        when(mockApiService.get('users?id=eq.$userId&limit=1'))
            .thenAnswer((_) async => null);
        final result = await userRepository.getUserById(userId);
        expect(result, isNull);
      });

      test('returns null on ApiService exception', () async {
        when(mockApiService.get('users?id=eq.$userId&limit=1'))
            .thenThrow(Exception('API Error'));
        final result = await userRepository.getUserById(userId);
        expect(result, isNull);
      });
    });

    group('getUserRole', () {
      const userId = 'test_uid';
      const role = 'buyer';
      test('returns user role string on success', () async {
        when(mockApiService.get('users?uid=eq.$userId&select=role&limit=1'))
            .thenAnswer((_) async => {'data': [{'role': role}]});

        final result = await userRepository.getUserRole(userId);

        expect(result, role);
      });

      test('returns null if role not found or data malformed', () async {
        when(mockApiService.get('users?uid=eq.$userId&select=role&limit=1'))
            .thenAnswer((_) async => {'data': [{}]}); // No 'role' key
        final result = await userRepository.getUserRole(userId);
        expect(result, isNull);
      });

       test('returns null if data list is empty', () async {
        when(mockApiService.get('users?uid=eq.$userId&select=role&limit=1'))
            .thenAnswer((_) async => {'data': []});
        final result = await userRepository.getUserRole(userId);
        expect(result, isNull);
      });

      test('returns null when ApiService returns null', () async {
        when(mockApiService.get('users?uid=eq.$userId&select=role&limit=1'))
            .thenAnswer((_) async => null);
        final result = await userRepository.getUserRole(userId);
        expect(result, isNull);
      });
    });

    group('createUser', () {
      test('returns true on successful creation', () async {
        // ApiService.post for 'users' expects specific data structure for user creation
        final createUserData = {
          'uid': testUser.uid,
          'email': testUser.email,
          'phone': testUser.phone,
          'role': testUser.activeRole,
        };
        when(mockApiService.post('users', createUserData))
            .thenAnswer((_) async => {'data': testUserMap}); // Simulate successful response

        final result = await userRepository.createUser(testUser);

        expect(result, isTrue);
        verify(mockApiService.post('users', createUserData)).called(1);
      });

      test('returns false when ApiService returns null', () async {
         final createUserData = {
          'uid': testUser.uid,
          'email': testUser.email,
          'phone': testUser.phone,
          'role': testUser.activeRole,
        };
        when(mockApiService.post('users', createUserData))
            .thenAnswer((_) async => null);
        final result = await userRepository.createUser(testUser);
        expect(result, isFalse);
      });
    });

    group('updateUser', () {
      test('returns true on successful update', () async {
        final updateUserData = {
          'email': testUser.email,
          'phone': testUser.phone,
          'role': testUser.activeRole,
        };
        when(mockApiService.put('users?uid=eq.${testUser.uid}', updateUserData))
            .thenAnswer((_) async => {'data': testUserMap});

        final result = await userRepository.updateUser(testUser);

        expect(result, isTrue);
      });
      test('returns false when ApiService returns null', () async {
         final updateUserData = {
          'email': testUser.email,
          'phone': testUser.phone,
          'role': testUser.activeRole,
        };
        when(mockApiService.put('users?uid=eq.${testUser.uid}', updateUserData))
            .thenAnswer((_) async => null);
        final result = await userRepository.updateUser(testUser);
        expect(result, isFalse);
      });
    });

    group('deleteUser', () {
      const userId = 'test_uid';
      test('returns true on successful deletion', () async {
        when(mockApiService.delete('users?uid=eq.$userId'))
            .thenAnswer((_) async => {'status': 'success'});

        final result = await userRepository.deleteUser(userId);

        expect(result, isTrue);
      });
      test('returns false when ApiService returns null', () async {
        when(mockApiService.delete('users?uid=eq.$userId'))
            .thenAnswer((_) async => null);
        final result = await userRepository.deleteUser(userId);
        expect(result, isFalse);
      });
    });

    group('getAllUsers', () {
      test('returns list of users on success (no filters)', () async {
        when(mockApiService.get('users?select=*'))
            .thenAnswer((_) async => {'data': testUserListMap});

        final result = await userRepository.getAllUsers();

        expect(result.length, 1);
        expect(result.first.uid, testUser.uid);
      });

      test('returns list of users with search query', () async {
        const searchQuery = 'test';
        when(mockApiService.get('users?select=*&or=(email.ilike.%$searchQuery%,phone.ilike.%$searchQuery%)'))
            .thenAnswer((_) async => {'data': testUserListMap});

        final result = await userRepository.getAllUsers(searchQuery: searchQuery);

        expect(result.length, 1);
      });

      test('returns list of users with role filter', () async {
        const roleFilter = 'buyer';
        when(mockApiService.get('users?select=*&role=eq.$roleFilter'))
            .thenAnswer((_) async => {'data': testUserListMap});

        final result = await userRepository.getAllUsers(roleFilter: roleFilter);

        expect(result.length, 1);
      });

      test('returns list of users with search query and role filter', () async {
        const searchQuery = 'test';
        const roleFilter = 'buyer';
        when(mockApiService.get('users?select=*&or=(email.ilike.%$searchQuery%,phone.ilike.%$searchQuery%)&role=eq.$roleFilter'))
            .thenAnswer((_) async => {'data': testUserListMap});

        final result = await userRepository.getAllUsers(searchQuery: searchQuery, roleFilter: roleFilter);

        expect(result.length, 1);
      });

      test('returns empty list when ApiService returns null', () async {
        when(mockApiService.get(any)).thenAnswer((_) async => null);
        final result = await userRepository.getAllUsers();
        expect(result, isEmpty);
      });
    });

    group('emailExists', () {
      const email = 'test@example.com';
      test('returns true if email exists', () async {
        when(mockApiService.get('users?email=eq.$email&select=email&limit=1'))
            .thenAnswer((_) async => {'data': [{'email': email}]});

        final result = await userRepository.emailExists(email);

        expect(result, isTrue);
      });

      test('returns false if email does not exist (empty list)', () async {
        when(mockApiService.get('users?email=eq.$email&select=email&limit=1'))
            .thenAnswer((_) async => {'data': []});
        final result = await userRepository.emailExists(email);
        expect(result, isFalse);
      });

      test('returns false when ApiService returns null', () async {
        when(mockApiService.get('users?email=eq.$email&select=email&limit=1'))
            .thenAnswer((_) async => null);
        final result = await userRepository.emailExists(email);
        expect(result, isFalse);
      });
    });

    group('phoneExists', () {
      const phone = '1234567890';
      test('returns true if phone exists', () async {
        when(mockApiService.get('users?phone=eq.$phone&select=phone&limit=1'))
            .thenAnswer((_) async => {'data': [{'phone': phone}]});

        final result = await userRepository.phoneExists(phone);

        expect(result, isTrue);
      });

      test('returns false if phone does not exist (empty list)', () async {
        when(mockApiService.get('users?phone=eq.$phone&select=phone&limit=1'))
            .thenAnswer((_) async => {'data': []});
        final result = await userRepository.phoneExists(phone);
        expect(result, isFalse);
      });

      test('returns false when ApiService returns null', () async {
        when(mockApiService.get('users?phone=eq.$phone&select=phone&limit=1'))
            .thenAnswer((_) async => null);
        final result = await userRepository.phoneExists(phone);
        expect(result, isFalse);
      });
    });
  });
}
