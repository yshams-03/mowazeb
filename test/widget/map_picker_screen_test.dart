import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:latlong2/latlong.dart';
import 'package:ummah_pulse/features/locations/models/map_picker_result.dart';
import 'package:ummah_pulse/features/locations/screens/map_picker_screen.dart';
import 'package:ummah_pulse/features/locations/services/reverse_geocode_service.dart';

class _StubGeocode extends ReverseGeocodeService {
  _StubGeocode(this._handler);

  final Future<MapPickerResult?> Function(double lat, double lng) _handler;

  @override
  Future<MapPickerResult?> reverseGeocode(double lat, double lng) =>
      _handler(lat, lng);
}

class _FakeGeolocator extends GeolocatorPlatform {
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.denied;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.denied;
}

Future<void> _pumpUntilSettled(WidgetTester tester, {int rounds = 8}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('MapPickerScreen', () {
    const cairo = LatLng(30.0444, 31.2357);

    setUp(() {
      GeolocatorPlatform.instance = _FakeGeolocator();
    });

    Widget wrap(Widget child) {
      return MaterialApp(home: child);
    }

    testWidgets('loads with center pin and placeholder', (tester) async {
      await tester.pumpWidget(
        wrap(
          MapPickerScreen(
            initialLatLng: cairo,
            reverseGeocodeService: _StubGeocode((_, __) async => null),
          ),
        ),
      );
      await _pumpUntilSettled(tester);

      expect(find.byIcon(Icons.location_pin), findsOneWidget);
      expect(find.text('Pick a location'), findsOneWidget);
      expect(find.text('Move the map to select a location'), findsWidgets);
      expect(find.text('Confirm Location'), findsOneWidget);

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Confirm Location'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('shows address after geocode completes', (tester) async {
      await tester.pumpWidget(
        wrap(
          MapPickerScreen(
            initialLatLng: cairo,
            reverseGeocodeService: _StubGeocode(
              (_, __) async => const MapPickerResult(
                shortName: 'Cairo Tower',
                address: 'Zamalek, Cairo, Egypt',
                latitude: 30.0444,
                longitude: 31.2357,
              ),
            ),
          ),
        ),
      );
      await _pumpUntilSettled(tester);

      expect(find.text('Cairo Tower'), findsOneWidget);
      expect(find.textContaining('Zamalek'), findsOneWidget);

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Confirm Location'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('confirm pops with MapPickerResult', (tester) async {
      MapPickerResult? popped;

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  popped = await Navigator.of(context).push<MapPickerResult>(
                    MaterialPageRoute(
                      builder: (_) => MapPickerScreen(
                        initialLatLng: cairo,
                        reverseGeocodeService: _StubGeocode(
                          (_, __) async => const MapPickerResult(
                            shortName: 'Home',
                            address: 'Cairo',
                            latitude: 30.04,
                            longitude: 31.23,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await _pumpUntilSettled(tester);

      await tester.tap(find.text('Confirm Location'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(popped, isNotNull);
      expect(popped!.shortName, 'Home');
    });

    testWidgets('back button pops null', (tester) async {
      dynamic popped = 'unset';

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  popped = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MapPickerScreen(
                        initialLatLng: cairo,
                        reverseGeocodeService: _StubGeocode((_, __) async => null),
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byType(BackButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(popped, isNull);
    });

    testWidgets('my location FAB is present', (tester) async {
      await tester.pumpWidget(
        wrap(
          MapPickerScreen(
            initialLatLng: cairo,
            reverseGeocodeService: _StubGeocode((_, __) async => null),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.my_location), findsOneWidget);
    });

    testWidgets('geocode error shows snackbar', (tester) async {
      await tester.pumpWidget(
        wrap(
          MapPickerScreen(
            initialLatLng: cairo,
            reverseGeocodeService: _StubGeocode((_, __) async => null),
          ),
        ),
      );
      await _pumpUntilSettled(tester);

      expect(
        find.textContaining("Couldn't get address"),
        findsOneWidget,
      );
    });
  });
}
