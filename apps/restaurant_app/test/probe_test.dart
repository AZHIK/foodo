import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_pos/utils/export_helper.dart';
import 'package:restaurant_pos/widgets/data_page/data_column_spec.dart';

class R { const R(this.n); final String n; }

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('probe', (tester) async {
    final result = await ExportHelper.exportToExcel(
      columns: [DataColumnSpec<R>(label: 'N', field: 'n', value: (r) => r.n)],
      rows: const [R('x')],
      title: 'Probe',
    );
    // ignore: avoid_print
    print('OK=${result.ok} PATH=${result.path}');
    if (result.path != null) File(result.path!).deleteSync();
  });
}
