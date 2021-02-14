import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_timer/ticker.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

part 'timer_event.dart';
part 'timer_state.dart';

class TimerBloc extends Bloc<TimerEvent, TimerState> {
  final Ticker _ticker;
  static const int _duration = 60;

  StreamSubscription<int> _tickerSubscription;

  TimerBloc({@required Ticker ticker})
      : assert(ticker != null),
        _ticker = ticker,
        super(TimerInitial(_duration));

  @override
  void onTransition(Transition<TimerEvent, TimerState> transition) {
    print(transition);
    super.onTransition(transition);
  }

  @override
  Stream<TimerState> mapEventToState(
    TimerEvent event,
  ) async* {
    switch (event.runtimeType) {
      case TimerStarted:
        yield* _mapTimerStartedToState(event);
        break;
      case TimerPaused:
        yield* _mapTimerPausedToState(event);
        break;
      case TimerResumed:
        yield* _mapTimerResumedToState(event);
        break;
      case TimerReset:
        yield* _mapTimerResetToState(event);
        break;
      case TimerTicked:
        yield* _mapTimerTickedToState(event);
        break;
      default:
    }
  }

  @override
  Future<void> close() {
    _tickerSubscription?.cancel();
    return super.close();
  }

  Stream<TimerState> _mapTimerStartedToState(TimerStarted start) async* {
    yield TimerRunInProgress(start.duration);

    _tickerSubscription?.cancel();
    _tickerSubscription = _ticker
        .tick(ticks: start.duration)
        .listen((duration) => add(TimerTicked(duration: duration)));
  }

  Stream<TimerState> _mapTimerPausedToState(TimerPaused pause) async* {
    if (state is TimerRunInProgress) {
      _tickerSubscription?.pause();
      yield TimerRunPause(state.duration);
    }
  }

  Stream<TimerState> _mapTimerResumedToState(TimerResumed resumed) async* {
    if (state is TimerRunPause) {
      _tickerSubscription?.resume();
      yield TimerRunInProgress(state.duration);
    }
  }

  Stream<TimerState> _mapTimerResetToState(TimerReset reset) async* {
    _tickerSubscription?.cancel();
    yield TimerInitial(_duration);
  }

  Stream<TimerState> _mapTimerTickedToState(TimerTicked ticked) async* {
    yield ticked.duration > 0
        ? TimerRunInProgress(ticked.duration)
        : TimerRunComplete();
  }
}
