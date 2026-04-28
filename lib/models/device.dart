class Device {
  final int id;
  final String deviceName;
  final String location;
  final String macAddress;
  final bool isOnline;
  final String lastKnownIp;
  final String lastConnectedAt;
  final String createdAt;

  Device({
    required this.id,
    required this.deviceName,
    required this.location,
    required this.macAddress,
    required this.isOnline,
    required this.lastKnownIp,
    required this.lastConnectedAt,
    required this.createdAt,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as int,
      deviceName: json['device_name'] as String,
      location: json['location'] as String,
      macAddress: json['mac_address'] as String,
      isOnline: json['is_online'] as bool,
      lastKnownIp: json['last_known_ip'] as String,
      lastConnectedAt: json['last_connected_at'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_name': deviceName,
      'location': location,
      'mac_address': macAddress,
      'is_online': isOnline,
      'last_known_ip': lastKnownIp,
      'last_connected_at': lastConnectedAt,
      'created_at': createdAt,
    };
  }
}
