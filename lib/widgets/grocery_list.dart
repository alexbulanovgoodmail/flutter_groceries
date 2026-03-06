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
  List<GroceryItem> _groceryItems = [];

  void _loadItems() async {
    final url = Uri.https(
      'groceries-f1b8e-default-rtdb.firebaseio.com',
      'shopping-list.json',
    );

    try {
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
              // Category not found, skip this item
              print('Category ${itemData['category']} not found');
            }
          }
        }
      }

      setState(() {
        _groceryItems.clear();
        _groceryItems.addAll(loadedItems);
      });
    } catch (error) {
      print('Error occurred while fetching data: $error');
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(
      context,
    ).push<GroceryItem>(MaterialPageRoute(builder: (ctx) => const NewItem()));

    if (newItem != null) {
      setState(() {
        _groceryItems.add(newItem);
      });
    }
  }

  void _onRemoveItem(GroceryItem item, int itemIndex) {
    setState(() {
      _groceryItems.remove(item);
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Grocery deleted.'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _groceryItems.insert(itemIndex, item);
            });
          },
        ),
      ),
    );
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
            _onRemoveItem(_groceryItems[index], index);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [IconButton(onPressed: _addItem, icon: const Icon(Icons.add))],
      ),
      body: content,
    );
  }
}
