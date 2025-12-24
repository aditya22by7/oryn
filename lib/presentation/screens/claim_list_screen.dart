import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:oryn/presentation/screens/statistics_screen.dart';
import '../../core/models/claim.dart';
import '../../data/repositories/claim_repository.dart';
import '../../core/services/export_service.dart';
import '../../core/services/search_service.dart';
import '../widgets/claim_tile.dart';
import 'claim_detail_screen.dart';
import 'create_claim_screen.dart';

/// Main screen - displays all claims with search and filter
///
/// Minimal, text-centric, no social features
class ClaimListScreen extends StatefulWidget {
  const ClaimListScreen({super.key});

  @override
  State<ClaimListScreen> createState() => _ClaimListScreenState();
}

class _ClaimListScreenState extends State<ClaimListScreen> {
  List<Claim> _allClaims = [];
  List<Claim> _filteredClaims = [];
  bool _loading = true;
  bool _showSearch = false;

  // Search and filter state
  final _searchController = TextEditingController();
  ConfidenceFilter _confidenceFilter = ConfidenceFilter.all;
  SortOption _sortOption = SortOption.confidenceHighToLow;
  String? _selectedScope;
  List<String> _availableScopes = [];

  @override
  void initState() {
    super.initState();
    _loadClaims();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClaims() async {
    setState(() => _loading = true);

    final claims = await ClaimRepository.getClaimsByConfidence();

    setState(() {
      _allClaims = claims;
      _availableScopes = SearchService.getUniqueScopes(claims);
      _loading = false;
    });

    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _filteredClaims = SearchService.applyFilters(
        claims: _allClaims,
        searchQuery: _searchController.text,
        scope: _selectedScope,
        confidenceFilter: _confidenceFilter,
        sortOption: _sortOption,
      );
    });
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        _confidenceFilter = ConfidenceFilter.all;
        _sortOption = SortOption.confidenceHighToLow;
        _selectedScope = null;
        _applyFilters();
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _confidenceFilter = ConfidenceFilter.all;
      _sortOption = SortOption.confidenceHighToLow;
      _selectedScope = null;
    });
    _applyFilters();
  }

  bool get _hasActiveFilters {
    return _searchController.text.isNotEmpty ||
        _confidenceFilter != ConfidenceFilter.all ||
        _sortOption != SortOption.confidenceHighToLow ||
        _selectedScope != null;
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

  Future<void> _exportAllClaims() async {
    if (_allClaims.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No claims to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final filePath = await ExportService.exportAllToFile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to: $filePath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importClaims() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not read file path'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final importResult = await ExportService.importFromFile(filePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(importResult.summary),
            backgroundColor: importResult.success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );

        if (importResult.success && importResult.importedCount > 0) {
          _loadClaims();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openStatistics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StatisticsScreen(),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'SORT BY',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
            ),
            ...SortOption.values.map((option) => ListTile(
              title: Text(
                option.displayName,
                style: TextStyle(
                  color: _sortOption == option ? Colors.white : Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              trailing: _sortOption == option
                  ? const Icon(Icons.check, color: Colors.green, size: 18)
                  : null,
              onTap: () {
                setState(() => _sortOption = option);
                _applyFilters();
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'FILTER BY CONFIDENCE',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
            ),
            ...ConfidenceFilter.values.map((filter) => ListTile(
              title: Text(
                filter.displayName,
                style: TextStyle(
                  color: _confidenceFilter == filter ? Colors.white : Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              trailing: _confidenceFilter == filter
                  ? const Icon(Icons.check, color: Colors.green, size: 18)
                  : null,
              onTap: () {
                setState(() => _confidenceFilter = filter);
                _applyFilters();
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: _showSearch
            ? _buildSearchField()
            : const Text(
          'ORYN',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w300,
            letterSpacing: 8,
          ),
        ),
        centerTitle: !_showSearch,
        actions: [
          if (!_showSearch)
            IconButton(
              icon: Icon(
                Icons.analytics_outlined,
                color: Colors.grey[600],
                size: 20,
              ),
              onPressed: _openStatistics,
              tooltip: 'View statistics',
            ),
          IconButton(
            icon: Icon(
              _showSearch ? Icons.close : Icons.search,
              color: _showSearch ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            onPressed: _toggleSearch,
            tooltip: _showSearch ? 'Close search' : 'Search claims',
          ),
          if (!_showSearch) ...[
            IconButton(
              icon: Icon(
                Icons.upload_outlined,
                color: Colors.grey[600],
                size: 20,
              ),
              onPressed: _importClaims,
              tooltip: 'Import claims',
            ),
            IconButton(
              icon: Icon(
                Icons.download_outlined,
                color: Colors.grey[600],
                size: 20,
              ),
              onPressed: _exportAllClaims,
              tooltip: 'Export all claims',
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_filteredClaims.length}/${_allClaims.length}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Filter bar (only when search is active)
          if (_showSearch) _buildFilterBar(),

          // Claims list
          Expanded(
            child: _loading
                ? const Center(
              child: CircularProgressIndicator(
                color: Colors.grey,
                strokeWidth: 1,
              ),
            )
                : _filteredClaims.isEmpty
                ? _buildEmptyState()
                : _buildClaimList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewClaim,
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        child: const Icon(Icons.add, size: 24),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: 'Search claims...',
        hintStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border(
          bottom: BorderSide(color: Colors.grey[900]!),
        ),
      ),
      child: Row(
        children: [
          // Sort button
          _FilterChip(
            label: 'Sort',
            icon: Icons.sort,
            isActive: _sortOption != SortOption.confidenceHighToLow,
            onTap: _showSortOptions,
          ),
          const SizedBox(width: 8),

          // Confidence filter button
          _FilterChip(
            label: _confidenceFilter.displayName,
            icon: Icons.filter_list,
            isActive: _confidenceFilter != ConfidenceFilter.all,
            onTap: _showFilterOptions,
          ),
          const SizedBox(width: 8),

          // Scope dropdown (if scopes exist)
          if (_availableScopes.isNotEmpty)
            _FilterChip(
              label: _selectedScope ?? 'Scope',
              icon: Icons.category_outlined,
              isActive: _selectedScope != null,
              onTap: _showScopeOptions,
            ),

          const Spacer(),

          // Clear filters button
          if (_hasActiveFilters)
            GestureDetector(
              onTap: _clearFilters,
              child: Text(
                'Clear',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showScopeOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'FILTER BY SCOPE',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
            ),
            ListTile(
              title: Text(
                'All Scopes',
                style: TextStyle(
                  color: _selectedScope == null ? Colors.white : Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              trailing: _selectedScope == null
                  ? const Icon(Icons.check, color: Colors.green, size: 18)
                  : null,
              onTap: () {
                setState(() => _selectedScope = null);
                _applyFilters();
                Navigator.pop(context);
              },
            ),
            ..._availableScopes.map((scope) => ListTile(
              title: Text(
                scope,
                style: TextStyle(
                  color: _selectedScope == scope ? Colors.white : Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              trailing: _selectedScope == scope
                  ? const Icon(Icons.check, color: Colors.green, size: 18)
                  : null,
              onTap: () {
                setState(() => _selectedScope = scope);
                _applyFilters();
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilters = _hasActiveFilters;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.search_off : Icons.inbox_outlined,
            size: 48,
            color: Colors.grey[800],
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'No claims match your filters' : 'No claims yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters ? 'Try adjusting your search or filters' : 'Tap + to create your first claim',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: _clearFilters,
              child: const Text(
                'Clear Filters',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
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
        itemCount: _filteredClaims.length,
        itemBuilder: (context, index) {
          final claim = _filteredClaims[index];
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

/// Reusable filter chip widget
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.withOpacity(0.2) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? Colors.blue.withOpacity(0.5) : Colors.grey[800]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.blue : Colors.grey[500],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.blue : Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}