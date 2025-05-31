import 'package:flutter_test/flutter_test.dart';
import 'package:klasifikasi_uang/main.dart';
import 'package:camera/camera.dart';

void main() {
  testWidgets('Camera is passed to MyApp widget', (WidgetTester tester) async {
    // Mocking the camera (you can use any camera here)
    final cameras = await availableCameras();
    final firstCamera = cameras.first; // Menggunakan kamera pertama sebagai parameter

    // Membuat widget untuk diuji
    await tester.pumpWidget(MyApp(camera: firstCamera));

    // Cek apakah widget berhasil dimuat (contoh tes dasar)
    expect(find.byType(MyHomePage), findsOneWidget);
  });
}
