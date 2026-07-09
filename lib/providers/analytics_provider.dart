import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thumbhq/providers/project_provider.dart';

import '../core/constants/app_constants.dart';
import '../models/commission_model.dart';
import '../models/project_model.dart';
import '../models/revenue_model.dart';
import '../models/client_model.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';
import 'client_provider.dart';
import 'user_provider.dart';

final commissionsProvider = StreamProvider<List<CommissionModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamCommissions();
});

final allRevenuesProvider = StreamProvider<List<RevenueModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamAllRevenues();
});

/// Computes all analytics data from streams
final analyticsDataProvider = Provider<AnalyticsData>((ref) {
  final projects = (ref.watch(allProjectsProvider).value ?? [])
      .where((p) => p.status != ProjectStatus.practice)
      .toList();
  final commissions = ref.watch(commissionsProvider).value ?? [];
  final revenues = ref.watch(allRevenuesProvider).value ?? [];
  final clients = ref.watch(clientsProvider).value ?? [];
  final users = ref.watch(allUsersProvider).value ?? [];
  
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);

  String getUserName(String uid) {
    try {
      return users.firstWhere((u) => u.uid == uid).displayName;
    } catch (_) {
      return 'Unknown';
    }
  }

  // Helper map for client ticket sizes
  final clientTicketSizes = {for (var c in clients) c.id: c.averagePayout};

  // 1. Total projects done this month
  final completedThisMonth = projects.where((p) => 
    p.status == ProjectStatus.completed && 
    p.updatedAt.isAfter(startOfMonth)
  ).toList();

  final totalProjectsDoneThisMonth = completedThisMonth.length;

  // 2. Strategist pie chart (% of total projects done this month)
  final strategistMap = <String, int>{};
  for (var p in completedThisMonth) {
    if (p.strategistId != null && p.strategistId!.isNotEmpty) {
      final name = getUserName(p.strategistId!);
      strategistMap[name] = (strategistMap[name] ?? 0) + 1;
    }
  }

  // 3. Designer pie chart (total project revenue done this month)
  final designerRevenueMap = <String, double>{};
  for (var p in completedThisMonth) {
    if (p.designerId != null && p.designerId!.isNotEmpty && p.clientId != null) {
      final name = getUserName(p.designerId!);
      final ticketSize = clientTicketSizes[p.clientId] ?? 0.0;
      designerRevenueMap[name] = (designerRevenueMap[name] ?? 0.0) + ticketSize;
    }
  }
  
  // 4. Project revenue chart (monthly)
  final projectRevenueByMonth = <int, double>{};
  for (var p in projects) {
    if (p.status == ProjectStatus.completed && p.clientId != null) {
      final ticketSize = clientTicketSizes[p.clientId] ?? 0.0;
      final month = p.updatedAt.month;
      // Note: this groups across years if not filtered. Assuming current year for simplicity.
      if (p.updatedAt.year == now.year) {
        projectRevenueByMonth[month] = (projectRevenueByMonth[month] ?? 0.0) + ticketSize;
      }
    }
  }

  // 5. Direct Revenue this month and by month
  double directRevenueThisMonth = 0.0;
  final directRevenueByMonth = <int, double>{};
  for (var r in revenues) {
    if (r.createdAt.year == now.year) {
      final month = r.createdAt.month;
      directRevenueByMonth[month] = (directRevenueByMonth[month] ?? 0.0) + r.amount;
      if (r.createdAt.isAfter(startOfMonth)) {
        directRevenueThisMonth += r.amount;
      }
    }
  }

  // 6. Designer commission this month and by month
  final designerCommissionsMap = <String, double>{};
  final commissionsByMonth = <int, double>{};
  double totalDesignerCostThisMonth = 0.0;
  for (var c in commissions) {
    if (c.role == 'designer') {
      if (c.createdAt.year == now.year) {
        final month = c.createdAt.month;
        commissionsByMonth[month] = (commissionsByMonth[month] ?? 0.0) + c.amount;
      }
      if (c.createdAt.isAfter(startOfMonth)) {
        final name = getUserName(c.userId);
        designerCommissionsMap[name] = (designerCommissionsMap[name] ?? 0.0) + c.amount;
        totalDesignerCostThisMonth += c.amount;
      }
    }
  }

  // 7. Average client retention and daily retention for last 7 days
  double averageClientRetention = 0.0;
  final retentionByDay = <int, double>{};
  
  if (clients.isNotEmpty) {
    int totalDays = 0;
    for (var c in clients) {
      final end = c.endDate ?? now;
      totalDays += end.difference(c.onboardingDate).inDays;
    }
    averageClientRetention = totalDays / clients.length;

    // Calculate daily retention for the sparkline (last 7 days)
    for (int i = 6; i >= 0; i--) {
      final targetDate = now.subtract(Duration(days: i));
      
      final activeOrPastClients = clients.where((c) {
        // Only include clients that onboarded before or on the target date
        return c.onboardingDate.isBefore(targetDate) || c.onboardingDate.isAtSameMomentAs(targetDate);
      }).toList();
      
      if (activeOrPastClients.isEmpty) {
        retentionByDay[7 - i] = 0.0;
        continue;
      }

      int dailyTotalDays = 0;
      for (var c in activeOrPastClients) {
        final end = (c.endDate != null && c.endDate!.isBefore(targetDate)) ? c.endDate! : targetDate;
        dailyTotalDays += end.difference(c.onboardingDate).inDays;
      }
      retentionByDay[7 - i] = dailyTotalDays / activeOrPastClients.length;
    }
  } else {
    // Fill with 0 if no clients
    for (int i = 6; i >= 0; i--) {
      retentionByDay[7 - i] = 0.0;
    }
  }

  return AnalyticsData(
    totalProjectsDoneThisMonth: totalProjectsDoneThisMonth,
    strategistProjectsMap: strategistMap,
    designerRevenueMap: designerRevenueMap,
    projectRevenueByMonth: projectRevenueByMonth,
    directRevenueThisMonth: directRevenueThisMonth,
    designerCommissionsMap: designerCommissionsMap,
    totalDesignerCostThisMonth: totalDesignerCostThisMonth,
    averageClientRetention: averageClientRetention,
    commissionsByMonth: commissionsByMonth,
    directRevenueByMonth: directRevenueByMonth,
    retentionByDay: retentionByDay,
  );
});

class AnalyticsData {
  final int totalProjectsDoneThisMonth;
  final Map<String, int> strategistProjectsMap;
  final Map<String, double> designerRevenueMap;
  final Map<int, double> projectRevenueByMonth; // 1-12
  final double directRevenueThisMonth;
  final Map<String, double> designerCommissionsMap;
  final double totalDesignerCostThisMonth;
  final double averageClientRetention;
  final Map<int, double> commissionsByMonth;
  final Map<int, double> directRevenueByMonth;
  final Map<int, double> retentionByDay;

  AnalyticsData({
    required this.totalProjectsDoneThisMonth,
    required this.strategistProjectsMap,
    required this.designerRevenueMap,
    required this.projectRevenueByMonth,
    required this.directRevenueThisMonth,
    required this.designerCommissionsMap,
    required this.totalDesignerCostThisMonth,
    required this.averageClientRetention,
    required this.commissionsByMonth,
    required this.directRevenueByMonth,
    required this.retentionByDay,
  });
}
