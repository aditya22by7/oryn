/// Oryn Core Library
///
/// Core engine for the Oryn truth-resolution protocol.
///
/// Pure Dart. No external dependencies.
///
/// ## Usage
///
/// ```dart
/// import 'package:oryn_core/oryn_core.dart';
///
/// // Create a claim
/// final claim = Claim.create(
///   statement: 'The Earth orbits the Sun',
///   scope: 'Astronomy',
/// );
///
/// // Add evidence
/// final withEvidence = claim.addEvidence(
///   Evidence.create(
///     type: EvidenceType.link,
///     reference: 'https://nasa.gov',
///     strength: 0.8,
///   ),
/// );
///
/// // Compute confidence
/// final confidence = ConfidenceEngine.compute(withEvidence);
/// ```
library oryn_core;

// Models
export 'src/models/models.dart';

// Engines
export 'src/engines/engines.dart';

// Validators
export 'src/validators/validators.dart';