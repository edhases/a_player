import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    size: Size(900, 700),
    minimumSize: Size(700, 500),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'Oxide Player - Test Runner',
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(
    ChangeNotifierProvider(
      create: (_) => TestRunnerState(),
      child: const TestRunnerApp(),
    ),
  );
}

class TestRunnerApp extends StatelessWidget {
  const TestRunnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Runner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const TestRunnerScreen(),
    );
  }
}

// ============== Models ==============

enum TestStatus { pending, running, passed, failed, skipped }

class TestFile {
  final String name;
  final String path;
  final List<TestCase> tests;
  TestStatus status;
  Duration? duration;

  TestFile({
    required this.name,
    required this.path,
    List<TestCase>? tests,
    this.status = TestStatus.pending,
    this.duration,
  }) : tests = tests ?? [];

  int get passedCount =>
      tests.where((t) => t.status == TestStatus.passed).length;
  int get failedCount =>
      tests.where((t) => t.status == TestStatus.failed).length;
  int get skippedCount =>
      tests.where((t) => t.status == TestStatus.skipped).length;
}

class TestCase {
  final String name;
  final String? group;
  TestStatus status;
  String? errorMessage;
  Duration? duration;

  TestCase({
    required this.name,
    this.group,
    this.status = TestStatus.pending,
    this.errorMessage,
    this.duration,
  });
}

// ============== State ==============

class TestRunnerState extends ChangeNotifier {
  List<TestFile> testFiles = [];
  bool isRunning = false;
  bool isDiscovering = false;
  String projectPath = '';
  String output = '';
  int totalPassed = 0;
  int totalFailed = 0;
  int totalSkipped = 0;
  Duration totalDuration = Duration.zero;
  Process? _currentProcess;

  TestRunnerState() {
    _findProjectPath();
  }

  Future<void> _findProjectPath() async {
    // Find the project root (2 levels up from tools/test_runner_gui)
    var dir = Directory.current;

    // Try to find pubspec.yaml of main project
    for (var i = 0; i < 5; i++) {
      final pubspec = File('${dir.path}/pubspec.yaml');
      if (pubspec.existsSync()) {
        final content = pubspec.readAsStringSync();
        if (content.contains('oxide_player') ||
            content.contains('name: a_player')) {
          projectPath = dir.path;
          await discoverTests();
          return;
        }
      }
      dir = dir.parent;
    }

    // Fallback to manual path
    projectPath = r'E:\Github\a_player';
    await discoverTests();
  }

  Future<void> discoverTests() async {
    isDiscovering = true;
    notifyListeners();

    testFiles.clear();
    output = 'Discovering tests in $projectPath...\n';

    try {
      final testDir = Directory('$projectPath/test');
      if (!testDir.existsSync()) {
        output += 'Error: Test directory not found\n';
        isDiscovering = false;
        notifyListeners();
        return;
      }

      await _scanDirectory(testDir);

      output += 'Found ${testFiles.length} test files\n';
      for (final file in testFiles) {
        output += '  - ${file.name}\n';
      }
    } catch (e) {
      output += 'Error discovering tests: $e\n';
    }

    isDiscovering = false;
    notifyListeners();
  }

  Future<void> _scanDirectory(Directory dir) async {
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('_test.dart')) {
        final relativePath = entity.path
            .replaceAll(projectPath, '')
            .replaceAll('\\', '/')
            .replaceFirst('/', '');

        testFiles.add(TestFile(
          name: entity.path.split(Platform.pathSeparator).last,
          path: relativePath,
        ));
      }
    }
  }

  Future<void> runAllTests() async {
    if (isRunning) return;

    isRunning = true;
    totalPassed = 0;
    totalFailed = 0;
    totalSkipped = 0;
    totalDuration = Duration.zero;
    output = '';

    for (final file in testFiles) {
      file.status = TestStatus.pending;
      file.tests.clear();
      file.duration = null;
    }
    notifyListeners();

    for (final file in testFiles) {
      if (!isRunning) break;
      await _runTestFile(file);
    }

    isRunning = false;
    output += '\n${'=' * 50}\n';
    output +=
        'SUMMARY: $totalPassed passed, $totalFailed failed, $totalSkipped skipped\n';
    output += 'Total time: ${_formatDuration(totalDuration)}\n';
    notifyListeners();
  }

  Future<void> runSingleTest(TestFile file) async {
    if (isRunning) return;

    isRunning = true;
    file.status = TestStatus.pending;
    file.tests.clear();
    file.duration = null;
    notifyListeners();

    await _runTestFile(file);

    isRunning = false;
    notifyListeners();
  }

  Future<void> _runTestFile(TestFile file) async {
    file.status = TestStatus.running;
    output += '\n🔄 Running: ${file.name}\n';
    notifyListeners();

    final stopwatch = Stopwatch()..start();

    try {
      final result = await Process.run(
        'flutter',
        ['test', file.path, '--reporter', 'json'],
        workingDirectory: projectPath,
        runInShell: true,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      stopwatch.stop();
      file.duration = stopwatch.elapsed;
      totalDuration += stopwatch.elapsed;

      _parseJsonOutput(result.stdout, file);

      if (file.failedCount > 0) {
        file.status = TestStatus.failed;
        output +=
            '❌ ${file.name}: ${file.passedCount} passed, ${file.failedCount} failed\n';
      } else {
        file.status = TestStatus.passed;
        output +=
            '✅ ${file.name}: ${file.passedCount} passed (${_formatDuration(file.duration!)})\n';
      }

      totalPassed += file.passedCount;
      totalFailed += file.failedCount;
      totalSkipped += file.skippedCount;
    } catch (e) {
      stopwatch.stop();
      file.status = TestStatus.failed;
      file.duration = stopwatch.elapsed;
      output += '❌ Error running ${file.name}: $e\n';
    }

    notifyListeners();
  }

  void _parseJsonOutput(String jsonOutput, TestFile file) {
    final lines = jsonOutput.split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      try {
        final event = json.decode(line) as Map<String, dynamic>;
        final type = event['type'] as String?;

        if (type == 'testStart') {
          final test = event['test'] as Map<String, dynamic>?;
          if (test != null) {
            final name = test['name'] as String? ?? 'Unknown';
            final groupIDs = test['groupIDs'] as List?;

            file.tests.add(TestCase(
              name: name,
              status: TestStatus.running,
            ));
          }
        } else if (type == 'testDone') {
          final result = event['result'] as String?;
          final testID = event['testID'] as int?;

          if (file.tests.isNotEmpty) {
            final test = file.tests.last;
            if (result == 'success') {
              test.status = TestStatus.passed;
            } else if (result == 'failure') {
              test.status = TestStatus.failed;
            } else if (result == 'skipped') {
              test.status = TestStatus.skipped;
            }
          }
        } else if (type == 'error') {
          final error = event['error'] as String? ?? '';
          if (file.tests.isNotEmpty) {
            file.tests.last.errorMessage = error;
          }
        }
      } catch (e) {
        // Not valid JSON, skip
      }
    }
  }

  void stopTests() {
    isRunning = false;
    _currentProcess?.kill();
    output += '\n⏹ Tests stopped by user\n';
    notifyListeners();
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds % 60}s';
    }
    return '${d.inSeconds}.${(d.inMilliseconds % 1000 ~/ 100)}s';
  }
}

// ============== UI ==============

class TestRunnerScreen extends StatelessWidget {
  const TestRunnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          const Expanded(
            child: Row(
              children: [
                Expanded(flex: 2, child: TestFilesList()),
                VerticalDivider(width: 1),
                Expanded(flex: 3, child: OutputPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final state = context.watch<TestRunnerState>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.science_outlined,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Oxide Player Test Runner',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                state.projectPath,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
          const Spacer(),
          _buildStats(context, state),
          const SizedBox(width: 24),
          _buildActions(context, state),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context, TestRunnerState state) {
    return Row(
      children: [
        _StatBadge(
          icon: Icons.check_circle,
          value: state.totalPassed,
          color: Colors.green,
          label: 'Passed',
        ),
        const SizedBox(width: 8),
        _StatBadge(
          icon: Icons.cancel,
          value: state.totalFailed,
          color: Colors.red,
          label: 'Failed',
        ),
        const SizedBox(width: 8),
        _StatBadge(
          icon: Icons.skip_next,
          value: state.totalSkipped,
          color: Colors.orange,
          label: 'Skipped',
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, TestRunnerState state) {
    return Row(
      children: [
        if (state.isRunning)
          FilledButton.icon(
            onPressed: state.stopTests,
            icon: const Icon(Icons.stop),
            label: const Text('Stop'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          )
        else
          FilledButton.icon(
            onPressed: state.isDiscovering ? null : state.runAllTests,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Run All'),
          ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: state.isRunning ? null : state.discoverTests,
          icon: state.isDiscovering
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          tooltip: 'Refresh test list',
        ),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;
  final String label;

  const _StatBadge({
    required this.icon,
    required this.value,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class TestFilesList extends StatelessWidget {
  const TestFilesList({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TestRunnerState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Row(
            children: [
              const Icon(Icons.folder_outlined, size: 20),
              const SizedBox(width: 8),
              Text(
                'Test Files (${state.testFiles.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
        Expanded(
          child: state.testFiles.isEmpty
              ? const Center(child: Text('No test files found'))
              : ListView.builder(
                  itemCount: state.testFiles.length,
                  itemBuilder: (context, index) {
                    final file = state.testFiles[index];
                    return _TestFileItem(file: file);
                  },
                ),
        ),
      ],
    );
  }
}

class _TestFileItem extends StatelessWidget {
  final TestFile file;

  const _TestFileItem({required this.file});

  @override
  Widget build(BuildContext context) {
    final state = context.read<TestRunnerState>();

    return ExpansionTile(
      leading: _buildStatusIcon(),
      title: Text(
        file.name,
        style: const TextStyle(fontSize: 13),
      ),
      subtitle: file.status != TestStatus.pending
          ? Text(
              '${file.passedCount}/${file.tests.length} passed'
              '${file.duration != null ? ' • ${_formatDuration(file.duration!)}' : ''}',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.outline,
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!state.isRunning)
            IconButton(
              icon: const Icon(Icons.play_arrow, size: 20),
              onPressed: () => state.runSingleTest(file),
              tooltip: 'Run this test file',
            ),
        ],
      ),
      children: file.tests.map((test) {
        return ListTile(
          dense: true,
          leading: _buildTestStatusIcon(test.status),
          title: Text(
            test.name,
            style: const TextStyle(fontSize: 12),
          ),
          subtitle: test.errorMessage != null
              ? Text(
                  test.errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
        );
      }).toList(),
    );
  }

  Widget _buildStatusIcon() {
    switch (file.status) {
      case TestStatus.pending:
        return const Icon(Icons.circle_outlined, color: Colors.grey, size: 18);
      case TestStatus.running:
        return const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case TestStatus.passed:
        return const Icon(Icons.check_circle, color: Colors.green, size: 18);
      case TestStatus.failed:
        return const Icon(Icons.cancel, color: Colors.red, size: 18);
      case TestStatus.skipped:
        return const Icon(Icons.skip_next, color: Colors.orange, size: 18);
    }
  }

  Widget _buildTestStatusIcon(TestStatus status) {
    switch (status) {
      case TestStatus.pending:
        return const Icon(Icons.circle_outlined, color: Colors.grey, size: 14);
      case TestStatus.running:
        return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case TestStatus.passed:
        return const Icon(Icons.check, color: Colors.green, size: 14);
      case TestStatus.failed:
        return const Icon(Icons.close, color: Colors.red, size: 14);
      case TestStatus.skipped:
        return const Icon(Icons.skip_next, color: Colors.orange, size: 14);
    }
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds % 60}s';
    }
    return '${d.inSeconds}.${(d.inMilliseconds % 1000 ~/ 100)}s';
  }
}

class OutputPanel extends StatelessWidget {
  const OutputPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TestRunnerState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Row(
            children: [
              const Icon(Icons.terminal, size: 20),
              const SizedBox(width: 8),
              Text(
                'Output',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: state.output.isEmpty
                    ? null
                    : () {
                        Clipboard.setData(ClipboardData(text: state.output));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Output copied to clipboard'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                tooltip: 'Copy output',
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.black87,
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              state.output.isEmpty
                  ? 'Click "Run All" to start tests...'
                  : state.output,
              style: const TextStyle(
                fontFamily: 'Consolas',
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
