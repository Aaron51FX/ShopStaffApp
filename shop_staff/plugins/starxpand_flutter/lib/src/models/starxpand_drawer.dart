class StarXpandDrawerStatus {
  const StarXpandDrawerStatus({
    required this.hasError,
    required this.coverOpen,
    required this.drawerOpenCloseSignal,
    required this.paperEmpty,
    required this.paperNearEmpty,
  });

  factory StarXpandDrawerStatus.fromJson(Map<String, dynamic> json) {
    return StarXpandDrawerStatus(
      hasError: json['hasError'] == true,
      coverOpen: json['coverOpen'] == true,
      drawerOpenCloseSignal: json['drawerOpenCloseSignal'] == true,
      paperEmpty: json['paperEmpty'] == true,
      paperNearEmpty: json['paperNearEmpty'] == true,
    );
  }

  final bool hasError;
  final bool coverOpen;
  final bool drawerOpenCloseSignal;
  final bool paperEmpty;
  final bool paperNearEmpty;
}

enum StarXpandDrawerChannel { no1, no2 }

extension StarXpandDrawerChannelX on StarXpandDrawerChannel {
  String get wireValue {
    switch (this) {
      case StarXpandDrawerChannel.no1:
        return 'no1';
      case StarXpandDrawerChannel.no2:
        return 'no2';
    }
  }
}
