// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:health/health.dart';
//import 'package:intl/intl.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainHomeScreen(),
    ));

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 0;

  // පිටු දෙක (Dashboard සහ BMI)
  final List<Widget> _pages = [
    const HealthDashboard(),
    const BMICalculator(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'BMI'),
        ],
      ),
    );
  }
}

// --- ලස්සන Dashboard එක ---
class HealthDashboard extends StatefulWidget {
  const HealthDashboard({super.key});

  @override
  State<HealthDashboard> createState() => _HealthDashboardState();
}

class _HealthDashboardState extends State<HealthDashboard> {
  List<HealthDataPoint> _healthDataList = [];
  bool _isLoading = false;
  Health health = Health();

Future<void> fetchData() async {
  setState(() => _isLoading = true);

  List<HealthDataType> types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
  ];

  try {
    bool accessGranted = await health.requestAuthorization(types);

    if (accessGranted) {
      DateTime now = DateTime.now();
      DateTime yesterday = now.subtract(const Duration(hours: 24));

      List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
        startTime: yesterday,
        endTime: now,
        types: types,
      );

      setState(() {
        _healthDataList = health.removeDuplicates(healthData);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      print("අවසර ලැබුණේ නැත");
    }
  } catch (e) {
    setState(() => _isLoading = false);
    print("Error: $e");
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Health Dashboard"), centerTitle: true),
      body: Column(
        children: [
          _buildSummaryCard(), // සාරාංශයක් පෙන්වන කාඩ් එක
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : ListView.builder(
                  itemCount: _healthDataList.length,
                  itemBuilder: (c, i) => _buildDataTile(_healthDataList[i]),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchData,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.green, Colors.teal]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Daily Goal", style: TextStyle(color: Colors.white70)),
              Text("6,500 Steps", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          Icon(Icons.directions_run, color: Colors.white, size: 40),
        ],
      ),
    );
  }

  Widget _buildDataTile(HealthDataPoint p) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: ListTile(
        leading: Icon(p.type == HealthDataType.STEPS ? Icons.nordic_walking : Icons.favorite, color: Colors.green),
        title: Text(p.typeString.replaceAll("HealthDataType.", "")),
        trailing: Text(p.value.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}

// --- BMI Calculator පිටුව ---
class BMICalculator extends StatefulWidget {
  const BMICalculator({super.key});

  @override
  State<BMICalculator> createState() => _BMICalculatorState();
}

class _BMICalculatorState extends State<BMICalculator> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  double? _bmiResult;

  void calculateBMI() {
    double h = double.tryParse(_heightController.text) ?? 0;
    double w = double.tryParse(_weightController.text) ?? 0;
    if (h > 0 && w > 0) {
      setState(() {
        _bmiResult = w / ((h / 100) * (h / 100));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BMI Calculator")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: _heightController, decoration: const InputDecoration(labelText: "උස (cm)", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _weightController, decoration: const InputDecoration(labelText: "බර (kg)", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: calculateBMI, child: const Text("ගණනය කරන්න")),
            if (_bmiResult != null) ...[
              const SizedBox(height: 30),
              Text("ඔබේ BMI අගය: ${_bmiResult!.toStringAsFixed(1)}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(_bmiResult! < 18.5 ? "අඩු බර (Underweight)" : _bmiResult! < 25 ? "සාමාන්‍ය බර (Normal)" : "වැඩි බර (Overweight)", 
                style: TextStyle(fontSize: 18, color: Colors.blueGrey[700])),
            ]
          ],
        ),
      ),
    );
  }
}