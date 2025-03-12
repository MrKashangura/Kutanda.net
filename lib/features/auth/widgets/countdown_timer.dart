import 'dart:async';

import 'package:flutter/material.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime endTime;
  final Function? onTimerEnd;
  final TextStyle? textStyle;
  
  const CountdownTimer({
    super.key,
    required this.endTime,
    this.onTimerEnd,
    this.textStyle,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  late Duration _timeRemaining;
  bool _isEnded = false;

  @override
  void initState() {
    super.initState();
    _calculateTimeRemaining();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _calculateTimeRemaining() {
    final now = DateTime.now();
    if (now.isAfter(widget.endTime)) {
      _timeRemaining = Duration.zero;
      _isEnded = true;
      widget.onTimerEnd?.call();
    } else {
      _timeRemaining = widget.endTime.difference(now);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _calculateTimeRemaining();
          if (_isEnded) {
            _timer.cancel();
          }
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) {
      return 'Auction ended';
    }
    
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String displayTime = _formatDuration(_timeRemaining);
    
    Color textColor;
    if (_isEnded) {
      textColor = Colors.red;
    } else if (_timeRemaining.inHours < 1) {
      textColor = Colors.orange;
    } else if (_timeRemaining.inDays < 1) {
      textColor = Colors.blue;
    } else {
      textColor = Colors.green;
    }
    
    return Text(
      displayTime,
      style: widget.textStyle?.copyWith(
        color: textColor,
      ) ?? TextStyle(
        color: textColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}