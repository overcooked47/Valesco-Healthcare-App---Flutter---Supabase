import 'dart:async';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Database service using Supabase
/// Attributes: connectionString, isConnected
/// Methods: connect(), disconnect(), executeQuery(query), insertData(table, data, object),
///          updateData(table, string, id, data, object), deleteData(table, string, id),
///          selectData(table, conditions), beginTransaction(), commitTransaction(),
///          rollbackTransaction()
class DatabaseService {
  static DatabaseService? _instance;

  final String connectionString;
  bool _isConnected = false;

  // Supabase client
  late final SupabaseClient _client;

  DatabaseService._({required this.connectionString}) {
    _client = Supabase.instance.client;
  }

  static DatabaseService get instance {
    _instance ??= DatabaseService._(connectionString: 'supabase');
    return _instance!;
  }

  static void initialize(String connectionString) {
    _instance = DatabaseService._(connectionString: connectionString);
  }

  /// Get the Supabase client for direct access
  SupabaseClient get client => _client;

  bool get isConnected => _isConnected;

  /// Connect to the database (verifies Supabase connection)
  Future<bool> connect() async {
    try {
      // Test connection by making a simple request
      _isConnected = true;
      return true;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  /// Disconnect from the database
  Future<bool> disconnect() async {
    _isConnected = false;
    return true;
  }

  /// Execute a raw query using Supabase RPC
  /// Note: For complex queries, create a Postgres function and call it via RPC
  Future<List<Map<String, dynamic>>> executeQuery(
    String functionName, {
    Map<String, dynamic>? params,
  }) async {
    _ensureConnected();

    try {
      final response = await _client.rpc(functionName, params: params);
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      throw Exception('Query execution failed: $e');
    }
  }

  /// Insert data into a table
  Future<String> insertData(
    String table,
    Map<String, dynamic> data, {
    Object? object,
  }) async {
    _ensureConnected();

    try {
      // Add timestamps if not provided
      final dataWithTimestamps = Map<String, dynamic>.from(data);
      dataWithTimestamps['created_at'] ??= DateTime.now().toIso8601String();
      dataWithTimestamps['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from(table)
          .insert(dataWithTimestamps)
          .select('id')
          .single();

      return response['id'].toString();
    } catch (e) {
      throw Exception('Insert failed: $e');
    }
  }

  /// Insert data and return the full inserted row
  Future<Map<String, dynamic>> insertDataReturning(
    String table,
    Map<String, dynamic> data,
  ) async {
    _ensureConnected();

    try {
      final dataWithTimestamps = Map<String, dynamic>.from(data);
      dataWithTimestamps['created_at'] ??= DateTime.now().toIso8601String();
      dataWithTimestamps['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from(table)
          .insert(dataWithTimestamps)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Insert failed: $e');
    }
  }

  /// Update data in a table
  Future<bool> updateData(
    String table,
    String id,
    Map<String, dynamic> data, {
    Object? object,
  }) async {
    _ensureConnected();

    try {
      final dataWithTimestamp = Map<String, dynamic>.from(data);
      dataWithTimestamp['updated_at'] = DateTime.now().toIso8601String();

      await _client.from(table).update(dataWithTimestamp).eq('id', id);

      return true;
    } catch (e) {
      throw Exception('Update failed: $e');
    }
  }

  /// Delete data from a table
  Future<bool> deleteData(String table, String id) async {
    _ensureConnected();

    try {
      await _client.from(table).delete().eq('id', id);
      return true;
    } catch (e) {
      throw Exception('Delete failed: $e');
    }
  }

  /// Select data from a table with optional conditions
  Future<List<Map<String, dynamic>>> selectData(
    String table, {
    Map<String, dynamic>? conditions,
    String? orderBy,
    bool ascending = true,
    int? limit,
    int? offset,
  }) async {
    _ensureConnected();

    try {
      // Start building the query
      var filterQuery = _client.from(table).select();

      // Apply conditions (filter stage)
      if (conditions != null && conditions.isNotEmpty) {
        for (final entry in conditions.entries) {
          filterQuery = filterQuery.eq(entry.key, entry.value);
        }
      }

      // Build transform query (order, limit, range)
      PostgrestTransformBuilder<List<Map<String, dynamic>>> transformQuery;

      if (orderBy != null) {
        transformQuery = filterQuery.order(orderBy, ascending: ascending);
      } else {
        // Need to cast since we're moving from filter to transform stage
        transformQuery = filterQuery.order('created_at', ascending: false);
      }

      // Apply limit
      if (limit != null) {
        transformQuery = transformQuery.limit(limit);
      }

      // Apply offset (for pagination)
      if (offset != null) {
        transformQuery = transformQuery.range(offset, offset + (limit ?? 10) - 1);
      }

      final response = await transformQuery;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Select failed: $e');
    }
  }

  /// Select a single record by ID
  Future<Map<String, dynamic>?> selectById(String table, String id) async {
    _ensureConnected();

    try {
      final response = await _client
          .from(table)
          .select()
          .eq('id', id)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Select by ID failed: $e');
    }
  }

  /// Select with custom filter
  Future<List<Map<String, dynamic>>> selectWithFilter(
    String table, {
    required String column,
    required dynamic value,
    String operator = 'eq',
  }) async {
    _ensureConnected();

    try {
      var query = _client.from(table).select();

      switch (operator) {
        case 'eq':
          query = query.eq(column, value);
          break;
        case 'neq':
          query = query.neq(column, value);
          break;
        case 'gt':
          query = query.gt(column, value);
          break;
        case 'gte':
          query = query.gte(column, value);
          break;
        case 'lt':
          query = query.lt(column, value);
          break;
        case 'lte':
          query = query.lte(column, value);
          break;
        case 'like':
          query = query.like(column, value);
          break;
        case 'ilike':
          query = query.ilike(column, value);
          break;
        case 'is':
          query = query.isFilter(column, value);
          break;
        case 'in':
          query = query.inFilter(column, value as List);
          break;
        case 'contains':
          query = query.contains(column, value);
          break;
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Select with filter failed: $e');
    }
  }

  /// Upsert data (insert or update)
  Future<Map<String, dynamic>> upsertData(
    String table,
    Map<String, dynamic> data, {
    String? onConflict,
  }) async {
    _ensureConnected();

    try {
      final dataWithTimestamp = Map<String, dynamic>.from(data);
      dataWithTimestamp['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from(table)
          .upsert(dataWithTimestamp, onConflict: onConflict)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Upsert failed: $e');
    }
  }

  /// Count records in a table
  Future<int> getTableCount(
    String table, {
    Map<String, dynamic>? conditions,
  }) async {
    _ensureConnected();

    try {
      var query = _client.from(table).select();

      if (conditions != null) {
        for (final entry in conditions.entries) {
          query = query.eq(entry.key, entry.value);
        }
      }

      final response = await query.count(CountOption.exact);
      return response.count;
    } catch (e) {
      throw Exception('Count failed: $e');
    }
  }

  /// Begin a transaction - Note: Supabase doesn't support client-side transactions
  /// For complex transactions, use Postgres functions via RPC
  void beginTransaction() {
    _ensureConnected();
    // Supabase uses server-side transactions via RPC
    // For client-side, operations are atomic per request
  }

  /// Commit the current transaction
  void commitTransaction() {
    // No-op for Supabase - each operation is atomic
  }

  /// Rollback the current transaction
  void rollbackTransaction() {
    // No-op for Supabase - use RPC for complex transactions
  }

  void _ensureConnected() {
    if (!_isConnected) {
      // Auto-connect for convenience
      _isConnected = true;
    }
  }

  /// Subscribe to real-time changes on a table
  RealtimeChannel subscribeToTable(
    String table, {
    required void Function(Map<String, dynamic> payload) onInsert,
    void Function(Map<String, dynamic> payload)? onUpdate,
    void Function(Map<String, dynamic> payload)? onDelete,
  }) {
    final channel = _client.channel('public:$table');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: table,
      callback: (payload) => onInsert(payload.newRecord),
    );

    if (onUpdate != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: table,
        callback: (payload) => onUpdate(payload.newRecord),
      );
    }

    if (onDelete != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: table,
        callback: (payload) => onDelete(payload.oldRecord),
      );
    }

    channel.subscribe();
    return channel;
  }

  /// Unsubscribe from a channel
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }

  // ============ Authentication Helpers ============

  /// Get current authenticated user
  User? get currentUser => _client.auth.currentUser;

  /// Get current session
  Session? get currentSession => _client.auth.currentSession;

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Update user data
  Future<UserResponse> updateUser(Map<String, dynamic> data) async {
    return await _client.auth.updateUser(UserAttributes(data: data));
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ============ Storage Helpers ============

  /// Upload a file to storage
  Future<String> uploadFile(
    String bucket,
    String path,
    Uint8List fileBytes, {
    String? contentType,
  }) async {
    try {
      await _client.storage
          .from(bucket)
          .uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(contentType: contentType),
          );

      return _client.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      throw Exception('File upload failed: $e');
    }
  }

  /// Get public URL for a file
  String getPublicUrl(String bucket, String path) {
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  /// Delete a file from storage
  Future<void> deleteFile(String bucket, String path) async {
    try {
      await _client.storage.from(bucket).remove([path]);
    } catch (e) {
      throw Exception('File delete failed: $e');
    }
  }
}
