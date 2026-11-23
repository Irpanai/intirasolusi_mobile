import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intirasolusi_app/config/routes/app_routes.dart';
import 'package:intirasolusi_app/presentation/screens/notification/notification_screen.dart';
import 'package:intirasolusi_app/data/repositories/dashboard_repository.dart';

void main() {
  group('NotificationScreen Tests', () {
    testWidgets('NotificationScreen renders title and header properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NotificationScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Notifikasi'), findsOneWidget);
      expect(find.text('Kembali'), findsOneWidget);
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Transaksi'), findsOneWidget);
      expect(find.text('Pengajuan'), findsOneWidget);
      expect(find.text('Akun & Info'), findsOneWidget);
    });

    testWidgets('NotificationScreen renders alerts from DashboardData', (WidgetTester tester) async {
      final mockData = DashboardData(
        customer: CustomerInfo(
          name: 'Budi Santoso',
          code: 'CUST-001',
          isProfileComplete: false,
        ),
        stats: DashboardStats(
          activeTransactions: 1,
          pendingRequests: 0,
          totalLoan: 5000000,
          overdueTransactions: 2,
        ),
        recentRequests: [],
        activeTransactions: [],
        alerts: [
          DashboardAlert(
            type: 'warning',
            title: 'Info Pemeliharaan Sistem',
            message: 'Sistem akan maintenance malam ini.',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationScreen(initialData: mockData),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Overdue transactions alert
      expect(find.text('Peringatan Jatuh Tempo'), findsOneWidget);
      // Profile incomplete alert
      expect(find.text('Profil Belum Lengkap'), findsOneWidget);
      // Custom backend alert
      expect(find.text('Info Pemeliharaan Sistem'), findsOneWidget);
    });

    test('AppRoutes.notifications constant should be /notifications', () {
      expect(AppRoutes.notifications, equals('/notifications'));
    });
  });
}
