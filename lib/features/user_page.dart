import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:fyp_scaneat_cc/data/restaurant_data.dart';
import 'package:fyp_scaneat_cc/services/ticket_service.dart';
import 'package:fyp_scaneat_cc/services/reservation_service.dart';

class UserPage extends StatefulWidget {
  const UserPage({Key? key}) : super(key: key);

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  bool _isRestaurantOwner = false;
  bool _isRegistering = false;
  bool _isManagingRestaurants = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _chatMessages = [];
  Map<String, dynamic>? _restaurantData;
  final TicketService _ticketService = TicketService();
  final ReservationService _reservationService = ReservationService();

  // Initialize Gemini
  final model = GenerativeModel(
    model: 'gemini-pro',
    apiKey: 'AIzaSyAr-Y2j4EDzhAs0qFrto47owTtuRQTwKGE',
  );

  void _startRegistration() {
    setState(() {
      _isRegistering = true;
      _isManagingRestaurants = false;
      _chatMessages.clear();
      _restaurantData = null;
    });

    // Initial message from Gemini
    _addGeminiMessage('''
Hello! I'll help you register your restaurant. Please provide the following information:
1. Restaurant name
2. Address
3. Cuisine type
4. Description
5. Menu items with prices

You can tell me everything at once or one by one. I'll help you format it properly.
''');
  }

  void _addGeminiMessage(String message) {
    setState(() {
      _chatMessages.add({
        'role': 'assistant',
        'content': message,
      });
    });
    _scrollToBottom();
  }

  void _addUserMessage(String message) {
    setState(() {
      _chatMessages.add({
        'role': 'user',
        'content': message,
      });
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final userMessage = _messageController.text.trim();
    _addUserMessage(userMessage);
    _messageController.clear();

    // Handle confirmation
    if (userMessage.toLowerCase() == 'yes' && _restaurantData != null) {
      await _saveRestaurantData();
      return;
    }

    try {
      final prompt = '''
You are a restaurant registration assistant. Help format the user's input into valid restaurant data.
Current chat history: ${json.encode(_chatMessages)}

Based on the user's latest message, extract and format relevant restaurant information.
If you have enough information, provide it in this JSON format:
{
  "info": {
    "name": "Restaurant Name",
    "address": "Full Address (must include mall name in English or Chinese)",
    "description": "Description",
    "cuisine": "Cuisine Type"
  },
  "menu": {
    "categories": [
      {
        "name": "Category Name",
        "items": [
          {"name": "Item Name", "price": price}
        ]
      }
    ]
  }
}

If you don't have enough information, ask for the missing details.
If you have the complete information, start the response with "REGISTRATION_COMPLETE:" followed by the JSON data.

User's message: $userMessage
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      final responseText = response.text;

      if (responseText != null) {
        if (responseText.startsWith('REGISTRATION_COMPLETE:')) {
          // Parse the JSON data
          final jsonStr = responseText.substring('REGISTRATION_COMPLETE:'.length).trim();
          _restaurantData = json.decode(jsonStr);
          
          _addGeminiMessage('''
Great! I've formatted your restaurant information. Here's a summary:
- Name: ${_restaurantData!['info']['name']}
- Cuisine: ${_restaurantData!['info']['cuisine']}
- Address: ${_restaurantData!['info']['address']}

Would you like to save this information? Type "yes" to confirm or continue providing more details.
''');
        } else {
          _addGeminiMessage(responseText);
        }
      }
    } catch (e) {
      _addGeminiMessage('Sorry, there was an error processing your request. Please try again.');
      print('Error: $e');
    }
  }

  Future<void> _saveRestaurantData() async {
    if (_restaurantData == null) {
      _addGeminiMessage('No restaurant data to save. Please provide the information first.');
      return;
    }

    try {
      _addGeminiMessage('Processing your restaurant registration...');
      
      final info = _restaurantData!['info'] as Map<String, dynamic>;
      if (!info.containsKey('name') || !info.containsKey('address') || 
          info['name'] == null || info['address'] == null ||
          (info['name'] as String).isEmpty || (info['address'] as String).isEmpty) {
        _addGeminiMessage('Missing required information. Please provide restaurant name and address.');
        return;
      }

      String address = info['address'] as String;
      _addGeminiMessage('Step 1/2: Finding location...');
      print('Original address: $address');

      // First try to match with known mall coordinates
      Map<String, double>? coordinates = await _getMallCoordinates(address);
      
      if (coordinates != null) {
        _addGeminiMessage('Location found! ✓');
        
        _addGeminiMessage('Step 2/2: Saving restaurant information...');

        // Create a complete restaurant data structure
        final completeRestaurantData = {
          'info': {
            'name': info['name'],
            'address': info['address'], // Keep the original address for display
            'description': info['description'] ?? '',
            'cuisine': info['cuisine'] ?? 'Not specified',
            'coordinates': coordinates,
          },
          'menu': _restaurantData!['menu'] ?? {
            'categories': [
              {
                'name': 'Menu',
                'items': [],
              }
            ]
          },
        };

        print('Restaurant data to save: $completeRestaurantData');

        // Add to restaurant data store
        addCustomRestaurant(completeRestaurantData);

        if (mounted) {
          _addGeminiMessage('''
Registration successful! ✨

Restaurant details:
- Name: ${info['name']}
- Address: ${info['address']}
- Coordinates: (${coordinates['latitude']?.toStringAsFixed(4)}, ${coordinates['longitude']?.toStringAsFixed(4)})

Your restaurant has been added to the map. Returning to map view...''');

          // Wait for 3 seconds to let user read the success message
          await Future.delayed(const Duration(seconds: 3));

          setState(() {
            _isRegistering = false;
          });
          
          // Pop back to map screen without disposing the controller
          if (mounted) {
            Navigator.of(context).pop(true); // Pass true to indicate successful registration
          }
        }
      } else {
        _addGeminiMessage(
          'Could not find the location. Currently, we support automatic registration for these malls:\n\n'
          '- New Town Plaza (新城市廣場) - Sha Tin\n'
          '- Metroplaza (新都會廣場) - Kwai Fong\n'
          '- Festival Walk (又一城) - Kowloon Tong\n'
          '- Times Square (時代廣場) - Causeway Bay\n'
          '- IFC Mall (國際金融中心商場) - Central\n'
          '- Elements (圓方) - West Kowloon\n'
          '- Pacific Place (太古廣場) - Admiralty\n\n'
          'Please make sure your address includes one of these mall names in English or Chinese.'
        );
      }
    } catch (e) {
      print('General error: $e');
      _addGeminiMessage(
        'Error saving restaurant data. Please make sure all information is provided correctly.'
      );
    }
  }

  // Mall coordinates in Hong Kong
  final Map<String, Map<String, double>> mallCoordinates = {
    'new town plaza': {'latitude': 22.3814, 'longitude': 114.1890},  // Sha Tin
    '新城市廣場': {'latitude': 22.3814, 'longitude': 114.1890},      // Sha Tin
    'metroplaza': {'latitude': 22.3571, 'longitude': 114.1267},      // Kwai Fong
    '新都會廣場': {'latitude': 22.3571, 'longitude': 114.1267},      // Kwai Fong
    'festival walk': {'latitude': 22.3372, 'longitude': 114.1745},   // Kowloon Tong
    '又一城': {'latitude': 22.3372, 'longitude': 114.1745},          // Kowloon Tong
    'times square': {'latitude': 22.2782, 'longitude': 114.1829},    // Causeway Bay
    '時代廣場': {'latitude': 22.2782, 'longitude': 114.1829},        // Causeway Bay
    'ifc mall': {'latitude': 22.2849, 'longitude': 114.1577},        // Central
    '國際金融中心商場': {'latitude': 22.2849, 'longitude': 114.1577}, // Central
    'elements': {'latitude': 22.3048, 'longitude': 114.1609},        // West Kowloon
    '圓方': {'latitude': 22.3048, 'longitude': 114.1609},            // West Kowloon
    'pacific place': {'latitude': 22.2777, 'longitude': 114.1655},   // Admiralty
    '太古廣場': {'latitude': 22.2777, 'longitude': 114.1655},        // Admiralty
  };

  Future<Map<String, double>?> _getMallCoordinates(String address) {
    // Convert address to lowercase for matching
    address = address.toLowerCase();
    
    // Check each mall name
    for (var entry in mallCoordinates.entries) {
      if (address.contains(entry.key)) {
        return Future.value(entry.value);
      }
    }
    
    return Future.value(null);
  }

  void _startManagingRestaurants() {
    setState(() {
      _isManagingRestaurants = true;
      _isRegistering = false;
    });
  }

  void _deleteRestaurant(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Restaurant'),
        content: const Text('Are you sure you want to delete this restaurant?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              deleteCustomRestaurant(index);
              setState(() {}); // Refresh the UI
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Restaurant deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editMenu(Map<String, dynamic> restaurant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuEditorPage(restaurant: restaurant),
      ),
    ).then((_) {
      setState(() {}); // Refresh the list when returning from menu editor
    });
  }

  Widget _buildRestaurantList() {
    final customRestaurants = getCustomRestaurants();
    
    if (customRestaurants.isEmpty) {
      return const Center(
        child: Text('No restaurants registered yet'),
      );
    }

    return ListView.builder(
      itemCount: customRestaurants.length,
      itemBuilder: (context, index) {
        final restaurant = customRestaurants[index];
        final info = restaurant['info'] as Map<String, dynamic>;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(info['name'] as String),
            subtitle: Text(info['address'] as String),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.restaurant_menu),
                  onPressed: () => _editMenu(restaurant),
                  tooltip: 'Edit Menu',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteRestaurant(index),
                  tooltip: 'Delete Restaurant',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        actions: [
          Switch(
            value: _isRestaurantOwner,
            onChanged: (value) {
              setState(() {
                _isRestaurantOwner = value;
                if (!value) {
                  _isRegistering = false;
                  _isManagingRestaurants = false;
                }
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isRegistering
          ? _buildRegistrationChat()
          : _isManagingRestaurants
              ? _buildRestaurantList()
              : _buildUserProfile(),
    );
  }

  Widget _buildUserProfile() {
    final ticketInfo = _ticketService.getTicketInfoForChat();
    final customerName = ticketInfo?['Passenger Name'] as String?;
    List<Reservation> userReservations = [];
    
    if (customerName != null) {
      userReservations = _reservationService.getReservationsForCustomer(customerName);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account Type Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Account Type:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isRestaurantOwner ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isRestaurantOwner ? 'Restaurant Owner' : 'Customer',
                        style: TextStyle(
                          fontSize: 16,
                          color: _isRestaurantOwner ? Colors.blue : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Ticket Information Section
          if (ticketInfo != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.airplane_ticket, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Flight Ticket Information',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...ticketInfo.entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            '${entry.key}:',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value.toString(),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (customerName != null) ...[
            const SizedBox(height: 20),

            // Reservations Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.restaurant_menu, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'My Reservations',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (userReservations.isEmpty)
                    const Text(
                      'No reservations yet',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    ...userReservations.map((reservation) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(reservation.restaurantName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date: ${reservation.reservationTime.toLocal().toString().split('.')[0]}',
                            ),
                            Text('Number of People: ${reservation.numberOfPeople}'),
                          ],
                        ),
                      ),
                    )).toList(),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Restaurant Owner Actions
          if (_isRestaurantOwner) ...[
            ElevatedButton.icon(
              onPressed: _startRegistration,
              icon: const Icon(Icons.add_business),
              label: const Text('Register New Restaurant'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _startManagingRestaurants,
              icon: const Icon(Icons.manage_accounts),
              label: const Text('Manage My Restaurants'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRegistrationChat() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _chatMessages.length,
            itemBuilder: (context, index) {
              final message = _chatMessages[index];
              final isUser = message['role'] == 'user';
              
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blue : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message['content']!,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isRegistering = false;
                  });
                },
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Enter restaurant information...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class MenuEditorPage extends StatefulWidget {
  final Map<String, dynamic> restaurant;

  const MenuEditorPage({
    Key? key,
    required this.restaurant,
  }) : super(key: key);

  @override
  State<MenuEditorPage> createState() => _MenuEditorPageState();
}

class _MenuEditorPageState extends State<MenuEditorPage> {
  late Map<String, dynamic> _menu;
  Map<String, Map<String, dynamic>> _translatedMenus = {};
  final _categoryNameController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _itemPriceController = TextEditingController();
  final _languageController = TextEditingController();
  bool _isTranslating = false;

  // Initialize Gemini
  final model = GenerativeModel(
    model: 'gemini-pro',
    apiKey: 'AIzaSyAr-Y2j4EDzhAs0qFrto47owTtuRQTwKGE',
  );

  @override
  void initState() {
    super.initState();
    _menu = Map<String, dynamic>.from(widget.restaurant['menu'] ?? {'categories': []});
    // Load existing translations
    final translations = widget.restaurant['translations'] as Map<String, dynamic>?;
    if (translations != null) {
      translations.forEach((lang, menu) {
        _translatedMenus[lang] = Map<String, dynamic>.from(menu);
      });
    }
  }

  void _showTranslationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Translate Menu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _languageController,
              decoration: const InputDecoration(
                labelText: 'Target Language (e.g., Korean, Japanese, Chinese)',
                hintText: 'Enter language name',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Note: Please enter the language name in English',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_languageController.text.isNotEmpty) {
                Navigator.pop(context);
                _translateMenu(_languageController.text);
                _languageController.clear();
              }
            },
            child: const Text('Translate'),
          ),
        ],
      ),
    );
  }

  Future<void> _translateMenu(String targetLanguage) async {
    setState(() {
      _isTranslating = true;
    });

    try {
      // Prepare menu data for translation
      final menuData = jsonEncode(_menu);
      
      final prompt = '''
You are a professional menu translator. Translate this menu from English to ${targetLanguage}.
Keep the prices and structure exactly the same, only translate the text.
Maintain the JSON structure and format.

Menu to translate:
$menuData

Please provide ONLY the translated JSON data with no additional text or explanation.
Make sure the translation is natural and appropriate for a restaurant menu in ${targetLanguage}.
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      final translatedText = response.text;

      if (translatedText != null) {
        try {
          final translatedMenu = jsonDecode(translatedText);
          setState(() {
            _translatedMenus[targetLanguage.toLowerCase()] = Map<String, dynamic>.from(translatedMenu);
            widget.restaurant['translations'] = _translatedMenus;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Menu translated to $targetLanguage successfully!')),
          );
        } catch (e) {
          print('Error parsing translated menu: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error parsing translated menu')),
          );
        }
      }
    } catch (e) {
      print('Translation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error translating menu')),
      );
    } finally {
      setState(() {
        _isTranslating = false;
      });
    }
  }

  void _showTranslations(String itemName, Map<String, dynamic>? translations) {
    if (translations == null || translations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No translations available')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(itemName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Translations:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...translations.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key}: ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Text(entry.value.toString()),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _addCategory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: _categoryNameController,
          decoration: const InputDecoration(
            labelText: 'Category Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_categoryNameController.text.isNotEmpty) {
                setState(() {
                  (_menu['categories'] as List).add({
                    'name': _categoryNameController.text,
                    'items': [],
                  });
                });
                _categoryNameController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addMenuItem(int categoryIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Menu Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _itemNameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _itemPriceController,
              decoration: const InputDecoration(
                labelText: 'Price (HKD)',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_itemNameController.text.isNotEmpty &&
                  _itemPriceController.text.isNotEmpty) {
                setState(() {
                  ((_menu['categories'] as List)[categoryIndex]['items'] as List).add({
                    'name': _itemNameController.text,
                    'price': int.tryParse(_itemPriceController.text) ?? _itemPriceController.text,
                  });
                });
                _itemNameController.clear();
                _itemPriceController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _deleteMenuItem(int categoryIndex, int itemIndex) {
    setState(() {
      ((_menu['categories'] as List)[categoryIndex]['items'] as List).removeAt(itemIndex);
    });
  }

  void _deleteCategory(int categoryIndex) {
    setState(() {
      (_menu['categories'] as List).removeAt(categoryIndex);
    });
  }

  void _saveMenu() {
    widget.restaurant['menu'] = _menu;
    widget.restaurant['translations'] = _translatedMenus;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Menu'),
        actions: [
          if (_isTranslating)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.translate),
              onPressed: _showTranslationDialog,
              tooltip: 'Translate Menu',
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveMenu,
            tooltip: 'Save Menu',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: (_menu['categories'] as List).length,
        itemBuilder: (context, categoryIndex) {
          final category = (_menu['categories'] as List)[categoryIndex];
          
          return Card(
            margin: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          category['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.translate),
                        onPressed: () {
                          final translations = _getTranslationsForItem(category['name'] as String);
                          _showTranslations(category['name'] as String, translations);
                        },
                        tooltip: 'View Translations',
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _addMenuItem(categoryIndex),
                        tooltip: 'Add Item',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteCategory(categoryIndex),
                        tooltip: 'Delete Category',
                      ),
                    ],
                  ),
                ),
                if ((category['items'] as List).isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: (category['items'] as List).length,
                    itemBuilder: (context, itemIndex) {
                      final item = (category['items'] as List)[itemIndex];
                      
                      return ListTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(item['name'] as String),
                            ),
                            IconButton(
                              icon: const Icon(Icons.translate, size: 20),
                              onPressed: () {
                                final translations = _getTranslationsForItem(item['name'] as String);
                                _showTranslations(item['name'] as String, translations);
                              },
                              tooltip: 'View Translations',
                            ),
                          ],
                        ),
                        subtitle: Text('HK\$ ${item['price']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteMenuItem(categoryIndex, itemIndex),
                          tooltip: 'Delete Item',
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        child: const Icon(Icons.add),
        tooltip: 'Add Category',
      ),
    );
  }

  Map<String, String>? _getTranslationsForItem(String itemName) {
    final translations = <String, String>{};
    _translatedMenus.forEach((language, menu) {
      // Search for the item in categories and their items
      for (final category in (menu['categories'] as List)) {
        if (category['name'] == itemName) {
          translations[language] = category['name'];
          break;
        }
        for (final item in (category['items'] as List)) {
          if (item['name'] == itemName) {
            translations[language] = item['name'];
            break;
          }
        }
      }
    });
    return translations.isEmpty ? null : translations;
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    _itemNameController.dispose();
    _itemPriceController.dispose();
    _languageController.dispose();
    super.dispose();
  }
} 