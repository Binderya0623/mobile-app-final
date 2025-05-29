// lib/providers/global_provider.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider, PhoneAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import '../repository/repository.dart';
import '../services/httpService.dart';

/// A ChangeNotifier that handles:
///  1. Firebase initialization & Auth state
///  2. Fetching products from fakestoreapi
///  3. Cart, Favorites & Reviews in Firestore
///  4. Push notifications via Firebase Messaging
class GlobalProvider extends ChangeNotifier {
  // ─────────────────────────────────────────────────────────────────────────────
  // Firebase Auth & Firestore
  // ─────────────────────────────────────────────────────────────────────────────
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firebase Messaging
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // ─────────────────────────────────────────────────────────────────────────────
  // Application State Fields
  // ─────────────────────────────────────────────────────────────────────────────

  User? _firebaseUser;
  User? get firebaseUser => _firebaseUser;
  bool get isLoggedIn => _firebaseUser != null;

  UserModel? _currentUserModel;
  UserModel? get currentUserModel => _currentUserModel;

  List<ProductModel> _products = [];
  List<ProductModel> get products => _products;

  List<ProductModel> _cartItems = [];
  List<ProductModel> get cartItems => _cartItems;

  List<ProductModel> _favorites = [];
  List<ProductModel> get favorites => _favorites;

  Map<int, int> _quantities = {}; // productId → quantity
  int getQuantity(ProductModel p) => _quantities[p.id!] ?? 1;

  List<ReviewModel> _currentProductReviews = [];
  List<ReviewModel> get currentProductReviews => _currentProductReviews;

  String? _messagingToken;
  String? get messagingToken => _messagingToken;

  bool _busy = false;
  bool get busy => _busy;

  String? _error;
  String? get error => _error;

  // ─────────────────────────────────────────────────────────────────────────────
  // Constructor
  // ─────────────────────────────────────────────────────────────────────────────

  GlobalProvider() {
    _initializeFirebase();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Initialization
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _initializeFirebase() async {
    _busy = true;
    notifyListeners();

    // 1) Initialize Firebase Core
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2) Listen to auth state changes
    _auth.userChanges().listen((user) async {
      _firebaseUser = user;
      if (_firebaseUser != null) {
        // User signed in or already signed in
        await _createOrLoadUserFirestoreDoc();
        await _loadUserDataFromFirestore();
        await _configureFirebaseMessaging();
      } else {
        // User signed out
        _clearLocalData();
      }
      notifyListeners();
    });

    _busy = false;
    notifyListeners();
  }

  Future<void> _createOrLoadUserFirestoreDoc() async {
    if (_firebaseUser == null) return;

    final uid = _firebaseUser!.uid;
    final userDocRef = _firestore.collection('users').doc(uid);
    final snapshot = await userDocRef.get();

    if (snapshot.exists) {
      // Load existing user document into UserModel
      _currentUserModel = UserModel.fromMap(snapshot.data()!);
    } else {
      // Create new user document
      final newUserModel = UserModel(
        uid: _firebaseUser!.uid,
        email: _firebaseUser!.email!,
        displayName: _firebaseUser!.displayName ?? '',
        photoUrl: _firebaseUser!.photoURL ?? '',
      );
      await userDocRef.set(newUserModel.toMap());
      _currentUserModel = newUserModel;
    }
  }

  Future<void> _configureFirebaseMessaging() async {
    // 1) Request permissions (iOS)
    await _firebaseMessaging.requestPermission();

    // 2) Get FCM token
    _messagingToken = await _firebaseMessaging.getToken();
    if (_messagingToken != null && _firebaseUser != null) {
      // Save token into Firestore under users collection
      await _firestore
          .collection('users')
          .doc(_firebaseUser!.uid)
          .set({'fcmToken': _messagingToken}, SetOptions(merge: true));
    }

    // 3) Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null && notification.title != null) {
        debugPrint('FCM Message Received: ${notification.title} - ${notification.body}');
      }
    });
  }

  void _clearLocalData() {
    _cartItems.clear();
    _favorites.clear();
    _quantities.clear();
    _currentProductReviews.clear();
    _messagingToken = null;
    _currentUserModel = null;
  }

  Future<void> _loadUserDataFromFirestore() async {
    if (_firebaseUser == null) return;
    final uid = _firebaseUser!.uid;

    // 1) Load favorites
    final favSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .get();
    _favorites = favSnapshot.docs
        .map((doc) => ProductModel.fromMap(doc.data()))
        .toList();

    // 2) Load cart
    final cartSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('cart')
        .get();
    _cartItems = [];
    _quantities.clear();
    for (var doc in cartSnapshot.docs) {
      final data = doc.data();
      final productId = data['productId'] as int;
      final qty = (data['quantity'] as num).toInt();
      final productDetails = await MyRepository(
        httpService: HttpService(baseUrl: 'https://fakestoreapi.com'),
      ).getProduct(productId);
      _cartItems.add(productDetails);
      _quantities[productId] = qty;
    }

    // 3) No need to preload reviews here; fetch per product when needed
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Authentication Methods
  // ─────────────────────────────────────────────────────────────────────────────

  /// Register a new user with email & password
  Future<void> registerWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      _busy = true;
      notifyListeners();

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (displayName != null) {
        await result.user!.updateDisplayName(displayName.trim());
      }

      // The userChanges() listener will handle creating/loading Firestore doc
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      notifyListeners();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Sign in existing user
  Future<void> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      _busy = true;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      // userChanges() listener fires automatically
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      notifyListeners();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Sign out current user
  Future<void> logout() async {
    await _auth.signOut();
    _firebaseUser = null;
    _clearLocalData();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Fetching Products from FakeStore API
  // ─────────────────────────────────────────────────────────────────────────────

  /// Fetch all products and merge favorite flags
  Future<void> fetchAllProducts() async {
    if (_busy) return;
    _busy = true;
    notifyListeners();

    try {
      final fetchedProducts = await MyRepository(
        httpService: HttpService(baseUrl: 'https://fakestoreapi.com'),
      ).getProducts();

      // Mark favorites based on Firestore‐loaded favorite IDs
      final favoriteIds = _favorites.map((p) => p.id).toSet();
      _products = fetchedProducts.map((p) {
        p.isFavorite = favoriteIds.contains(p.id);
        return p;
      }).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Favorites Management (Firestore)
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> toggleFavorite(ProductModel product) async {
    if (!isLoggedIn || _firebaseUser == null) {
      throw Exception('Please login first');
    }
    final uid = _firebaseUser!.uid;
    final favCollection = _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites');

    final exists = _favorites.any((p) => p.id == product.id);
    if (exists) {
      // Remove from favorites
      _favorites.removeWhere((p) => p.id == product.id);
      product.isFavorite = false;

      await favCollection.doc(product.id.toString()).delete();
    } else {
      // Add to favorites
      _favorites.add(product);
      product.isFavorite = true;

      await favCollection.doc(product.id.toString()).set(product.toMap());
    }

    // Update the products list’s isFavorite flags
    for (var p in _products) {
      if (p.id == product.id) p.isFavorite = product.isFavorite;
    }
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Cart Management (Firestore)
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> addToCart(ProductModel product) async {
    if (!isLoggedIn || _firebaseUser == null) {
      throw Exception('Please login first');
    }
    final uid = _firebaseUser!.uid;
    final cartCollection = _firestore
        .collection('users')
        .doc(uid)
        .collection('cart');

    final existingIndex = _cartItems.indexWhere((p) => p.id == product.id);
    if (existingIndex >= 0) {
      await _incrementCartQuantity(product);
    } else {
      _cartItems.add(product);
      _quantities[product.id!] = 1;

      await cartCollection.doc(product.id.toString()).set({
        'productId': product.id,
        'quantity': 1,
      });
      notifyListeners();
    }
  }

  Future<void> _incrementCartQuantity(ProductModel product) async {
    final uid = _firebaseUser!.uid;
    int currentQty = getQuantity(product);
    _quantities[product.id!] = currentQty + 1;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('cart')
        .doc(product.id.toString())
        .update({'quantity': currentQty + 1});

    notifyListeners();
  }

  Future<void> increaseQuantity(ProductModel product) async {
    if (product.id == null) return;
    await _incrementCartQuantity(product);
  }

  Future<void> decreaseQuantity(ProductModel product) async {
    if (product.id == null) return;
    int currentQty = getQuantity(product);
    if (currentQty > 1) {
      _quantities[product.id!] = currentQty - 1;
      await _firestore
          .collection('users')
          .doc(_firebaseUser!.uid)
          .collection('cart')
          .doc(product.id.toString())
          .update({'quantity': currentQty - 1});
    } else {
      await removeFromCart(product);
    }
    notifyListeners();
  }

  Future<void> removeFromCart(ProductModel product) async {
    if (product.id == null || _firebaseUser == null) return;
    final uid = _firebaseUser!.uid;

    _cartItems.removeWhere((p) => p.id == product.id);
    _quantities.remove(product.id);

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('cart')
        .doc(product.id.toString())
        .delete();

    notifyListeners();
  }

  Future<void> clearCart() async {
    if (_firebaseUser == null) return;
    final uid = _firebaseUser!.uid;

    final cartCollection = _firestore
        .collection('users')
        .doc(uid)
        .collection('cart');
    final snapshot = await cartCollection.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
    _cartItems.clear();
    _quantities.clear();
    notifyListeners();
  }

  double get totalPrice {
    return _cartItems.fold(0.0, (sum, prod) {
      return sum + (prod.safePrice * getQuantity(prod));
    });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Reviews Management (Firestore)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Write a review for a given productId
  Future<void> writeReview({
    required int productId,
    required String title,
    required String content,
    required double rating,
  }) async {
    if (!isLoggedIn || _firebaseUser == null) {
      throw Exception('Please login first');
    }
    final uid = _firebaseUser!.uid;
    final userName = _firebaseUser!.displayName ?? _firebaseUser!.email!;

    final reviewsCollection = _firestore
        .collection('products')
        .doc(productId.toString())
        .collection('reviews');

    final newReview = ReviewModel(
      userId: uid,
      userName: userName,
      title: title,
      content: content,
      rating: rating,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await reviewsCollection.add(newReview.toMap());
  }

  /// Fetch all reviews for a given productId
  Future<void> fetchReviews(int productId) async {
    final reviewsCollection = _firestore
        .collection('products')
        .doc(productId.toString())
        .collection('reviews');

    final snapshot = await reviewsCollection
        .orderBy('timestamp', descending: true)
        .get();

    _currentProductReviews = snapshot.docs
        .map((doc) => ReviewModel.fromMap(doc.data()))
        .toList();
    notifyListeners();
  }

  // ────────────────────────────────────────────────────────────
  // Bottom‐nav, email-verification getter & refresh support
  // ────────────────────────────────────────────────────────────

  int _currentIdx = 0;
  int get currentIdx => _currentIdx;
  void changeCurrentIdx(int idx) {
    _currentIdx = idx;
    notifyListeners();
  }

  /// Whether the current Firebase user's email is verified
  bool get isEmailVerified => _firebaseUser?.emailVerified ?? false;

  /// Force-reload the Firebase user (e.g. to re-check emailVerified)
  Future<void> refreshLoggedInUser() async {
    if (_firebaseUser == null) return;
    await _firebaseUser!.reload();
    // pull in the reloaded currentUser
    _firebaseUser = _auth.currentUser;
    notifyListeners();
  }
}