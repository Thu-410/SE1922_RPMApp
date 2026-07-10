import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rental_management_app/main.dart';

void main() {
  testWidgets('shows the rental management app', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    await tester.pumpWidget(const RentalManagementApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('Quản lý trọ'), findsOneWidget);
  });
}
