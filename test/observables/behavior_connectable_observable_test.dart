import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  group('BehaviorConnectableObservable', () {
    test('should begin emitting items after connection', () {
      final BehaviorConnectableObservable<int> observable =
          BehaviorConnectableObservable<int>(
              Stream<int>.fromIterable(<int>[1, 2, 3]));

      observable.connect();

      expect(observable, emitsInOrder(<int>[1, 2, 3]));
    });

    test('stops emitting after the connection is cancelled', () async {
      final ConnectableObservable<int> observable =
          Observable<int>.fromIterable(<int>[1, 2, 3]).publishBehavior();

      observable.connect()..cancel();

      expect(observable, neverEmits(anything));
    });

    test('stops emitting after the last subscriber unsubscribes', () async {
      final Observable<int> observable =
          Observable<int>.fromIterable(<int>[1, 2, 3]).shareBehavior();

      observable.listen(null)..cancel();

      expect(observable, neverEmits(anything));
    });

    test('single subscription error', () async {
      final ConnectableObservable<int> observable =
          BehaviorConnectableObservable<int>(
              Stream<int>.fromIterable(<int>[1, 2, 3]));

      observable.connect();
      observable.listen(null)..cancel();

      expect(observable, emitsInOrder(<int>[1, 2, 3]));
    });

    test('keeps emitting with an active subscription', () async {
      final Observable<int> observable =
          Observable<int>.fromIterable(<int>[1, 2, 3]).shareBehavior();

      observable.listen(null);
      observable.listen(null)..cancel();

      expect(observable, emitsInOrder(<int>[1, 2, 3]));
    });

    test('multicasts a single-subscription stream', () async {
      final Observable<int> observable = new BehaviorConnectableObservable<int>(
        Stream<int>.fromIterable(<int>[1, 2, 3]),
      ).autoConnect();

      expect(observable, emitsInOrder(<int>[1, 2, 3]));
      expect(observable, emitsInOrder(<int>[1, 2, 3]));
      expect(observable, emitsInOrder(<int>[1, 2, 3]));
    });

    test('replays the latest item', () async {
      final Observable<int> observable = new BehaviorConnectableObservable<int>(
        Stream<int>.fromIterable(<int>[1, 2, 3]),
      ).autoConnect();

      expect(observable, emitsInOrder(<int>[1, 2, 3]));
      expect(observable, emitsInOrder(<int>[1, 2, 3]));
      expect(observable, emitsInOrder(<int>[1, 2, 3]));

      await Future<Null>.delayed(Duration(milliseconds: 200));

      expect(observable, emits(3));
    });

    test('can multicast observables', () async {
      final BehaviorObservable<int> observable =
          Observable<int>.fromIterable(<int>[1, 2, 3]).shareBehavior();

      expect(observable, emitsInOrder(<int>[1, 2, 3]));
      expect(observable, emitsInOrder(<int>[1, 2, 3]));
      expect(observable, emitsInOrder(<int>[1, 2, 3]));
    });

    test('transform Observables with initial value', () async {
      final BehaviorObservable<int> observable =
          Observable<int>.fromIterable(<int>[1, 2, 3])
              .shareBehavior(seedValue: 0);

      expect(observable.value, 0);
      expect(observable, emitsInOrder(<int>[0, 1, 2, 3]));
    });

    test('provides access to the latest value', () async {
      final List<int> items = <int>[1, 2, 3];
      int count = 0;
      final BehaviorObservable<int> observable =
          Observable<int>.fromIterable(<int>[1, 2, 3]).shareBehavior();

      observable.listen(expectAsync1((int data) {
        expect(data, items[count]);
        count++;
        if (count == items.length) {
          expect(observable.value, 3);
        }
      }, count: items.length));
    });
  });
}