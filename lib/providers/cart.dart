import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CartItem {
  final String id;
  final String title;
  final int quantity;
  final double price;

  CartItem(
      {required this.id,
      required this.title,
      required this.quantity,
      required this.price});
}

/**
 * ChangeNotifier can also be imported from widgets.dart
 */
class Cart with ChangeNotifier {
  Map<String, CartItem> _items = {};

  Map<String, CartItem> items() {
    return {..._items};
  }

  int get itemsCount {
    return _items.length;
  }

  void addItem(String id, double price, String title) {
    if (_items.containsKey(id)) {
      _items.update(
          id,
          (existingCartItem) => CartItem(
              id: existingCartItem.id,
              title: existingCartItem.title,
              price: existingCartItem.price,
              quantity: existingCartItem.quantity + 1));
    } else {
      _items.putIfAbsent(
          id,
          () => CartItem(
              id: DateTime.now().toString(),
              title: title,
              price: price,
              quantity: 1));
      notifyListeners();
    }
  }
}
