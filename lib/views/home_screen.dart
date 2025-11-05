import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stridelog/controllers/auth_provider.dart';
import 'package:stridelog/controllers/activity_provider.dart';
import 'package:stridelog/models/activity.dart';
import 'package:stridelog/views/add_activity_screen.dart';
import 'package:stridelog/views/activity_history_screen.dart';
import 'package:stridelog/views/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<ActivityHistoryScreenState> _historyKey = GlobalKey<ActivityHistoryScreenState>();

  @override
  void initState() {
    super.initState();
  }

  final List<Widget> _pages = [];

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomePage(),
      AddActivityScreen(
        onSaved: () {
          setState(() => _currentIndex = 2);
          _historyKey.currentState?.refresh();
        },
      ),
      ActivityHistoryScreen(key: _historyKey),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHomePage() {
    final activityProvider = context.watch<ActivityProvider>();
    final isLoading = activityProvider.isLoading;
    final statistics = activityProvider.statistics;
    final recentActivities = activityProvider.activities.take(3).toList();

    if (isLoading && statistics.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF6B35), Color(0xFFE91E63)],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6B35), Color(0xFFE91E63)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildStatsCards(statistics),
              const SizedBox(height: 32),
              _buildRecentActivities(recentActivities),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final user = context.watch<AuthProvider>().currentUser;
    final firstName = user?.name.split(' ').first ?? 'Usuário';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, $firstName! 👋',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vamos treinar hoje?',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 28,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards(Map<String, dynamic> statistics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suas estatísticas',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Atividades',
                '${statistics['totalActivities'] ?? 0}',
                Icons.fitness_center,
                const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Tempo Total',
                '${(statistics['totalTime'] ?? 0) ~/ 60}h ${(statistics['totalTime'] ?? 0) % 60}min',
                Icons.timer,
                const Color(0xFF2196F3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Distância',
                '${(statistics['totalDistance'] ?? 0.0).toStringAsFixed(1)} km',
                Icons.straighten,
                const Color(0xFFFF9800),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Calorias',
                '${statistics['totalCalories'] ?? 0} kcal',
                Icons.local_fire_department,
                const Color(0xFFF44336),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities(List<Activity> recentActivities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Atividades recentes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() => _currentIndex = 2);
                _historyKey.currentState?.refresh();
              },
              child: const Text(
                'Ver todas',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentActivities.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.directions_run,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma atividade ainda',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toque no + para adicionar sua primeira atividade',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ...(recentActivities.map((activity) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildActivityCard(activity),
          ))),
      ],
    );
  }

  Widget _buildActivityCard(Activity activity) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getActivityIcon(activity.type),
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.displayTypeName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${activity.formattedDuration}${activity.distanceKm != null ? ' • ${activity.formattedDistance}' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (activity.calories != null)
                Text(
                  '${activity.calories} kcal',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                '${activity.date.day}/${activity.date.month}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return Icons.directions_run;
      case ActivityType.cycling:
        return Icons.directions_bike;
      case ActivityType.gym:
        return Icons.fitness_center;
      case ActivityType.walking:
        return Icons.directions_walk;
      case ActivityType.yoga:
        return Icons.self_improvement;
      case ActivityType.swimming:
        return Icons.pool;
      case ActivityType.custom:
        return Icons.category;
    }
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 2) _historyKey.currentState?.refresh();
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[400],
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Adicionar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Histórico',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}