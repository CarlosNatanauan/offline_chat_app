// lib/services/new/wifi_direct_protocol.dart
enum WiFiControlType {
  chatRequest,
  chatAccept,
  chatDecline,
}

class WiFiControlMessage {
  final WiFiControlType type;
  final String fromName;

  WiFiControlMessage(this.type, this.fromName);

  static const String _prefix = '__CAFCTRL__';

  /// Encode a control message into a string payload
  static String encode(WiFiControlType type, String fromName) {
    // Example: "__CAFCTRL__:chatRequest:Alice"
    return '$_prefix:${type.name}:$fromName';
  }

  /// Try to parse a raw string as a control message.
  /// Returns null if it's not a control message.
  static WiFiControlMessage? tryParse(String raw) {
    if (!raw.startsWith(_prefix)) return null;

    final parts = raw.split(':');
    if (parts.length < 3) return null;

    final typeStr = parts[1];
    final fromName = parts.sublist(2).join(':'); // allow ':' in names

    WiFiControlType? type;
    for (final t in WiFiControlType.values) {
      if (t.name == typeStr) {
        type = t;
        break;
      }
    }
    if (type == null) return null;

    return WiFiControlMessage(type, fromName);
  }
}
