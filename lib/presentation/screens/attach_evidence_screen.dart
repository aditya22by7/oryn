import 'package:flutter/material.dart';
import '../../core/models/claim.dart';
import '../../core/models/evidence.dart';
import '../../core/models/counter_evidence.dart';
import '../../core/engines/evidence/evidence_engine.dart';
import '../../data/repositories/claim_repository.dart';

/// Attach evidence or counter-evidence to a claim
class AttachEvidenceScreen extends StatefulWidget {
  final Claim claim;
  final bool isCounter;

  const AttachEvidenceScreen({
    super.key,
    required this.claim,
    this.isCounter = false,
  });

  @override
  State<AttachEvidenceScreen> createState() => _AttachEvidenceScreenState();
}

class _AttachEvidenceScreenState extends State<AttachEvidenceScreen> {
  final _referenceController = TextEditingController();
  EvidenceType _type = EvidenceType.link;
  double _strength = 0.5;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final reference = _referenceController.text.trim();

    if (reference.isEmpty) {
      setState(() => _error = 'Reference is required');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      Claim updatedClaim;

      if (widget.isCounter) {
        updatedClaim = EvidenceEngine.addCounterEvidence(
          claim: widget.claim,
          type: CounterEvidenceType.values[_type.index],
          reference: reference,
          strength: _strength,
        );
      } else {
        updatedClaim = EvidenceEngine.addEvidence(
          claim: widget.claim,
          type: _type,
          reference: reference,
          strength: _strength,
        );
      }

      await ClaimRepository.saveClaim(updatedClaim);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to save: $e';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isCounter ? Colors.red : Colors.green;
    final title = widget.isCounter ? 'COUNTER-EVIDENCE' : 'EVIDENCE';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ADD $title',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w300,
            letterSpacing: 4,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(
              'SAVE',
              style: TextStyle(
                color: _saving ? Colors.grey[700] : accentColor,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error display
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),

            // Claim preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.claim.statement ?? '',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 24),

            // Type selector
            _buildLabel('TYPE'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: EvidenceType.values.map((type) {
                final isSelected = type == _type;
                return GestureDetector(
                  onTap: () => setState(() => _type = type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor.withOpacity(0.2)
                          : const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected
                            ? accentColor
                            : Colors.grey[900]!,
                      ),
                    ),
                    child: Text(
                      type.name.toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? accentColor : Colors.grey[500],
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Reference field
            _buildLabel('REFERENCE'),
            const SizedBox(height: 8),
            TextField(
              controller: _referenceController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'monospace',
              ),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'URL, document path, or description...',
                hintStyle: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
                filled: true,
                fillColor: const Color(0xFF111111),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.grey[900]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.grey[900]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: accentColor.withOpacity(0.5)),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),

            const SizedBox(height: 24),

            // Strength slider
            _buildLabel('STRENGTH'),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${(_strength * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 16,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: accentColor.withOpacity(0.7),
                      inactiveTrackColor: Colors.grey[900],
                      thumbColor: accentColor,
                      overlayColor: accentColor.withOpacity(0.1),
                    ),
                    child: Slider(
                      value: _strength,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      onChanged: (value) {
                        setState(() => _strength = value);
                      },
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'How strong is this ${widget.isCounter ? 'counter-' : ''}evidence?',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 11,
              ),
            ),

            const SizedBox(height: 32),

            // Info box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: accentColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: accentColor.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.isCounter
                          ? 'Counter-evidence reduces the claim\'s confidence score.'
                          : 'Evidence increases the claim\'s confidence score.',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.grey[500],
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
      ),
    );
  }
}