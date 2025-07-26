import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MonitorPage extends StatefulWidget {
  const MonitorPage({super.key});

  @override
  State<MonitorPage> createState() => _MonitorPageState();
}

class _MonitorPageState extends State<MonitorPage> {
  final DatabaseReference _sensorsRef = FirebaseDatabase.instance.ref(
    'Sensors',
  );

  // Live values
  double? temperature;
  double? ph;
  double? waterLevel;
  double? turbidity;

  // History
  List<FlSpot> tempHistory = [];
  List<FlSpot> phHistory = [];
  List<FlSpot> waterLevelHistory = [];
  List<FlSpot> turbidityHistory = [];

  String unit = 'Metric';

  @override
  void initState() {
    super.initState();
    _loadUnit();
    // Simulate history for now; will update with live data
    tempHistory = List.generate(
      12,
      (i) => FlSpot(i.toDouble(), 22.0 + i % 3 + (i % 2 == 0 ? 0.5 : -0.5)),
    );
    phHistory = List.generate(
      12,
      (i) => FlSpot(i.toDouble(), 7.0 + (i % 2 == 0 ? 0.2 : -0.2)),
    );
    waterLevelHistory = List.generate(
      12,
      (i) => FlSpot(i.toDouble(), 60.0 + i * 1.5),
    );
    turbidityHistory = List.generate(
      12,
      (i) => FlSpot(i.toDouble(), 10.0 + (i % 3)),
    );
  }

  Future<void> _loadUnit() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      unit = prefs.getString('unit_of_measurement') ?? 'Metric';
    });
  }

  double _toFahrenheit(double c) => c * 9 / 5 + 32;
  String get tempUnit => unit == 'Imperial' ? '°F' : '°C';
  String get tempSafeRange => unit == 'Imperial'
      ? '${_toFahrenheit(20).toStringAsFixed(0)}-${_toFahrenheit(30).toStringAsFixed(0)}°F'
      : '20-30°C';

  void _updateHistory(double? value, List<FlSpot> history) {
    if (value == null) return;
    if (history.length >= 20) {
      history.removeAt(0);
    }
    history.add(FlSpot(history.isNotEmpty ? history.last.x + 1 : 0, value));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: AppBar(
          backgroundColor:
              theme.appBarTheme.backgroundColor ??
              theme.scaffoldBackgroundColor,
          elevation: 0,
          flexibleSpace: Container(
            alignment: Alignment.bottomCenter,
            child: Image.asset(
              'assets/images/Fishly_logo.png',
              width: double.infinity,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(24),
            child: Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Last updated: Just now',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 48),
            StreamBuilder<DatabaseEvent>(
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
                  // Update histories
                  _updateHistory(temperature, tempHistory);
                  _updateHistory(ph, phHistory);
                  _updateHistory(waterLevel, waterLevelHistory);
                  _updateHistory(turbidity, turbidityHistory);
                }
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _WideParameterCard(
                        title: 'Temperature',
                        value: temperature != null
                            ? (unit == 'Imperial'
                                  ? '${_toFahrenheit(temperature!).toStringAsFixed(2)} $tempUnit'
                                  : '${temperature!.toStringAsFixed(2)} $tempUnit')
                            : '--',
                        normalRange: tempSafeRange,
                        color: Colors.orange,
                        icon: Icons.thermostat,
                      ),
                      const SizedBox(height: 16),
                      _WideParameterCard(
                        title: 'pH Level',
                        value: ph != null ? ph!.toStringAsFixed(2) : '--',
                        normalRange: '6.5-8.5',
                        color: Colors.green,
                        icon: Icons.science,
                      ),
                      const SizedBox(height: 16),
                      _WideParameterCard(
                        title: 'Water Turbidity',
                        value: turbidity != null
                            ? '${turbidity!.toStringAsFixed(2)} NTU'
                            : '--',
                        normalRange: '0-70 NTU',
                        color: Colors.blue,
                        icon: Icons.opacity,
                      ),
                      const SizedBox(height: 16),
                      _WideParameterCard(
                        title: 'Water Level',
                        value: waterLevel != null
                            ? '${waterLevel!.toStringAsFixed(2)}%'
                            : '--',
                        normalRange: '20-80%',
                        color: Colors.purple,
                        icon: Icons.water,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WideParameterCard extends StatelessWidget {
  final String title;
  final String value;
  final String normalRange;
  final Color color;
  final IconData icon;

  const _WideParameterCard({
    required this.title,
    required this.value,
    required this.normalRange,
    required this.color,
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 24,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Normal range: $normalRange',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
