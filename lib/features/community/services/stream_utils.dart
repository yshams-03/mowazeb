import 'dart:async';

/// Emits whenever any input stream emits, with the latest value from each.
Stream<List<T>> combineLatestList<T>(List<Stream<T>> streams) {
  if (streams.isEmpty) {
    return Stream.value(const []);
  }

  if (streams.length == 1) {
    return streams.first.map((value) => [value]);
  }

  late StreamController<List<T>> controller;
  final latest = List<T?>.filled(streams.length, null);
  final subscriptions = <StreamSubscription<T>>[];
  var initialized = 0;

  controller = StreamController<List<T>>(
    onListen: () {
      for (var i = 0; i < streams.length; i++) {
        final index = i;
        subscriptions.add(
          streams[i].listen(
            (value) {
              latest[index] = value;
              initialized = latest.where((item) => item != null).length;
              if (initialized == streams.length) {
                controller.add(latest.cast<T>().toList());
              }
            },
            onError: controller.addError,
          ),
        );
      }
    },
    onCancel: () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    },
  );

  return controller.stream;
}
