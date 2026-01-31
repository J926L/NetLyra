import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:netlyra_ui/models/data_models.dart';
import 'package:netlyra_ui/services/websocket_service.dart';
import 'package:netlyra_ui/theme/colors.dart';
import 'package:netlyra_ui/theme/typography.dart';
import 'package:netlyra_ui/widgets/alert_item_tile.dart';
import 'package:netlyra_ui/widgets/bento_card.dart';
import 'package:netlyra_ui/widgets/connection_item_tile.dart';
import 'package:netlyra_ui/widgets/glow_text.dart';
import 'package:netlyra_ui/widgets/stat_tile.dart';
import 'package:netlyra_ui/widgets/scanline_overlay.dart';
import 'package:netlyra_ui/widgets/glitch_effect.dart';
import 'package:netlyra_ui/widgets/velocity_chart.dart';

/// Main dashboard page with Bento grid layout.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final WebSocketService _wsService = WebSocketService();
  StreamSubscription? _wsSubscription;

  int _packetCount = 0;
  bool _isWsConnected = false;
  bool _triggerGlitch = false;

  // Store alerts, connections and chart data
  final List<AlertItem> _alerts = [];
  final List<ConnectionItem> _connections = [];
  final List<FlSpot> _velocityPoints = [];
  double _chartX = 0;

  static const int _maxAlerts = 50;
  static const int _maxConnections = 100;
  static const int _maxChartPoints = 30;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    _wsSubscription = _wsService.stream.listen((event) {
      if (!mounted) return;
      
      final type = event['type'] as String?;
      final data = event['data'] as Map<String, dynamic>? ?? {};

      setState(() {
        _isWsConnected = _wsService.isConnected;

        if (type == WSEventType.stats) {
          final packets = data['packets'] as int? ?? 0;
          _packetCount += packets;
          
          // Update velocity chart
          _velocityPoints.add(FlSpot(_chartX, packets.toDouble()));
          _chartX += 1;
          if (_velocityPoints.length > _maxChartPoints) {
            _velocityPoints.removeAt(0);
          }
        } else if (type == WSEventType.alert) {
          final alertData = data.isNotEmpty ? data : event;
          final alert = AlertItem.fromJson(alertData);
          _alerts.insert(0, alert);
          
          if (alert.severity == 'critical') {
            _triggerGlitch = true;
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) setState(() => _triggerGlitch = false);
            });
          }

          if (_alerts.length > _maxAlerts) {
            _alerts.removeLast();
          }
        } else if (type == WSEventType.connection) {
          final connList = data['connections'] as List<dynamic>? ?? 
                          event['connections'] as List<dynamic>?;
          if (connList != null) {
            _connections.clear();
            for (final c in connList) {
              if (c is Map<String, dynamic>) {
                _connections.add(ConnectionItem.fromJson(c));
              }
            }
            if (_connections.length > _maxConnections) {
              _connections.removeRange(_maxConnections, _connections.length);
            }
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _wsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScanlineOverlay(
      child: GlitchEffect(
        trigger: _triggerGlitch,
        child: Scaffold(
          backgroundColor: NetLyraColors.background,
          appBar: _buildAppBar(),
          body: _buildBody(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: NetLyraColors.background,
      title: GlowText(
        'NETLYRA',
        style: NetLyraTypography.h2,
        glowColor: NetLyraColors.primary,
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isWsConnected ? NetLyraColors.primary : NetLyraColors.warning,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isWsConnected ? NetLyraColors.primary : NetLyraColors.warning).withAlpha(150),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isWsConnected ? 'ONLINE' : 'OFFLINE',
                style: NetLyraTypography.bodySmall.copyWith(
                  color: _isWsConnected ? NetLyraColors.primary : NetLyraColors.warning,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatsRow(),
          const SizedBox(height: 16),
          _buildVelocityChartRow(),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildAlertFeed()),
                const SizedBox(width: 16),
                Expanded(child: _buildConnectionsTable()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: StatTile(
            label: 'PACKETS',
            value: _packetCount.toString(),
            color: NetLyraColors.accent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatTile(
            label: 'ALERTS',
            value: _alerts.length.toString(),
            color: NetLyraColors.warning,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatTile(
            label: 'CONNECTIONS',
            value: _connections.length.toString(),
            color: NetLyraColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildVelocityChartRow() {
    return SizedBox(
      height: 100,
      child: BentoCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('PACKET VELOCITY', style: NetLyraTypography.bodySmall.copyWith(color: NetLyraColors.textMuted)),
                if (_velocityPoints.isNotEmpty)
                  Text('${_velocityPoints.last.y.toInt()} PKT/s', style: NetLyraTypography.mono.copyWith(color: NetLyraColors.accent, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(child: VelocityChart(dataPoints: _velocityPoints)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertFeed() {
    return BentoCard(
      borderColor: _triggerGlitch ? NetLyraColors.warning : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ALERT FEED',
            style: NetLyraTypography.h3.copyWith(
              color: NetLyraColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _alerts.isEmpty
                ? Center(child: Text('No alerts', style: NetLyraTypography.body.copyWith(color: NetLyraColors.textMuted)))
                : ListView.builder(
                    itemCount: _alerts.length,
                    itemBuilder: (context, index) => AlertItemTile(alert: _alerts[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionsTable() {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVE CONNECTIONS',
            style: NetLyraTypography.h3.copyWith(
              color: NetLyraColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _connections.isEmpty
                ? Center(child: Text('No connections', style: NetLyraTypography.body.copyWith(color: NetLyraColors.textMuted)))
                : ListView.builder(
                    itemCount: _connections.length,
                    itemBuilder: (context, index) => ConnectionItemTile(connection: _connections[index]),
                  ),
          ),
        ],
      ),
    );
  }
}



