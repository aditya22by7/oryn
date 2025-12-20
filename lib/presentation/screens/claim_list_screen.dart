import 'package:flutter/material.dart';
import '../../core/models/claim.dart';
import '../../data/repositories/claim_repository.dart';
import '../widgets/claim_tile.dart';
import 'claim_detail_screen.dart';
import 'create_claim_screen.dart';

/// Main screen - displays all claims
///
/// Minimal, text-centric, no social features
class ClaimListScreen extends StatefulWidget {
  const ClaimListScreen({super.key});

  @override
  State<ClaimListScreen> createState() => _ClaimListScreenState();
}

class _ClaimListScreenState extends State<ClaimListScreen> {
  List<Claim> _claims = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadClaims();
  }

  Future<void> _loadClaims() async {
    setState(() => _loading = true);

    final claims = await ClaimRepository.getClaimsByConfidence();

    setState(() {
      _claims = claims;
      _loading = false;
    });
  }

  Future<void> _deleteClaim(Claim claim) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text(
          'Delete Claim',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This will permanently delete this claim and all its evidence.',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && claim.id != null) {
      await ClaimRepository.deleteClaim(claim.id!);
      _loadClaims();
    }
  }

  void _openClaimDetail(Claim claim) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClaimDetailScreen(claim: claim),
      ),
    );
    _loadClaims();
  }

  void _createNewClaim() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateClaimScreen(),
      ),
    );
    _loadClaims();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: const Text(
          'ORYN',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w300,
            letterSpacing: 8,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_claims.length} claims',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(
          color: Colors.grey,
          strokeWidth: 1,
        ),
      )
          : _claims.isEmpty
          ? _buildEmptyState()
          : _buildClaimList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewClaim,
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        child: const Icon(Icons.add, size: 24),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
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
            'Tap + to create your first claim',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimList() {
    return RefreshIndicator(
      onRefresh: _loadClaims,
      color: Colors.grey,
      backgroundColor: const Color(0xFF111111),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: _claims.length,
        itemBuilder: (context, index) {
          final claim = _claims[index];
          return ClaimTile(
            claim: claim,
            onTap: () => _openClaimDetail(claim),
            onLongPress: () => _deleteClaim(claim),
          );
        },
      ),
    );
  }
}