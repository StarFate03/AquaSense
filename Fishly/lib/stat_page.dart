import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatPage extends StatefulWidget {
  const StatPage({Key? key}) : super(key: key);

  @override
  State<StatPage> createState() => _StatPageState();
}

class _StatPageState extends State<StatPage> {
  final DatabaseReference _sensorsRef = FirebaseDatabase.instance.ref(
    'Sensors',
  );

  double? temperature;
  double? ph;
  double? waterLevel;
  double? turbidity;

  List<FlSpot> tempHistory = [];
  List<FlSpot> phHistory = [];
  List<FlSpot> waterLevelHistory = [];
  List<FlSpot> turbidityHistory = [];

  // Add pond selection state
  int _selectedPond = 1; // 0: Pond A, 1: Pond B, 2: Pond C
  final List<String> _pondNames = ['Pond A', 'Pond B', 'Pond C'];

  String unit = 'Metric';

  @override
  void initState() {
    super.initState();
    _loadSelectedPond();
    _loadUnit();
  }

  Future<void> _loadUnit() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      unit = prefs.getString('unit_of_measurement') ?? 'Metric';
    });
  }

  Future<void> _loadSelectedPond() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedPond = prefs.getInt('selectedPond') ?? 1;
    });
  }

  Future<void> _saveSelectedPond(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedPond', index);
  }

  void _updateHistory(double? value, List<FlSpot> history) {
    if (value == null) return;
    if (history.length >= 20) {
      history.removeAt(0);
    }
    history.add(FlSpot(history.isNotEmpty ? history.last.x + 1 : 0, value));
  }

  double _averageLast24(List<FlSpot> history) {
    if (history.isEmpty) return 0;
    final last24 = history.length > 24
        ? history.sublist(history.length - 24)
        : history;
    final sum = last24.fold(0.0, (prev, spot) => prev + spot.y);
    return sum / last24.length;
  }

  double _toFahrenheit(double c) => c * 9 / 5 + 32;
  double _toCelsius(double f) => (f - 32) * 5 / 9;
  String get tempUnit => unit == 'Imperial' ? '°F' : '°C';
  String get tempSafeRange => unit == 'Imperial'
      ? '${_toFahrenheit(20).toStringAsFixed(0)}-${_toFahrenheit(30).toStringAsFixed(0)}°F'
      : '20-30°C';

  void _showDetailModal(
    BuildContext context,
    String title,
    String value,
    String unit,
    Color color,
    String status,
    Color statusColor,
    String safeRange,
    List<FlSpot> chartData, {
    String dailyAvg = '',
    String high = '',
    String low = '',
    String tag = '',
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (tag.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 32,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: Text(
                        unit,
                        style: TextStyle(
                          fontSize: 18,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                'Optimal range: $safeRange',
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: chartData,
                        isCurved: true,
                        color: color,
                        barWidth: 3,
                        belowBarData: BarAreaData(show: false),
                        dotData: FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daily Average',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                      Text(
                        dailyAvg,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '24h High',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                      Text(
                        high,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '24h Low',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                      Text(
                        low,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Pond Monitoring',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: theme.iconTheme.color),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _sensorsRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            final data = Map<String, dynamic>.from(
              snapshot.data!.snapshot.value as Map,
            );
            temperature = (data['temperature_C'] ?? 0).toDouble();
            ph = (data['pH Value'] ?? 0).toDouble();
            waterLevel = (data['Water Level'] ?? 0).toDouble();
            turbidity = (data['turbidity'] ?? 0).toDouble();
            _updateHistory(temperature, tempHistory);
            _updateHistory(ph, phHistory);
            _updateHistory(waterLevel, waterLevelHistory);
            _updateHistory(turbidity, turbidityHistory);
          }
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Row (keep as is)
                  Row(
                    children: [
                      for (int i = 0; i < _pondNames.length; i++) ...[
                        FilterChip(
                          label: Text(_pondNames[i]),
                          selected: _selectedPond == i,
                          onSelected: (selected) async {
                            setState(() {
                              _selectedPond = i;
                            });
                            await _saveSelectedPond(i);
                          },
                        ),
                        if (i < _pondNames.length - 1) const SizedBox(width: 8),
                      ],
                      const Spacer(),
                      DropdownButton<String>(
                        value: '24h',
                        dropdownColor: const Color(0xFF1a3442),
                        style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(value: '24h', child: Text('24h')),
                          DropdownMenuItem(value: '7d', child: Text('7d')),
                        ],
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Temperature Card
                  GestureDetector(
                    onTap: () => _showDetailModal(
                      context,
                      'Water Temperature',
                      temperature != null
                          ? (unit == 'Imperial'
                                ? _toFahrenheit(temperature!).toStringAsFixed(2)
                                : temperature!.toStringAsFixed(2))
                          : '--',
                      tempUnit,
                      Colors.redAccent,
                      (temperature != null &&
                              ((unit == 'Imperial' &&
                                      _toFahrenheit(temperature!) >
                                          _toFahrenheit(30)) ||
                                  (unit == 'Metric' && temperature! > 30)))
                          ? 'Above threshold'
                          : (temperature != null &&
                                ((unit == 'Imperial' &&
                                        _toFahrenheit(temperature!) <
                                            _toFahrenheit(20)) ||
                                    (unit == 'Metric' && temperature! < 20)))
                          ? 'Below threshold'
                          : 'Normal',
                      (temperature != null &&
                              ((unit == 'Imperial' &&
                                      (_toFahrenheit(temperature!) <
                                              _toFahrenheit(20) ||
                                          _toFahrenheit(temperature!) >
                                              _toFahrenheit(30))) ||
                                  (unit == 'Metric' &&
                                      (temperature! < 20 ||
                                          temperature! > 30))))
                          ? Colors.red
                          : Colors.green,
                      tempSafeRange,
                      List<FlSpot>.from(
                        tempHistory.map(
                          (spot) => FlSpot(
                            spot.x,
                            unit == 'Imperial' ? _toFahrenheit(spot.y) : spot.y,
                          ),
                        ),
                      ),
                      dailyAvg: tempHistory.isNotEmpty
                          ? (unit == 'Imperial'
                                ? _toFahrenheit(
                                        _averageLast24(tempHistory),
                                      ).toStringAsFixed(2) +
                                      '°F'
                                : _averageLast24(
                                        tempHistory,
                                      ).toStringAsFixed(2) +
                                      '°C')
                          : '--',
                      high: tempHistory.isNotEmpty
                          ? (unit == 'Imperial'
                                ? tempHistory
                                          .map((spot) => _toFahrenheit(spot.y))
                                          .reduce((a, b) => a > b ? a : b)
                                          .toStringAsFixed(2) +
                                      '°F'
                                : tempHistory
                                          .map((spot) => spot.y)
                                          .reduce((a, b) => a > b ? a : b)
                                          .toStringAsFixed(2) +
                                      '°C')
                          : '--',
                      low: tempHistory.isNotEmpty
                          ? (unit == 'Imperial'
                                ? tempHistory
                                          .map((spot) => _toFahrenheit(spot.y))
                                          .reduce((a, b) => a < b ? a : b)
                                          .toStringAsFixed(2) +
                                      '°F'
                                : tempHistory
                                          .map((spot) => spot.y)
                                          .reduce((a, b) => a < b ? a : b)
                                          .toStringAsFixed(2) +
                                      '°C')
                          : '--',
                      tag: 'Live',
                    ),
                    child: StatCard(
                      title: 'Temperature',
                      value: temperature != null
                          ? (unit == 'Imperial'
                                ? _toFahrenheit(temperature!).toStringAsFixed(2)
                                : temperature!.toStringAsFixed(2))
                          : '--',
                      unit: tempUnit,
                      color: Colors.redAccent,
                      status:
                          (temperature != null &&
                              ((unit == 'Imperial' &&
                                      _toFahrenheit(temperature!) >
                                          _toFahrenheit(30)) ||
                                  (unit == 'Metric' && temperature! > 30)))
                          ? 'Above threshold'
                          : (temperature != null &&
                                ((unit == 'Imperial' &&
                                        _toFahrenheit(temperature!) <
                                            _toFahrenheit(20)) ||
                                    (unit == 'Metric' && temperature! < 20)))
                          ? 'Below threshold'
                          : 'Normal',
                      statusColor:
                          (temperature != null &&
                              ((unit == 'Imperial' &&
                                      (_toFahrenheit(temperature!) <
                                              _toFahrenheit(20) ||
                                          _toFahrenheit(temperature!) >
                                              _toFahrenheit(30))) ||
                                  (unit == 'Metric' &&
                                      (temperature! < 20 ||
                                          temperature! > 30))))
                          ? Colors.red
                          : Colors.green,
                      safeRange: tempSafeRange,
                      chartData: List<FlSpot>.from(
                        tempHistory.map(
                          (spot) => FlSpot(
                            spot.x,
                            unit == 'Imperial' ? _toFahrenheit(spot.y) : spot.y,
                          ),
                        ),
                      ),
                      isLive: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // pH Card
                  GestureDetector(
                    onTap: () => _showDetailModal(
                      context,
                      'pH Level',
                      ph != null ? ph!.toStringAsFixed(2) : '--',
                      '',
                      Colors.green,
                      (ph != null && (ph! < 6.5 || ph! > 8.5))
                          ? 'Out of range'
                          : 'Normal',
                      (ph != null && (ph! < 6.5 || ph! > 8.5))
                          ? Colors.red
                          : Colors.green,
                      '6.5-8.5',
                      List<FlSpot>.from(phHistory),
                      dailyAvg: phHistory.isNotEmpty
                          ? _averageLast24(phHistory).toStringAsFixed(2)
                          : '--',
                      high: ph != null ? (ph! + 0.2).toStringAsFixed(2) : '--',
                      low: ph != null ? (ph! - 0.2).toStringAsFixed(2) : '--',
                      tag: 'Live',
                    ),
                    child: StatCard(
                      title: 'pH Value',
                      value: ph != null ? ph!.toStringAsFixed(2) : '--',
                      unit: '',
                      color: Colors.green,
                      status: (ph != null && (ph! < 6.5 || ph! > 8.5))
                          ? 'Out of range'
                          : 'Normal',
                      statusColor: (ph != null && (ph! < 6.5 || ph! > 8.5))
                          ? Colors.red
                          : Colors.green,
                      safeRange: '6.5-8.5',
                      chartData: List<FlSpot>.from(phHistory),
                      isLive: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Water Level Card
                  GestureDetector(
                    onTap: () => _showDetailModal(
                      context,
                      'Water Level',
                      waterLevel != null
                          ? waterLevel!.toStringAsFixed(2)
                          : '--',
                      '%',
                      Colors.amber,
                      (waterLevel != null && waterLevel! >= 80)
                          ? 'Attention needed'
                          : 'Normal',
                      (waterLevel != null && waterLevel! >= 80)
                          ? Colors.orange
                          : Colors.green,
                      '<80%',
                      List<FlSpot>.from(waterLevelHistory),
                      dailyAvg: waterLevelHistory.isNotEmpty
                          ? _averageLast24(
                                  waterLevelHistory,
                                ).toStringAsFixed(2) +
                                '%'
                          : '--',
                      high: waterLevel != null
                          ? (waterLevel! + 2).toStringAsFixed(2) + '%'
                          : '--',
                      low: waterLevel != null
                          ? (waterLevel! - 2).toStringAsFixed(2) + '%'
                          : '--',
                      tag: 'Live',
                    ),
                    child: StatCard(
                      title: 'Water Level',
                      value: waterLevel != null
                          ? waterLevel!.toStringAsFixed(2)
                          : '--',
                      unit: '%',
                      color: Colors.amber,
                      status: (waterLevel != null && waterLevel! >= 80)
                          ? 'Attention needed'
                          : 'Normal',
                      statusColor: (waterLevel != null && waterLevel! >= 80)
                          ? Colors.orange
                          : Colors.green,
                      safeRange: '<80%',
                      chartData: List<FlSpot>.from(waterLevelHistory),
                      isLive: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Turbidity Card
                  GestureDetector(
                    onTap: () => _showDetailModal(
                      context,
                      'Turbidity',
                      turbidity != null ? turbidity!.toStringAsFixed(2) : '--',
                      'NTU',
                      Colors.cyan,
                      (turbidity != null && turbidity! >= 80)
                          ? 'High'
                          : 'Normal',
                      (turbidity != null && turbidity! >= 80)
                          ? Colors.red
                          : Colors.green,
                      '<80 NTU',
                      List<FlSpot>.from(turbidityHistory),
                      dailyAvg: turbidityHistory.isNotEmpty
                          ? _averageLast24(
                                  turbidityHistory,
                                ).toStringAsFixed(2) +
                                ' NTU'
                          : '--',
                      high: turbidity != null
                          ? (turbidity! + 5).toStringAsFixed(2) + ' NTU'
                          : '--',
                      low: turbidity != null
                          ? (turbidity! - 5).toStringAsFixed(2) + ' NTU'
                          : '--',
                      tag: 'Live',
                    ),
                    child: StatCard(
                      title: 'Turbidity',
                      value: turbidity != null
                          ? turbidity!.toStringAsFixed(2)
                          : '--',
                      unit: 'NTU',
                      color: Colors.cyan,
                      status: (turbidity != null && turbidity! >= 80)
                          ? 'High'
                          : 'Normal',
                      statusColor: (turbidity != null && turbidity! >= 80)
                          ? Colors.red
                          : Colors.green,
                      safeRange: '<80 NTU',
                      chartData: List<FlSpot>.from(turbidityHistory),
                      isLive: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Critical Alert (keep as is)
                  Card(
                    color: Colors.red[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Critical Alert',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Temperature exceeds safe threshold in Pond A. Immediate action required.',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final Color color;
  final String status;
  final Color statusColor;
  final String safeRange;
  final List<FlSpot> chartData;
  final bool isLive;

  const StatCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
    required this.status,
    required this.statusColor,
    required this.safeRange,
    required this.chartData,
    this.isLive = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  '$value $unit',
                  style: TextStyle(
                    fontSize: 20,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData,
                      isCurved: true,
                      color: color,
                      barWidth: 2,
                      belowBarData: BarAreaData(show: false),
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  status == 'Normal'
                      ? Icons.check_circle
                      : status == 'Above threshold'
                      ? Icons.warning
                      : Icons.info,
                  color: statusColor,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'Safe range: $safeRange',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
