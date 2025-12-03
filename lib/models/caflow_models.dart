// models/caflow_models.dart

class CaflowDevice {
  final String name;
  final String address;

  CaflowDevice({
    required this.name,
    required this.address,
  });

  @override
  String toString() => 'CaflowDevice($name, $address)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaflowDevice &&
          runtimeType == other.runtimeType &&
          address == other.address;

  @override
  int get hashCode => address.hashCode;
}