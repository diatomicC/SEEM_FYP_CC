class TicketInfo {
  final String ticketId;
  final String passengerName;
  final String flightNumber;
  final DateTime travelDate;
  final String destination;
  final String seatNumber;
  final bool isUsed;

  TicketInfo({
    required this.ticketId,
    required this.passengerName,
    required this.flightNumber,
    required this.travelDate,
    required this.destination,
    required this.seatNumber,
    this.isUsed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'ticketId': ticketId,
      'passengerName': passengerName,
      'flightNumber': flightNumber,
      'travelDate': travelDate.toIso8601String(),
      'destination': destination,
      'seatNumber': seatNumber,
      'isUsed': isUsed,
    };
  }

  factory TicketInfo.fromMap(Map<String, dynamic> map) {
    return TicketInfo(
      ticketId: map['ticketId'],
      passengerName: map['passengerName'],
      flightNumber: map['flightNumber'],
      travelDate: DateTime.parse(map['travelDate']),
      destination: map['destination'],
      seatNumber: map['seatNumber'],
      isUsed: map['isUsed'] ?? false,
    );
  }

  // Parse ticket information from barcode data
  factory TicketInfo.fromBarcodeText(String barcodeText) {
    try {
      // Example format: M1BOLTMAN/AARON EJRWYLQ HKGNRTCX 0504 027Y054C0122 34B>6180
      final parts = barcodeText.split(RegExp(r'\s+'));
      
      String name = '';
      String date = '';
      String dest = '';
      String flightNum = '';
      String seatNum = '';
      String ticketId = DateTime.now().millisecondsSinceEpoch.toString();
      
      if (parts.isNotEmpty) {
        // Parse name (M1BOLTMAN/AARON -> AARON BOLTMAN)
        if (parts[0].contains('/')) {
          final nameParts = parts[0].split('/');
          if (nameParts.length == 2) {
            final lastName = nameParts[0].replaceAll(RegExp(r'^[A-Z][0-9]'), '');
            name = '${nameParts[1].trim()} ${lastName.trim()}';
          }
        }
        
        // Parse destination code (HKGNRTCX -> HKG)
        if (parts.length > 2) {
          for (var part in parts) {
            if (part.length >= 3 && RegExp(r'^[A-Z]{3}').hasMatch(part)) {
              dest = part.substring(0, 3);
              break;
            }
          }
        }
        
        // Parse date (0504 -> 2024-05-04)
        if (parts.length > 3) {
          for (var part in parts) {
            if (RegExp(r'^\d{4}$').hasMatch(part)) {
              final month = part.substring(0, 2);
              final day = part.substring(2, 4);
              final year = DateTime.now().year;
              date = '$year-$month-$day';
              break;
            }
          }
        }
        
        // Parse flight number (027Y054C0122 -> 027Y)
        if (parts.length > 4) {
          flightNum = parts[4].substring(0, 4);
        }
        
        // Parse seat number (34B>6180 -> 34B)
        if (parts.length > 5) {
          seatNum = parts[5].substring(0, 3);
        }
      }

      if (name.isEmpty || date.isEmpty || dest.isEmpty || flightNum.isEmpty || seatNum.isEmpty) {
        throw FormatException('Missing required ticket information');
      }

      return TicketInfo(
        ticketId: ticketId,
        passengerName: name,
        flightNumber: flightNum,
        travelDate: DateTime.parse(date),
        destination: dest,
        seatNumber: seatNum,
      );
    } catch (e) {
      throw FormatException('Error parsing ticket data: $e');
    }
  }
} 