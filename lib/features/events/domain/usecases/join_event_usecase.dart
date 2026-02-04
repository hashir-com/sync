import '../repositories/event_repository.dart';

class JoinEventUseCase {
  final EventRepository repository;

  JoinEventUseCase(this.repository);

  // Join an event by adding userId to attendees
  Future<void> call(String eventId, String userId) {
    return repository.joinEvent(eventId, userId);
  }
}
