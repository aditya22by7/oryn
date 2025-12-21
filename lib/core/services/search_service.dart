import '../models/claim.dart';

/// Search & Filter Service
/// 
/// Provides filtering capabilities for claims.
/// All filtering is done locally on the device.
class SearchService {

  /// Filter claims by search query
  /// Searches in statement and scope
  static List<Claim> searchByText(List<Claim> claims, String query) {
    if (query.trim().isEmpty) return claims;

    final lowerQuery = query.toLowerCase().trim();

    return claims.where((claim) {
      final statement = claim.statement?.toLowerCase() ?? '';
      final scope = claim.scope?.toLowerCase() ?? '';

      return statement.contains(lowerQuery) || scope.contains(lowerQuery);
    }).toList();
  }

  /// Filter claims by scope
  static List<Claim> filterByScope(List<Claim> claims, String? scope) {
    if (scope == null || scope.trim().isEmpty) return claims;

    final lowerScope = scope.toLowerCase().trim();

    return claims.where((claim) {
      final claimScope = claim.scope?.toLowerCase() ?? '';
      return claimScope.contains(lowerScope);
    }).toList();
  }

  /// Filter claims by confidence level
  static List<Claim> filterByConfidence(
      List<Claim> claims,
      ConfidenceFilter filter,
      ) {
    switch (filter) {
      case ConfidenceFilter.all:
        return claims;
      case ConfidenceFilter.high:
        return claims.where((c) => c.confidenceScore >= 0.7).toList();
      case ConfidenceFilter.moderate:
        return claims.where((c) => c.confidenceScore >= 0.4 && c.confidenceScore < 0.7).toList();
      case ConfidenceFilter.low:
        return claims.where((c) => c.confidenceScore >= 0.1 && c.confidenceScore < 0.4).toList();
      case ConfidenceFilter.unverified:
        return claims.where((c) => c.confidenceScore < 0.1).toList();
      case ConfidenceFilter.needsReverification:
        return claims.where((c) => c.confidenceScore < 0.3).toList();
    }
  }

  /// Filter claims that have evidence
  static List<Claim> filterWithEvidence(List<Claim> claims) {
    return claims.where((c) => c.evidenceList.isNotEmpty).toList();
  }

  /// Filter claims that have counter-evidence
  static List<Claim> filterWithCounterEvidence(List<Claim> claims) {
    return claims.where((c) => c.counterEvidenceList.isNotEmpty).toList();
  }

  /// Filter claims with no evidence at all
  static List<Claim> filterNoEvidence(List<Claim> claims) {
    return claims.where((c) =>
    c.evidenceList.isEmpty && c.counterEvidenceList.isEmpty
    ).toList();
  }

  /// Sort claims by different criteria
  static List<Claim> sortClaims(List<Claim> claims, SortOption option) {
    final sorted = List<Claim>.from(claims);

    switch (option) {
      case SortOption.confidenceHighToLow:
        sorted.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));
        break;
      case SortOption.confidenceLowToHigh:
        sorted.sort((a, b) => a.confidenceScore.compareTo(b.confidenceScore));
        break;
      case SortOption.newestFirst:
        sorted.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
        break;
      case SortOption.oldestFirst:
        sorted.sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
        break;
      case SortOption.recentlyVerified:
        sorted.sort((a, b) => (b.lastVerifiedAt ?? DateTime(0)).compareTo(a.lastVerifiedAt ?? DateTime(0)));
        break;
      case SortOption.needsVerification:
        sorted.sort((a, b) => (a.lastVerifiedAt ?? DateTime(0)).compareTo(b.lastVerifiedAt ?? DateTime(0)));
        break;
    }

    return sorted;
  }

  /// Apply multiple filters at once
  static List<Claim> applyFilters({
    required List<Claim> claims,
    String? searchQuery,
    String? scope,
    ConfidenceFilter confidenceFilter = ConfidenceFilter.all,
    SortOption sortOption = SortOption.confidenceHighToLow,
  }) {
    var result = claims;

    // Apply text search
    if (searchQuery != null && searchQuery.isNotEmpty) {
      result = searchByText(result, searchQuery);
    }

    // Apply scope filter
    if (scope != null && scope.isNotEmpty) {
      result = filterByScope(result, scope);
    }

    // Apply confidence filter
    result = filterByConfidence(result, confidenceFilter);

    // Apply sorting
    result = sortClaims(result, sortOption);

    return result;
  }

  /// Get unique scopes from all claims
  static List<String> getUniqueScopes(List<Claim> claims) {
    final scopes = <String>{};

    for (final claim in claims) {
      if (claim.scope != null && claim.scope!.trim().isNotEmpty) {
        scopes.add(claim.scope!.trim());
      }
    }

    final sortedScopes = scopes.toList()..sort();
    return sortedScopes;
  }
}

/// Confidence filter options
enum ConfidenceFilter {
  all,
  high,
  moderate,
  low,
  unverified,
  needsReverification,
}

/// Confidence filter display names
extension ConfidenceFilterExtension on ConfidenceFilter {
  String get displayName {
    switch (this) {
      case ConfidenceFilter.all:
        return 'All';
      case ConfidenceFilter.high:
        return 'High (70%+)';
      case ConfidenceFilter.moderate:
        return 'Moderate (40-70%)';
      case ConfidenceFilter.low:
        return 'Low (10-40%)';
      case ConfidenceFilter.unverified:
        return 'Unverified (<10%)';
      case ConfidenceFilter.needsReverification:
        return 'Needs Reverification';
    }
  }
}

/// Sort options
enum SortOption {
  confidenceHighToLow,
  confidenceLowToHigh,
  newestFirst,
  oldestFirst,
  recentlyVerified,
  needsVerification,
}

/// Sort option display names
extension SortOptionExtension on SortOption {
  String get displayName {
    switch (this) {
      case SortOption.confidenceHighToLow:
        return 'Confidence: High to Low';
      case SortOption.confidenceLowToHigh:
        return 'Confidence: Low to High';
      case SortOption.newestFirst:
        return 'Newest First';
      case SortOption.oldestFirst:
        return 'Oldest First';
      case SortOption.recentlyVerified:
        return 'Recently Verified';
      case SortOption.needsVerification:
        return 'Needs Verification';
    }
  }
}