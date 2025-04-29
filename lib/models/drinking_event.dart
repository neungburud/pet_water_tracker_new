enum DrinkingEvent {
  startDrinking,
  finishDrinking,
}

class DrinkingEventData {
  final int petId;
  final String name;
  final DrinkingEvent action;
  final int timestamp;
  final int? duration;
  final int? count;

  DrinkingEventData({
    required this.petId,
    required this.name,
    required this.action,
    required this.timestamp,
    this.duration,
    this.count,
  });

  factory DrinkingEventData.fromJson(Map<String, dynamic> json) {
    DrinkingEvent action;
    if (json['action'] == 'start_drinking') {
      action = DrinkingEvent.startDrinking;
    } else {
      action = DrinkingEvent.finishDrinking;
    }

    return DrinkingEventData(
      petId: json['pet'],
      name: json['name'],
      action: action,
      timestamp: json['timestamp'],
      duration: json['duration'],
      count: json['count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pet': petId,
      'name': name,
      'action': action == DrinkingEvent.startDrinking ? 'start_drinking' : 'finish_drinking',
      'timestamp': timestamp,
      if (duration != null) 'duration': duration,
      if (count != null) 'count': count,
    };
  }
}