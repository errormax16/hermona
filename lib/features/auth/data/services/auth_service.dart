import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/entities/user_entity.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA – AuthService (Firebase Auth + Firestore)
// ─────────────────────────────────────────────────────────────────────────────
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _google = GoogleSignIn();

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ── Récupérer les données utilisateur ──────────────────────────────────────
  Future<UserEntity?> fetchUser(String uid) async {
    final doc = await _db.collection(AppConstants.colUsers).doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserEntity.fromJson(doc.data()!, doc.id);
  }

  // ── Inscription ────────────────────────────────────────────────────────────
  Future<UserEntity> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user!;
      await user.updateDisplayName('$firstName $lastName');

      final entity = UserEntity(
        id: user.uid,
        firstName: firstName,
        lastName: lastName,
        email: email,
        createdAt: DateTime.now(),
        termsAccepted: true,
      );

      await _db
          .collection(AppConstants.colUsers)
          .doc(user.uid)
          .set(entity.toJson(), SetOptions(merge: true));

      return entity;

    } on FirebaseAuthException catch (e) {
      print('🔥 Firebase register error: ${e.code} - ${e.message}');
      throw AuthException(
        '${_mapFirebaseError(e.code)} (code: ${e.code})',
      );
    } catch (e) {
      throw AuthException('Erreur inconnue: $e');
    }
  }

  // ── Connexion email/mot de passe ───────────────────────────────────────────
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = await fetchUser(cred.user!.uid);

      // ❗ IMPORTANT : ne pas créer un faux user
      if (user == null) {
        throw const AuthException('Profil utilisateur introuvable');
      }

      return user;

    } on FirebaseAuthException catch (e) {
      print('🔥 Firebase login error: ${e.code} - ${e.message}');
      throw AuthException(
        '${_mapFirebaseError(e.code)} (code: ${e.code})',
      );
    } catch (e) {
      throw AuthException('Erreur inconnue: $e');
    }
  }

  // ── Connexion Google ───────────────────────────────────────────────────────
  Future<UserEntity> signInWithGoogle() async {
    try {
      final gUser = await _google.signIn();
      if (gUser == null) {
        throw const AuthException('Connexion Google annulée');
      }

      final gAuth = await gUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      final user = cred.user!;

      final existing = await fetchUser(user.uid);
      if (existing != null) return existing;

      final parts = (user.displayName ?? '').split(' ');

      final entity = UserEntity(
        id: user.uid,
        firstName: parts.isNotEmpty ? parts.first : '',
        lastName: parts.length > 1 ? parts.last : '',
        email: user.email ?? '',
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
        termsAccepted: true,
      );

      await _db
          .collection(AppConstants.colUsers)
          .doc(user.uid)
          .set(entity.toJson(), SetOptions(merge: true));

      return entity;

    } on FirebaseAuthException catch (e) {
      print('🔥 Google login error: ${e.code} - ${e.message}');
      throw AuthException(
        '${_mapFirebaseError(e.code)} (code: ${e.code})',
      );
    } catch (e) {
      throw AuthException('Erreur inconnue: $e');
    }
  }

  // ── Déconnexion ────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _google.signOut(),
    ]);
  }

  // ── Mot de passe oublié ────────────────────────────────────────────────────
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        '${_mapFirebaseError(e.code)} (code: ${e.code})',
      );
    }
  }

  // ── Mapper les codes d'erreur Firebase ────────────────────────────────────
  String _mapFirebaseError(String code) {
    const map = {
      'email-already-in-use': 'Cet email est déjà utilisé',
      'user-not-found': 'Aucun compte trouvé',
      'wrong-password': 'Mot de passe incorrect',
      'invalid-credential': 'Email ou mot de passe incorrect',
      'weak-password': 'Mot de passe trop faible (min. 6 caractères)',
      'invalid-email': 'Email invalide',
      'too-many-requests': 'Trop de tentatives, réessayez plus tard',
      'network-request-failed': 'Erreur réseau',
    };

    return map[code] ?? 'Erreur d\'authentification';
  }
}