import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class ProjectConfig {
  final String name;
  final String repoOwner;
  final String repoName;
  final String branchName;
  final String pubspecName;
  final String artifactPrefix;
  final String displayName;

  ProjectConfig({
    required this.name,
    required this.repoOwner,
    required this.repoName,
    required this.branchName,
    required this.pubspecName,
    required this.artifactPrefix,
    required this.displayName,
  });
}

final List<ProjectConfig> ecosystemProjects = [
  ProjectConfig(
    name: 'a_player',
    repoOwner: 'edhases',
    repoName: 'a_player',
    branchName: 'YTM-integation',
    pubspecName: 'oxide_player',
    artifactPrefix: 'a_player',
    displayName: 'Oxide Player',
  ),
  ProjectConfig(
    name: 'oxide_film',
    repoOwner: 'edhases',
    repoName: 'oxide_film',
    branchName: 'refactor20260204',
    pubspecName: 'oxide_film',
    artifactPrefix: 'oxide_film',
    displayName: 'Oxide Film',
  ),
];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1000, 700),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ReleaseCommanderApp());
}

class ReleaseCommanderApp extends StatelessWidget {
  const ReleaseCommanderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReleaseProvider(),
      child: MaterialApp(
        title: 'Release Commander',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0F111A),
          cardColor: const Color(0xFF1A1D2D),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00F0FF),
            secondary: Color(0xFF7000FF),
            surface: Color(0xFF1A1D2D),
          ),
          textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
        ),
        home: const MainWindow(),
      ),
    );
  }
}

class MainWindow extends StatelessWidget {
  const MainWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const WindowTitleBar(),
          Expanded(
            child: Row(
              children: [
                const SizedBox(width: 300, child: Sidebar()),
                Expanded(child: DashboardContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WindowTitleBar extends StatelessWidget {
  const WindowTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: const Color(0xFF0A0C12),
      child: Row(
        children: [
          Expanded(
            child: DragToMoveArea(
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.rocket_launch,
                    color: Color(0xFF00F0FF),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'RELEASE COMMANDER',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.white, size: 18),
            onPressed: () => windowManager.minimize(),
            tooltip: 'Minimize',
          ),
          IconButton(
            icon: const Icon(Icons.crop_square, color: Colors.white, size: 18),
            onPressed: () async {
              if (await windowManager.isMaximized()) {
                windowManager.unmaximize();
              } else {
                windowManager.maximize();
              }
            },
            tooltip: 'Maximize',
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
            onPressed: () => windowManager.close(),
            tooltip: 'Close',
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF131620),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(context),
          const SizedBox(height: 30),
          const Text(
            'ECOSYSTEM PROJECT',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 10),
          _buildProjectSelector(context),
          const SizedBox(height: 30),
          const Text(
            'RELEASE STEPS',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Consumer<ReleaseProvider>(
                builder: (context, provider, _) => Column(
                  children: [
                    _buildStep(1, 'Git Check', provider.stepStatus[0]),
                    _buildStep(2, 'Version Bump', provider.stepStatus[1]),
                    _buildStep(3, 'Flutter Clean', provider.stepStatus[2]),
                    _buildStep(4, 'Build APK', provider.stepStatus[3]),
                    _buildStep(5, 'Rename Artifact', provider.stepStatus[4]),
                    _buildStep(6, 'Git Push', provider.stepStatus[5]),
                    _buildStep(7, 'GitHub Upload', provider.stepStatus[6]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectSelector(BuildContext context) {
    final provider = context.watch<ReleaseProvider>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ProjectConfig>(
          value: provider.selectedProject,
          isExpanded: true,
          dropdownColor: const Color(0xFF1A1D2D),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF00F0FF)),
          items: ecosystemProjects.map((p) {
            return DropdownMenuItem(value: p, child: Text(p.displayName));
          }).toList(),
          onChanged: provider.isBusy
              ? null
              : (p) {
                  if (p != null) provider.switchProject(p);
                },
        ),
      ),
    );
  }

  Widget _buildStep(int index, String title, StepStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case StepStatus.pending:
        color = Colors.grey.withOpacity(0.3);
        icon = Icons.radio_button_unchecked;
        break;
      case StepStatus.running:
        color = const Color(0xFF00F0FF);
        icon = Icons.sync;
        break;
      case StepStatus.success:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case StepStatus.error:
        color = Colors.red;
        icon = Icons.error;
        break;
      case StepStatus.skipped:
        color = Colors.orange;
        icon = Icons.skip_next;
        break;
    }

    return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D2D),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: status == StepStatus.running
                  ? const Color(0xFF00F0FF)
                  : Colors.transparent,
            ),
            boxShadow: status == StepStatus.running
                ? [
                    BoxShadow(
                      color: const Color(0xFF00F0FF).withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              status == StepStatus.running
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(icon, color: color, size: 18),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: status == StepStatus.pending
                      ? Colors.grey
                      : Colors.white,
                ),
              ),
            ],
          ),
        )
        .animate(target: status == StepStatus.running ? 1 : 0)
        .shimmer(duration: 1.seconds);
  }

  Widget _buildInfoCard(BuildContext context) {
    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    return Consumer<ReleaseProvider>(
      builder: (context, provider, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7000FF), Color(0xFF00F0FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TARGET RELEASE',
              style: TextStyle(color: Colors.white70, fontSize: 10),
            ),
            Text(
              dateStr,
              style: GoogleFonts.orbitron(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Branch: ${provider.selectedProject.branchName}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardContent extends StatelessWidget {
  final TextEditingController _changelogController = TextEditingController();
  final TextEditingController _versionNameCtrl = TextEditingController();
  final TextEditingController _versionCodeCtrl = TextEditingController();
  final TextEditingController _tagNameCtrl = TextEditingController();
  final TextEditingController _releaseTitleCtrl = TextEditingController();

  DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReleaseProvider>();

    // Initial load of config values into controllers
    // We only set them if the controller is empty (to avoid overwriting user processing)
    if (_versionNameCtrl.text != provider.versionName) {
      _versionNameCtrl.text = provider.versionName;
    }
    if (_versionCodeCtrl.text != provider.versionCode) {
      _versionCodeCtrl.text = provider.versionCode;
    }
    if (_tagNameCtrl.text != provider.tagName) {
      _tagNameCtrl.text = provider.tagName;
    }
    if (_releaseTitleCtrl.text != provider.releaseTitle) {
      _releaseTitleCtrl.text = provider.releaseTitle;
    }

    // Initial load of changelog
    if (_changelogController.text.isEmpty && provider.changelog.isNotEmpty) {
      _changelogController.text = provider.changelog;
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              children: [
                // Settings & Changelog
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      const Text(
                        'CONFIGURATION',
                        style: TextStyle(
                          color: Color(0xFF00F0FF),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Config Fields
                      _buildConfigField(
                        'Version Name (pubspec)',
                        _versionNameCtrl,
                        (v) => provider.updateVersionName(v),
                      ),
                      const SizedBox(height: 8),
                      _buildConfigField(
                        'Version Code',
                        _versionCodeCtrl,
                        (v) => provider.updateVersionCode(v),
                      ),
                      const SizedBox(height: 8),
                      _buildConfigField(
                        'Git Tag',
                        _tagNameCtrl,
                        (v) => provider.updateTagName(v),
                      ),
                      const SizedBox(height: 8),
                      _buildConfigField(
                        'Release Title',
                        _releaseTitleCtrl,
                        (v) => provider.updateReleaseTitle(v),
                      ),

                      const SizedBox(height: 20),
                      const Text(
                        'RELEASE NOTES',
                        style: TextStyle(
                          color: Color(0xFF00F0FF),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF131620),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          child: TextField(
                            controller: _changelogController,
                            onChanged: (val) => provider.updateChangelog(val),
                            maxLines: null,
                            style: const TextStyle(color: Colors.white70),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                              hintText: 'Loading git history...',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Console Output
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'SYSTEM LOGS',
                            style: TextStyle(
                              color: Color(0xFF00F0FF),
                              letterSpacing: 1.5,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.content_copy, size: 18),
                            color: const Color(0xFF00F0FF),
                            tooltip: 'Copy Logs',
                            onPressed: provider.logs.isEmpty
                                ? null
                                : () {
                                    final logText = provider.logs
                                        .map((l) => '${l.time} > ${l.message}')
                                        .join('\n');
                                    Clipboard.setData(
                                      ClipboardData(text: logText),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Logs copied to clipboard',
                                        ),
                                        duration: Duration(seconds: 2),
                                        backgroundColor: Color(0xFF00F0FF),
                                      ),
                                    );
                                  },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            color: Colors.grey,
                            tooltip: 'Clear Logs',
                            onPressed: provider.logs.isEmpty
                                ? null
                                : () {
                                    provider.clearLogs();
                                  },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF00F0FF).withOpacity(0.3),
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: ListView.builder(
                            controller: provider.scrollController,
                            itemCount: provider.logs.length,
                            itemBuilder: (context, index) {
                              final log = provider.logs[index];
                              return Text(
                                '${log.time} > ${log.message}',
                                style: TextStyle(
                                  color: log.color,
                                  fontSize: 13,
                                  fontFamily: 'Consolas',
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Action Bar
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOptionToggle(
                    'Run Flutter Clean',
                    provider.runClean,
                    (val) => provider.setRunClean(val),
                    provider.isBusy || provider.skipBuild,
                  ),
                  const SizedBox(height: 4),
                  _buildOptionToggle(
                    'Skip Build (Upload Only)',
                    provider.skipBuild,
                    (val) => provider.setSkipBuild(val),
                    provider.isBusy,
                  ),
                  const SizedBox(height: 4),
                  _buildOptionToggle(
                    'Build Windows',
                    provider.buildWindows,
                    (val) => provider.setBuildWindows(val),
                    provider.isBusy || provider.skipBuild,
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Dependency check button
              OutlinedButton.icon(
                onPressed: provider.isBusy
                    ? null
                    : () => provider._checkDependencies(),
                icon: const Icon(Icons.security, size: 18),
                label: const Text('Check Deps'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00F0FF),
                  side: const BorderSide(color: Color(0xFF00F0FF)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const Spacer(),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (provider.isBusy)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: CircularProgressIndicator(
                            color: Color(0xFF00F0FF),
                          ),
                        ),
                      if (!provider.isBusy)
                        ElevatedButton(
                          onPressed: () => provider.startRelease(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00F0FF),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            textStyle: GoogleFonts.orbitron(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                provider.skipBuild
                                    ? Icons.cloud_upload
                                    : Icons.rocket_launch,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                provider.skipBuild
                                    ? 'INITIATE UPLOAD'
                                    : 'INITIATE RELEASE',
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfigField(
    String label,
    TextEditingController ctrl,
    Function(String) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131620),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              onChanged: onChanged,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'Consolas',
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionToggle(
    String label,
    bool value,
    Function(bool) onChanged,
    bool disabled,
  ) {
    return Row(
      children: [
        Switch(
          value: value,
          onChanged: disabled ? null : onChanged,
          activeThumbColor: const Color(0xFF00F0FF),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: disabled ? Colors.grey : Colors.white),
        ),
      ],
    );
  }
}

// --- Provider Logic ---

enum StepStatus { pending, running, success, error, skipped }

class LogEntry {
  final String message;
  final String time;
  final Color color;
  LogEntry(this.message, {this.color = Colors.white})
    : time = DateFormat('HH:mm:ss').format(DateTime.now());
}

/// Result of dependency conflict analysis
class DependencyConflict {
  final String package;
  final String requiredVersion;
  final String resolvedVersion;
  final List<String> conflictingDeps;

  DependencyConflict({
    required this.package,
    required this.requiredVersion,
    required this.resolvedVersion,
    this.conflictingDeps = const [],
  });

  bool get isConflict => requiredVersion != resolvedVersion;
}

/// Result of pre-release validation
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });
}

class ReleaseProvider extends ChangeNotifier {
  List<StepStatus> stepStatus = List.filled(7, StepStatus.pending);
  List<LogEntry> logs = [];
  String changelog = '';
  bool isBusy = false;
  bool runClean = false;
  bool skipBuild = false;
  bool buildWindows = Platform.isWindows;
  final ScrollController scrollController = ScrollController();
  ProjectConfig selectedProject = ecosystemProjects.first;
  String versionName = '';
  String versionCode = '';
  String tagName = '';
  String releaseTitle = '';

  ReleaseProvider() {
    _init();
  }

  Future<void> switchProject(ProjectConfig project) async {
    selectedProject = project;
    changelog = '';
    versionName = '';
    versionCode = '';
    tagName = '';
    releaseTitle = '';
    stepStatus = List.filled(7, StepStatus.pending);
    notifyListeners();
    await _init();
  }

  Future<void> _init() async {
    await _loadInitialChangelog();
    await _generateVersionDetails();
    // Check dependencies on startup
    await _checkDependencies();
  }

  /// Check for dependency conflicts and outdated packages
  Future<void> _checkDependencies() async {
    log('Analyzing dependencies...', color: Colors.blue);

    try {
      final projectRoot = await _findProjectRoot();

      // Run flutter pub outdated to check for issues
      final outdatedResult = await Process.run(
        'flutter',
        ['pub', 'outdated', '--json'],
        workingDirectory: projectRoot,
        runInShell: true,
      );

      if (outdatedResult.exitCode == 0) {
        try {
          final jsonOutput = jsonDecode(outdatedResult.stdout.toString());
          final packages = jsonOutput['packages'] as List? ?? [];

          int outdatedCount = 0;
          int majorUpdates = 0;

          for (final pkg in packages) {
            final current = pkg['current']?['version'];
            final latest = pkg['latest']?['version'];
            final upgradable = pkg['upgradable']?['version'];

            if (current != null && latest != null && current != latest) {
              outdatedCount++;

              // Check for major version bump
              if (_isMajorVersionBump(current, latest)) {
                majorUpdates++;
              }
            }
          }

          if (outdatedCount > 0) {
            log(
              '📦 $outdatedCount packages have updates available',
              color: Colors.orange,
            );
            if (majorUpdates > 0) {
              log(
                '⚠️ $majorUpdates packages have major version updates (breaking changes possible)',
                color: Colors.orange,
              );
            }
          } else {
            log('✅ All dependencies are up to date', color: Colors.green);
          }
        } catch (e) {
          log('Could not parse outdated output: $e', color: Colors.grey);
        }
      }

      // Check pubspec.lock for potential conflicts
      await _analyzePubspecLock(projectRoot);
    } catch (e) {
      log('Error checking dependencies: $e', color: Colors.orange);
    }
  }

  /// Check if version change is a major bump (e.g., 1.x.x -> 2.x.x)
  bool _isMajorVersionBump(String current, String latest) {
    try {
      final currentMajor = int.parse(current.split('.').first);
      final latestMajor = int.parse(latest.split('.').first);
      return latestMajor > currentMajor;
    } catch (e) {
      return false;
    }
  }

  /// Analyze pubspec.lock for dependency conflicts
  Future<void> _analyzePubspecLock(String projectRoot) async {
    final lockFile = File('$projectRoot/pubspec.lock');
    if (!await lockFile.exists()) {
      log(
        'pubspec.lock not found - run flutter pub get first',
        color: Colors.orange,
      );
      return;
    }

    final content = await lockFile.readAsString();

    // Check for common problematic patterns
    final issues = <String>[];

    // Check for SDK constraints that might cause issues
    if (content.contains('sdk: ">=2.') && content.contains('sdk: ">=3.')) {
      issues.add('Mixed Dart SDK constraints detected (2.x and 3.x)');
    }

    // Check for known problematic package combinations
    final knownConflicts = [
      ['flutter_lints', 'lints'], // These shouldn't coexist
      ['http', 'dio'], // Not a conflict but worth noting
    ];

    for (final pair in knownConflicts) {
      if (content.contains('${pair[0]}:') && content.contains('${pair[1]}:')) {
        // This is just informational, not necessarily an issue
      }
    }

    if (issues.isNotEmpty) {
      for (final issue in issues) {
        log('⚠️ $issue', color: Colors.orange);
      }
    }
  }

  /// Validate release configuration before starting
  Future<ValidationResult> validateRelease() async {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate version name format
    if (versionName.isEmpty) {
      errors.add('Version name cannot be empty');
    } else if (!RegExp(r'^\d+\.\d+\.\d+').hasMatch(versionName)) {
      warnings.add('Version name should follow semver format (X.Y.Z)');
    }

    // Validate version code
    if (versionCode.isEmpty) {
      errors.add('Version code cannot be empty');
    } else if (int.tryParse(versionCode) == null) {
      warnings.add('Version code should be a number for Android');
    }

    // Validate tag name
    if (tagName.isEmpty) {
      errors.add('Tag name cannot be empty');
    } else if (tagName.contains(' ')) {
      errors.add('Tag name cannot contain spaces');
    }

    // Check if tag already exists on remote
    try {
      final projectRoot = await _findProjectRoot();
      final result = await Process.run(
        'git',
        ['ls-remote', '--tags', 'origin', tagName],
        workingDirectory: projectRoot,
        runInShell: true,
      );

      if (result.stdout.toString().contains(tagName)) {
        warnings.add(
          'Tag "$tagName" already exists on remote (will be overwritten)',
        );
      }
    } catch (e) {
      // Ignore errors during tag check
    }

    // Check changelog
    if (changelog.trim().isEmpty) {
      warnings.add('Changelog is empty');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Run dependency conflict resolution
  Future<bool> resolveDependencies() async {
    log('Resolving dependencies...', color: Colors.blue);

    try {
      final projectRoot = await _findProjectRoot();

      // First, try flutter pub get
      final result = await Process.run(
        'flutter',
        ['pub', 'get'],
        workingDirectory: projectRoot,
        runInShell: true,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      if (result.exitCode != 0) {
        final stderr = result.stderr.toString();

        // Check for version solving failure
        if (stderr.contains('version solving failed') ||
            stderr.contains('Because ')) {
          log('❌ Version solving failed!', color: Colors.red);

          // Extract the conflicting package info
          final lines = stderr.split('\n');
          for (final line in lines) {
            if (line.contains('Because ') || line.contains('depends on')) {
              log('  $line', color: Colors.orange);
            }
          }

          log('\n💡 Suggestions:', color: Colors.cyan);
          log(
            '  1. Run "flutter pub upgrade --major-versions" to update constraints',
            color: Colors.grey,
          );
          log(
            '  2. Check pubspec.yaml for conflicting version constraints',
            color: Colors.grey,
          );
          log(
            '  3. Try "flutter pub cache repair" if cache is corrupted',
            color: Colors.grey,
          );

          return false;
        }

        log('pub get failed: $stderr', color: Colors.red);
        return false;
      }

      log('✅ Dependencies resolved successfully', color: Colors.green);
      return true;
    } catch (e) {
      log('Error resolving dependencies: $e', color: Colors.red);
      return false;
    }
  }

  Future<void> _generateVersionDetails() async {
    final now = DateTime.now();
    final dateBase = DateFormat('yyyyMMdd').format(now);

    // Check for existing tags with this date base
    int iteration = 0;
    try {
      final projectRoot = await _findProjectRoot();
      final result = await Process.run(
        'git',
        ['tag', '--list', '$dateBase*'],
        workingDirectory: projectRoot,
        runInShell: true,
      );

      if (result.exitCode == 0) {
        final functions = result.stdout.toString().split('\n');
        // Logic: if 20260127 exists, we need .1, if .1 exists, .2 etc.
        // If we just want to follow user request: "if released same day, 20260127.1"
        // Actually tag usually can't contain . if we want strictly 20260127
        // But user said "20260127.1"
        if (functions.any((t) => t.trim() == dateBase)) {
          iteration = 1;
          // naive check for higher iterations could go here but let's start with 1 level deep as requested
          // or we can parse.
          for (var t in functions) {
            if (t.startsWith('$dateBase.')) {
              final parts = t.split('.');
              if (parts.length > 1) {
                final v = int.tryParse(parts[1]) ?? 0;
                if (v >= iteration) iteration = v + 1;
              }
            }
          }
        }
      }
    } catch (e) {
      log('Error checking tags: $e', color: Colors.orange);
    }

    if (iteration == 0) {
      tagName = dateBase;
      // pubspec requires x.y.z.
      // User requested "just 20260127".
      // We can map 20260127 -> 20260127.0.0 in pubspec?
      // Or 2026.1.27.
      // Let's try 20260127.0.0
      versionName = '$dateBase.0.0';
      versionCode = dateBase;
      releaseTitle = '${selectedProject.displayName} $dateBase';
    } else {
      tagName = '$dateBase.$iteration';
      versionName = '$dateBase.$iteration.0';
      versionCode =
          dateBase; // Code usually integer, can't handle dots. keep same or append?
      // Android statusCode is int. 202601271 ?
      // Let's append iteration if it fits.
      versionCode = '$dateBase$iteration';
      releaseTitle = '${selectedProject.displayName} $tagName';
    }

    notifyListeners();
  }

  void updateVersionName(String val) {
    versionName = val;
    notifyListeners();
  }

  void updateVersionCode(String val) {
    versionCode = val;
    notifyListeners();
  }

  void updateTagName(String val) {
    tagName = val;
    notifyListeners();
  }

  void updateReleaseTitle(String val) {
    releaseTitle = val;
    notifyListeners();
  }

  void log(String message, {Color color = Colors.white70}) {
    logs.add(LogEntry(message, color: color));
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void updateChangelog(String val) {
    changelog = val;
    notifyListeners();
  }

  void clearLogs() {
    logs.clear();
    notifyListeners();
  }

  // ... (init methods) ...

  void setRunClean(bool val) {
    runClean = val;
    notifyListeners();
  }

  void setSkipBuild(bool val) {
    skipBuild = val;
    if (val) runClean = false; // Disable clean if skipping build
    notifyListeners();
  }

  void setBuildWindows(bool val) {
    buildWindows = val;
    notifyListeners();
  }

  Future<void> _loadInitialChangelog() async {
    log('Analyzing git history...', color: Colors.blue);
    try {
      final tagResult = await Process.run('git', [
        'describe',
        '--tags',
        '--abbrev=0',
      ], runInShell: true);
      String range = '';
      if (tagResult.exitCode == 0) {
        final lastTag = tagResult.stdout.toString().trim();
        if (lastTag.isNotEmpty) {
          range = '$lastTag..HEAD';
          log('Creating changelog since tag: $lastTag', color: Colors.green);
        }
      }

      final args = ['log', '--pretty=format:- %s', '--no-merges'];
      if (range.isNotEmpty) args.add(range);

      final result = await Process.run('git', args, runInShell: true);
      if (result.exitCode == 0) {
        var rawLogs = result.stdout.toString().trim();
        if (rawLogs.isNotEmpty) {
          changelog = rawLogs
              .split('\n')
              .where(
                (l) =>
                    !l.contains('Bump version') &&
                    !l.contains('Update update.json'),
              )
              .take(15)
              .join('\n');
          notifyListeners();
        } else {
          changelog = '- General improvements and bug fixes';
          notifyListeners();
        }
      }
    } catch (e) {
      log('Error loading logs: $e', color: Colors.red);
    }
  }

  void _setStep(int index, StepStatus status) {
    stepStatus[index] = status;
    notifyListeners();
  }

  Future<void> startRelease() async {
    isBusy = true;
    // Reset steps
    stepStatus = List.filled(7, StepStatus.pending);
    notifyListeners();

    // === PRE-RELEASE VALIDATION ===
    log('═══════════════════════════════════════════', color: Colors.cyan);
    log('        PRE-RELEASE VALIDATION', color: Colors.cyan);
    log('═══════════════════════════════════════════', color: Colors.cyan);

    final validation = await validateRelease();

    if (validation.errors.isNotEmpty) {
      for (final error in validation.errors) {
        log('❌ ERROR: $error', color: Colors.red);
      }
      log('Release aborted due to validation errors.', color: Colors.red);
      isBusy = false;
      notifyListeners();
      return;
    }

    for (final warning in validation.warnings) {
      log('⚠️ WARNING: $warning', color: Colors.orange);
    }

    log('✅ Validation passed', color: Colors.green);
    log('');

    // Project root - assumes we are running from tools/release_manager
    // We need to go up two levels
    // Find project root dynamically
    String projectRoot;
    try {
      projectRoot = await _findProjectRoot();
    } catch (e) {
      log('ERROR: $e', color: Colors.red);
      _setStep(0, StepStatus.error);
      isBusy = false;
      notifyListeners();
      return;
    }

    log('Target Project Root: $projectRoot', color: Colors.yellow);

    // === DEPENDENCY CHECK ===
    if (!skipBuild) {
      log('');
      log('═══════════════════════════════════════════', color: Colors.cyan);
      log('        DEPENDENCY RESOLUTION', color: Colors.cyan);
      log('═══════════════════════════════════════════', color: Colors.cyan);

      final depsOk = await resolveDependencies();
      if (!depsOk) {
        log('');
        log('❌ Dependency resolution failed!', color: Colors.red);
        log('Fix the issues above and try again.', color: Colors.red);
        isBusy = false;
        notifyListeners();
        return;
      }
      log('');
    }

    // Use user-defined values
    log('Configuration:', color: Colors.blue);
    log('  Version: $versionName', color: Colors.grey);
    log('  Code: $versionCode', color: Colors.grey);
    log('  Tag: $tagName', color: Colors.grey);
    log('  Title: $releaseTitle', color: Colors.grey);

    // Note: User can override everything, so we rely on class fields.

    try {
      // 1. Git Check
      _setStep(0, StepStatus.running);
      log('Checking git status...');
      final statusResult = await Process.run(
        'git',
        ['status', '--porcelain'],
        workingDirectory: projectRoot,
        runInShell: true,
      );
      if (statusResult.stdout.toString().trim().isNotEmpty) {
        log('WARNING: Uncommitted changes detected!', color: Colors.orange);
      } else {
        log('Git working tree clean.', color: Colors.green);
      }
      _setStep(0, StepStatus.success);

      // 2. Version Bump
      _setStep(1, StepStatus.running);
      log('Bumping version in pubspec.yaml...');
      final pubspecFile = File('$projectRoot/pubspec.yaml');
      String? originalPubspec;
      if (await pubspecFile.exists()) {
        originalPubspec = await pubspecFile.readAsString();
        final lines = originalPubspec.split('\n');
        final newLines = <String>[];
        bool updated = false;

        for (var line in lines) {
          if (line.startsWith('version:')) {
            // Format: version: X.Y.Z+buildNumber (where buildNumber = versionCode)
            final fullVersion = '$versionName+$versionCode';
            newLines.add('version: $fullVersion');
            log('Version format: $fullVersion', color: Colors.grey);
            updated = true;
          } else {
            newLines.add(line);
          }
        }
        if (updated) {
          await pubspecFile.writeAsString(newLines.join('\n'));
          log(
            'Version updated to $versionName+$versionCode',
            color: Colors.green,
          );
        } else {
          throw 'Could not find version in pubspec.yaml';
        }
      } else {
        throw 'pubspec.yaml not found at $projectRoot';
      }
      _setStep(1, StepStatus.success);

      final env = Map<String, String>.from(Platform.environment);
      final home =
          Platform.environment['UserProfile'] ?? Platform.environment['HOME'];

      // Fix Path case-sensitivity for Windows
      String pathKey = 'Path';
      if (Platform.isWindows) {
        pathKey = env.keys.firstWhere(
          (k) => k.toUpperCase() == 'PATH',
          orElse: () => 'Path',
        );
      }

      if (home != null) {
        final currentPath = env[pathKey] ?? '';
        env[pathKey] = "$currentPath;$home\\.cargo\\bin";
      }

      // 3. Clean & 4. Build
      if (skipBuild) {
        _setStep(2, StepStatus.skipped);
        _setStep(3, StepStatus.skipped);
        log('Skipping Build/Clean as requested.', color: Colors.orange);
      } else {
        // 3. Clean
        if (runClean) {
          _setStep(2, StepStatus.running);
          log('Running flutter clean...', color: Colors.blue);
          await _runCmd('flutter', ['clean'], projectRoot);
          log('Running flutter pub get...', color: Colors.blue);
          await _runCmd('flutter', ['pub', 'get'], projectRoot);
          _setStep(2, StepStatus.success);
        } else {
          _setStep(2, StepStatus.skipped);
          log('Skipping clean step.', color: Colors.grey);
        }

        // 4. Build
        _setStep(3, StepStatus.running);

        // Build APK
        log('Building Release APK...', color: Colors.cyan);
        await _runCmd(
          'flutter',
          ['build', 'apk', '--release'],
          projectRoot,
          env: env,
        );

        // Build Windows (if enabled)
        if (buildWindows && Platform.isWindows) {
          log('Building Windows Release...', color: Colors.cyan);
          await _runCmd(
            'flutter',
            ['build', 'windows', '--release'],
            projectRoot,
            env: env,
          );
        }

        _setStep(3, StepStatus.success);
      }

      // 5. Rename & Hash
      _setStep(4, StepStatus.running);

      // APK Handling
      final buildDirApk = '$projectRoot/build/app/outputs/flutter-apk';
      final releaseApk = File('$buildDirApk/app-release.apk');
      final newFilenameApk = '${selectedProject.artifactPrefix}_v$tagName.apk';
      final targetApk = File('$buildDirApk/$newFilenameApk');
      String apkHash = '';

      if (!await targetApk.exists()) {
        if (await releaseApk.exists()) {
          await releaseApk.rename(targetApk.path);
          log('APK Renamed: $newFilenameApk', color: Colors.green);
        } else {
          if (!skipBuild) throw 'APK artifact missing!';
        }
      } else {
        log('Using existing APK: $newFilenameApk', color: Colors.green);
      }

      if (await targetApk.exists()) {
        log('Calculating APK SHA-256...');
        final bytes = await targetApk.readAsBytes();
        apkHash = sha256.convert(bytes).toString().toUpperCase();
        log('APK Hash: $apkHash', color: Colors.grey);
      }

      // Windows Handling
      String windowsHash = '';
      String releasedWindowsName = '';

      if (buildWindows && Platform.isWindows) {
        final buildDirWin = '$projectRoot/build/windows/x64/runner/Release';

        // Check for MSIX config
        final pubspecFile = File('$projectRoot/pubspec.yaml');
        final pubspecContent = await pubspecFile.readAsString();
        final hasMsix = pubspecContent.contains('msix_config:');

        File? windowsArtifact;

        if (hasMsix) {
          log('Creating MSIX installer...', color: Colors.purple);
          await _runCmd(
            'dart',
            ['run', 'msix:create', '--build-windows=false'],
            projectRoot,
            env: env,
          );

          // MSIX usually outputs to build/windows/runner/Release or build/windows/x64/runner/Release
          // We'll search in a few likely places
          final potentialDirs = [
            Directory(buildDirWin),
            Directory('$projectRoot/build/windows/runner/Release'),
            Directory('$projectRoot/build'),
          ];

          File? srcMsix;
          for (final dir in potentialDirs) {
            if (await dir.exists()) {
              final msixFiles = dir
                  .listSync()
                  .whereType<File>()
                  .where((f) => f.path.toLowerCase().endsWith('.msix'))
                  .toList();
              if (msixFiles.isNotEmpty) {
                srcMsix = msixFiles.first;
                break;
              }
            }
          }

          if (srcMsix != null) {
            final newMsixName =
                '${selectedProject.artifactPrefix}_v$tagName.msix';
            final targetMsix = File('$buildDirWin/$newMsixName');

            if (await targetMsix.exists()) {
              await targetMsix.delete();
            }

            // Copy instead of rename to avoid cross-device link errors if on different drives/partitions (unlikely but safe)
            await srcMsix.copy(targetMsix.path);
            // Try to cleanup source if possible, but not critical
            try {
              await srcMsix.delete();
            } catch (_) {}

            windowsArtifact = targetMsix;
            releasedWindowsName = newMsixName;
            log('MSIX Created & Moving: $newMsixName', color: Colors.green);
          } else {
            log(
              'Error: MSIX build succeeded but file not found!',
              color: Colors.orange,
            );
          }
        }

        // Fallback: ZIP (Portable) if no MSIX
        if (windowsArtifact == null) {
          final zipName = '${selectedProject.artifactPrefix}_v$tagName.zip';
          final targetZip = File('$buildDirWin/$zipName');

          if (!await targetZip.exists()) {
            log('Zipping Windows Release directory...', color: Colors.purple);
            // PowerShell command to zip contents of Release folder
            // Using -Path 'folder\*' avoids including the parent folder itself in the zip
            await _runCmd('powershell', [
              '-Command',
              'Compress-Archive -Path "$buildDirWin\\*" -DestinationPath "${targetZip.path}" -Force',
            ], projectRoot);
          }

          if (await targetZip.exists()) {
            windowsArtifact = targetZip;
            releasedWindowsName = zipName;
            log('Windows ZIP Created: $zipName', color: Colors.green);
          } else {
            log('Error: Windows ZIP creation failed!', color: Colors.red);
          }
        }

        if (windowsArtifact != null && await windowsArtifact.exists()) {
          log('Calculating Windows SHA-256...');
          final bytes = await windowsArtifact.readAsBytes();
          windowsHash = sha256.convert(bytes).toString().toUpperCase();
          log('Windows Hash: $windowsHash', color: Colors.grey);
        }
      }

      // Update update.json
      log('Updating update.json...');
      final updateFile = File('$projectRoot/update.json');
      if (await updateFile.exists()) {
        final jsonContent = await updateFile.readAsString();
        final Map<String, dynamic> jsonMap = jsonDecode(jsonContent);

        // Common fields
        jsonMap['versionName'] = versionName;
        jsonMap['changelog'] = changelog;
        try {
          jsonMap['versionCode'] = int.parse(versionCode);
        } catch (_) {
          jsonMap['versionCode'] = 0;
        }

        // Android fields
        if (apkHash.isNotEmpty) {
          jsonMap['apkUrl'] =
              'https://github.com/${selectedProject.repoOwner}/${selectedProject.repoName}/releases/download/$tagName/$newFilenameApk';
          jsonMap['apkSha256'] = apkHash;
        }

        // Windows fields
        if (windowsHash.isNotEmpty) {
          jsonMap['windowsUrl'] =
              'https://github.com/${selectedProject.repoOwner}/${selectedProject.repoName}/releases/download/$tagName/$releasedWindowsName';
          jsonMap['windowsSha256'] = windowsHash;
        }

        await updateFile.writeAsString(
          JsonEncoder.withIndent('    ').convert(jsonMap),
        );
      }
      _setStep(4, StepStatus.success);

      // 6. Git Push
      _setStep(5, StepStatus.running);
      log('Committing changes...');
      await _runCmd('git', ['add', '.'], projectRoot);
      try {
        await _runCmd('git', [
          'commit',
          '-m',
          'Release $tagName: $changelog',
        ], projectRoot);
      } catch (e) {
        if (e.toString().contains('nothing to commit') ||
            e.toString().contains('working tree clean')) {
          log(
            'Nothing to commit (files already updated).',
            color: Colors.orange,
          );
        } else {
          rethrow;
        }
      }

      log('Updating tags...');
      await Process.run(
        'git',
        ['tag', '-d', tagName],
        workingDirectory: projectRoot,
        runInShell: true,
      );
      await _runCmd('git', ['tag', tagName], projectRoot);

      log('Pushing to remote...', color: Colors.cyan);
      await _runCmd('git', [
        'push',
        'origin',
        selectedProject.branchName,
      ], projectRoot);
      await _runCmd('git', ['push', 'origin', tagName, '--force'], projectRoot);
      _setStep(5, StepStatus.success);

      // 7. GitHub Upload (gh CLI)
      _setStep(6, StepStatus.running);
      log(
        'Creating Release & Uploading Asset via gh CLI...',
        color: Colors.purple,
      );

      // Resolve 'gh' executable path
      String ghExecutable = 'gh';
      if (Platform.isWindows) {
        final defaultGhPath = r'C:\Program Files\GitHub CLI\gh.exe';
        if (await File(defaultGhPath).exists()) {
          ghExecutable = defaultGhPath;
          log('Using found gh CLI: $ghExecutable');
        }
      }

      // Collect all artifacts for upload
      final List<String> uploadAssets = [];

      // APK
      final apkPath =
          '$projectRoot/build/app/outputs/flutter-apk/${selectedProject.artifactPrefix}_v$tagName.apk';
      if (await File(apkPath).exists()) {
        uploadAssets.add(apkPath);
      }

      // Windows (ZIP or MSIX)
      final winDirs = [
        '$projectRoot/build/windows/x64/runner/Release',
        '$projectRoot/build/windows/runner/Release',
      ];
      final winFiles = [
        '${selectedProject.artifactPrefix}_v$tagName.zip',
        '${selectedProject.artifactPrefix}_v$tagName.msix',
      ];

      for (final dir in winDirs) {
        for (final file in winFiles) {
          final path = '$dir/$file';
          if (await File(path).exists()) {
            uploadAssets.add(path);
          }
        }
      }

      if (uploadAssets.isEmpty) {
        log('WARNING: No artifacts found for upload!', color: Colors.orange);
      } else {
        log(
          'Uploading assets: ${uploadAssets.map((p) => p.split('/').last).join(', ')}',
          color: Colors.cyan,
        );

        // Create release (idempotent due to verification, but 'create' handles it well usually)
        await _runCmd(ghExecutable, [
          'release',
          'create',
          tagName,
          ...uploadAssets,
          '--generate-notes',
          '--title',
          releaseTitle,
        ], projectRoot);
      }

      _setStep(6, StepStatus.success);

      log('🎉 RELEASE SEQUENCE COMPLETE!', color: Colors.green);
    } catch (e) {
      log('CRITICAL ERROR: $e', color: Colors.red);
      _setStep(
        stepStatus.indexWhere((s) => s == StepStatus.running),
        StepStatus.error,
      );
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _runCmd(
    String cmd,
    List<String> args,
    String cwd, {
    Map<String, String>? env,
  }) async {
    try {
      // Logic fix: On Windows, runInShell: true invokes cmd.exe.
      // If 'cmd' has spaces (e.g. C:\Program Files\...), cmd.exe breaks unless quoted.
      // PROPER FIX: Use runInShell: false for executables with spaces.
      final bool useShell = Platform.isWindows && cmd.contains(' ')
          ? false
          : true;

      final result = await Process.run(
        cmd,
        args,
        workingDirectory: cwd,
        runInShell: useShell,
        environment: env,
      );
      if (result.exitCode != 0) {
        throw '${result.stderr}\n${result.stdout}';
      }
    } catch (e) {
      log(
        'Direct command failed ("$cmd"): $e. User fallback...',
        color: Colors.orange,
      );
      // Fallback for Windows if direct command fails (often due to PATH issues)
      if (Platform.isWindows) {
        // When running via cmd /c directly, we MUST quote paths with spaces.
        final cmdStr = cmd.contains(' ') ? '"$cmd"' : cmd;
        final result = await Process.run(
          'cmd',
          ['/c', cmdStr, ...args],
          workingDirectory: cwd,
          runInShell: true,
          environment: env,
        );
        if (result.exitCode != 0) {
          throw '${result.stderr}\n${result.stdout}';
        }
      } else {
        rethrow;
      }
    }
  }

  Future<String> _findProjectRoot() async {
    // 1. Try searching upwards from current directory (works if we are inside the project)
    Directory dir = Directory.current;
    for (int i = 0; i < 10; i++) {
      final pubspec = File('${dir.path}/pubspec.yaml');
      if (await pubspec.exists()) {
        final content = await pubspec.readAsString();
        if (content.contains('name: ${selectedProject.pubspecName}')) {
          return dir.path;
        }
      }
      final parent = dir.parent;
      if (dir.path == parent.path) break;
      dir = parent;
    }

    // 2. Try searching for sibling directories (common in ecosystem)
    // Ecosystem root is usually the parent of a_player etc.
    // If we are in a_player/tools/release_manager, we need to go up 3 levels to reach Github/
    dir = Directory.current;
    for (int i = 0; i < 5; i++) {
      final siblingDir = Directory('${dir.path}/${selectedProject.name}');
      if (await siblingDir.exists()) {
        final pubspec = File('${siblingDir.path}/pubspec.yaml');
        if (await pubspec.exists()) {
          final content = await pubspec.readAsString();
          if (content.contains('name: ${selectedProject.pubspecName}')) {
            return siblingDir.path;
          }
        }
      }
      final parent = dir.parent;
      if (dir.path == parent.path) break;
      dir = parent;
    }

    throw 'Could not find project root for ${selectedProject.displayName} (expecting name: ${selectedProject.pubspecName}). Searched up from ${Directory.current.path} and checked sibling folders.';
  }
}
