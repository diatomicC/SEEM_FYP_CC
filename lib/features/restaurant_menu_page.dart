import 'package:flutter/material.dart';
import 'package:fyp_scaneat_cc/services/reservation_service.dart';
import 'package:fyp_scaneat_cc/services/ticket_service.dart';

class RestaurantMenuPage extends StatefulWidget {
  final Map<String, dynamic> restaurant;

  const RestaurantMenuPage({
    Key? key,
    required this.restaurant,
  }) : super(key: key);

  @override
  State<RestaurantMenuPage> createState() => _RestaurantMenuPageState();
}

class _RestaurantMenuPageState extends State<RestaurantMenuPage> {
  String _currentLanguage = 'en';
  List<String> _availableLanguages = ['en'];
  final ReservationService _reservationService = ReservationService();
  final TicketService _ticketService = TicketService();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _numberOfPeople = 1;

  @override
  void initState() {
    super.initState();
    _loadAvailableLanguages();
  }

  void _loadAvailableLanguages() {
    final translations = widget.restaurant['translations'] as Map<String, dynamic>?;
    if (translations != null) {
      setState(() {
        _availableLanguages = ['en', ...translations.keys];
      });
    }
  }

  Map<String, dynamic> _getCurrentMenu() {
    if (_currentLanguage == 'en') {
      return widget.restaurant['menu'] as Map<String, dynamic>? ?? {'categories': []};
    } else {
      final translations = widget.restaurant['translations'] as Map<String, dynamic>?;
      return translations?[_currentLanguage] ?? widget.restaurant['menu'] as Map<String, dynamic>? ?? {'categories': []};
    }
  }

  Map<String, dynamic> _getCurrentInfo() {
    if (_currentLanguage == 'en') {
      return widget.restaurant['info'] as Map<String, dynamic>;
    } else {
      final translations = widget.restaurant['translations'] as Map<String, dynamic>?;
      if (translations != null && translations[_currentLanguage] != null) {
        return translations[_currentLanguage]['info'] as Map<String, dynamic>? ?? widget.restaurant['info'] as Map<String, dynamic>;
      }
      return widget.restaurant['info'] as Map<String, dynamic>;
    }
  }

  Future<void> _showReservationDialog() async {
    final ticketInfo = _ticketService.getTicketInfoForChat();
    if (ticketInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan your ticket first to make a reservation')),
      );
      return;
    }

    final customerName = ticketInfo['Passenger Name'] as String;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Make Reservation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer: $customerName'),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(_selectedDate == null 
                    ? 'Select Date' 
                    : 'Date: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                    }
                  },
                ),
                ListTile(
                  title: Text(_selectedTime == null 
                    ? 'Select Time' 
                    : 'Time: ${_selectedTime!.format(context)}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() => _selectedTime = time);
                    }
                  },
                ),
                ListTile(
                  title: const Text('Number of People'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: _numberOfPeople > 1 
                          ? () => setState(() => _numberOfPeople--) 
                          : null,
                      ),
                      Text('$_numberOfPeople'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _numberOfPeople < 10 
                          ? () => setState(() => _numberOfPeople++) 
                          : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: (_selectedDate != null && _selectedTime != null)
                ? () => _makeReservation(context)
                : null,
              child: const Text('Confirm Reservation'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _makeReservation(BuildContext context) async {
    if (_selectedDate == null || _selectedTime == null) return;

    final reservationTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final success = await _reservationService.makeReservation(
      restaurantName: widget.restaurant['info']['name'] as String,
      reservationTime: reservationTime,
      numberOfPeople: _numberOfPeople,
    );

    if (mounted) {
      Navigator.pop(context); // Close dialog

      if (success) {
        final ticketInfo = _ticketService.getTicketInfoForChat();
        final customerName = ticketInfo?['Passenger Name'] as String? ?? 'Unknown';
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Reservation Confirmed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thank you for your reservation, $customerName!'),
                const SizedBox(height: 16),
                Text('Restaurant: ${widget.restaurant['info']['name']}'),
                Text('Date: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                Text('Time: ${_selectedTime!.format(context)}'),
                Text('Number of People: $_numberOfPeople'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to make reservation. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.restaurant['info'] == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Text('Restaurant information not available'),
        ),
      );
    }

    final info = _getCurrentInfo();
    final menu = _getCurrentMenu();
    final details = widget.restaurant['details'] as Map<String, dynamic>? ?? {'highlights': []};

    return Scaffold(
      appBar: AppBar(
        title: Text(info['name'] as String? ?? 'Restaurant Menu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_availableLanguages.length > 1)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: DropdownButton<String>(
                value: _currentLanguage,
                dropdownColor: Theme.of(context).primaryColor,
                icon: const Icon(Icons.language, color: Colors.white),
                underline: Container(),
                items: _availableLanguages.map((String language) {
                  return DropdownMenuItem<String>(
                    value: language,
                    child: Text(
                      language.toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _currentLanguage = newValue;
                    });
                  }
                },
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Info Section
            Text(
              info['name'] as String? ?? 'Unnamed Restaurant',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            if (info['cuisine'] != null)
              Text(
                info['cuisine'] as String,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            const SizedBox(height: 16),
            if (info['description'] != null)
              Text(
                info['description'] as String,
                style: Theme.of(context).textTheme.bodyLarge,
              ),

            // Menu Section
            if ((menu['categories'] as List?)?.isNotEmpty ?? false) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.grey[200],
                child: Text(
                  'Menu',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...(menu['categories'] as List<dynamic>).map(
                (category) => _buildMenuCategory(context, category as Map<String, dynamic>),
              ),
            ],

            // Highlights Section
            if ((details['highlights'] as List?)?.isNotEmpty ?? false) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.grey[200],
                child: Text(
                  'Highlights',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...(details['highlights'] as List<dynamic>).map(
                (highlight) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Text(
                          highlight as String,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showReservationDialog,
        icon: const Icon(Icons.calendar_today),
        label: const Text('Make Reservation'),
      ),
    );
  }

  Widget _buildMenuCategory(BuildContext context, Map<String, dynamic> category) {
    final items = category['items'] as List<dynamic>? ?? [];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              category['name'] as String? ?? 'Menu Items',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item['name'] as String? ?? 'Unnamed Item',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Text(
                    item['price'] is int ? 'HK\$ ${item['price']}' : item['price']?.toString() ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 