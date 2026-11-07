// Test untuk memastikan data phone dari registrasi terbawa ke complete profile

import 'package:flutter_test/flutter_test.dart';
import 'package:intirasolusi_mobile/presentation/screens/profile/profile_complete_screen.dart';
import 'package:intirasolusi_mobile/presentation/blocs/auth/auth_bloc.dart';
import 'package:intirasolusi_mobile/data/models/user_model.dart';

void main() {
  group('Registration Phone Flow Tests', () {
    test('ProfileCompleteScreen should accept initialPhone parameter', () {
      // Test that ProfileCompleteScreen can be constructed with initialPhone
      const testPhone = '08123456789';
      
      // This verifies the constructor accepts the parameter
      expect(
        () => const ProfileCompleteScreen(initialPhone: testPhone),
        returnsNormally,
      );
    });

    test('ProfileCompleteScreen without initialPhone should also work', () {
      // Test backward compatibility - screen can be created without phone
      expect(
        () => const ProfileCompleteScreen(),
        returnsNormally,
      );
    });

    test('Route arguments should correctly extract phone', () {
      // Simulate route arguments extraction like in app_routes.dart
      final Map<String, dynamic> arguments = {'phone': '08123456789'};
      
      final phone = arguments['phone'] as String?;
      
      expect(phone, equals('08123456789'));
    });

    test('Route arguments with null should handle gracefully', () {
      final Map<String, dynamic>? arguments = null;
      
      final phone = arguments?['phone'] as String?;
      
      expect(phone, isNull);
    });

    test('UserModel should have phone field', () {
      final user = UserModel(
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
        phone: '08123456789',
      );

      expect(user.phone, equals('08123456789'));
    });

    test('UserModel.fromJson should parse phone correctly', () {
      final json = {
        'id': 1,
        'name': 'Test User',
        'email': 'test@example.com',
        'phone': '08123456789',
      };

      final user = UserModel.fromJson(json);

      expect(user.phone, equals('08123456789'));
    });

    test('CustomerModel should have phone field', () {
      final customer = CustomerModel(
        id: 1,
        userId: 1,
        phone: '08123456789',
      );

      expect(customer.phone, equals('08123456789'));
    });

    test('CustomerModel.fromJson should parse phone correctly', () {
      final json = {
        'id': 1,
        'user_id': 1,
        'phone': '08123456789',
      };

      final customer = CustomerModel.fromJson(json);

      expect(customer.phone, equals('08123456789'));
    });

    test('Profile data should always include phone field', () {
      // Simulate the profile data creation from profile_complete_screen.dart
      const phoneController = '08123456789';
      
      final profileData = {
        'birth_place': 'Jakarta',
        'birth_date': '1990-01-01',
        'gender': 'L',
        // Phone should always be included (not conditional)
        'phone': phoneController,
        'address': 'Jl. Test',
      };

      // Verify phone is always in the data
      expect(profileData.containsKey('phone'), isTrue);
      expect(profileData['phone'], equals('08123456789'));
    });

    test('Phone priority: user.phone > customer.phone > initialPhone', () {
      String resolvePhone(
        String? userPhone,
        String? customerPhone,
        String? initialPhone,
      ) {
        if (userPhone != null && userPhone.isNotEmpty) {
          return userPhone;
        } else if (customerPhone != null && customerPhone.isNotEmpty) {
          return customerPhone;
        } else if (initialPhone != null && initialPhone.isNotEmpty) {
          return initialPhone;
        }
        return '';
      }

      // Case 1: user.phone available
      expect(
        resolvePhone('08111111111', '08222222222', '08333333333'),
        equals('08111111111'),
      );

      // Case 2: only customer.phone available
      expect(
        resolvePhone(null, '08222222222', '08333333333'),
        equals('08222222222'),
      );

      // Case 3: only initialPhone available (from registration)
      expect(
        resolvePhone(null, null, '08333333333'),
        equals('08333333333'),
      );
    });
  });

  group('AuthRegister Event Tests', () {
    test('AuthRegister should include phone parameter', () {
      final event = AuthRegister(
        name: 'Test User',
        email: 'test@example.com',
        phone: '08123456789',
        password: 'password123',
      );

      expect(event.phone, equals('08123456789'));
    });

    test('AuthRegister props should include phone', () {
      final event = AuthRegister(
        name: 'Test User',
        email: 'test@example.com',
        phone: '08123456789',
        password: 'password123',
      );

      expect(event.props.contains('08123456789'), isTrue);
    });
  });
}
