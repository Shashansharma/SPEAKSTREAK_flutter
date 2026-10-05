import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const SpeakStreakApp());
}

class SpeakStreakApp extends StatelessWidget {
  const SpeakStreakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SpeakStreak',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
        ),
      ),
      home: const SpeakStreakHome(),
    );
  }
}

class PracticeSession {
  final DateTime date;
  final String language;
  final int duration;
  final int confidence;

  PracticeSession({
    required this.date,
    required this.language,
    required this.duration,
    required this.confidence,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'language': language,
      'duration': duration,
      'confidence': confidence,
    };
  }

  factory PracticeSession.fromMap(Map<String, dynamic> map) {
    return PracticeSession(
      date: DateTime.parse(map['date']),
      language: map['language'],
      duration: map['duration'],
      confidence: map['confidence'],
    );
  }
}

class SpeakStreakHome extends StatefulWidget {
  const SpeakStreakHome({super.key});

  @override
  State<SpeakStreakHome> createState() => _SpeakStreakHomeState();
}

class _SpeakStreakHomeState extends State<SpeakStreakHome> {
  int _currentIndex = 0;

  List<PracticeSession> _sessions = [];

  int _streak = 0;

  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final prefs = await SharedPreferences.getInstance();

    final savedSessions = prefs.getStringList('practice_sessions');

    if (savedSessions != null) {
      final loaded = savedSessions.map((item) {
        return PracticeSession.fromMap(
          jsonDecode(item),
        );
      }).toList();

      loaded.sort(
        (a, b) => b.date.compareTo(a.date),
      );

      setState(() {
        _sessions = loaded;
        _streak = _calculateStreak();
      });
    }
  }

  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();

    final data = _sessions.map((session) {
      return jsonEncode(session.toMap());
    }).toList();

    await prefs.setStringList(
      'practice_sessions',
      data,
    );
  }

  int _calculateStreak() {
    if (_sessions.isEmpty) {
      return 0;
    }

    final uniqueDates = _sessions
        .map(
          (session) => DateTime(
            session.date.year,
            session.date.month,
            session.date.day,
          ),
        )
        .toSet()
        .toList();

    uniqueDates.sort(
      (a, b) => b.compareTo(a),
    );

    final today = DateTime.now();

    final todayOnly = DateTime(
      today.year,
      today.month,
      today.day,
    );

    final latestDate = uniqueDates.first;

    final daysFromLatest =
        todayOnly.difference(latestDate).inDays;

    if (daysFromLatest > 1) {
      return 0;
    }

    int streak = 1;

    for (int i = 0; i < uniqueDates.length - 1; i++) {
      final difference =
          uniqueDates[i].difference(uniqueDates[i + 1]).inDays;

      if (difference == 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  Future<void> _addSession(
    PracticeSession session,
  ) async {
    final oldStreak = _streak;

    setState(() {
      _sessions.add(session);

      _sessions.sort(
        (a, b) => b.date.compareTo(a.date),
      );

      _streak = _calculateStreak();
    });

    await _saveSessions();

    if (_streak > oldStreak) {
      setState(() {
        _showCelebration = true;
      });

      Future.delayed(
        const Duration(seconds: 2),
        () {
          if (mounted) {
            setState(() {
              _showCelebration = false;
            });
          }
        },
      );
    }

    setState(() {
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        sessions: _sessions,
        streak: _streak,
        showCelebration: _showCelebration,
        openLogScreen: () {
          setState(() {
            _currentIndex = 1;
          });
        },
      ),
      LogPracticeScreen(
        onSave: _addSession,
      ),
      HistoryScreen(
        sessions: _sessions,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: screens[_currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_fire_department_outlined),
            selectedIcon: Icon(Icons.local_fire_department),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Log Practice',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final List<PracticeSession> sessions;
  final int streak;
  final bool showCelebration;
  final VoidCallback openLogScreen;

  const DashboardScreen({
    super.key,
    required this.sessions,
    required this.streak,
    required this.showCelebration,
    required this.openLogScreen,
  });

  bool get practicedToday {
    final today = DateTime.now();

    return sessions.any(
      (session) =>
          session.date.year == today.year &&
          session.date.month == today.month &&
          session.date.day == today.day,
    );
  }

  int get totalMinutes {
    return sessions.fold(
      0,
      (total, session) => total + session.duration,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 700,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SpeakStreak',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Keep practicing. Keep improving.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 30),

          Center(
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepOrange.shade400,
                    Colors.orange.shade300,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    size: 75,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$streak Day Streak',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Keep your speaking streak alive!',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          AnimatedScale(
            scale: showCelebration ? 1 : 0,
            duration: const Duration(
              milliseconds: 500,
            ),
            child: Container(
              margin: const EdgeInsets.only(top: 20),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Text(
                '🎉 Great job! Your streak increased! 🔥',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),

          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Sessions',
                  value: '${sessions.length}',
                  icon: Icons.record_voice_over,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Minutes',
                  value: '$totalMinutes',
                  icon: Icons.timer_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Card(
          elevation: 0,
          color: practicedToday
              ? Colors.green.shade50
              : Colors.orange.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: practicedToday
                  ? Colors.green.shade100
                  : Colors.orange.shade100,
            ),
          ),
          child: ListTile(
              leading: Icon(
                practicedToday
                    ? Icons.check_circle
                    : Icons.pending_outlined,
                color: practicedToday
                    ? Colors.green
                    : Colors.orange,
              ),
              title: const Text(
                "Today's Practice",
              ),
              subtitle: Text(
                practicedToday
                    ? 'Completed'
                    : 'Not completed yet',
              ),
            ),
          ),

          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: openLogScreen,
              icon: const Icon(
                Icons.mic,
              ),
              label: const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 14,
                ),
                child: Text(
                  "Log Today's Practice",
                  style: TextStyle(
                    fontSize: 17,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.orange.shade100,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 28,
              color: Colors.deepOrange,
            ),
          ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class LogPracticeScreen extends StatefulWidget {
  final Future<void> Function(
    PracticeSession session,
  ) onSave;

  const LogPracticeScreen({
    super.key,
    required this.onSave,
  });

  @override
  State<LogPracticeScreen> createState() =>
      _LogPracticeScreenState();
}

class _LogPracticeScreenState
    extends State<LogPracticeScreen> {
    final _formKey = GlobalKey<FormState>();
  String _language = 'English';

  int _duration = 15;

  int _confidence = 3;

  DateTime _selectedDate = DateTime.now();

  final languages = [
    'English',
    'Hindi',
    'German',
    'French',
    'Spanish',
    'Japanese',
  ];

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
  key: _formKey,
  child: SingleChildScrollView(
  padding: const EdgeInsets.all(20),
  child: Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 700,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Log Practice',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Record your speaking practice session.',
          ),
          const SizedBox(height: 30),

          DropdownButtonFormField<String>(
            initialValue: _language,
            decoration: const InputDecoration(
              labelText: 'Language',
              border: OutlineInputBorder(),
              prefixIcon: Icon(
                Icons.language,
              ),
            ),
            items: languages.map((language) {
              return DropdownMenuItem(
                value: language,
                child: Text(language),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _language = value;
                });
              }
            },
          ),

          const SizedBox(height: 20),

          ListTile(
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Colors.grey.shade400,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            leading: const Icon(
              Icons.calendar_month,
            ),
            title: const Text('Practice Date'),
            subtitle: Text(
              formatDate(_selectedDate),
            ),
            trailing: const Icon(
              Icons.edit_calendar,
            ),
            onTap: _chooseDate,
          ),

          const SizedBox(height: 25),

          Text(
            'Duration: $_duration minutes',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),

          Slider(
            min: 5,
            max: 120,
            divisions: 23,
            value: _duration.toDouble(),
            label: '$_duration min',
            onChanged: (value) {
              setState(() {
                _duration = value.toInt();
              });
            },
          ),

          const SizedBox(height: 20),

          Text(
            'Confidence: $_confidence / 5',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < _confidence
                    ? Icons.star
                    : Icons.star_border,
                color: Colors.amber,
                size: 35,
              ),
            ),
          ),

          Slider(
            min: 1,
            max: 5,
            divisions: 4,
            value: _confidence.toDouble(),
            label: '$_confidence',
            onChanged: (value) {
              setState(() {
                _confidence = value.toInt();
              });
            },
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                final session = PracticeSession(
                  date: _selectedDate,
                  language: _language,
                  duration: _duration,
                  confidence: _confidence,
                );

                await widget.onSave(session);

                if (!context.mounted) return;

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Practice session saved successfully!',
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.save,
              ),
              label: const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 14,
                ),
                child: Text(
                  'Save Practice',
                  style: TextStyle(
                    fontSize: 17,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
      ),
      ),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  final List<PracticeSession> sessions;

  const HistoryScreen({
    super.key,
    required this.sessions,
  });

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
  padding: const EdgeInsets.all(20),
  child: Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 700,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Practice History',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'View all your speaking practice sessions.',
          ),
          const SizedBox(height: 20),

          Expanded(
            child: sessions.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 70,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 15),
                        Text(
                          'No practice history yet.',
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session =
                          sessions[index];

                      return Card(
                        margin:
                            const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: Padding(
                          padding:
                              const EdgeInsets.all(
                            8,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                session.language[0],
                              ),
                            ),
                            title: Text(
                              session.language,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                const SizedBox(
                                  height: 6,
                                ),
                                Text(
                                  'Date: ${formatDate(session.date)}',
                                ),
                                Text(
                                  'Duration: ${session.duration} minutes',
                                ),
                                Row(
                                  children:
                                      List.generate(
                                    5,
                                    (starIndex) =>
                                        Icon(
                                      starIndex <
                                              session
                                                  .confidence
                                          ? Icons.star
                                          : Icons
                                              .star_border,
                                      color:
                                          Colors.amber,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  ),
    );
  }
}