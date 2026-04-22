import 'dart:async';

class CartService {
  static final CartService _instance = CartService._internal();

  final _cartChangeController = StreamController<CartChangeEvent>.broadcast();

  CartService._internal();

  factory CartService() {
    return _instance;
  }

  Stream<CartChangeEvent> get cartChangeStream => _cartChangeController.stream;

  void notifyCartChange(CartChangeEvent event) {
    _cartChangeController.add(event);
  }

  void dispose() {
    _cartChangeController.close();
  }
}

class CartChangeEvent {
  final int productId;
  final bool isAdded; // true if added, false if removed
  final int quantity; // for updates

  CartChangeEvent({
    required this.productId,
    required this.isAdded,
    this.quantity = 1,
  });
}