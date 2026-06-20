import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Eyeventory/services/firebase_services.dart';
import 'package:Eyeventory/utils/constants.dart';
import 'package:Eyeventory/widgets/widgets.dart';
import 'package:Eyeventory/models/inventory_item.dart';

class StoreInsights extends ConsumerStatefulWidget {
  const StoreInsights({super.key});

  @override
  ConsumerState<StoreInsights> createState() => _StoreInsightsState();
}

class _StoreInsightsState extends ConsumerState<StoreInsights> {
  @override
  Widget build(BuildContext context) {
    final fridgesAsync = ref.watch(userFridgesProvider);
    final storeName = ref.watch(storeNameProvider);

    final fridges = fridgesAsync.value ?? [];
    final List<InventoryItem> allItems = [];

    // Dynamically watch each fridge's items to calculate combined stats reactively
    for (final fridge in fridges) {
      final fridgeId = fridge['id'] as String;
      final itemsAsync = ref.watch(fridgeItemsProvider(fridgeId));
      final items = itemsAsync.value ?? [];
      allItems.addAll(items);
    }

    // Calculations
    final int totalItems = allItems.length;
    final int expiringSoon = allItems.where((i) => i.status == 'Expiring Soon').length;
    final int spoiled = allItems.where((i) => i.status == 'Spoiled').length;
    final double wasteRateVal = (totalItems + spoiled) > 0 
        ? (spoiled / (totalItems + spoiled)) * 100 
        : 0.0;
    final String wasteRate = '${wasteRateVal.toStringAsFixed(0)}%';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppHeader(
        title: storeName,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: fridgesAsync.when(
          data: (_) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsGrid(totalItems, expiringSoon, wasteRate, spoiled),
                  const SizedBox(height: 24),
                  _buildWasteOverTimeChart(allItems),
                  const SizedBox(height: 24),
                  _buildDonutChartsRow(allItems, totalItems, spoiled),
                  const SizedBox(height: 80), // Bottom padding for nav bar
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text('Error loading insights: $err', style: const TextStyle(color: Colors.red)),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(int totalItems, int expiringSoon, String wasteRate, int spoiled) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Total Items',
                value: '$totalItems',
                color: statusFresh,
                isActive: false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                label: 'Expiring Soon',
                value: '$expiringSoon',
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
                value: '$spoiled',
                color: statusSpoiled,
                isActive: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWasteOverTimeChart(List<InventoryItem> allItems) {
    // Group spoiled items by expiry month (0 = Jan, 11 = Dec)
    final Map<int, int> monthlyWaste = {
      0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0,
      6: 0, 7: 0, 8: 0, 9: 0, 10: 0, 11: 0,
    };

    final spoiledItems = allItems.where((i) => i.status == 'Spoiled').toList();
    for (final item in spoiledItems) {
      if (item.expiryDate != null) {
        final month = item.expiryDate!.month - 1; // 0-indexed
        if (month >= 0 && month < 12) {
          monthlyWaste[month] = (monthlyWaste[month] ?? 0) + 1;
        }
      }
    }

    final List<FlSpot> spots = [];
    double maxWaste = 0;
    for (int i = 0; i < 12; i++) {
      final val = (monthlyWaste[i] ?? 0).toDouble();
      spots.add(FlSpot(i.toDouble(), val));
      if (val > maxWaste) {
        maxWaste = val;
      }
    }

    // Dynamic maxY calculation with baseline safety
    final double maxY = max(maxWaste * 1.2, 5.0);

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
          const Text(
            'Waste Over Time',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
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
                      interval: 2,
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
                            text = const Text('Mar', style: style);
                            break;
                          case 4:
                            text = const Text('May', style: style);
                            break;
                          case 6:
                            text = const Text('Jul', style: style);
                            break;
                          case 8:
                            text = const Text('Sep', style: style);
                            break;
                          case 10:
                            text = const Text('Nov', style: style);
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
                      interval: (maxY / 4).clamp(1.0, double.infinity),
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
                maxX: 11,
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
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

  Widget _buildDonutChartsRow(List<InventoryItem> allItems, int totalItems, int spoiledCount) {
    // 1. Item Status Donut Chart Calculations
    final int freshCount = allItems.where((i) => i.status == 'Fresh').length;
    final int expiringCount = allItems.where((i) => i.status == 'Expiring Soon').length;

    final double totalForStatus = (freshCount + expiringCount + spoiledCount).toDouble();

    final List<PieChartSectionData> statusSections = [];
    if (totalForStatus > 0) {
      statusSections.add(PieChartSectionData(
        color: statusFresh,
        value: freshCount.toDouble(),
        radius: 20,
        showTitle: false,
      ));
      statusSections.add(PieChartSectionData(
        color: statusExpiring,
        value: expiringCount.toDouble(),
        radius: 20,
        showTitle: false,
      ));
      statusSections.add(PieChartSectionData(
        color: statusSpoiled,
        value: spoiledCount.toDouble(),
        radius: 20,
        showTitle: false,
      ));
    } else {
      // Empty state donut chart segment
      statusSections.add(PieChartSectionData(
        color: Colors.grey[200]!,
        value: 1,
        radius: 20,
        showTitle: false,
      ));
    }

    final double freshPercent = totalForStatus > 0 ? (freshCount / totalForStatus) * 100 : 0.0;
    final double expiringPercent = totalForStatus > 0 ? (expiringCount / totalForStatus) * 100 : 0.0;
    final double spoiledPercent = totalForStatus > 0 ? (spoiledCount / totalForStatus) * 100 : 0.0;

    // 2. Waste by Category Donut Chart Calculations
    final Map<String, int> categoryWaste = {};
    for (final cat in itemCategories) {
      categoryWaste[cat] = 0;
    }

    final spoiledItems = allItems.where((i) => i.status == 'Spoiled').toList();
    for (final item in spoiledItems) {
      categoryWaste[item.category] = (categoryWaste[item.category] ?? 0) + 1;
    }

    final double totalSpoiled = spoiledCount.toDouble();
    final List<PieChartSectionData> categorySections = [];
    final List<Color> categoryColors = [
      statusFresh, // Produce (Green)
      Colors.blue, // Dairy (Blue)
      statusExpiring, // Meat (Orange)
      Colors.lightBlueAccent, // Frozen (Light blue)
      Colors.cyan, // Beverage (Cyan)
      Colors.grey, // Others (Grey)
    ];

    if (totalSpoiled > 0) {
      for (int i = 0; i < itemCategories.length; i++) {
        final cat = itemCategories[i];
        final count = categoryWaste[cat] ?? 0;
        if (count > 0) {
          categorySections.add(PieChartSectionData(
            color: categoryColors[i % categoryColors.length],
            value: count.toDouble(),
            radius: 20,
            showTitle: false,
          ));
        }
      }
    } else {
      categorySections.add(PieChartSectionData(
        color: Colors.grey[200]!,
        value: 1,
        radius: 20,
        showTitle: false,
      ));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1: Item Status
        Expanded(
          child: _buildDonutChartCard(
            title: 'Item Status',
            sections: statusSections,
            legendItems: [
              _buildLegendItem(
                color: statusFresh,
                label: 'Fresh',
                value: '${freshPercent.toStringAsFixed(0)}%',
                isDown: false,
              ),
              _buildLegendItem(
                color: statusExpiring,
                label: 'Expiring Soon',
                value: '${expiringPercent.toStringAsFixed(0)}%',
                isDown: false,
              ),
              _buildLegendItem(
                color: statusSpoiled,
                label: 'Spoiled',
                value: '${spoiledPercent.toStringAsFixed(0)}%',
                isDown: true,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Card 2: Waste by Category
        Expanded(
          child: _buildDonutChartCard(
            title: 'Waste by Category',
            sections: categorySections,
            legendItems: List.generate(itemCategories.length, (index) {
              final cat = itemCategories[index];
              final count = categoryWaste[cat] ?? 0;
              final percent = totalSpoiled > 0 ? (count / totalSpoiled) * 100 : 0.0;
              return _buildLegendItem(
                color: categoryColors[index % categoryColors.length],
                label: cat,
                value: '${percent.toStringAsFixed(0)}%',
                isDown: true,
              );
            }),
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
                centerSpaceRadius: 35,
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
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
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
