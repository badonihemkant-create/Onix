import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await AppDatabase.instance.database;
  final identity = await DeviceIdentity.load();
  final session = await LocalSession.load();

  runApp(
    OffMessApp(
      database: database,
      identity: identity,
      session: session,
    ),
  );
}

/* ============================================================
   APP
   ============================================================ */

class OffMessApp extends StatefulWidget {
  final Database database;
  final DeviceIdentity identity;
  final LocalSession session;

  const OffMessApp({
    super.key,
    required this.database,
    required this.identity,
    required this.session,
  });

  @override
  State<OffMessApp> createState() => _OffMessAppState();
}

class _OffMessAppState extends State<OffMessApp> {
  ThemeMode themeMode = ThemeMode.dark;
  late LocalSession session;

  @override
  void initState() {
    super.initState();
    session = widget.session;
  }

  Future<void> login(LocalProfile profile) async {
    await session.save(profile);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> logout() async {
    await session.logout();

    if (mounted) {
      setState(() {});
    }
  }

  void toggleTheme() {
    setState(() {
      themeMode = themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OffMess by B onix',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: session.loggedIn
          ? HomePage(
              database: widget.database,
              identity: widget.identity,
              profile: session.profile!,
              onLogout: logout,
              onToggleTheme: toggleTheme,
            )
          : LoginPage(
              identity: widget.identity,
              onLogin: login,
            ),
    );
  }
}

/* ============================================================
   THEME
   ============================================================ */

class AppTheme {
  static const purple = Color(0xff8b5cf6);
  static const deepPurple = Color(0xff5b21b6);
  static const pink = Color(0xffd946ef);

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: purple,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xff090611),
      inputDecorationTheme: _inputTheme(true),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: purple,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xfff7f2ff),
      inputDecorationTheme: _inputTheme(false),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  static InputDecorationTheme _inputTheme(bool dark) {
    return InputDecorationTheme(
      filled: true,
      fillColor: dark
          ? Colors.white.withOpacity(0.055)
          : Colors.white.withOpacity(0.75),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: dark
              ? Colors.white.withOpacity(0.10)
              : purple.withOpacity(0.12),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: dark
              ? Colors.white.withOpacity(0.10)
              : purple.withOpacity(0.12),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: purple,
          width: 1.5,
        ),
      ),
    );
  }
}

/* ============================================================
   LIQUID GLASS BACKGROUND
   ============================================================ */

class LiquidBackground extends StatelessWidget {
  final Widget child;

  const LiquidBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? const [
                        Color(0xff08050f),
                        Color(0xff160b27),
                        Color(0xff0d0618),
                      ]
                    : const [
                        Color(0xfffbf8ff),
                        Color(0xffeee5ff),
                        Color(0xfff8f0ff),
                      ],
              ),
            ),
          ),
        ),

        const Positioned(
          left: -100,
          top: -100,
          child: GlowOrb(
            size: 300,
            color: AppTheme.purple,
          ),
        ),

        const Positioned(
          right: -90,
          top: 180,
          child: GlowOrb(
            size: 260,
            color: AppTheme.pink,
          ),
        ),

        const Positioned(
          left: 50,
          bottom: -150,
          child: GlowOrb(
            size: 310,
            color: Color(0xff4f46e5),
          ),
        ),

        SafeArea(
          child: child,
        ),
      ],
    );
  }
}

class GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const GlowOrb({
    super.key,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.22),
              blurRadius: size * 0.55,
              spreadRadius: size * 0.05,
            ),
          ],
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final BorderRadius radius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = const BorderRadius.all(
      Radius.circular(24),
    ),
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            color: Colors.white.withOpacity(
              dark ? 0.055 : 0.52,
            ),
            border: Border.all(
              color: Colors.white.withOpacity(
                dark ? 0.11 : 0.65,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  dark ? 0.20 : 0.06,
                ),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/* ============================================================
   DATABASE
   ============================================================ */

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();

  AppDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final databasesPath = await getDatabasesPath();

    final databasePath = join(
      databasesPath,
      'offmess_by_bonix.db',
    );

    _database = await openDatabase(
      databasePath,
      version: 2,
      onConfigure: (db) async {
        await db.execute(
          'PRAGMA foreign_keys = ON',
        );
      },
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            '''
            ALTER TABLE conversations
            ADD COLUMN avatar_color INTEGER
            ''',
          );
        }
      },
    );

    return _database!;
  }

  static Future<void> _createTables(
    Database db,
  ) async {
    await db.execute(
      '''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        pairing_code TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        avatar_color INTEGER
      )
      ''',
    );

    await db.execute(
      '''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        text TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        is_me INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY(conversation_id)
          REFERENCES conversations(id)
          ON DELETE CASCADE
      )
      ''',
    );

    await db.execute(
      '''
      CREATE INDEX idx_messages_conversation
      ON messages(conversation_id)
      ''',
    );

    await db.execute(
      '''
      CREATE INDEX idx_messages_created
      ON messages(created_at)
      ''',
    );
  }
}

/* ============================================================
   PROFILE
   ============================================================ */

class LocalProfile {
  final String name;
  final String username;
  final String bio;

  const LocalProfile({
    required this.name,
    required this.username,
    required this.bio,
  });
}

class LocalSession {
  final SharedPreferences prefs;

  LocalProfile? profile;

  LocalSession._(
    this.prefs,
  );

  bool get loggedIn {
    return profile != null;
  }

  static Future<LocalSession> load() async {
    final prefs =
        await SharedPreferences.getInstance();

    final session = LocalSession._(
      prefs,
    );

    final loggedIn =
        prefs.getBool('logged_in') ?? false;

    if (loggedIn) {
      final name =
          prefs.getString('profile_name') ?? '';

      if (name.trim().isNotEmpty) {
        session.profile = LocalProfile(
          name: name,
          username:
              prefs.getString('profile_username') ??
                  'user',
          bio:
              prefs.getString('profile_bio') ??
                  'Offline & private.',
        );
      }
    }

    return session;
  }

  Future<void> save(
    LocalProfile profile,
  ) async {
    this.profile = profile;

    await prefs.setBool(
      'logged_in',
      true,
    );

    await prefs.setString(
      'profile_name',
      profile.name,
    );

    await prefs.setString(
      'profile_username',
      profile.username,
    );

    await prefs.setString(
      'profile_bio',
      profile.bio,
    );
  }

  Future<void> logout() async {
    profile = null;

    await prefs.setBool(
      'logged_in',
      false,
    );
  }
}

/* ============================================================
   DEVICE IDENTITY
   ============================================================ */

class DeviceIdentity {
  final String deviceId;
  final String publicIdentity;

  DeviceIdentity({
    required this.deviceId,
    required this.publicIdentity,
  });

  static Future<DeviceIdentity> load() async {
    final prefs =
        await SharedPreferences.getInstance();

    String? deviceId =
        prefs.getString('device_id');

    String? identity =
        prefs.getString('public_identity');

    if (deviceId == null ||
        deviceId.isEmpty) {
      deviceId = const Uuid().v4();

      await prefs.setString(
        'device_id',
        deviceId,
      );
    }

    if (identity == null ||
        identity.isEmpty) {
      final raw =
          '$deviceId-${DateTime.now().microsecondsSinceEpoch}';

      identity = sha256
          .convert(
            utf8.encode(raw),
          )
          .toString();

      await prefs.setString(
        'public_identity',
        identity,
      );
    }

    return DeviceIdentity(
      deviceId: deviceId,
      publicIdentity: identity,
    );
  }

  String get shortId {
    return deviceId.substring(
      0,
      min(8, deviceId.length),
    );
  }

  String get fingerprint {
    return sha256
        .convert(
          utf8.encode(publicIdentity),
        )
        .toString()
        .substring(0, 16)
        .toUpperCase();
  }
}

/* ============================================================
   MODELS
   ============================================================ */

class Conversation {
  final String id;
  final String name;
  final String? pairingCode;
  final int updatedAt;
  final int? avatarColor;

  Conversation({
    required this.id,
    required this.name,
    required this.pairingCode,
    required this.updatedAt,
    required this.avatarColor,
  });

  factory Conversation.fromMap(
    Map<String, dynamic> map,
  ) {
    return Conversation(
      id: map['id'] as String,
      name: map['name'] as String,
      pairingCode:
          map['pairing_code'] as String?,
      updatedAt:
          map['updated_at'] as int,
      avatarColor:
          map['avatar_color'] as int?,
    );
  }
}

class LocalMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final int createdAt;
  final bool isMe;

  LocalMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    required this.isMe,
  });

  factory LocalMessage.fromMap(
    Map<String, dynamic> map,
  ) {
    return LocalMessage(
      id: map['id'] as String,
      conversationId:
          map['conversation_id'] as String,
      senderId:
          map['sender_id'] as String,
      text: map['text'] as String,
      createdAt:
          map['created_at'] as int,
      isMe: map['is_me'] == 1,
    );
  }
}

/* ============================================================
   CHAT REPOSITORY
   ============================================================ */

class ChatRepository {
  final Database db;

  ChatRepository(this.db);

  Future<List<Conversation>>
      getConversations() async {
    final result = await db.query(
      'conversations',
      orderBy: 'updated_at DESC',
    );

    return result
        .map(
          Conversation.fromMap,
        )
        .toList();
  }

  Future<Conversation?> getConversation(
    String id,
  ) async {
    final result = await db.query(
      'conversations',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return Conversation.fromMap(
      result.first,
    );
  }

  Future<Conversation> createConversation(
    String name,
  ) async {
    final now =
        DateTime.now().millisecondsSinceEpoch;

    final id = const Uuid().v4();

    final pairingCode =
        Random.secure()
            .nextInt(1000000)
            .toString()
            .padLeft(6, '0');

    final colors = [
      AppTheme.purple.value,
      const Color(0xffec4899).value,
      const Color(0xff6366f1).value,
      const Color(0xffa855f7).value,
    ];

    final avatarColor =
        colors[
          Random().nextInt(
            colors.length,
          )
        ];

    await db.insert(
      'conversations',
      {
        'id': id,
        'name': name,
        'pairing_code': pairingCode,
        'created_at': now,
        'updated_at': now,
        'avatar_color': avatarColor,
      },
    );

    return Conversation(
      id: id,
      name: name,
      pairingCode: pairingCode,
      updatedAt: now,
      avatarColor: avatarColor,
    );
  }

  Future<List<LocalMessage>> getMessages(
    String conversationId,
  ) async {
    final result = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at ASC',
    );

    return result
        .map(
          LocalMessage.fromMap,
        )
        .toList();
  }

  Future<void> addMessage({
    required String conversationId,
    required String senderId,
    required String text,
    bool isMe = true,
  }) async {
    final now =
        DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      'messages',
      {
        'id': const Uuid().v4(),
        'conversation_id':
            conversationId,
        'sender_id': senderId,
        'text': text,
        'created_at': now,
        'is_me': isMe ? 1 : 0,
      },
    );

    await db.update(
      'conversations',
      {
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  Future<void> deleteMessage(
    String id,
  ) async {
    await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearConversation(
    String id,
  ) async {
    await db.delete(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteConversation(
    String id,
  ) async {
    await db.delete(
      'conversations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<LocalMessage>>
      searchMessages(
    String query,
  ) async {
    final result = await db.query(
      'messages',
      where: 'text LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'created_at DESC',
    );

    return result
        .map(
          LocalMessage.fromMap,
        )
        .toList();
  }
}

/* ============================================================
   LOGIN PAGE
   ============================================================ */

class LoginPage extends StatefulWidget {
  final DeviceIdentity identity;
  final Future<void> Function(
    LocalProfile profile,
  ) onLogin;

  const LoginPage({
    super.key,
    required this.identity,
    required this.onLogin,
  });

  @override
  State<LoginPage> createState() =>
      _LoginPageState();
}

class _LoginPageState
    extends State<LoginPage> {
  final formKey =
      GlobalKey<FormState>();

  final nameController =
      TextEditingController();

  final usernameController =
      TextEditingController();

  final bioController =
      TextEditingController(
    text: 'Offline & private.',
  );

  bool loading = false;

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    bioController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!(formKey.currentState
            ?.validate() ??
        false)) {
      return;
    }

    setState(() {
      loading = true;
    });

    await widget.onLogin(
      LocalProfile(
        name:
            nameController.text.trim(),
        username:
            usernameController.text.trim(),
        bio:
            bioController.text.trim().isEmpty
                ? 'Offline & private.'
                : bioController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidBackground(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 480,
              ),
              child: GlassCard(
                padding:
                    const EdgeInsets.all(28),
                radius:
                    BorderRadius.circular(32),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Logo(
                            size: 58,
                          ),
                          const SizedBox(
                            width: 14,
                          ),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  'OffMess',
                                  style:
                                      TextStyle(
                                    fontSize: 26,
                                    fontWeight:
                                        FontWeight
                                            .w900,
                                  ),
                                ),
                                Text(
                                  'by B onix',
                                  style:
                                      TextStyle(
                                    color:
                                        AppTheme
                                            .purple,
                                    fontWeight:
                                        FontWeight
                                            .w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons
                                .lock_outline_rounded,
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 32,
                      ),

                      const Text(
                        'Welcome',
                        style:
                            TextStyle(
                          fontSize: 32,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        'Create your local OffMess profile. No online account is required.',
                        style:
                            Theme.of(context)
                                .textTheme
                                .bodyMedium,
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      TextFormField(
                        controller:
                            nameController,
                        textCapitalization:
                            TextCapitalization
                                .words,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Display name',
                          prefixIcon:
                              Icon(
                            Icons
                                .person_outline_rounded,
                          ),
                        ),
                        validator: (value) {
                          if ((value ?? '')
                                  .trim()
                                  .length <
                              2) {
                            return 'Enter at least 2 characters';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      TextFormField(
                        controller:
                            usernameController,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Username',
                          prefixText: '@ ',
                          prefixIcon:
                              Icon(
                            Icons
                                .alternate_email_rounded,
                          ),
                        ),
                        validator: (value) {
                          final username =
                              (value ?? '')
                                  .trim();

                          if (username
                                  .length <
                              3) {
                            return 'Minimum 3 characters';
                          }

                          if (!RegExp(
                            r'^[A-Za-z0-9_]+$',
                          ).hasMatch(
                            username,
                          )) {
                            return 'Use letters, numbers and _ only';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      TextFormField(
                        controller:
                            bioController,
                        maxLength: 80,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Bio',
                          prefixIcon:
                              Icon(
                            Icons
                                .notes_rounded,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      FilledButton(
                        onPressed:
                            loading
                                ? null
                                : submit,
                        style:
                            FilledButton.styleFrom(
                          minimumSize:
                              const Size
                                  .fromHeight(
                            54,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              18,
                            ),
                          ),
                        ),
                        child:
                            loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                    ),
                                  )
                                : const Text(
                                    'Enter OffMess',
                                    style:
                                        TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .w800,
                                    ),
                                  ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      Center(
                        child: Text(
                          'Device ${widget.identity.shortId}',
                          style:
                              Theme.of(
                                context,
                              )
                                  .textTheme
                                  .bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ============================================================
   HOME PAGE
   ============================================================ */

class HomePage extends StatefulWidget {
  final Database database;
  final DeviceIdentity identity;
  final LocalProfile profile;
  final Future<void> Function() onLogout;
  final VoidCallback onToggleTheme;

  const HomePage({
    super.key,
    required this.database,
    required this.identity,
    required this.profile,
    required this.onLogout,
    required this.onToggleTheme,
  });

  @override
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState
    extends State<HomePage> {
  late final ChatRepository repository;

  List<Conversation> conversations = [];

  bool loading = true;

  String filter = '';

  @override
  void initState() {
    super.initState();

    repository =
        ChatRepository(
      widget.database,
    );

    loadConversations();
  }

  Future<void> loadConversations() async {
    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    final result =
        await repository
            .getConversations();

    if (!mounted) {
      return;
    }

    setState(() {
      conversations = result;
      loading = false;
    });
  }

  Future<void> createChat() async {
    final controller =
        TextEditingController();

    final name =
        await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text(
            'New chat',
          ),
          content:
              TextField(
            controller:
                controller,
            autofocus: true,
            textCapitalization:
                TextCapitalization
                    .words,
            decoration:
                const InputDecoration(
              labelText:
                  'Contact / chat name',
              hintText:
                  'Example: Rahul',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child:
                  const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                final value =
                    controller
                        .text
                        .trim();

                if (value
                    .isEmpty) {
                  return;
                }

                Navigator.pop(
                  context,
                  value,
                );
              },
              child:
                  const Text(
                'Create',
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null ||
        name.trim().isEmpty) {
      return;
    }

    final chat =
        await repository
            .createConversation(
      name.trim(),
    );

    await loadConversations();

    if (!mounted) {
      return;
    }

    openConversation(
      chat,
    );
  }

  Future<void> openConversation(
    Conversation conversation,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChatPage(
          repository:
              repository,
          conversation:
              conversation,
          identity:
              widget.identity,
          profile:
              widget.profile,
        ),
      ),
    );

    loadConversations();
  }

  Future<void> deleteConversation(
    Conversation conversation,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text(
            'Delete chat?',
          ),
          content:
              Text(
            'Delete "${conversation.name}" and all its messages?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    Colors.red,
              ),
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child:
                  const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed ==
        true) {
      await repository
          .deleteConversation(
        conversation.id,
      );

      await loadConversations();
    }
  }

  Future<void> showProfile() async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return ProfileSheet(
          profile:
              widget.profile,
          identity:
              widget.identity,
          onLogout:
              widget.onLogout,
        );
      },
    );
  }

  Future<void> searchMessages() async {
    final controller =
        TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text(
            'Search messages',
          ),
          content:
              TextField(
            controller:
                controller,
            autofocus: true,
            decoration:
                const InputDecoration(
              hintText:
                  'Search text...',
              prefixIcon:
                  Icon(
                Icons
                    .search_rounded,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child:
                  const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () async {
                final query =
                    controller
                        .text
                        .trim();

                if (query
                    .isEmpty) {
                  return;
                }

                Navigator.pop(
                  context,
                );

                final results =
                    await repository
                        .searchMessages(
                  query,
                );

                if (!mounted) {
                  return;
                }

                showSearchResults(
                  query,
                  results,
                );
              },
              child:
                  const Text(
                'Search',
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  void showSearchResults(
    String query,
    List<LocalMessage> messages,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SizedBox(
          height:
              MediaQuery.of(
                    context,
                  ).size.height *
                  0.75,
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.all(
                  18,
                ),
                child: Text(
                  'Results for "$query"',
                  style:
                      const TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
              const Divider(
                height: 1,
              ),
              Expanded(
                child:
                    messages.isEmpty
                        ? const Center(
                            child:
                                Text(
                              'No messages found',
                            ),
                          )
                        : ListView
                            .builder(
                            padding:
                                const EdgeInsets
                                    .all(
                              16,
                            ),
                            itemCount:
                                messages
                                    .length,
                            itemBuilder:
                                (
                              context,
                              index,
                            ) {
                              final message =
                                  messages[
                                      index];

                              return ListTile(
                                leading:
                                    CircleAvatar(
                                  child:
                                      Icon(
                                    message.isMe
                                        ? Icons
                                            .arrow_upward_rounded
                                        : Icons
                                            .arrow_downward_rounded,
                                  ),
                                ),
                                title:
                                    Text(
                                  message.text,
                                ),
                                subtitle:
                                    Text(
                                  DateFormat(
                                    'dd MMM, HH:mm',
                                  ).format(
                                    DateTime
                                        .fromMillisecondsSinceEpoch(
                                      message
                                          .createdAt,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final visible =
        conversations
            .where(
              (chat) => chat.name
                  .toLowerCase()
                  .contains(
                    filter
                        .toLowerCase(),
                  ),
            )
            .toList();

    return Scaffold(
      body:
          LiquidBackground(
        child:
            Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets
                      .fromLTRB(
                18,
                10,
                12,
                8,
              ),
              child:
                  Row(
                children: [
                  const Logo(
                    size: 48,
                  ),
                  const SizedBox(
                    width: 11,
                  ),
                  const Expanded(
                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          'OffMess',
                          style:
                              TextStyle(
                            fontSize:
                                21,
                            fontWeight:
                                FontWeight
                                    .w900,
                          ),
                        ),
                        Text(
                          'Offline • local • private',
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed:
                        searchMessages,
                    icon:
                        const Icon(
                      Icons
                          .search_rounded,
                    ),
                  ),
                  IconButton(
                    onPressed:
                        widget
                            .onToggleTheme,
                    icon:
                        const Icon(
                      Icons
                          .brightness_6_rounded,
                    ),
                  ),
                  ProfileAvatar(
                    name:
                        widget.profile.name,
                    radius: 21,
                    onTap:
                        showProfile,
                  ),
                ],
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets
                      .fromLTRB(
                18,
                3,
                18,
                10,
              ),
              child:
                  TextField(
                onChanged:
                    (value) {
                  setState(() {
                    filter =
                        value;
                  });
                },
                decoration:
                    const InputDecoration(
                  hintText:
                      'Filter chats...',
                  prefixIcon:
                      Icon(
                    Icons
                        .tune_rounded,
                  ),
                  suffixIcon:
                      Icon(
                    Icons
                        .search_rounded,
                  ),
                ),
              ),
            ),

            Expanded(
              child:
                  loading
                      ? const Center(
                          child:
                              CircularProgressIndicator(),
                        )
                      : visible
                              .isEmpty
                          ? _EmptyChats(
                              onCreate:
                                  createChat,
                            )
                          : RefreshIndicator(
                              onRefresh:
                                  loadConversations,
                              child:
                                  ListView
                                      .separated(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(
                                  18,
                                  5,
                                  18,
                                  100,
                                ),
                                itemCount:
                                    visible
                                        .length,
                                separatorBuilder:
                                    (
                                  context,
                                  index,
                                ) =>
                                        const SizedBox(
                                  height:
                                      9,
                                ),
                                itemBuilder:
                                    (
                                  context,
                                  index,
                                ) {
                                  final chat =
                                      visible[
                                          index];

                                  final color =
                                      chat.avatarColor ==
                                              null
                                          ? AppTheme
                                              .purple
                                          : Color(
                                              chat.avatarColor!,
                                            );

                                  return Dismissible(
                                    key:
                                        ValueKey(
                                      chat.id,
                                    ),
                                    direction:
                                        DismissDirection
                                            .endToStart,
                                    confirmDismiss:
                                        (_) async {
                                      await deleteConversation(
                                        chat,
                                      );
                                      return false;
                                    },
                                    background:
                                        Container(
                                      alignment:
                                          Alignment
                                              .centerRight,
                                      padding:
                                          const EdgeInsets
                                              .only(
                                        right:
                                            22,
                                      ),
                                      decoration:
                                          BoxDecoration(
                                        color: Colors
                                            .red
                                            .withOpacity(
                                          .18,
                                        ),
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          22,
                                        ),
                                      ),
                                      child:
                                          const Icon(
                                        Icons
                                            .delete_outline_rounded,
                                        color:
                                            Colors.red,
                                      ),
                                    ),
                                    child:
                                        GlassCard(
                                      padding:
                                          EdgeInsets
                                              .zero,
                                      radius:
                                          BorderRadius
                                              .circular(
                                        22,
                                      ),
                                      child:
                                          ListTile(
                                        onTap:
                                            () {
                                          openConversation(
                                            chat,
                                          );
                                        },
                                        contentPadding:
                                            const EdgeInsets
                                                .symmetric(
                                          horizontal:
                                              14,
                                          vertical:
                                              8,
                                        ),
                                        leading:
                                            CircleAvatar(
                                          radius:
                                              27,
                                          backgroundColor:
                                              color.withOpacity(
                                            .18,
                                          ),
                                          child:
                                              Text(
                                            chat
                                                .name
                                                .characters
                                                .first
                                                .toUpperCase(),
                                            style:
                                                TextStyle(
                                              color:
                                                  color,
                                              fontWeight:
                                                  FontWeight
                                                      .w900,
                                            ),
                                          ),
                                        ),
                                        title:
                                            Text(
                                          chat
                                              .name,
                                          style:
                                              const TextStyle(
                                            fontWeight:
                                                FontWeight
                                                    .w800,
                                          ),
                                        ),
                                        subtitle:
                                            Text(
                                          'Pairing code • ${chat.pairingCode ?? "—"}',
                                        ),
                                        trailing:
                                            const Icon(
                                          Icons
                                              .chevron_right_rounded,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            createChat,
        icon:
            const Icon(
          Icons
              .chat_bubble_outline_rounded,
        ),
        label:
            const Text(
          'New chat',
        ),
      ),
    );
  }
}

/* ============================================================
   EMPTY CHATS
   ============================================================ */

class _EmptyChats extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyChats({
    required this.onCreate,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child:
          Padding(
        padding:
            const EdgeInsets.all(
          30,
        ),
        child:
            GlassCard(
          child:
              Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons
                    .forum_outlined,
                size:
                    50,
              ),
              const SizedBox(
                height:
                    13,
              ),
              const Text(
                'No chats yet',
                style:
                    TextStyle(
                  fontSize:
                      21,
                  fontWeight:
                      FontWeight
                          .w800,
                ),
              ),
              const SizedBox(
                height:
                    8,
              ),
              const Text(
                'Create your first local conversation.',
                textAlign:
                    TextAlign
                        .center,
              ),
              const SizedBox(
                height:
                    18,
              ),
              FilledButton.icon(
                onPressed:
                    onCreate,
                icon:
                    const Icon(
                  Icons.add_rounded,
                ),
                label:
                    const Text(
                  'New chat',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ============================================================
   CHAT PAGE
   ============================================================ */

class ChatPage extends StatefulWidget {
  final ChatRepository repository;
  final Conversation conversation;
  final DeviceIdentity identity;
  final LocalProfile profile;

  const ChatPage({
    super.key,
    required this.repository,
    required this.conversation,
    required this.identity,
    required this.profile,
  });

  @override
  State<ChatPage> createState() =>
      _ChatPageState();
}

class _ChatPageState
    extends State<ChatPage> {
  final messageController =
      TextEditingController();

  final scrollController =
      ScrollController();

  List<LocalMessage> messages = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();

    loadMessages();
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();

    super.dispose();
  }

  Future<void> loadMessages() async {
    final result =
        await widget.repository
            .getMessages(
      widget.conversation.id,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      messages = result;
      loading = false;
    });

    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        if (scrollController
            .hasClients) {
          scrollController.jumpTo(
            scrollController
                .position
                .maxScrollExtent,
          );
        }
      },
    );
  }

  Future<void> sendMessage() async {
    final text =
        messageController
            .text
            .trim();

    if (text.isEmpty) {
      return;
    }

    messageController.clear();

    await widget.repository
        .addMessage(
      conversationId:
          widget.conversation.id,
      senderId:
          widget.identity.deviceId,
      text: text,
    );

    await loadMessages();
  }

  Future<void> clearMessages() async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text(
            'Clear messages?',
          ),
          content:
              const Text(
            'All messages in this local chat will be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child:
                  const Text(
                'Clear',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed ==
        true) {
      await widget.repository
          .clearConversation(
        widget.conversation.id,
      );

      await loadMessages();
    }
  }

  Future<void> deleteMessage(
    LocalMessage message,
  ) async {
    await widget.repository
        .deleteMessage(
      message.id,
    );

    await loadMessages();
  }

  void copyPairingCode() {
    final code =
        widget.conversation
            .pairingCode;

    if (code == null ||
        code.isEmpty) {
      return;
    }

    Clipboard.setData(
      ClipboardData(
        text: code,
      ),
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content:
            Text(
          'Pairing code copied',
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final color =
        widget.conversation
                    .avatarColor ==
                null
            ? AppTheme.purple
            : Color(
                widget.conversation
                    .avatarColor!,
              );

    return Scaffold(
      body:
          LiquidBackground(
        child:
            Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets
                      .fromLTRB(
                5,
                6,
                7,
                7,
              ),
              child:
                  Row(
                children: [
                  IconButton(
                    onPressed:
                        () {
                      Navigator.pop(
                        context,
                      );
                    },
                    icon:
                        const Icon(
                      Icons
                          .arrow_back_rounded,
                    ),
                  ),

                  CircleAvatar(
                    radius:
                        21,
                    backgroundColor:
                        color.withOpacity(
                      .18,
                    ),
                    child:
                        Text(
                      widget
                          .conversation
                          .name
                          .characters
                          .first
                          .toUpperCase(),
                      style:
                          TextStyle(
                        color:
                            color,
                        fontWeight:
                            FontWeight
                                .w900,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width:
                        10,
                  ),

                  Expanded(
                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          widget
                              .conversation
                              .name,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .w900,
                          ),
                        ),
                        Text(
                          'Local • ${widget.conversation.pairingCode ?? "unpaired"}',
                          style:
                              Theme.of(
                                context,
                              )
                                  .textTheme
                                  .bodySmall,
                        ),
                      ],
                    ),
                  ),

                  PopupMenuButton<
                      String>(
                    onSelected:
                        (value) {
                      if (value ==
                          'copy') {
                        copyPairingCode();
                      } else if (value ==
                          'clear') {
                        clearMessages();
                      }
                    },
                    itemBuilder:
                        (context) {
                      return const [
                        PopupMenuItem(
                          value:
                              'copy',
                          child:
                              Text(
                            'Copy pairing code',
                          ),
                        ),
                        PopupMenuItem(
                          value:
                              'clear',
                          child:
                              Text(
                            'Clear messages',
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child:
                  loading
                      ? const Center(
                          child:
                              CircularProgressIndicator(),
                        )
                      : messages
                              .isEmpty
                          ? _EmptyChat(
                              pairingCode:
                                  widget
                                      .conversation
                                      .pairingCode,
                            )
                          : ListView
                              .builder(
                              controller:
                                  scrollController,
                              padding:
                                  const EdgeInsets
                                      .fromLTRB(
                                14,
                                8,
                                14,
                                14,
                              ),
                              itemCount:
                                  messages
                                      .length,
                              itemBuilder:
                                  (
                                context,
                                index,
                              ) {
                                final message =
                                    messages[
                                        index];

                                return MessageBubble(
                                  message:
                                      message,
                                  onDelete:
                                      () {
                                    deleteMessage(
                                      message,
                                    );
                                  },
                                );
                              },
                            ),
            ),

            Padding(
              padding:
                  const EdgeInsets
                      .fromLTRB(
                10,
                5,
                10,
                10,
              ),
              child:
                  Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .end,
                children: [
                  Expanded(
                    child:
                        GlassCard(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal:
                            7,
                      ),
                      radius:
                          BorderRadius
                              .circular(
                        26,
                      ),
                      child:
                          TextField(
                        controller:
                            messageController,
                        minLines:
                            1,
                        maxLines:
                            5,
                        textCapitalization:
                            TextCapitalization
                                .sentences,
                        decoration:
                            const InputDecoration(
                          hintText:
                              'Write a message...',
                          border:
                              InputBorder
                                  .none,
                          filled:
                              false,
                          contentPadding:
                              EdgeInsets
                                  .symmetric(
                            horizontal:
                                10,
                            vertical:
                                12,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width:
                        8,
                  ),

                  Material(
                    color:
                        AppTheme
                            .purple,
                    borderRadius:
                        BorderRadius
                            .circular(
                      22,
                    ),
                    child:
                        InkWell(
                      onTap:
                          sendMessage,
                      borderRadius:
                          BorderRadius
                              .circular(
                        22,
                      ),
                      child:
                          const SizedBox(
                        width:
                            54,
                        height:
                            54,
                        child:
                            Icon(
                          Icons
                              .send_rounded,
                          color:
                              Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================================================
   EMPTY CHAT
   ============================================================ */

class _EmptyChat
    extends StatelessWidget {
  final String? pairingCode;

  const _EmptyChat({
    required this.pairingCode,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child:
          Padding(
        padding:
            const EdgeInsets.all(
          25,
        ),
        child:
            GlassCard(
          child:
              Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons
                    .lock_outline_rounded,
                size:
                    46,
              ),
              const SizedBox(
                height:
                    12,
              ),
              const Text(
                'Private local chat',
                style:
                    TextStyle(
                  fontSize:
                      19,
                  fontWeight:
                      FontWeight
                          .w800,
                ),
              ),
              const SizedBox(
                height:
                    8,
              ),
              const Text(
                'Your messages are currently stored locally on this device.',
                textAlign:
                    TextAlign
                        .center,
              ),
              if (pairingCode !=
                  null) ...[
                const SizedBox(
                  height:
                      15,
                ),
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal:
                        18,
                    vertical:
                        10,
                  ),
                  decoration:
                      BoxDecoration(
                    color: AppTheme
                        .purple
                        .withOpacity(
                      .14,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      15,
                    ),
                  ),
                  child:
                      Text(
                    'Pairing code: $pairingCode',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight
                              .w800,
                      letterSpacing:
                          1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/* ============================================================
   MESSAGE BUBBLE
   ============================================================ */

class MessageBubble
    extends StatelessWidget {
  final LocalMessage message;
  final VoidCallback onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    required this.onDelete,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final time =
        DateFormat(
      'HH:mm',
    ).format(
      DateTime
          .fromMillisecondsSinceEpoch(
        message.createdAt,
      ),
    );

    return Align(
      alignment:
          message.isMe
              ? Alignment.centerRight
              : Alignment.centerLeft,
      child:
          GestureDetector(
        onLongPress:
            onDelete,
        child:
            Container(
          constraints:
              BoxConstraints(
            maxWidth:
                MediaQuery.of(
                      context,
                    ).size.width *
                    0.78,
          ),
          margin:
              const EdgeInsets
                  .only(
            bottom:
                8,
          ),
          padding:
              const EdgeInsets
                  .fromLTRB(
            15,
            11,
            12,
            7,
          ),
          decoration:
              BoxDecoration(
            gradient:
                message.isMe
                    ? const LinearGradient(
                        colors: [
                          Color(
                            0xff8b5cf6,
                          ),
                          Color(
                            0xff6d28d9,
                          ),
                        ],
                      )
                    : null,
            color:
                message.isMe
                    ? null
                    : Theme.of(
                        context,
                      )
                            .colorScheme
                            .surfaceContainerHighest,
            borderRadius:
                BorderRadius.only(
              topLeft:
                  const Radius
                      .circular(
                20,
              ),
              topRight:
                  const Radius
                      .circular(
                20,
              ),
              bottomLeft:
                  Radius.circular(
                message.isMe
                    ? 20
                    : 5,
              ),
              bottomRight:
                  Radius.circular(
                message.isMe
                    ? 5
                    : 20,
              ),
            ),
          ),
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .end,
            children: [
              Align(
                alignment:
                    Alignment
                        .centerLeft,
                child:
                    Text(
                  message.text,
                  style:
                      const TextStyle(
                    fontSize:
                        15.5,
                    height:
                        1.35,
                  ),
                ),
              ),
              const SizedBox(
                height:
                    3,
              ),
              Text(
                time,
                style:
                    TextStyle(
                  fontSize:
                      10,
                  color:
                      Colors.white
                          .withOpacity(
                    .65,
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

/* ============================================================
   PROFILE SHEET
   ============================================================ */

class ProfileSheet
    extends StatelessWidget {
  final LocalProfile profile;
  final DeviceIdentity identity;
  final Future<void> Function()
      onLogout;

  const ProfileSheet({
    super.key,
    required this.profile,
    required this.identity,
    required this.onLogout,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return SafeArea(
      child:
          Padding(
        padding:
            const EdgeInsets
                .fromLTRB(
          20,
          6,
          20,
          26,
        ),
        child:
            Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            ProfileAvatar(
              name:
                  profile.name,
              radius:
                  38,
            ),

            const SizedBox(
              height:
                  11,
            ),

            Text(
              profile.name,
              style:
                  const TextStyle(
                fontSize:
                    23,
                fontWeight:
                    FontWeight
                        .w900,
              ),
            ),

            Text(
              '@${profile.username}',
              style:
                  const TextStyle(
                color:
                    AppTheme
                        .purple,
                fontWeight:
                    FontWeight
                        .w700,
              ),
            ),

            const SizedBox(
              height:
                  6,
            ),

            Text(
              profile.bio,
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(
              height:
                  18,
            ),

            GlassCard(
              radius:
                  BorderRadius
                      .circular(
                18,
              ),
              child:
                  Column(
                children: [
                  ProfileInfo(
                    icon:
                        Icons
                            .smartphone_rounded,
                    title:
                        'Device ID',
                    value:
                        identity
                            .shortId,
                  ),
                  const Divider(
                    height:
                        20,
                  ),
                  ProfileInfo(
                    icon:
                        Icons
                            .fingerprint_rounded,
                    title:
                        'Identity fingerprint',
                    value:
                        identity
                            .fingerprint,
                  ),
                ],
              ),
            ),

            const SizedBox(
              height:
                  10,
            ),

            ListTile(
              leading:
                  const Icon(
                Icons
                    .logout_rounded,
              ),
              title:
                  const Text(
                'Log out locally',
              ),
              subtitle:
                  const Text(
                'Your chats will remain on this device',
              ),
              onTap:
                  () async {
                Navigator.pop(
                  context,
                );

                await onLogout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileInfo
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const ProfileInfo({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size:
              20,
        ),
        const SizedBox(
          width:
              12,
        ),
        Expanded(
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight
                          .w700,
                ),
              ),
              SelectableText(
                value,
                style:
                    Theme.of(
                      context,
                    )
                        .textTheme
                        .bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/* ============================================================
   PROFILE AVATAR
   ============================================================ */

class ProfileAvatar
    extends StatelessWidget {
  final String name;
  final double radius;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    required this.name,
    this.radius = 24,
    this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final trimmed =
        name.trim();

    final letter =
        trimmed.isEmpty
            ? '?'
            : trimmed
                .characters
                .first
                .toUpperCase();

    final avatar =
        CircleAvatar(
      radius:
          radius,
      backgroundColor:
          AppTheme.purple
              .withOpacity(
        .18,
      ),
      child:
          Text(
        letter,
        style:
            TextStyle(
          color:
              Theme.of(
            context,
          )
                  .colorScheme
                  .primary,
          fontSize:
              radius *
                  .62,
          fontWeight:
              FontWeight
                  .w900,
        ),
      ),
    );

    if (onTap == null) {
      return avatar;
    }

    return GestureDetector(
      onTap:
          onTap,
      child:
          avatar,
    );
  }
}

/* ============================================================
   LOGO
   ============================================================ */

class Logo
    extends StatelessWidget {
  final double size;

  const Logo({
    super.key,
    required this.size,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          size,
      height:
          size,
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius
                .circular(
          size *
              .28,
        ),
        gradient:
            const LinearGradient(
          begin:
              Alignment
                  .topLeft,
          end:
              Alignment
                  .bottomRight,
          colors: [
            Color(
              0xffc084fc,
            ),
            Color(
              0xff7c3aed,
            ),
            Color(
              0xff4c1d95,
            ),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme
                    .purple
                    .withOpacity(
              .28,
            ),
            blurRadius:
                20,
          ),
        ],
      ),
      child:
          Icon(
        Icons
            .forum_rounded,
        color:
            Colors.white,
        size:
            size *
                .52,
      ),
    );
  }
}
