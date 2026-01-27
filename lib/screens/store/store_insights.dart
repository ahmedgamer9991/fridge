import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:Eyeventory/utils/constants.dart';
import 'package:Eyeventory/widgets/widgets.dart';

class StoreInsights extends StatefulWidget {
  const StoreInsights({super.key});

  @override
  State<StoreInsights> createState() => _StoreInsightsState();
}

class _StoreInsightsState extends State<StoreInsights> {
  // Mock Data
  final String totalItems = '1125';
  final String expiringSoon = '5';
  final String wasteRate = '33%';
  final String spoiled = '27';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppHeader(
        title: 'Dashboard',
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsGrid(),
              const SizedBox(height: 24),
              _buildWasteOverTimeChart(),
              const SizedBox(height: 24),
              _buildDonutChartsRow(),
              const SizedBox(height: 80), // Bottom padding for nav bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Total Items',
                value: totalItems,
                color: statusFresh,
                isActive: false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                label: 'Expiring Soon',
                value: expiringSoon,
                color: statusExpiring,
                isActive: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Waste Rate',
                value: wasteRate,
                color: const Color(0xFFFFC107), // Amber
                isActive: false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                label: 'Spoiled',
                value: spoiled,
                color: statusSpoiled,
                isActive: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWasteOverTimeChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Waste Over Time',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 100,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        );
                        Widget text;
                        switch (value.toInt()) {
                          case 0:
                            text = const Text('Jan', style: style);
                            break;
                          case 2:
                            text = const Text('Feb', style: style);
                            break;
                          case 4:
                            text = const Text('Mar', style: style);
                            break;
                          case 6:
                            text = const Text('Apr', style: style);
                            break;
                          case 8:
                            text = const Text('May', style: style);
                            break;
                          case 10:
                            text = const Text('Jun', style: style);
                            break;
                          case 12:
                            text = const Text('Jul', style: style);
                            break;
                          default:
                            text = const Text('', style: style);
                        }
                        return SideTitleWidget(meta: meta, child: text);
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 100,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 12,
                minY: 0,
                maxY: 500,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 360),
                      FlSpot(4, 200),
                      FlSpot(6, 250),
                      FlSpot(12, 50),
                    ],
                    isCurved: false,
                    color: Colors.orange,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.orange.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChartsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildDonutChartCard(
            title: 'Item Status',
            sections: [
              PieChartSectionData(
                color: statusFresh,
                value: 25,
                radius: 25,
                showTitle: false,
              ),
              PieChartSectionData(
                color: statusExpiring,
                value: 40,
                radius: 25,
                showTitle: false,
              ),
              PieChartSectionData(
                color: statusSpoiled,
                value: 35,
                radius: 25,
                showTitle: false,
              ),
            ],
            legendItems: [
              _buildLegendItem(
                color: statusFresh,
                label: 'Fresh',
                value: '25%',
              ),
              _buildLegendItem(
                color: statusExpiring,
                label: 'Expiring',
                value: '40%',
              ),
              _buildLegendItem(
                color: statusSpoiled,
                label: 'Expired',
                value: '35%',
                isDown: true,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDonutChartCard(
            title: 'Waste by Category',
            sections: [
              PieChartSectionData(
                color: statusFresh, // Veggies (Green)
                value: 25,
                radius: 25,
                showTitle: false,
              ),
              PieChartSectionData(
                color: statusExpiring, // Meat (Orange)
                value: 40,
                radius: 25,
                showTitle: false,
              ),
              PieChartSectionData(
                color: Colors.lightBlue, // Beverages (Blue)
                value: 35,
                radius: 25,
                showTitle: false,
              ),
            ],
            legendItems: [
              _buildLegendItem(
                color: statusFresh,
                label: 'Veggies',
                value: '25%',
              ),
              _buildLegendItem(
                color: statusExpiring,
                label: 'Meat',
                value: '40%',
              ),
              _buildLegendItem(
                color: Colors.lightBlue,
                label: 'Beverages',
                value: '35%',
                isDown: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDonutChartCard({
    required String title,
    required List<PieChartSectionData> sections,
    required List<Widget> legendItems,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 0,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...legendItems,
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String value,
    bool isDown = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(
                isDown ? Icons.arrow_downward : Icons.arrow_upward,
                size: 14,
                color: isDown ? statusSpoiled : statusFresh,
              ),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
