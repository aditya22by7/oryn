import 'package:flutter/material.dart';
import '../../core/services/statistics_service.dart';

/// Statistics Dashboard Screen
///
/// Shows overview of all claims and their status.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  ClaimStatistics? _statistics;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _loading = true);

    final stats = await StatisticsService.getStatistics();

    if (mounted) {
      setState(() {
        _statistics = stats;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'STATISTICS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w300,
            letterSpacing: 4,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(
          color: Colors.grey,
          strokeWidth: 1,
        ),
      )
          : _statistics == null || _statistics!.isEmpty
          ? _buildEmptyState()
          : _buildStatistics(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 48,
            color: Colors.grey[800],
          ),
          const SizedBox(height: 16),
          Text(
            'No claims yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create claims to see statistics',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    final stats = _statistics!;

    return RefreshIndicator(
      onRefresh: _loadStatistics,
      color: Colors.grey,
      backgroundColor: const Color(0xFF111111),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview card
            _buildOverviewCard(stats),

            const SizedBox(height: 24),

            // Confidence distribution
            _buildSectionHeader('CONFIDENCE DISTRIBUTION'),
            const SizedBox(height: 12),
            _buildConfidenceDistribution(stats),

            const SizedBox(height: 24),

            // Evidence stats
            _buildSectionHeader('EVIDENCE STATUS'),
            const SizedBox(height: 12),
            _buildEvidenceStats(stats),

            const SizedBox(height: 24),

            // Attention needed
            if (stats.needsReverification > 0) ...[
              _buildSectionHeader('NEEDS ATTENTION'),
              const SizedBox(height: 12),
              _buildAttentionCard(stats),
              const SizedBox(height: 24),
            ],

            // Top scopes
            if (stats.topScopes.isNotEmpty) ...[
              _buildSectionHeader('TOP SCOPES'),
              const SizedBox(height: 12),
              _buildTopScopes(stats),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.grey[500],
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildOverviewCard(ClaimStatistics stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[900]!),
      ),
      child: Column(
        children: [
          // Total claims
          Text(
            '${stats.totalClaims}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w200,
            ),
          ),
          Text(
            'TOTAL CLAIMS',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 24),

          // Average confidence
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMiniStat(
                label: 'AVG CONFIDENCE',
                value: '${(stats.averageConfidence * 100).toStringAsFixed(1)}%',
                color: _getConfidenceColor(stats.averageConfidence),
              ),
              const SizedBox(width: 32),
              _buildMiniStat(
                label: 'TOTAL EVIDENCE',
                value: '${stats.totalEvidence + stats.totalCounterEvidence}',
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w300,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 9,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceDistribution(ClaimStatistics stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildDistributionRow(
            label: 'High (70%+)',
            count: stats.highConfidence,
            total: stats.totalClaims,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildDistributionRow(
            label: 'Moderate (40-70%)',
            count: stats.moderateConfidence,
            total: stats.totalClaims,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildDistributionRow(
            label: 'Low (10-40%)',
            count: stats.lowConfidence,
            total: stats.totalClaims,
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          _buildDistributionRow(
            label: 'Unverified (<10%)',
            count: stats.unverified,
            total: stats.totalClaims,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionRow({
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final percentage = total > 0 ? count / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEvidenceStats(ClaimStatistics stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildEvidenceStat(
              icon: Icons.add_circle_outline,
              label: 'With Evidence',
              count: stats.withEvidence,
              color: Colors.green,
            ),
          ),
          Expanded(
            child: _buildEvidenceStat(
              icon: Icons.remove_circle_outline,
              label: 'With Counter',
              count: stats.withCounterEvidence,
              color: Colors.red,
            ),
          ),
          Expanded(
            child: _buildEvidenceStat(
              icon: Icons.circle_outlined,
              label: 'No Evidence',
              count: stats.noEvidence,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceStat({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAttentionCard(ClaimStatistics stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withAlpha(75)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_outlined,
            color: Colors.orange[400],
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stats.needsReverification} claims need reverification',
                  style: TextStyle(
                    color: Colors.orange[300],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'These claims have confidence below 30%',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopScopes(ClaimStatistics stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: stats.topScopes.map((scope) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  scope.scope,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${scope.count}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.7) return Colors.green;
    if (confidence >= 0.4) return Colors.orange;
    if (confidence >= 0.1) return Colors.red;
    return Colors.grey;
  }
}