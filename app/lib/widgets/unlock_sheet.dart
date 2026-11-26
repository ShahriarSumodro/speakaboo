/// Paywall and character unlock bottom sheet.
library;

import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../config/theme.dart';

class UnlockSheet extends StatefulWidget {
  final String title;
  final String priceText;
  final VoidCallback? onPayWithPlay;
  final VoidCallback? onPayWithBkash;
  final VoidCallback? onPayWithNagad;
  final VoidCallback? onRestore;
  final void Function(String trxId, String gateway)? onVerifyManualTrxId;

  const UnlockSheet({
    super.key,
    required this.title,
    required this.priceText,
    this.onPayWithPlay,
    this.onPayWithBkash,
    this.onPayWithNagad,
    this.onRestore,
    this.onVerifyManualTrxId,
  });

  @override
  State<UnlockSheet> createState() => _UnlockSheetState();
}

class _UnlockSheetState extends State<UnlockSheet> {
  bool _showManualTrx = false;
  String _selectedGateway = 'bkash';
  final TextEditingController _trxController = TextEditingController();

  @override
  void dispose() {
    _trxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlay = AppConfig.isPlayFlavor;
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(SpeakabooTheme.spacingLg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(SpeakabooTheme.radiusLg),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: SpeakabooTheme.spacingMd),
              Text(
                'Unlock ${widget.title}',
                style: TextStyle(
                  fontSize: SpeakabooTheme.headingSize,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: SpeakabooTheme.spacingXs),
              Text(
                'Practice unlimited spoken English (${widget.priceText})',
                style: SpeakabooTheme.bodyStyle(
                  color: colors.textSecondary,
                  size: SpeakabooTheme.baseFontSize,
                ),
              ),
              const SizedBox(height: SpeakabooTheme.spacingMd),
              // Trust strip (Paywall only, true statements only)
              Container(
                padding: const EdgeInsets.all(SpeakabooTheme.spacing12),
                decoration: BoxDecoration(
                  color: colors.pastelMint,
                  borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _TrustBadge(
                        icon: Icons.lock_outline_rounded,
                        label: 'Zero raw audio stored',
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TrustBadge(
                        icon: Icons.restore_rounded,
                        label: 'Restore anytime',
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: SpeakabooTheme.spacingLg),
              if (isPlay) ...[
                // Google Play In-App Billing Button (Policy-compliant for Play flavor)
                SizedBox(
                  width: double.infinity,
                  height: SpeakabooTheme.minTapTarget,
                  child: ElevatedButton.icon(
                    onPressed: widget.onPayWithPlay,
                    icon: const Icon(Icons.shop_outlined, color: Colors.white),
                    label: const Text(
                      'Unlock with Google Play',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF01875F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Direct Distribution: Instant Web Checkout bKash & Nagad
                SizedBox(
                  width: double.infinity,
                  height: SpeakabooTheme.minTapTarget,
                  child: ElevatedButton(
                    onPressed: widget.onPayWithBkash,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE2136E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
                      ),
                    ),
                    child: const Text(
                      'Pay with bKash',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: SpeakabooTheme.spacingSm),
                SizedBox(
                  width: double.infinity,
                  height: SpeakabooTheme.minTapTarget,
                  child: ElevatedButton(
                    onPressed: widget.onPayWithNagad,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF7921E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
                      ),
                    ),
                    child: const Text(
                      'Pay with Nagad',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: SpeakabooTheme.spacingSm),

                // CD-004: Direct USSD / Manual TrxID section
                InkWell(
                  onTap: () => setState(() => _showManualTrx = !_showManualTrx),
                  borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          _showManualTrx ? Icons.expand_less : Icons.expand_more,
                          size: 20,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Paid via bKash/Nagad USSD (*247# / *167#)?',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showManualTrx) ...[
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                    padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(SpeakabooTheme.radiusSm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Send Money to Merchant: 01700-000000, then paste your Transaction ID below:',
                          style: TextStyle(fontSize: 11, color: colors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ChoiceChip(
                              label: const Text('bKash'),
                              selected: _selectedGateway == 'bkash',
                              onSelected: (_) => setState(() => _selectedGateway = 'bkash'),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Nagad'),
                              selected: _selectedGateway == 'nagad',
                              onSelected: (_) => setState(() => _selectedGateway = 'nagad'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _trxController,
                          decoration: const InputDecoration(
                            labelText: 'Transaction ID (TrxID)',
                            hintText: 'e.g. BL9A3KQ912',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () {
                              final text = _trxController.text.trim();
                              if (text.isNotEmpty) {
                                widget.onVerifyManualTrxId?.call(text, _selectedGateway);
                              }
                            },
                            child: const Text('Verify TrxID & Unlock'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              const SizedBox(height: SpeakabooTheme.spacingSm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.onRestore != null)
                    TextButton(
                      onPressed: widget.onRestore,
                      child: const Text('Restore Purchases'),
                    )
                  else
                    const SizedBox(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TrustBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: SpeakabooTheme.bodyStyle(
              color: color,
              size: 12,
              weight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
