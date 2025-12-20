import 'package:flutter/material.dart';
import '../../core/models/claim.dart';
import '../../core/engines/claim/claim_engine.dart';
import '../../data/repositories/claim_repository.dart';

/// Create new claim screen
///
/// Minimal form: statement, scope, decay half-life
class CreateClaimScreen extends StatefulWidget {
  final Claim? existingClaim;

  const CreateClaimScreen({
    super.key,
    this.existingClaim,
  });

  @override
  State<CreateClaimScreen> createState() => _CreateClaimScreenState();
}

class _CreateClaimScreenState extends State<CreateClaimScreen> {
  final _statementController = TextEditingController();
  final _scopeController = TextEditingController();
  int _decayHalfLifeDays = 90;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.existingClaim != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _statementController.text = widget.existingClaim!.statement ?? '';
      _scopeController.text = widget.existingClaim!.scope ?? '';
      _decayHalfLifeDays = widget.existingClaim!.decayHalfLifeDays;
    }
  }

  @override
  void dispose() {
    _statementController.dispose();
    _scopeController.dispose();
    super.dispose();
  }

  Future<void> _saveClaim() async {
    final statement = _statementController.text.trim();

    if (statement.isEmpty) {
      setState(() => _error = 'Statement is required');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      Claim claim;

      if (_isEditing) {
        claim = ClaimEngine.editClaim(
          claim: widget.existingClaim!,
          statement: statement,
          scope: _scopeController.text.trim(),
          decayHalfLifeDays: _decayHalfLifeDays,
        );
      } else {
        claim = ClaimEngine.createClaim(
          statement: statement,
          scope: _scopeController.text.trim(),
          decayHalfLifeDays: _decayHalfLifeDays,
        );
      }

      // Validate
      final validation = ClaimEngine.validateClaim(claim);
      if (!validation.isValid) {
        setState(() {
          _error = validation.errors.first;
          _saving = false;
        });
        return;
      }

      await ClaimRepository.saveClaim(claim);

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
          _isEditing ? 'EDIT CLAIM' : 'NEW CLAIM',
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
            onPressed: _saving ? null : _saveClaim,
            child: Text(
              'SAVE',
              style: TextStyle(
                color: _saving ? Colors.grey[700] : Colors.white,
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

            // Statement field
            _buildLabel('STATEMENT'),
            const SizedBox(height: 8),
            TextField(
              controller: _statementController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              maxLines: 4,
              decoration: _inputDecoration('Enter a declarative claim...'),
            ),

            const SizedBox(height: 24),

            // Scope field
            _buildLabel('SCOPE (OPTIONAL)'),
            const SizedBox(height: 8),
            TextField(
              controller: _scopeController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              decoration: _inputDecoration('e.g., AI / ML / Ethics'),
            ),

            const SizedBox(height: 24),

            // Decay half-life
            _buildLabel('DECAY HALF-LIFE'),
            const SizedBox(height: 8),
            Text(
              '$_decayHalfLifeDays days',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: Colors.grey[600],
                inactiveTrackColor: Colors.grey[900],
                thumbColor: Colors.white,
                overlayColor: Colors.white.withOpacity(0.1),
              ),
              child: Slider(
                value: _decayHalfLifeDays.toDouble(),
                min: 7,
                max: 365,
                divisions: 50,
                onChanged: (value) {
                  setState(() => _decayHalfLifeDays = value.round());
                },
              ),
            ),
            Text(
              'How fast evidence becomes stale. Shorter = stricter proof requirements.',
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
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How this works:',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Claims start with 0% confidence\n'
                        '• Add evidence to increase confidence\n'
                        '• Add counter-evidence to decrease it\n'
                        '• All proof decays over time\n'
                        '• Re-verify to reset decay',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                      height: 1.6,
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
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
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      contentPadding: const EdgeInsets.all(12),
    );
  }
}