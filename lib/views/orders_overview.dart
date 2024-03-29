import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/orders.dart' show Orders;
import '../widgets/layouts/app_drawer.dart';
import '../widgets/order_item.dart';

class OrdersOverview extends StatefulWidget {
  static const routeName = '/orders';

  const OrdersOverview({super.key});

  @override
  State<OrdersOverview> createState() => _OrdersOverviewState();
}

class _OrdersOverviewState extends State<OrdersOverview> {
  late Future _loadedOrders;

  Future _loadOrder() {
    return Provider.of<Orders>(context, listen: false).fetchAndSetOrders();
  }

  @override
  void initState() {
    _loadedOrders = _loadOrder();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Orders'),
      ),
      drawer: const AppDrawer(),
      body: FutureBuilder(
        future: _loadedOrders,
        builder: (ctx, dataSnapshot) {
          if (dataSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            if (dataSnapshot.error != null) {
              return const Center(
                child: Text('Something goes wrong'),
              );
            } else {
              return Consumer<Orders>(
                builder: (ctx, orderData, _) => ListView.builder(
                  itemCount: orderData.orders.length,
                  itemBuilder: (ctx, index) =>
                      OrderItem(orderData.orders[index]),
                ),
              );
            }
          }
        },
      ),
    );
  }
}
