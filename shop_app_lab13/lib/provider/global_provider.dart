import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider, PhoneAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';
import '../models/product_model.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import '../repository/repository.dart';
import '../services/httpService.dart';

class GlobalProvider extends ChangeNotifier {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  FirebaseMessaging? _firebaseMessaging;

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

  Map<int, int> _quantities = {};
  int getQuantity(ProductModel p) => _quantities[p.id!] ?? 1;

  List<ReviewModel> _currentProductReviews = [];
  List<ReviewModel> get currentProductReviews => _currentProductReviews;

  String? _messagingToken;
  String? get messagingToken => _messagingToken;

  bool _busy = false;
  bool get busy => _busy;

  String? _error;
  String? get error => _error;

  int _currentIdx = 0;
  int get currentIdx => _currentIdx;
  
  bool _isFirebaseInitialized = false;
  bool get isFirebaseInitialized => _isFirebaseInitialized;
  
  GlobalProvider();

  Future<void> initializeFirebase() async {
    if (_isFirebaseInitialized) return;
    
    _busy = true;
    notifyListeners();

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // ehleed Firebase init hiigdeh yostoi
      // ugui bol DEADLOCK
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _firebaseMessaging = FirebaseMessaging.instance;
      
      _isFirebaseInitialized = true;

      // Listen to auth state changes
      _auth!.userChanges().listen((user) async {
        _firebaseUser = user;
        if (_firebaseUser != null) {
          await _createOrLoadUserFirestoreDoc();
          await _loadUserDataFromFirestore();
          await _configureFirebaseMessaging();
        } else {
          _clearLocalData();
        }
        notifyListeners();
      });
    } catch (e) {
      _error = "Firebase initialization failed: ${e.toString()}";
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _createOrLoadUserFirestoreDoc() async {
    if (_firebaseUser == null || _firestore == null) return;

    final uid = _firebaseUser!.uid;
    final userDocRef = _firestore!.collection('users').doc(uid);
    final snapshot = await userDocRef.get();

    if (snapshot.exists) {
      _currentUserModel = UserModel.fromMap(snapshot.data()!);
    } else {
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
    if (_firebaseMessaging == null || _firestore == null || _firebaseUser == null) return;
    
    await _firebaseMessaging!.requestPermission();
    _messagingToken = await _firebaseMessaging!.getToken();
    debugPrint('FCM: $_messagingToken');
    
    if (_messagingToken != null) {
      await _firestore!
          .collection('users')
          .doc(_firebaseUser!.uid)
          .set({'fcmToken': _messagingToken}, SetOptions(merge: true));
    }

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
    if (_firebaseUser == null || _firestore == null) return;
    final uid = _firebaseUser!.uid;

    // Load favorites
    final favSnapshot = await _firestore!
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .get();
    _favorites = favSnapshot.docs
        .map((doc) => ProductModel.fromMap(doc.data()))
        .toList();

    // Load cart
    final cartSnapshot = await _firestore!
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
  }

  // Authentication Methods
  Future<void> registerWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (_auth == null) {
      _error = "Firebase not initialized";
      notifyListeners();
      return;
    }
    
    try {
      _busy = true;
      notifyListeners();

      UserCredential result = await _auth!.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (displayName != null) {
        await result.user!.updateDisplayName(displayName.trim());
      }
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      notifyListeners();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (_auth == null) {
      _error = "Firebase not initialized";
      notifyListeners();
      return;
    }
    
    try {
      _busy = true;
      notifyListeners();

      await _auth!.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      notifyListeners();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (_auth == null) return;
    
    await _auth!.signOut();
    _firebaseUser = null;
    _clearLocalData();
    notifyListeners();
  }

  // Product Methods
  Future<void> fetchAllProducts() async {
    if (_busy) return;
    _busy = true;
    notifyListeners();

    try {
      final fetchedProducts = await MyRepository(
        httpService: HttpService(baseUrl: 'https://fakestoreapi.com'),
      ).getProducts();

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

  // Favorites Management
  Future<void> toggleFavorite(ProductModel product) async {
    if (!isLoggedIn || _firebaseUser == null || _firestore == null) {
      throw Exception('Please login first or Firebase not initialized');
    }
    
    final uid = _firebaseUser!.uid;
    final favCollection = _firestore!
        .collection('users')
        .doc(uid)
        .collection('favorites');

    final exists = _favorites.any((p) => p.id == product.id);
    if (exists) {
      _favorites.removeWhere((p) => p.id == product.id);
      product.isFavorite = false;
      await favCollection.doc(product.id.toString()).delete();
    } else {
      _favorites.add(product);
      product.isFavorite = true;
      await favCollection.doc(product.id.toString()).set(product.toMap());
    }

    for (var p in _products) {
      if (p.id == product.id) p.isFavorite = product.isFavorite;
    }
    notifyListeners();
  }

  // Cart Management
  Future<void> addToCart(ProductModel product) async {
    if (!isLoggedIn || _firebaseUser == null || _firestore == null) {
      throw Exception('Please login first or Firebase not initialized');
    }
    
    final uid = _firebaseUser!.uid;
    final cartCollection = _firestore!
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
    if (_firestore == null || _firebaseUser == null) return;
    
    final uid = _firebaseUser!.uid;
    int currentQty = getQuantity(product);
    _quantities[product.id!] = currentQty + 1;

    await _firestore!
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
    if (product.id == null || _firestore == null || _firebaseUser == null) return;
    
    int currentQty = getQuantity(product);
    if (currentQty > 1) {
      _quantities[product.id!] = currentQty - 1;
      await _firestore!
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
    if (product.id == null || _firebaseUser == null || _firestore == null) return;
    
    final uid = _firebaseUser!.uid;
    _cartItems.removeWhere((p) => p.id == product.id);
    _quantities.remove(product.id);

    await _firestore!
        .collection('users')
        .doc(uid)
        .collection('cart')
        .doc(product.id.toString())
        .delete();

    notifyListeners();
  }

  Future<void> clearCart() async {
    if (_firebaseUser == null || _firestore == null) return;
    
    final uid = _firebaseUser!.uid;
    final cartCollection = _firestore!
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

  // Reviews Management
  Future<void> writeReview({
    required int productId,
    required String title,
    required String content,
    required double rating,
  }) async {
    if (!isLoggedIn || _firebaseUser == null || _firestore == null) {
      throw Exception('Please login first or Firebase not initialized');
    }
    
    final uid = _firebaseUser!.uid;
    final userName = _firebaseUser!.displayName ?? _firebaseUser!.email!;

    final reviewsCollection = _firestore!
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

  Future<void> fetchReviews(int productId) async {
    if (_firestore == null) return;
    
    final reviewsCollection = _firestore!
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

  // Navigation
  void changeCurrentIdx(int idx) {
    _currentIdx = idx;
    notifyListeners();
  }

  bool get isEmailVerified => _firebaseUser?.emailVerified ?? false;

  Future<void> refreshLoggedInUser() async {
    if (_firebaseUser == null) return;
    await _firebaseUser!.reload();
    _firebaseUser = _auth?.currentUser;
    notifyListeners();
  }
}