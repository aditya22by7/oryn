import 'package:flutter/material.dart';
import '../../core/models/claim.dart';
import '../../core/engines/claim/claim_engine.dart';
import '../../core/engines/confidence/confidence_engine.dart';
import '../../data/repositories/claim_repository.dart';
import '../widgets/confidence_bar.dart';
import '../widgets/decay_chart.dart';
import '../widgets/evidence_tile.dart';
import 'attach_evidence_screen.dart';
import 'create_claim_screen.dart';

/// Full claim detail view
///
/// Shows confidence breakdown, evidence, counter-evidence
class ClaimDetailScreen extends StatefulWidget {
  final Claim claim;

  const ClaimDetailScreen({
    super.key,
    required this.claim,
  });

  @override
  State<ClaimDetailScreen> createState() => _ClaimDetailScreenState();
}

class _ClaimDetailScreenState extends State<ClaimDetailScreen> {
  late Claim _claim;
  bool _showBreakdown = false;

  @override
  void initState() {
    super.initState();
    _claim = ClaimEngine.refreshConfidence(widget.claim);
  }

  Future<void> _reloadClaim() async {
    if (_claim.id == null) return;

    final updated = await ClaimRepository.getClaimById(_claim.id!);
    if (updated != null && mounted) {
      setState(() => _claim = updated);
    }
  }

  Future<void> _reverifyClaim() async {
    final updated = ClaimEngine.reverifyClaim(_claim);
    await ClaimRepository.saveClaim(updated);
    setState(() => _claim = updated);
  }

  void _editClaim() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateClaimScreen(existingClaim: _claim),
      ),
    );
    _reloadClaim();
  }

  void _addEvidence({required bool isCounter}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttachEvidenceScreen(
          claim: _claim,
          isCounter: isCounter,
        ),
      ),
    );
    _reloadClaim();
  }

  @override
  Widget build(BuildContext context) {
    final breakdown = ConfidenceEngine.getBreakdown(_claim);
    final daysSinceVerification = ClaimEngine.getDaysSinceVerification(_claim);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
            onPressed: _editClaim,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statement
            Text(
              _claim.statement ?? 'No statement',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 12),

            // Scope
            if (_claim.scope != null && _claim.scope!.isNotEmpty)
              Text(
                _claim.scope!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),

            const SizedBox(height: 24),

            // Confidence section
            _buildSectionHeader('CONFIDENCE'),
            const SizedBox(height: 12),
            ConfidenceBar(confidence: _claim.confidenceScore),

            const SizedBox(height: 12),

            // Toggle breakdown
            GestureDetector(
              onTap: () => setState(() => _showBreakdown = !_showBreakdown),
              child: Row(
                children: [
                  Icon(
                    _showBreakdown
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _showBreakdown ? 'Hide breakdown' : 'Show breakdown',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Breakdown details
            if (_showBreakdown) ...[
              const SizedBox(height: 12),
              _buildBreakdownCard(breakdown),
            ],

            const SizedBox(height: 24),

            // Decay chart
            DecayChart(
              claim: _claim,
              daysToProject: 180,
              height: 180,
            ),

            const SizedBox(height: 24),

            // Reverify section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last verified',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$daysSinceVerification days ago',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _reverifyClaim,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[900],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'REVERIFY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Evidence section
            _buildSectionHeader(
              'EVIDENCE (${_claim.evidenceList.length})',
              action: TextButton(
                onPressed: () => _addEvidence(isCounter: false),
                child: const Text(
                  '+ ADD',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            if (_claim.evidenceList.isEmpty)
              _buildEmptyMessage('No evidence attached')
            else
              ..._claim.evidenceList.map((e) => EvidenceTile.fromEvidence(
                evidence: e,
                halfLifeDays: _claim.decayHalfLifeDays,
              )),

            const SizedBox(height: 24),

            // Counter-evidence section
            _buildSectionHeader(
              'COUNTER-EVIDENCE (${_claim.counterEvidenceList.length})',
              action: TextButton(
                onPressed: () => _addEvidence(isCounter: true),
                child: const Text(
                  '+ ADD',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            if (_claim.counterEvidenceList.isEmpty)
              _buildEmptyMessage('No counter-evidence attached')
            else
              ..._claim.counterEvidenceList.map((c) => EvidenceTile.fromCounterEvidence(
                counter: c,
                halfLifeDays: _claim.decayHalfLifeDays,
              )),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Widget? action}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
        if (action != null) action,
      ],
    );
  }

  Widget _buildBreakdownCard(ConfidenceBreakdown breakdown) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[900]!),
      ),
      child: Column(
        children: [
          _buildBreakdownRow(
            'Evidence Score',
            breakdown.evidenceScore.toStringAsFixed(4),
          ),
          _buildBreakdownRow(
            'Counter Score',
            breakdown.counterEvidenceScore.toStringAsFixed(4),
          ),
          _buildBreakdownRow(
            'Decay Factor',
            breakdown.claimDecayFactor.toStringAsFixed(4),
          ),
          const Divider(color: Colors.grey, height: 16),
          _buildBreakdownRow(
            'Raw Score',
            breakdown.rawScore.toStringAsFixed(4),
          ),
          _buildBreakdownRow(
            'Decayed Score',
            breakdown.decayedScore.toStringAsFixed(4),
          ),
          _buildBreakdownRow(
            'Final Confidence',
            breakdown.finalConfidence.toStringAsFixed(4),
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: highlight ? Colors.white : Colors.grey[400],
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(
        message,
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 12,
        ),
      ),
    );
  }
}