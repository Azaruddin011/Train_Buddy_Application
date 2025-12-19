class PnrResult {
  final String pnr;
  final Journey journey;
  final Status status;
  final Chart chart;
  final Clarity clarity;

  PnrResult({
    required this.pnr,
    required this.journey,
    required this.status,
    required this.chart,
    required this.clarity,
  });

  factory PnrResult.fromJson(Map<String, dynamic> json) {
    return PnrResult(
      pnr: json['pnr'],
      journey: Journey.fromJson(json['journey']),
      status: Status.fromJson(json['status']),
      chart: Chart.fromJson(json['chart']),
      clarity: Clarity.fromJson(json['clarity']),
    );
  }
}

class Journey {
  final String trainNumber;
  final String trainName;
  final String trainClass;
  final String from;
  final String to;
  final String boardingDate;

  Journey({
    required this.trainNumber,
    required this.trainName,
    required this.trainClass,
    required this.from,
    required this.to,
    required this.boardingDate,
  });

  factory Journey.fromJson(Map<String, dynamic> json) {
    return Journey(
      trainNumber: json['trainNumber'],
      trainName: json['trainName'],
      trainClass: json['class'],
      from: json['from'],
      to: json['to'],
      boardingDate: json['boardingDate'],
    );
  }
}

class Status {
  final String type; // "WL" | "RAC" | "CNF"
  final int currentPosition;
  final int originalPosition;

  Status({
    required this.type,
    required this.currentPosition,
    required this.originalPosition,
  });

  factory Status.fromJson(Map<String, dynamic> json) {
    return Status(
      type: json['type'],
      currentPosition: json['currentPosition'],
      originalPosition: json['originalPosition'],
    );
  }
}

class Chart {
  final bool prepared;
  final String expectedTime; // ISO string

  Chart({
    required this.prepared,
    required this.expectedTime,
  });

  factory Chart.fromJson(Map<String, dynamic> json) {
    return Chart(
      prepared: json['prepared'],
      expectedTime: json['expectedTime'],
    );
  }
}

class Clarity {
  final String title;
  final String body;
  final List<String> tips;

  Clarity({
    required this.title,
    required this.body,
    required this.tips,
  });

  factory Clarity.fromJson(Map<String, dynamic> json) {
    return Clarity(
      title: json['title'],
      body: json['body'],
      tips: List<String>.from(json['tips']),
    );
  }
}
