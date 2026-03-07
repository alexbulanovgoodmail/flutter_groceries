import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_groceries/data/categories.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_groceries/models/grocery_item.dart';
import 'package:flutter_groceries/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  final List<GroceryItem> _groceryItems = [];
  bool _isLoading = false;
  String? _error;

  void _loadItems() async {
    final url = Uri.https(
      'groceries-f1b8e-default-rtdb.firebaseio.com',
      'shopping-list.json',
    );

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await http.get(url);

      if (response.body.isEmpty || response.body == 'null') {
        setState(() {
          _groceryItems.clear();
        });
        return;
      }

      final responseData = jsonDecode(response.body);

      if (responseData == null) {
        setState(() {
          _groceryItems.clear();
        });
        return;
      }

      final List<GroceryItem> loadedItems = [];

      if (responseData is Map<String, dynamic>) {
        for (final entry in responseData.entries) {
          final itemId = entry.key;
          final itemData = entry.value;

          if (itemData is Map<String, dynamic>) {
            try {
              final category = categories.entries
                  .firstWhere(
                    (catEntry) => catEntry.value.title == itemData['category'],
                  )
                  .value;

              loadedItems.add(
                GroceryItem(
                  id: itemId,
                  name: itemData['name'],
                  quantity: itemData['quantity'],
                  category: category,
                ),
              );
            } catch (e) {
              throw Exception('Category ${itemData['category']} not found');
            }
          }
        }
      }

      setState(() {
        _groceryItems.clear();
        _groceryItems.addAll(loadedItems);
      });
    } catch (error) {
      setState(() {
        _error = 'Error occurred while fetching data.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(
      context,
    ).push<GroceryItem>(MaterialPageRoute(builder: (ctx) => const NewItem()));

    if (!mounted) return;
    if (newItem != null) {
      setState(() {
        _groceryItems.add(newItem);
      });
    }
  }

  void _removeItem(GroceryItem item, int itemIndex) async {
    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https(
      'groceries-f1b8e-default-rtdb.firebaseio.com',
      'shopping-list/${item.id}.json',
    );

    try {
      await http.delete(url);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Failed to delete item. Please try again.',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
          elevation: 6,
        ),
      );

      setState(() {
        _groceryItems.insert(itemIndex, item);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('No items added yet.', style: TextStyle(fontSize: 18.0)),
    );

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (context, index) => Dismissible(
          key: ValueKey(_groceryItems[index].id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            margin: EdgeInsets.symmetric(horizontal: 0.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
              ],
            ),
          ),
          onDismissed: (direction) {
            _removeItem(_groceryItems[index], index);
          },
          child: ListTile(
            leading: Container(
              width: 24.0,
              height: 24.0,
              color: _groceryItems[index].category.color,
            ),
            title: Text(_groceryItems[index].name),
            trailing: Text(_groceryItems[index].quantity.toString()),
          ),
        ),
      );
    }

    if (_error != null) {
      content = Center(
        child: Text(
          _error!,
          style: const TextStyle(fontSize: 18.0, color: Colors.red),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [IconButton(onPressed: _addItem, icon: const Icon(Icons.add))],
      ),
      body: content,
    );
  }
}
