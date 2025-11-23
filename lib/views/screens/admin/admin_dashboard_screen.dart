import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../view_models/admin_appointments_view_model.dart';
import '../../../view_models/admin_doctors_view_model.dart';
import '../../../core/themes/app_colors.dart';
import '../auth/login_view.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<AdminAppointmentsViewModel>(context, listen: false).fetchCounts();
      Provider.of<AdminDoctorsViewModel>(context, listen: false).fetchCounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Using a soft background color for the whole screen
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Provider.of<AdminAppointmentsViewModel>(context, listen: false).fetchCounts();
            await Provider.of<AdminDoctorsViewModel>(context, listen: false).fetchCounts();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Custom Header
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Portal',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Dashboard Overview',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Main Content
              SliverPadding(
                padding: const EdgeInsets.all(20.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Action Banner
                    _buildVerifyDoctorsBanner(context),
                    const SizedBox(height: 24),

                    // Appointment Stats Section
                    const _SectionHeader(title: "Appointment Metrics"),
                    const SizedBox(height: 12),
                    
                    Consumer<AdminAppointmentsViewModel>(
                      builder: (context, vm, child) {
                        if (vm.isLoading && vm.totalCount == 0) return const _LoadingSkeleton(height: 120);
                        if (vm.error != null) return _ErrorWidget(message: vm.error!);

                        return Row(
                          children: [
                            Expanded(child: _ModernStatCard(
                              title: 'Today',
                              value: vm.todayCount.toString(),
                              icon: Icons.calendar_today,
                              color: Colors.blueAccent,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _ModernStatCard(
                              title: 'This Month',
                              value: vm.monthCount.toString(),
                              icon: Icons.calendar_month,
                              color: Colors.indigoAccent,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _ModernStatCard(
                              title: 'All Time',
                              value: vm.totalCount.toString(),
                              icon: Icons.history,
                              color: Colors.purpleAccent,
                            )),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Appointment Status Grid
                    Consumer<AdminAppointmentsViewModel>(
                      builder: (context, vm, child) {
                         if (vm.isLoading && vm.scheduledCount == 0) return const SizedBox();
                         
                         return Container(
                           padding: const EdgeInsets.all(16),
                           decoration: BoxDecoration(
                             color: Colors.white,
                             borderRadius: BorderRadius.circular(20),
                             boxShadow: [
                               BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                             ],
                           ),
                           child: Column(
                             children: [
                               Row(
                                 children: [
                                   Expanded(child: _StatusSummaryBox(label: 'Pending', count: vm.scheduledCount, color: Colors.orange)),
                                   const SizedBox(width: 12),
                                   Expanded(child: _StatusSummaryBox(label: 'Confirmed', count: vm.confirmedCount, color: Colors.blue)),
                                 ],
                               ),
                               const SizedBox(height: 12),
                               Row(
                                 children: [
                                   Expanded(child: _StatusSummaryBox(label: 'Completed', count: vm.completedCount, color: Colors.green)),
                                   const SizedBox(width: 12),
                                   Expanded(child: _StatusSummaryBox(label: 'Cancelled', count: vm.cancelledCount, color: Colors.red)),
                                 ],
                               ),
                             ],
                           ),
                         );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Doctors Section
                    const _SectionHeader(title: "Doctor Directory"),
                    const SizedBox(height: 12),
                    
                    Consumer<AdminDoctorsViewModel>(
                      builder: (context, vm, child) {
                        if (vm.isLoading) return const _LoadingSkeleton(height: 100);
                        
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.teal.shade100),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _DoctorBigStat(label: "Total Registered", count: vm.totalDoctorsCount.toString()),
                              Container(height: 40, width: 1, color: Colors.teal.shade200),
                              _DoctorBigStat(label: "Pending Approval", count: vm.pendingDoctorsCount.toString(), isWarning: true),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Specialties Section
                    const _SectionHeader(title: "Top Specialties"),
                    const SizedBox(height: 12),

                    Consumer<AdminDoctorsViewModel>(
                      builder: (context, vm, child) {
                        if (vm.topSpecialties.isEmpty) {
                          return const Center(child: Text("No specialties data available", style: TextStyle(color: Colors.grey)));
                        }

                        // Calculate max for progress bar
                        int maxVal = 1;
                        for(var e in vm.topSpecialties) {
                          if (e.value > maxVal) maxVal = e.value;
                        }

                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                             boxShadow: [
                               BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                             ],
                          ),
                          child: Column(
                            children: vm.topSpecialties.map((e) {
                              return _SpecialtyRow(
                                name: e.key, 
                                count: e.value, 
                                percentage: (e.value / maxVal)
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),

                    // Logout action
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // sign out and navigate back to login
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginView()),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.logout_outlined),
                        label: const Text('Logout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40), // Bottom padding
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- COMPONENT WIDGETS ---

  Widget _buildVerifyDoctorsBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/admin/verify-doctors'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E3192).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Action Required',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Verify Doctors',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Review pending registrations',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user_outlined, color: Colors.white, size: 30),
            )
          ],
        ),
      ),
    );
  }
}

// --- HELPER CLASSES ---

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}

class _ModernStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ModernStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusSummaryBox extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusSummaryBox({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(count.toString(), 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, 
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }
}

class _DoctorBigStat extends StatelessWidget {
  final String label;
  final String count;
  final bool isWarning;

  const _DoctorBigStat({required this.label, required this.count, this.isWarning = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isWarning ? Colors.orange : Colors.teal.shade800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.teal.shade600,
          ),
        ),
      ],
    );
  }
}

class _SpecialtyRow extends StatelessWidget {
  final String name;
  final int count;
  final double percentage;

  const _SpecialtyRow({required this.name, required this.count, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text("$count docs", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 6,
              backgroundColor: Colors.grey[100],
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  final double height;
  const _LoadingSkeleton({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  const _ErrorWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: const TextStyle(color: Colors.red)),
    );
  }
}