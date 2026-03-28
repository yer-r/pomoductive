import 'dart:async';

import 'package:flutter/material.dart';

const Duration defaultWorkDuration = Duration(minutes: 25);
const Duration defaultBreakDuration = Duration(minutes: 5);
const int defaultLoopCount = 4;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomoductive',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB54A3A)),
        scaffoldBackgroundColor: const Color(0xFFF9F1E7),
        useMaterial3: true,
      ),
      home: const MainMenuPage(),
    );
  }
}

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  double _workMinutes = defaultWorkDuration.inMinutes.toDouble();
  double _breakMinutes = defaultBreakDuration.inMinutes.toDouble();
  double _loopCount = defaultLoopCount.toDouble();

  void _startSession() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PomodoroPage(
          workDuration: Duration(minutes: _workMinutes.round()),
          breakDuration: Duration(minutes: _breakMinutes.round()),
          loopCount: _loopCount.round(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Pomoductive',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2C2522),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Set your focus, break, and loop count before starting a session.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF5C514B),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SelectionCard(
                    title: 'Focus length',
                    valueLabel: '${_workMinutes.round()} min',
                    activeColor: const Color(0xFFB54A3A),
                    value: _workMinutes,
                    min: 1,
                    max: 60,
                    onChanged: (value) {
                      setState(() {
                        _workMinutes = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _SelectionCard(
                    title: 'Break length',
                    valueLabel: '${_breakMinutes.round()} min',
                    activeColor: const Color(0xFF4B7F52),
                    value: _breakMinutes,
                    min: 1,
                    max: 30,
                    onChanged: (value) {
                      setState(() {
                        _breakMinutes = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _SelectionCard(
                    title: 'Number of loops',
                    valueLabel: _loopCount.round().toString(),
                    activeColor: const Color(0xFF2F4858),
                    value: _loopCount,
                    min: 1,
                    max: 12,
                    onChanged: (value) {
                      setState(() {
                        _loopCount = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _startSession,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2F4858),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: const Text('Start Pomodoro'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.title,
    required this.valueLabel,
    required this.activeColor,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String title;
  final String valueLabel;
  final Color activeColor;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2C2522),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            valueLabel,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: activeColor,
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: activeColor,
              thumbColor: activeColor,
              overlayColor: activeColor.withValues(alpha: 0.14),
              inactiveTrackColor: activeColor.withValues(alpha: 0.18),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).round(),
              label: valueLabel,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

enum TimerPhase { work, breakTime, completed }

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({
    super.key,
    required this.workDuration,
    required this.breakDuration,
    required this.loopCount,
  });

  final Duration workDuration;
  final Duration breakDuration;
  final int loopCount;

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  Timer? _timer;
  late TimerPhase _phase;
  late Duration _remaining;
  late int _currentLoop;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _startNewSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startNewSession() {
    _currentLoop = 1;
    _startWorkTimer();
  }

  void _startWorkTimer() {
    _startPhase(TimerPhase.work, widget.workDuration);
  }

  void _startBreakTimer() {
    _startPhase(TimerPhase.breakTime, widget.breakDuration);
  }

  void _startPhase(TimerPhase phase, Duration duration) {
    _timer?.cancel();
    setState(() {
      _phase = phase;
      _remaining = duration;
      _isPaused = false;
    });
    _resumeTimer();
  }

  void _resumeTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_remaining > const Duration(seconds: 1)) {
      setState(() {
        _remaining -= const Duration(seconds: 1);
      });
      return;
    }

    if (_phase == TimerPhase.work) {
      _startBreakTimer();
      return;
    }

    _advanceAfterBreak();
  }

  void _advanceAfterBreak() {
    if (_currentLoop < widget.loopCount) {
      _currentLoop += 1;
      _startWorkTimer();
      return;
    }

    _finishSession();
  }

  void _finishSession() {
    _timer?.cancel();
    setState(() {
      _phase = TimerPhase.completed;
      _remaining = Duration.zero;
      _isPaused = false;
    });
  }

  void _skipTimer() {
    if (_phase == TimerPhase.work) {
      _startBreakTimer();
      return;
    }

    if (_phase == TimerPhase.breakTime) {
      _advanceAfterBreak();
    }
  }

  void _resetCycle() {
    _startNewSession();
  }

  void _togglePause() {
    if (_phase == TimerPhase.completed) {
      return;
    }

    if (_isPaused) {
      setState(() {
        _isPaused = false;
      });
      _resumeTimer();
      return;
    }

    _timer?.cancel();
    setState(() {
      _isPaused = true;
    });
  }

  String get _phaseTitle {
    switch (_phase) {
      case TimerPhase.work:
        return 'Focus time';
      case TimerPhase.breakTime:
        return 'Break time';
      case TimerPhase.completed:
        return 'All loops complete';
    }
  }

  String get _phaseMessage {
    switch (_phase) {
      case TimerPhase.work:
        return 'Stay on one task until this session ends.';
      case TimerPhase.breakTime:
        return 'Step away for a short reset.';
      case TimerPhase.completed:
        return 'Nice work. Your full Pomodoro set is done.';
    }
  }

  Color get _accentColor {
    switch (_phase) {
      case TimerPhase.work:
        return const Color(0xFFB54A3A);
      case TimerPhase.breakTime:
        return const Color(0xFF4B7F52);
      case TimerPhase.completed:
        return const Color(0xFF2F4858);
    }
  }

  String get _pauseButtonLabel => _isPaused ? 'Resume timer' : 'Pause timer';

  String _formatDuration(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = _phase == TimerPhase.completed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro session'),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: isCompleted
          ? null
          : FloatingActionButton.small(
              onPressed: _skipTimer,
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              child: const Icon(Icons.skip_next_rounded),
            ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Loop $_currentLoop of ${widget.loopCount}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF5C514B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _phaseTitle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _accentColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 28,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 28,
                          offset: Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          _formatDuration(_remaining),
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF2C2522),
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _phaseMessage,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF5C514B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!isCompleted)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _togglePause,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _accentColor,
                          side: BorderSide(color: _accentColor),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(_pauseButtonLabel),
                      ),
                    ),
                  if (!isCompleted) const SizedBox(height: 16),
                  if (isCompleted)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _resetCycle,
                        style: FilledButton.styleFrom(
                          backgroundColor: _accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Start again'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
