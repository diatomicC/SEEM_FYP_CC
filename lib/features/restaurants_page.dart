import 'package:flutter/material.dart';
import 'package:fyp_scaneat_cc/data/restaurant_data.dart';
import 'package:fyp_scaneat_cc/features/restaurant_menu_page.dart';

class RestaurantsPage extends StatefulWidget {
  const RestaurantsPage({Key? key}) : super(key: key);

  @override
  State<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allRestaurants = [];
  List<Map<String, dynamic>> _filteredRestaurants = [];
  String _selectedCuisine = 'All';
  List<String> _cuisineTypes = ['All'];

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  void _loadRestaurants() {
    // Load default restaurants
    final defaultRestaurants = [
      getRestaurantData('Oi Man Sang', 'en'),
      getRestaurantData('One Dim Sum', 'en'),
    ];

    // Load custom restaurants
    final customRestaurants = getCustomRestaurants();

    setState(() {
      _allRestaurants = [...defaultRestaurants, ...customRestaurants];
      _filteredRestaurants = _allRestaurants;

      // Extract unique cuisine types
      final cuisineSet = <String>{'All'};
      for (var restaurant in _allRestaurants) {
        final cuisine = restaurant['info']['cuisine'] as String?;
        if (cuisine != null) {
          cuisineSet.add(cuisine);
        }
      }
      _cuisineTypes = cuisineSet.toList()..sort();
    });
  }

  void _filterRestaurants(String query) {
    setState(() {
      if (query.isEmpty && _selectedCuisine == 'All') {
        _filteredRestaurants = _allRestaurants;
      } else {
        _filteredRestaurants = _allRestaurants.where((restaurant) {
          final info = restaurant['info'] as Map<String, dynamic>;
          final name = info['name'].toString().toLowerCase();
          final description = info['description']?.toString().toLowerCase() ?? '';
          final cuisine = info['cuisine']?.toString() ?? '';
          
          final matchesSearch = query.isEmpty || 
              name.contains(query.toLowerCase()) || 
              description.contains(query.toLowerCase());
          
          final matchesCuisine = _selectedCuisine == 'All' || 
              cuisine == _selectedCuisine;

          return matchesSearch && matchesCuisine;
        }).toList();
      }
    });
  }

  void _onCuisineChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedCuisine = newValue;
        _filterRestaurants(_searchController.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurants'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search restaurants...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: _filterRestaurants,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: DropdownButton<String>(
                  value: _selectedCuisine,
                  isExpanded: true,
                  items: _cuisineTypes.map((String cuisine) {
                    return DropdownMenuItem<String>(
                      value: cuisine,
                      child: Text(cuisine),
                    );
                  }).toList(),
                  onChanged: _onCuisineChanged,
                  hint: const Text('Select Cuisine Type'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _filteredRestaurants.isEmpty
          ? const Center(
              child: Text(
                'No restaurants found',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: _filteredRestaurants.length,
              itemBuilder: (context, index) {
                final restaurant = _filteredRestaurants[index];
                final info = restaurant['info'] as Map<String, dynamic>;
                final isCustomRestaurant = info['coordinates'] != null;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCustomRestaurant ? Colors.red : Colors.blue,
                      child: const Icon(
                        Icons.restaurant,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      info['name'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (info['cuisine'] != null)
                          Text(
                            info['cuisine'] as String,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        Text(
                          info['address'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RestaurantMenuPage(
                            restaurant: restaurant,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 