import 'package:fyp_scaneat_cc/models/ticket_info.dart';

class TicketService {
  static final TicketService _instance = TicketService._internal();
  TicketInfo? _currentTicket;

  factory TicketService() {
    return _instance;
  }

  TicketService._internal();

  // Get current ticket information
  TicketInfo? get currentTicket => _currentTicket;

  // Set current ticket information
  void setTicket(TicketInfo ticket) {
    _currentTicket = ticket;
  }

  // Clear current ticket information
  void clearTicket() {
    _currentTicket = null;
  }

  // Get ticket information as a map for chat context
  Map<String, dynamic>? getTicketInfoForChat() {
    if (_currentTicket == null) return null;

    return {
      'Ticket ID': _currentTicket!.ticketId,
      'Passenger Name': _currentTicket!.passengerName,
      'Flight Number': _currentTicket!.flightNumber,
      'Travel Date': _currentTicket!.travelDate.toString(),
      'Destination': _currentTicket!.destination,
      'Seat Number': _currentTicket!.seatNumber,
      'Status': _currentTicket!.isUsed ? 'Used' : 'Not Used',
    };
  }
} 