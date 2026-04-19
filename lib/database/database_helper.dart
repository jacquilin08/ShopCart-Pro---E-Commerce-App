import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/cart_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('shopcart.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        imageUrl TEXT,
        category TEXT,
        rating REAL,
        reviews INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE cart_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    await _insertSampleProducts(db);
  }

  Future _insertSampleProducts(Database db) async {
    final products = [
      {
        'name': 'Wireless Headphones',
        'description': 'Premium noise-cancelling wireless headphones with 30-hour battery life',
        'price': 299.99,
        'imageUrl': 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500',
        'category': 'Electronics',
        'rating': 4.8,
        'reviews': 2341
      },
      {
        'name': 'Smart Watch Pro',
        'description': 'Advanced fitness tracking and health monitoring smartwatch',
        'price': 399.99,
        'imageUrl': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=500',
        'category': 'Electronics',
        'rating': 4.6,
        'reviews': 1823
      },
      {
        'name': 'Minimalist Backpack',
        'description': 'Water-resistant laptop backpack with USB charging port',
        'price': 89.99,
        'imageUrl': 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=500',
        'category': 'Accessories',
        'rating': 4.7,
        'reviews': 892
      },
      {
        'name': 'Running Shoes',
        'description': 'Lightweight breathable running shoes with cushioned sole',
        'price': 129.99,
        'imageUrl': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=500',
        'category': 'Fashion',
        'rating': 4.5,
        'reviews': 3156
      },
      {
        'name': 'Coffee Maker',
        'description': 'Programmable 12-cup coffee maker with thermal carafe',
        'price': 79.99,
        'imageUrl': 'https://images.unsplash.com/photo-1517668808822-9ebb02f2a0e6?w=500',
        'category': 'Home',
        'rating': 4.4,
        'reviews': 567
      },
      {
        'name': 'Yoga Mat',
        'description': 'Eco-friendly non-slip yoga mat with carrying strap',
        'price': 45.99,
        'imageUrl': 'https://images.unsplash.com/photo-1601925260368-ae2f83cf8b7f?w=500',
        'category': 'Fitness',
        'rating': 4.9,
        'reviews': 2341
      },
    ];

    for (var product in products) {
      await db.insert('products', product);
    }
  }

  Future<List<Product>> getProducts() async {
    final db = await database;
    final maps = await db.query('products');
    return maps.map((json) => Product.fromJson(json)).toList();
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'category = ?',
      whereArgs: [category],
    );
    return maps.map((json) => Product.fromJson(json)).toList();
  }

  Future<List<CartItem>> getCartItems() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT c.*, p.name, p.price, p.imageUrl, p.description 
      FROM cart_items c 
      JOIN products p ON c.productId = p.id
    ''');
    return maps.map((json) => CartItem.fromJson(json)).toList();
  }

  Future<void> addToCart(int productId, int quantity) async {
    final db = await database;
    final existing = await db.query(
      'cart_items',
      where: 'productId = ?',
      whereArgs: [productId],
    );

    if (existing.isNotEmpty) {
      final currentQty = existing.first['quantity'] as int;
      await db.update(
        'cart_items',
        {'quantity': currentQty + quantity},
        where: 'productId = ?',
        whereArgs: [productId],
      );
    } else {
      await db.insert('cart_items', {
        'productId': productId,
        'quantity': quantity,
      });
    }
  }

  Future<void> updateQuantity(int cartItemId, int quantity) async {
    final db = await database;
    if (quantity <= 0) {
      await db.delete(
        'cart_items',
        where: 'id = ?',
        whereArgs: [cartItemId],
      );
    } else {
      await db.update(
        'cart_items',
        {'quantity': quantity},
        where: 'id = ?',
        whereArgs: [cartItemId],
      );
    }
  }

  Future<void> removeFromCart(int cartItemId) async {
    final db = await database;
    await db.delete(
      'cart_items',
      where: 'id = ?',
      whereArgs: [cartItemId],
    );
  }

  Future<void> clearCart() async {
    final db = await database;
    await db.delete('cart_items');
  }

  Future<int> getCartItemCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(quantity) as count FROM cart_items');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<double> getCartTotal() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(c.quantity * p.price) as total 
      FROM cart_items c 
      JOIN products p ON c.productId = p.id
    ''');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
