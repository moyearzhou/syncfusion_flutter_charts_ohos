import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_charts_ohos/syncfusion_flutter_charts_ohos.dart';
import 'package:flutter/services.dart';


class _SalesData {
  String year;
  int sales;

  _SalesData(this.year, this.sales);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('syncfusion_flutter_charts_ohos');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('LineSeries initializes correctly', () async {
    List<_SalesData> data = [
      _SalesData('Jan', 35),
      _SalesData('Feb', 28),
    ];

    LineSeries<_SalesData, String> lineSeries = LineSeries<
        _SalesData, String>(
      dataSource: data,
      xValueMapper: (_SalesData sales, _) => sales.year,
      yValueMapper: (_SalesData sales, _) => sales.sales,
      name: 'Sales',
    );

    expect(lineSeries.dataSource, equals(data));
    expect(lineSeries.name, equals('Sales'));
  });
}
