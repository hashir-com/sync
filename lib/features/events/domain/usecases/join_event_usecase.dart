import '../entities/event_entity.dart';
import '../repositories/event_repository.dart';

class JoinEventUseCase {
  final EventRepository repository;

  JoinEventUseCase(this.repository);

  /// Join an event if it has NOT started and NOT ended
  Future<void> call(EventEntity event, String userId) {
    // 🔒 SAFETY CHECKS (business rules)

    if (event.hasEnded) {
      throw Exception('Event already ended');
    }

    if (event.hasStarted) {
      throw Exception('Event already started');
    }

    // Optional: prevent overbooking
    if (event.availableTickets <= 0) {
      throw Exception('No tickets available');
    }

    return repository.joinEvent(event.id, userId);
  }
}
