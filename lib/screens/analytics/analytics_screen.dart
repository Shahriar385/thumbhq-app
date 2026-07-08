import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsDataProvider);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Analytics Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Top Metrics ──────────────────────────────────────────────────
            if (isDesktop)
              Row(
                children: [
                  Expanded(child: _buildMetricCard('Total Projects (This Month)', analytics.totalProjectsDoneThisMonth.toString(), Icons.assignment_turned_in)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMetricCard('Direct Revenue (This Month)', '\$${analytics.directRevenueThisMonth.toStringAsFixed(2)}', Icons.attach_money)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMiniLineChartCard(analytics.retentionByDay)),
                ],
              )
            else
              Column(
                children: [
                  _buildMetricCard('Total Projects (This Month)', analytics.totalProjectsDoneThisMonth.toString(), Icons.assignment_turned_in),
                  const SizedBox(height: 16),
                  _buildMetricCard('Direct Revenue (This Month)', '\$${analytics.directRevenueThisMonth.toStringAsFixed(2)}', Icons.attach_money),
                  const SizedBox(height: 16),
                  _buildMiniLineChartCard(analytics.retentionByDay),
                ],
              ),
            const SizedBox(height: 32),
            
            // ─── Time-Series Line Charts (Tabs) ───────────────────────────────
            _LineChartTabWidget(
              projectRevenue: analytics.projectRevenueByMonth,
              commissions: analytics.commissionsByMonth,
              directRevenue: analytics.directRevenueByMonth,
            ),
            const SizedBox(height: 32),

            // ─── Pie Charts ───────────────────────────────────────────────────
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Expanded(
                  child: _buildChartCard(
                    title: 'Projects by Strategist',
                    subtitle: '% of Total Projects Done (This Month)',
                    child: _DonutChartWidget(
                      data: analytics.strategistProjectsMap.map((k, v) => MapEntry(k, v.toDouble())),
                      centerTitle: analytics.totalProjectsDoneThisMonth.toString(),
                      centerSubtitle: 'Total Project Done',
                      isCurrency: false,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildChartCard(
                    title: 'Revenue by Designer',
                    subtitle: '% of Project Revenue Contributed (This Month)',
                    child: _DonutChartWidget(
                      data: analytics.designerRevenueMap,
                      centerTitle: '\$${analytics.designerRevenueMap.values.fold(0.0, (a, b) => a + b).toStringAsFixed(0)}',
                      centerSubtitle: 'Total Revenue',
                      isCurrency: true,
                    ),
                  ),
                ),
              ],
              )
            else
              Column(
                children: [
                  _buildChartCard(
                    title: 'Projects by Strategist',
                    subtitle: '% of Total Projects Done (This Month)',
                    child: _DonutChartWidget(
                      data: analytics.strategistProjectsMap.map((k, v) => MapEntry(k, v.toDouble())),
                      centerTitle: analytics.totalProjectsDoneThisMonth.toString(),
                      centerSubtitle: 'Total Project Done',
                      isCurrency: false,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildChartCard(
                    title: 'Revenue by Designer',
                    subtitle: '% of Project Revenue Contributed (This Month)',
                    child: _DonutChartWidget(
                      data: analytics.designerRevenueMap,
                      centerTitle: '\$${analytics.designerRevenueMap.values.fold(0.0, (a, b) => a + b).toStringAsFixed(0)}',
                      centerSubtitle: 'Total Revenue',
                      isCurrency: true,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 32),

          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.accent, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniLineChartCard(Map<int, double> data) {
    final spots = data.entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    final minX = spots.isEmpty ? 0.0 : spots.first.x;
    final maxX = spots.isEmpty ? 1.0 : spots.last.x;
    final minY = 0.0;
    final maxY = data.values.isEmpty ? 10.0 : (data.values.reduce((a, b) => a > b ? a : b) * 1.5).ceilToDouble();

    final _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();

    return Container(
      height: 104,
      padding: const EdgeInsets.only(left: 16, right: 24, top: 12, bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 0,
            right: 0,
            child: Text(
              'Avg. Client Retention',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: LineChart(
              LineChartData(
                minX: minX,
                maxX: maxX,
                minY: minY,
                maxY: maxY == 0 ? 10 : maxY,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => Colors.transparent,
                    tooltipPadding: const EdgeInsets.all(0),
                    tooltipMargin: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        return LineTooltipItem(
                          '${touchedSpot.y.toStringAsFixed(0)}',
                          const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value == 1 || value == 4 || value == 7) {
                          final date = now.subtract(Duration(days: 7 - value.toInt()));
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('${_months[date.month - 1]} ${date.day}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      interval: maxY == 0 ? 5 : (maxY / 2).ceilToDouble(),
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10));
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(
                  show: true,
                  border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.2), width: 1)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.accent,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        // Only show dot for the last point or if hovered
                        if (index == spots.length - 1) {
                          return FlDotCirclePainter(
                            radius: 3,
                            color: AppColors.cardBackground,
                            strokeWidth: 2,
                            strokeColor: AppColors.accent,
                          );
                        }
                        return FlDotCirclePainter(radius: 0, color: Colors.transparent, strokeWidth: 0);
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accent.withValues(alpha: 0.2),
                          AppColors.accent.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
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

  Widget _buildChartCard({required String title, required String subtitle, required Widget child}) {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 24),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<String, double> data) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available', style: TextStyle(color: AppColors.textMuted)));
    }

    final maxVal = data.values.reduce((a, b) => a > b ? a : b);
    
    final barGroups = <BarChartGroupData>[];
    int xIndex = 0;
    final xLabels = <int, String>{};

    for (var entry in data.entries) {
      xLabels[xIndex] = entry.key;
      barGroups.add(
        BarChartGroupData(
          x: xIndex,
          barRods: [
            BarChartRodData(
              toY: entry.value,
              color: AppColors.accent,
              width: 22,
              borderRadius: BorderRadius.circular(4),
            )
          ],
        ),
      );
      xIndex++;
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    xLabels[value.toInt()] ?? '',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.border.withAlpha(50),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }
}

class _LineChartTabWidget extends StatefulWidget {
  final Map<int, double> projectRevenue;
  final Map<int, double> commissions;
  final Map<int, double> directRevenue;

  const _LineChartTabWidget({
    required this.projectRevenue,
    required this.commissions,
    required this.directRevenue,
  });

  @override
  State<_LineChartTabWidget> createState() => _LineChartTabWidgetState();
}

class _LineChartTabWidgetState extends State<_LineChartTabWidget> {
  int _selectedTabIndex = 0; // 0: Project, 1: Commissions, 2: Direct

  final _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    Map<int, double> activeData;
    if (_selectedTabIndex == 0) activeData = widget.projectRevenue;
    else if (_selectedTabIndex == 1) activeData = widget.commissions;
    else activeData = widget.directRevenue;

    return Container(
      height: 450,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTab(0, 'Project Revenue', Icons.pie_chart_outline),
                const SizedBox(width: 8),
                _buildTab(1, 'Commissions', Icons.pie_chart_outline),
                const SizedBox(width: 8),
                _buildTab(2, 'Revenue', Icons.pie_chart_outline),
              ],
            ),
          ),
          const SizedBox(height: 48),
          // Chart
          Expanded(child: _buildLineChart(activeData)),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String title, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.border : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? AppColors.textPrimary : AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(Map<int, double> data) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available', style: TextStyle(color: AppColors.textMuted)));
    }

    final maxVal = data.values.isEmpty ? 10.0 : data.values.reduce((a, b) => a > b ? a : b);
    
    // Create spots
    final spots = <FlSpot>[];
    final sortedKeys = data.keys.toList()..sort();
    
    for (var month in sortedKeys) {
      spots.add(FlSpot(month.toDouble(), data[month]!));
    }

    final gradient = LinearGradient(
      colors: [
        AppColors.accent.withValues(alpha: 0.3),
        AppColors.accent.withValues(alpha: 0.0),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final lineBarData = LineChartBarData(
      spots: spots,
      isCurved: false,
      color: AppColors.accent,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 3,
            color: AppColors.cardBackground,
            strokeWidth: 2,
            strokeColor: AppColors.accent,
          );
        }
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: gradient,
      ),
    );

    // Prepare tooltip indicators for every point
    final tooltipIndicators = <ShowingTooltipIndicators>[];
    for (var i = 0; i < spots.length; i++) {
      tooltipIndicators.add(ShowingTooltipIndicators([
        LineBarSpot(lineBarData, 0, spots[i]),
      ]));
    }

    return LineChart(
      LineChartData(
        minX: sortedKeys.first.toDouble(),
        maxX: sortedKeys.last.toDouble(),
        minY: 0,
        maxY: maxVal * 1.3, // space for tooltips
        lineTouchData: LineTouchData(
          enabled: false,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.transparent,
            tooltipPadding: const EdgeInsets.all(0),
            tooltipMargin: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                return LineTooltipItem(
                  '\$${touchedSpot.y.toStringAsFixed(2)}',
                  const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        showingTooltipIndicators: tooltipIndicators,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final monthIndex = value.toInt() - 1;
                if (monthIndex >= 0 && monthIndex < 12) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text('${_months[monthIndex]} ${DateTime.now().year}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                String label;
                if (value == 0) {
                  label = '\$0.00';
                } else if (value >= 1000) {
                  label = '\$${(value / 1000).toStringAsFixed(2)}K';
                } else {
                  label = '\$${value.toStringAsFixed(2)}';
                }
                return Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.border.withValues(alpha: 0.1),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.2), width: 1)),
        ),
        lineBarsData: [lineBarData],
      ),
    );
  }
}

class _DonutChartWidget extends StatefulWidget {
  final Map<String, double> data;
  final String centerTitle;
  final String centerSubtitle;
  final bool isCurrency;

  const _DonutChartWidget({
    required this.data,
    required this.centerTitle,
    required this.centerSubtitle,
    this.isCurrency = false,
  });

  @override
  State<_DonutChartWidget> createState() => _DonutChartWidgetState();
}

class _DonutChartWidgetState extends State<_DonutChartWidget> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const Center(child: Text('No data for this month', style: TextStyle(color: AppColors.textMuted)));
    }

    final total = widget.data.values.fold(0.0, (a, b) => a + b);

    final colors = [
      const Color(0xFFD09DF7),
      const Color(0xFFA671CF),
      const Color(0xFF8152A2),
      const Color(0xFF633D7D),
      const Color(0xFF4C2B63),
    ];

    return Column(
      children: [

        // Donut Chart
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final minSize = constraints.maxWidth < constraints.maxHeight 
                  ? constraints.maxWidth 
                  : constraints.maxHeight;
              
              final ringThickness = 22.0;
              final centerRadius = (minSize / 2) - ringThickness;

              int colorIndex = 0;
              final sections = widget.data.entries.map((entry) {
                final isTouched = colorIndex == _touchedIndex;
                final color = colors[colorIndex % colors.length];
                
                String valStr;
                if (widget.isCurrency) {
                  valStr = entry.value >= 1000 
                      ? '\$${(entry.value / 1000).toStringAsFixed(1)}K' 
                      : '\$${entry.value.toStringAsFixed(0)}';
                } else {
                  valStr = entry.value.toStringAsFixed(0);
                }
                
                final percentage = total == 0 ? 0 : (entry.value / total) * 100;
                final tooltipText = '${entry.key}\n$valStr (${percentage.toStringAsFixed(1)}%)';
                
                final section = PieChartSectionData(
                  color: color,
                  value: entry.value,
                  title: isTouched ? tooltipText : '',
                  radius: isTouched ? ringThickness + 10 : ringThickness,
                  showTitle: isTouched,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                );
                colorIndex++;
                return section;
              }).toList();

              // Format center title nicely if currency
              String finalCenterTitle = widget.centerTitle;
              if (widget.isCurrency) {
                final val = double.tryParse(widget.centerTitle.replaceAll('\$', '')) ?? 0.0;
                if (val >= 1000) {
                  finalCenterTitle = '\$${(val / 1000).toStringAsFixed(1)}K';
                }
              }

              return Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sectionsSpace: 3,
                      centerSpaceRadius: centerRadius > 0 ? centerRadius : 40,
                      sections: sections,
                    ),
                  ),
                  if (_touchedIndex == -1)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          finalCenterTitle,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.centerSubtitle,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
