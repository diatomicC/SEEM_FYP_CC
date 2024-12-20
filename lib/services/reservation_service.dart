import 'package:fyp_scaneat_cc/services/ticket_service.dart';

class Reservation {
  final String restaurantName;
  final String customerName;
  final DateTime reservationTime;
  final int numberOfPeople;

  Reservation({
    required this.restaurantName,
    required this.customerName,
    required this.reservationTime,
    required this.numberOfPeople,
  });

  Map<String, dynamic> toMap() {
    return {
      'restaurantName': restaurantName,
      'customerName': customerName,
      'reservationTime': reservationTime.toIso8601String(),
      'numberOfPeople': numberOfPeople,
    };
  }
}

class ReservationService {
  static final ReservationService _instance = ReservationService._internal();
  final List<Reservation> _reservations = [];
  final TicketService _ticketService = TicketService();

  factory ReservationService() {
    return _instance;
  }

  ReservationService._internal();

  List<Reservation> getReservations() => List.unmodifiable(_reservations);

  Future<bool> makeReservation({
    required String restaurantName,
    required DateTime reservationTime,
    required int numberOfPeople,
  }) async {
    // Get customer name from ticket
    final ticketInfo = _ticketService.getTicketInfoForChat();
    if (ticketInfo == null) return false;

    final customerName = ticketInfo['Passenger Name'] as String;

    final reservation = Reservation(
      restaurantName: restaurantName,
      customerName: customerName,
      reservationTime: reservationTime,
      numberOfPeople: numberOfPeople,
    );

    _reservations.add(reservation);
    return true;
  }

  List<Reservation> getReservationsForRestaurant(String restaurantName) {
    return _reservations
        .where((reservation) => reservation.restaurantName == restaurantName)
        .toList();
  }

  List<Reservation> getReservationsForCustomer(String customerName) {
    return _reservations
        .where((reservation) => reservation.customerName == customerName)
        .toList();
  }
} 