// lib/core/utils/throttler.dart

import 'dart:async';

/// A utility class that limits the frequency of function execution
class Throttler {
  final Duration _duration;
  Timer? _timer;
  DateTime? _lastRun;
  bool _isPending = false;
  Function? _pendingCallback;
  
  /// Creates a [Throttler] with the specified throttle duration
  Throttler(this._duration);
  
  /// Runs a function, throttling executions based on the set duration
  void run(Function callback) {
    final now = DateTime.now();
    
    // If this is the first run or if the throttle duration has passed
    if (_lastRun == null || now.difference(_lastRun!) > _duration) {
      _lastRun = now;
      callback();
    } else {
      // Otherwise, schedule to run after the throttle duration
      _isPending = true;
      _pendingCallback = callback;
      
      if (_timer?.isActive != true) {
        _timer = Timer(_getRemainingTime(), _processPending);
      }
    }
  }
  
  /// Calculates the remaining time until the next allowed execution
  Duration _getRemainingTime() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRun!);
    return _duration - elapsed;
  }
  
  /// Processes any pending executions
  void _processPending() {
    if (_isPending && _pendingCallback != null) {
      _lastRun = DateTime.now();
      _isPending = false;
      _pendingCallback!();
      _pendingCallback = null;
    }
  }
  
  /// Executes any pending function immediately
  void flush() {
    if (_isPending) {
      _timer?.cancel();
      _processPending();
    }
  }
  
  /// Cancels any pending executions
  void cancel() {
    _timer?.cancel();
    _isPending = false;
    _pendingCallback = null;
  }
  
  /// Releases resources used by this [Throttler]
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _pendingCallback = null;
  }
}