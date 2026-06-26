import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:getzio_billing/features/invoices/presentation/providers/invoice_provider.dart';
import 'package:getzio_billing/core/theme/app_colors.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesState = ref.watch(invoiceProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Insights'),
      ),
      body: SafeArea(
        child: invoicesState.when(
          data: (invoices) {
            if (invoices.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.borderDark : AppColors.borderLight).withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.bar_chart_rounded,
                        size: 48,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Create Invoices to Unlock Analytics',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                    ),
                  ],
                ),
              );
            }

            // Calculations
            double paidRevenue = 0.0;
            double outstandingBalance = 0.0;
            double draftValue = 0.0;
            double totalSalesValue = 0.0;
            int paidCount = 0;
            int pendingCount = 0;
            int overdueCount = 0;
            int draftCount = 0;

            final Map<String, double> customerSales = {};

            for (var inv in invoices) {
              if (inv.status == 'cancelled') continue;

              final total = inv.total;
              final paid = inv.amountPaid;
              final unpaid = total - paid;
              final clientName = inv.customerObject?.name ?? 'Unknown Customer';

              if (inv.status == 'draft') {
                draftValue += total;
                draftCount++;
              } else {
                totalSalesValue += total;
                paidRevenue += paid;
                outstandingBalance += unpaid;

                if (inv.status == 'paid') paidCount++;
                if (inv.status == 'pending') pendingCount++;
                if (inv.status == 'overdue') overdueCount++;

                customerSales[clientName] = (customerSales[clientName] ?? 0.0) + total;
              }
            }

            final averageInvoice = invoices.isEmpty ? 0.0 : totalSalesValue / (invoices.length - draftCount);

            // Sort customer sales
            final sortedCustomers = customerSales.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              children: [
                // Highlight Stats Grid
                _buildSectionHeader(context, 'Financial Overview'),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _buildStatCard(
                      context,
                      title: 'NET SALES',
                      value: currencyFormat.format(totalSalesValue),
                      color: Theme.of(context).colorScheme.primary,
                      icon: Icons.pie_chart_outline,
                      isDark: isDark,
                    ),
                    _buildStatCard(
                      context,
                      title: 'REVENUE COLLECTED',
                      value: currencyFormat.format(paidRevenue),
                      color: const Color(0xFF10B981), // Emerald
                      icon: Icons.check_circle_outline,
                      isDark: isDark,
                    ),
                    _buildStatCard(
                      context,
                      title: 'OUTSTANDING',
                      value: currencyFormat.format(outstandingBalance),
                      color: const Color(0xFFF59E0B), // Amber
                      icon: Icons.hourglass_empty_rounded,
                      isDark: isDark,
                    ),
                    _buildStatCard(
                      context,
                      title: 'AVERAGE INVOICE',
                      value: currencyFormat.format(averageInvoice),
                      color: const Color(0xFF8B5CF6), // Purple
                      icon: Icons.analytics_outlined,
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Documents status breakdown
                _buildSectionHeader(context, 'Invoices Status Breakdown'),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      children: [
                        _buildStatusProgressRow(context, label: 'Paid Invoices', count: paidCount, total: invoices.length - draftCount, color: const Color(0xFF10B981), isDark: isDark),
                        const SizedBox(height: 14),
                        _buildStatusProgressRow(context, label: 'Pending Invoices', count: pendingCount, total: invoices.length - draftCount, color: const Color(0xFFF59E0B), isDark: isDark),
                        const SizedBox(height: 14),
                        _buildStatusProgressRow(context, label: 'Overdue Invoices', count: overdueCount, total: invoices.length - draftCount, color: const Color(0xFFEF4444), isDark: isDark),
                        if (draftCount > 0) ...[
                          const SizedBox(height: 14),
                          _buildStatusProgressRow(context, label: 'Drafts', count: draftCount, total: invoices.length, color: const Color(0xFF64748B), isDark: isDark),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Top Customers Sales
                _buildSectionHeader(context, 'Top Customers by Sales Volume'),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: sortedCustomers.isEmpty
                        ? const ListTile(title: Text('No client data available'))
                        : Column(
                            children: sortedCustomers.take(5).map((entry) {
                              return ListTile(
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                      width: 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      entry.key.substring(0, 1).toUpperCase(),
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                trailing: Text(
                                  currencyFormat.format(entry.value),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text('Error rendering insights: $err', style: const TextStyle(color: Colors.red)),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.2,
          color: isDark ? Colors.white : AppColors.textPrimaryLight,
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Icon(icon, size: 16, color: color.withOpacity(0.8)),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusProgressRow(
    BuildContext context, {
    required String label,
    required int count,
    required int total,
    required Color color,
    required bool isDark,
  }) {
    final percent = total > 0 ? count / total : 0.0;
    final percentStr = (percent * 100).toStringAsFixed(0);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              '$count ($percentStr%)',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: (isDark ? AppColors.borderDark : AppColors.borderLight).withOpacity(0.5),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
