import 'package:flutter/material.dart';
import 'package:health/health.dart';
// import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';

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
  final List<Widget> _pages = [const HealthDashboard(), const BMICalculator()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'BMI'),
        ],
      ),
    );
  }
}

class HealthDashboard extends StatefulWidget {
  const HealthDashboard({super.key});

  @override
  State<HealthDashboard> createState() => _HealthDashboardState();
}

class _HealthDashboardState extends State<HealthDashboard> {
  List<HealthDataPoint> _healthDataList = [];
  bool _isLoading = false;
  int _steps = 0;
  double _heartRate = 0;
  Health health = Health();

  Future<void> fetchData() async {
    setState(() => _isLoading = true);
    List<HealthDataType> types = [HealthDataType.STEPS, HealthDataType.HEART_RATE];
    
    bool accessGranted = await health.requestAuthorization(types);

    if (accessGranted) {
      DateTime now = DateTime.now();
      DateTime midNight = DateTime(now.year, now.month, now.day);
      
      try {
        List<HealthDataPoint> data = await health.getHealthDataFromTypes(startTime: midNight, endTime: now, types: types);
        int totalSteps = 0;
        double lastHeartRate = 0;

        for (var p in data) {
          if (p.type == HealthDataType.STEPS) {
            totalSteps += int.parse(p.value.toString());
          } else if (p.type == HealthDataType.HEART_RATE) {
            lastHeartRate = double.parse(p.value.toString());
          }
        }

        setState(() {
          _healthDataList = health.removeDuplicates(data);
          _steps = totalSteps;
          _heartRate = lastHeartRate;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
        debugPrint("Error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double stepGoal = 6000; 
    double progress = (_steps / stepGoal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("My Health", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(onPressed: fetchData, icon: const Icon(Icons.sync, color: Colors.blueAccent))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Circular Progress Section
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                // ignore: deprecated_member_use
                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: CircularPercentIndicator(
                radius: 110.0,
                lineWidth: 12.0,
                animation: true,
                percent: progress,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("$_steps", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 35)),
                    const Text("Steps", style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ],
                ),
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: Colors.blueAccent,
                backgroundColor: Colors.blue.shade50,
              ),
            ),
            const SizedBox(height: 25),
            
            // Stats Row
            Row(
              children: [
                _buildSmallCard("Heart Rate", "${_heartRate.toInt()} bpm", Icons.favorite, Colors.redAccent),
                const SizedBox(width: 15),
                _buildSmallCard("Goal", "${(progress * 100).toInt()}%", Icons.flag, Colors.orangeAccent),
              ],
            ),
            const SizedBox(height: 20),
            
            // Recent Data List
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Recent Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            _isLoading 
              ? const CircularProgressIndicator()
              : Column(
                  children: _healthDataList.take(5).map((p) => _buildDataRow(p)).toList(),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 15),
            Text(title, style: const TextStyle(color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(HealthDataPoint p) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Icon(p.type == HealthDataType.STEPS ? Icons.directions_walk : Icons.favorite, color: Colors.blueAccent),
        ),
        title: Text(p.typeString.split('.').last),
        trailing: Text(p.value.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class BMICalculator extends StatefulWidget {
  const BMICalculator({super.key});
  @override
  State<BMICalculator> createState() => _BMICalculatorState();
}

class _BMICalculatorState extends State<BMICalculator> {
  final _hC = TextEditingController();
  final _wC = TextEditingController();
  double? _bmi;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BMI Calculator"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            TextField(controller: _hC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Height (cm)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
            const SizedBox(height: 15),
            TextField(controller: _wC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Weight (kg)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent, 
                foregroundColor: Colors.white, 
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
              ),
              onPressed: () {
                double h = double.parse(_hC.text) / 100;
                double w = double.parse(_wC.text);
                setState(() => _bmi = w / (h * h));
              },
              child: const Text("Calculate My BMI", style: TextStyle(fontSize: 18)),
            ),
            if (_bmi != null) ...[
              const SizedBox(height: 40),
              const Text("Your BMI Result", style: TextStyle(color: Colors.grey)),
              Text(_bmi!.toStringAsFixed(1), style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              Text(_bmi! < 18.5 ? "Underweight" : _bmi! < 25 ? "Healthy" : "Overweight", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
            ]
          ],
        ),
      ),
    );
  }
}