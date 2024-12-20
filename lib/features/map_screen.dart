import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'user_page.dart';
import 'package:fyp_scaneat_cc/data/restaurant_data.dart';
import 'package:fyp_scaneat_cc/features/restaurant_menu_page.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with AutomaticKeepAliveClientMixin {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};
  Map<String, dynamic>? _selectedRestaurant;
  bool _isShowingMenu = false;

  // Define fixed coordinates for default restaurants
  final Map<String, LatLng> defaultCoordinates = {
    'Oi Man Sang': LatLng(22.3311, 114.1622), // Sham Shui Po coordinates
    'One Dim Sum': LatLng(22.2783, 114.1747), // Central coordinates
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  @override
  void dispose() {
    if (_controller != null) {
      _controller!.dispose();
    }
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _controller = controller;
    });
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    Set<Marker> markers = {};

    try {
      // Load all restaurants
      final List<Map<String, dynamic>> allRestaurants = [
        ...getCustomRestaurants(),
        getRestaurantData('Oi Man Sang', 'en'),
        getRestaurantData('One Dim Sum', 'en'),
      ];

      for (var restaurant in allRestaurants) {
        final info = restaurant['info'] as Map<String, dynamic>;
        
        // For restaurants with direct coordinates
        if (info['coordinates'] != null) {
          final coordinates = info['coordinates'] as Map<String, dynamic>;
          markers.add(
            Marker(
              markerId: MarkerId(info['name'] as String),
              position: LatLng(
                coordinates['latitude'] as double,
                coordinates['longitude'] as double,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              infoWindow: InfoWindow(
                title: info['name'] as String,
                snippet: info['description'] as String? ?? '',
              ),
              onTap: () {
                setState(() {
                  _selectedRestaurant = restaurant;
                  _isShowingMenu = true;
                });
              },
            ),
          );
          continue;
        }

        // For default restaurants, use hardcoded coordinates
        final restaurantName = info['name'].toString().split(' (').first; // Remove Korean name in parentheses
        final coordinates = defaultCoordinates[restaurantName];
        if (coordinates != null) {
          markers.add(
            Marker(
              markerId: MarkerId(info['name'] as String),
              position: coordinates,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              infoWindow: InfoWindow(
                title: info['name'] as String,
                snippet: info['description'] as String,
              ),
              onTap: () {
                setState(() {
                  _selectedRestaurant = restaurant;
                  _isShowingMenu = true;
                });
              },
            ),
          );
          continue;
        }
      }

      // Update markers on the UI
      if (mounted) {
        setState(() {
          _markers = markers;
        });
      }
    } catch (e) {
      print('Error loading restaurants: $e');
    }
  }

  void _closeMenu() {
    setState(() {
      _isShowingMenu = false;
      _selectedRestaurant = null;
    });
  }

  void _openRestaurantMenu() {
    if (_selectedRestaurant != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RestaurantMenuPage(
            restaurant: _selectedRestaurant!,
          ),
        ),
      ).then((_) {
        // When returning from menu page
        if (mounted) {
          setState(() {
            _isShowingMenu = false;
            _selectedRestaurant = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return WillPopScope(
      onWillPop: () async {
        if (_isShowingMenu) {
          setState(() {
            _isShowingMenu = false;
            _selectedRestaurant = null;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: const CameraPosition(
                target: LatLng(22.3193, 114.1694), // Hong Kong center
                zoom: 11.0,
              ),
              markers: _markers,
              zoomControlsEnabled: true,
              mapToolbarEnabled: true,
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
            ),
            if (_isShowingMenu && _selectedRestaurant != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _selectedRestaurant!['info']['name'] as String,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _closeMenu,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedRestaurant!['info']['description'] as String,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _openRestaurantMenu,
                        child: const Text('View Menu'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UserPage()),
            );
            
            if (result == true) {
              _loadRestaurants(); // Reload all restaurants including newly registered ones
            }
          },
          child: const Icon(Icons.add_business),
        ),
      ),
    );
  }
} 