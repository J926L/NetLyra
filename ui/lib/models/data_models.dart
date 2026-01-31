/// Alert model for UI display.
class AlertItem {
  AlertItem({
    required this.id,
    required this.score,
    required this.timestamp,
    this.srcIp,
    this.dstIp,
    this.srcPort,
    this.dstPort,
    this.protocol,
  });

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    // Handle ts as either int (milliseconds) or string (ISO)
    DateTime ts;
    final tsValue = json['ts'];
    if (tsValue is int) {
      ts = DateTime.fromMillisecondsSinceEpoch(tsValue);
    } else if (tsValue is String) {
      ts = DateTime.tryParse(tsValue) ?? DateTime.now();
    } else {
      ts = DateTime.now();
    }

    return AlertItem(
      id: (json['id'] ?? 0).toString(),
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      timestamp: ts,
      srcIp: json['src_ip'] as String?,
      dstIp: json['dst_ip'] as String?,
      srcPort: json['src_port'] as int?,
      dstPort: json['dst_port'] as int?,
      protocol: json['protocol'] as String?,
    );
  }

  final String id;
  final double score;
  final DateTime timestamp;
  final String? srcIp;
  final String? dstIp;
  final int? srcPort;
  final int? dstPort;
  final String? protocol;

  /// Derive severity from score: >0.9 critical, >0.8 warning, else info
  String get severity {
    if (score > 0.9) return 'critical';
    if (score > 0.8) return 'warning';
    return 'info';
  }

  /// Generate message from flow data
  String get message {
    final proto = protocol ?? 'TCP';
    final src = srcPort != null ? '$srcIp:$srcPort' : (srcIp ?? '?');
    final dst = dstPort != null ? '$dstIp:$dstPort' : (dstIp ?? '?');
    return '$proto $src → $dst (${(score * 100).toStringAsFixed(0)}%)';
  }
}

/// Connection model for UI display.
class ConnectionItem {
  ConnectionItem({
    required this.id,
    required this.srcIp,
    required this.dstIp,
    required this.protocol,
    required this.bytesIn,
    required this.bytesOut,
    this.port,
  });

  factory ConnectionItem.fromJson(Map<String, dynamic> json) {
    return ConnectionItem(
      id: json['id'] as String? ?? '',
      srcIp: json['src_ip'] as String? ?? '0.0.0.0',
      dstIp: json['dst_ip'] as String? ?? '0.0.0.0',
      protocol: json['protocol'] as String? ?? 'TCP',
      bytesIn: json['bytes_in'] as int? ?? 0,
      bytesOut: json['bytes_out'] as int? ?? 0,
      port: json['port'] as int?,
    );
  }

  final String id;
  final String srcIp;
  final String dstIp;
  final String protocol;
  final int bytesIn;
  final int bytesOut;
  final int? port;

  String get formattedBytes {
    final total = bytesIn + bytesOut;
    if (total >= 1024 * 1024) {
      return '${(total / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (total >= 1024) {
      return '${(total / 1024).toStringAsFixed(1)} KB';
    }
    return '$total B';
  }
}
