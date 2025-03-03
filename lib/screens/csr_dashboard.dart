// lib/screens/csr_dashboard.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/support_ticket_model.dart';
import '../services/session_service.dart';
import '../services/support_ticket_service.dart';
import '../widgets/csr_analytics_widget.dart';
import '../widgets/csr_drawer.dart';
import '../widgets/csr_stats_summary.dart';
import '../widgets/csr_ticket_list.dart';
import 'login_screen.dart';

class CSRDashboard extends StatefulWidget {
  const CSRDashboard({super.key});

  @override
  State<CSRDashboard> createState() => _CSRDashboardState();
}

class _CSRDashboardState extends State<CSRDashboard> with SingleTickerProviderStateMixin {
  final SupportTicketService _ticketService = SupportTicketService();
  final SupabaseClient _supabase = Supabase.instance.client;
  late TabController _tabController;
  bool _isLoading = true;
  String _csrName = 'CSR';
  int _openCount = 0;
  int _inProgressCount = 0;
  int _pendingUserCount = 0;
  int _pendingAuctionsCount = 0;
  int _reportedContentCount = 0;
  int _disputeCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      // Get current CSR's name
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final userData = await _supabase
            .from('users')
            .select('display_name')
            .eq('id', user.id)
            .single();
        
        _csrName = userData['display_name'] ?? 'CSR';
      }
      
      // Get ticket counts
      final ticketCounts = await _ticketService.getTicketCountsByStatus();
      
      // Count reported content
      final contentReports = await _ticketService.getAllContentReports(
        statusFilter: ContentReportStatus.pending,
      );
      
      // Count disputes
      final disputes = await _ticketService.getAllDisputes(
        statusFilter: DisputeStatus.opened,
      );
      
      // Count pending auctions to moderate
      final pendingAuctions = 5; // Placeholder, implement actual count
      
      if (mounted) {
        setState(() {
          _openCount = ticketCounts['open'] ?? 0;
          _inProgressCount = ticketCounts['inProgress'] ?? 0;
          _pendingUserCount = ticketCounts['pendingUser'] ?? 0;
          _reportedContentCount = contentReports.length;
          _disputeCount = disputes.length;
          _pendingAuctionsCount = pendingAuctions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _supabase.auth.signOut();
      await SessionService.clearSession();
      
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("CSR Dashboard")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text("$_csrName's Dashboard"),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: "Open Tickets (${_openCount})"),
            Tab(text: "In Progress (${_inProgressCount})"),
            Tab(text: "Pending User (${_pendingUserCount})"),
            Tab(text: "Content Reports (${_reportedContentCount})"),
            Tab(text: "Disputes (${_disputeCount})"),
            Tab(text: "Pending Auctions (${_pendingAuctionsCount})"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: const CSRDrawer(),
      body: Column(
        children: [
          // Stats summary at the top
          const CSRStatsSummary(),
          
          // Main content area with tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Open tickets
                CSRTicketList(
                  statusFilter: TicketStatus.open,
                  onRefreshData: _loadData,
                ),
                
                // In Progress tickets
                CSRTicketList(
                  statusFilter: TicketStatus.inProgress,
                  onRefreshData: _loadData,
                ),
                
                // Pending User tickets
                CSRTicketList(
                  statusFilter: TicketStatus.pendingUser,
                  onRefreshData: _loadData,
                ),
                
                // Content Reports tab
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.content_paste, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'You have $_reportedContentCount content reports to review',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/content_moderation');
                        },
                        child: const Text('Go to Content Moderation'),
                      ),
                    ],
                  ),
                ),
                
                // Disputes tab
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.gavel, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'You have $_disputeCount disputes to resolve',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/dispute_resolution');
                        },
                        child: const Text('Go to Dispute Resolution'),
                      ),
                    ],
                  ),
                ),
                
                // Pending Auctions tab
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.gavel, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'You have $_pendingAuctionsCount auctions to review',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/content_moderation');
                        },
                        child: const Text('Go to Auction Moderation'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to analytics dashboard
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CSRAnalyticsWidget(),
            ),
          );
        },
        tooltip: 'View Analytics',
        child: const Icon(Icons.analytics),
      ),
    );
  }
}