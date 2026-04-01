import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

const Duration defaultWorkDuration = Duration(minutes: 25);
const Duration defaultBreakDuration = Duration(minutes: 5);
const int defaultLoopCount = 4;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError {
    // Allow the app to run on platforms not yet configured in FlutterFire.
  }
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

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

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

  Future<void> _showAuthDialog() async {
    if (!_firebaseReady) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firebase Auth is not configured on this platform yet.'),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => const AuthDialog(),
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: _firebaseReady
            ? StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  if (user == null) {
                    return const SizedBox.shrink();
                  }

                  return IconButton(
                    tooltip: 'Statistics',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const StatisticsPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bar_chart_rounded),
                  );
                },
              )
            : null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: _firebaseReady
                  ? StreamBuilder<User?>(
                      stream: FirebaseAuth.instance.authStateChanges(),
                      builder: (context, snapshot) {
                        final user = snapshot.data;
                        return TextButton(
                          onPressed: user == null ? _showAuthDialog : _signOut,
                          child: Text(user == null ? 'Log in' : 'Log out'),
                        );
                      },
                    )
                  : TextButton(
                      onPressed: _showAuthDialog,
                      child: const Text('Log in'),
                    ),
            ),
          ),
        ],
      ),
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
                  const SizedBox(height: 16),
                  _firebaseReady
                      ? StreamBuilder<User?>(
                          stream: FirebaseAuth.instance.authStateChanges(),
                          builder: (context, snapshot) {
                            final user = snapshot.data;
                            final label = user == null
                                ? 'Sign in to save your session history.'
                                : 'Signed in as ${_displayUsername(user)}.';
                            return Text(
                              label,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: const Color(0xFF5C514B),
                                  ),
                            );
                          },
                        )
                      : Text(
                          'Firebase Auth is not configured on this platform yet.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

class AuthDialog extends StatefulWidget {
  const AuthDialog({super.key});

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isCreatingAccount = false;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorText = 'Enter both a username and password.';
      });
      return;
    }

    final normalizedUsername = _normalizeUsername(username);
    if (normalizedUsername == null) {
      setState(() {
        _errorText =
            'Use 3-20 characters: letters, numbers, underscores, or periods.';
      });
      return;
    }

    final email = _usernameToEmail(normalizedUsername);

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      if (_isCreatingAccount) {
        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        await credential.user?.updateDisplayName(normalizedUsername);
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (error) {
      setState(() {
        _errorText = error.message ?? 'Authentication failed.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isCreatingAccount ? 'Create account' : 'Log in'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorText!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          TextButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    setState(() {
                      _isCreatingAccount = !_isCreatingAccount;
                      _errorText = null;
                    });
                  },
            child: Text(
              _isCreatingAccount
                  ? 'Already have an account? Log in'
                  : 'Need an account? Create one',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: Text(_isCreatingAccount ? 'Create account' : 'Log in'),
        ),
      ],
    );
  }
}

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: Colors.transparent,
      ),
      body: user == null
          ? const Center(
              child: Text('Log in to view your saved Pomodoro history.'),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('sessions')
                  .where('userId', isEqualTo: user.uid)
                  .orderBy('completedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Unable to load your statistics right now.'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                final totalSessions = docs.length;
                final totalFocusSeconds = docs.fold<int>(
                  0,
                  (sum, doc) => sum + _sessionFocusSeconds(doc.data()),
                );

                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Sessions',
                            value: totalSessions.toString(),
                            accentColor: const Color(0xFFB54A3A),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            title: 'Focus Time',
                            value: _formatElapsedTime(totalFocusSeconds),
                            accentColor: const Color(0xFF2F4858),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Recent sessions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2C2522),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (docs.isEmpty)
                      const _EmptyHistoryCard()
                    else
                      ...docs.map((doc) => _SessionHistoryCard(data: doc.data())),
                  ],
                );
              },
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.accentColor,
  });

  final String title;
  final String value;
  final Color accentColor;

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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF5C514B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard();

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
      child: Text(
        'No saved sessions yet. Finish a Pomodoro while logged in to see it here.',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: const Color(0xFF5C514B),
        ),
      ),
    );
  }
}

class _SessionHistoryCard extends StatelessWidget {
  const _SessionHistoryCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final completedAt = data['completedAt'];
    final timestamp = completedAt is Timestamp ? completedAt.toDate() : null;
    final focusMinutes = (data['focusMinutes'] as num?)?.toInt() ?? 0;
    final breakMinutes = (data['breakMinutes'] as num?)?.toInt() ?? 0;
    final loopCount = (data['loopCount'] as num?)?.toInt() ?? 0;
    final totalFocusSeconds = _sessionFocusSeconds(data);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            '$focusMinutes/$breakMinutes min x $loopCount loops',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2C2522),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Actual focus time: ${_formatElapsedTime(totalFocusSeconds)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF5C514B),
            ),
          ),
          if (timestamp != null) ...[
            const SizedBox(height: 6),
            Text(
              _formatCompletedAt(timestamp),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF5C514B),
              ),
            ),
          ],
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
  Duration _actualFocusDuration = Duration.zero;
  late int _currentLoop;
  bool _isPaused = false;
  bool _isSavingSession = false;

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

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  void _startNewSession() {
    _currentLoop = 1;
    _actualFocusDuration = Duration.zero;
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
        if (_phase == TimerPhase.work) {
          _actualFocusDuration += const Duration(seconds: 1);
        }
      });
      return;
    }

    if (_phase == TimerPhase.work) {
      setState(() {
        _actualFocusDuration += const Duration(seconds: 1);
      });
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

  Future<void> _finishSession() async {
    _timer?.cancel();
    setState(() {
      _phase = TimerPhase.completed;
      _remaining = Duration.zero;
      _isPaused = false;
    });
    await _saveCompletedSession();
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

  Future<void> _saveCompletedSession() async {
    if (_isSavingSession || !_firebaseReady) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in to save session history to Firestore.'),
        ),
      );
      return;
    }

    _isSavingSession = true;
    try {
      await FirebaseFirestore.instance.collection('sessions').add({
        'completedAt': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'userEmail': user.email,
        'username': _displayUsername(user),
        'focusMinutes': widget.workDuration.inMinutes,
        'breakMinutes': widget.breakDuration.inMinutes,
        'loopCount': widget.loopCount,
        'completedLoops': widget.loopCount,
        'actualFocusSeconds': _actualFocusDuration.inSeconds,
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session finished, but saving to Firestore failed.'),
        ),
      );
    } finally {
      _isSavingSession = false;
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

String? _normalizeUsername(String input) {
  final normalized = input.trim().toLowerCase();
  final isValid = RegExp(r'^[a-z0-9._]{3,20}$').hasMatch(normalized);
  return isValid ? normalized : null;
}

String _usernameToEmail(String username) => '$username@pomoductive.app';

String _displayUsername(User user) {
  final displayName = user.displayName;
  if (displayName != null && displayName.isNotEmpty) {
    return displayName;
  }

  final email = user.email;
  if (email == null || !email.contains('@')) {
    return 'your account';
  }

  return email.split('@').first;
}

String _formatCompletedAt(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final year = value.year.toString();
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '$month/$day/$year at $hour:$minute $period';
}

int _sessionFocusSeconds(Map<String, dynamic> data) {
  final actualFocusSeconds = (data['actualFocusSeconds'] as num?)?.toInt();
  if (actualFocusSeconds != null) {
    return actualFocusSeconds;
  }

  final totalFocusMinutes = (data['totalFocusMinutes'] as num?)?.toInt() ?? 0;
  return totalFocusMinutes * 60;
}

String _formatElapsedTime(int totalSeconds) {
  final duration = Duration(seconds: totalSeconds);
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}
