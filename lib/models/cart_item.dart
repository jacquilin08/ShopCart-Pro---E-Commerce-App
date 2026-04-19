class CartItem {
  final int id;
  final int productId;
  int quantity;
  final String name;
  final double price;
  final String imageUrl;
  final String description;

  CartItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id'],
        productId: json['productId'],
        quantity: json['quantity'],
        name: json['name'],
        price: json['price'],
        imageUrl: json['imageUrl'],
        description: json['description'],
      );

  double get total => price * quantity;
}
