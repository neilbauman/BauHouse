import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../core/theme/colours.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing.dart';
import '../../core/subscription/subscription_provider.dart';

/// Paywall screen for converting free users to Full Resident (premium).
///
/// Designed with BauHouse's tone: warm, understated, no pressure.
/// "Premium membership buys comfort and flexibility, not progress."
class PaywallScreen extends ConsumerWidget {
  /// Optional context string for analytics (e.g. "streak_shield", "archive").
  final String? triggerContext;

  const PaywallScreen({super.key, this.triggerContext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subState = ref.watch(subscriptionProvider);

    return Scaffold(
      backgroundColor: BauColours.cream,
      appBar: AppBar(
        backgroundColor: BauColours.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: BauColours.darkText),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: subState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : _PaywallContent(
                offerings: subState.offerings,
                triggerContext: triggerContext,
              ),
      ),
    );
  }
}

class _PaywallContent extends ConsumerStatefulWidget {
  final Offerings? offerings;
  final String? triggerContext;

  const _PaywallContent({this.offerings, this.triggerContext});

  @override
  ConsumerState<_PaywallContent> createState() => _PaywallContentState();
}

class _PaywallContentState extends ConsumerState<_PaywallContent> {
  bool _isAnnual = true;
  bool _purchasing = false;

  Package? get _monthlyPackage {
    return widget.offerings?.current?.monthly;
  }

  Package? get _annualPackage {
    return widget.offerings?.current?.annual;
  }

  Package? get _selectedPackage {
    return _isAnnual ? _annualPackage : _monthlyPackage;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: BauSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: BauSpacing.lg),
          _buildHeader(),
          const SizedBox(height: BauSpacing.xl),
          _buildBenefits(),
          const SizedBox(height: BauSpacing.xl),
          _buildPlanToggle(),
          const SizedBox(height: BauSpacing.lg),
          _buildPriceCard(),
          const SizedBox(height: BauSpacing.lg),
          _buildPurchaseButton(),
          const SizedBox(height: BauSpacing.md),
          _buildRestoreButton(),
          const SizedBox(height: BauSpacing.md),
          _buildLegalText(),
          const SizedBox(height: BauSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: BauColours.blueprintBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.home_work_outlined,
            size: 32,
            color: BauColours.blueprintBlue,
          ),
        ),
        const SizedBox(height: BauSpacing.md),
        Text(
          'Become a Full Resident',
          style: BauTypography.headline1.copyWith(
            color: BauColours.blueprintBlue,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: BauSpacing.sm),
        Text(
          'More comfort. More flexibility.\nThe same Elmfield you already know.',
          style: BauTypography.body.copyWith(color: BauColours.midGrey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBenefits() {
    const benefits = [
      _Benefit(
        icon: Icons.shield_outlined,
        title: 'Unlimited streak shields',
        subtitle: 'Never lose your streak to a busy day',
      ),
      _Benefit(
        icon: Icons.palette_outlined,
        title: 'Gropius district themes',
        subtitle: 'Exclusive architectural styles for your plot',
      ),
      _Benefit(
        icon: Icons.history_outlined,
        title: 'Full archive access',
        subtitle: 'Revisit any past Build Brief without credits',
      ),
      _Benefit(
        icon: Icons.visibility_off_outlined,
        title: 'No advertisements',
        subtitle: 'A clean, uninterrupted building experience',
      ),
      _Benefit(
        icon: Icons.preview_outlined,
        title: 'Next week preview',
        subtitle: 'See upcoming Build Briefs before they go live',
      ),
    ];

    return Column(
      children: benefits.map((b) => Padding(
        padding: const EdgeInsets.only(bottom: BauSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: BauColours.sage.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(b.icon, color: BauColours.sage, size: 20),
            ),
            const SizedBox(width: BauSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.title, style: BauTypography.headline3),
                  Text(b.subtitle, style: BauTypography.bodySmall),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildPlanToggle() {
    return Container(
      decoration: BoxDecoration(
        color: BauColours.surface,
        borderRadius: BorderRadius.circular(BauSpacing.borderRadius),
        border: Border.all(color: BauColours.gridLine),
      ),
      padding: const EdgeInsets.all(BauSpacing.xs),
      child: Row(
        children: [
          Expanded(child: _planTab('Annual', true, 'Save ~48%')),
          const SizedBox(width: BauSpacing.xs),
          Expanded(child: _planTab('Monthly', false, null)),
        ],
      ),
    );
  }

  Widget _planTab(String label, bool isAnnual, String? badge) {
    final selected = _isAnnual == isAnnual;
    return GestureDetector(
      onTap: () => setState(() => _isAnnual = isAnnual),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: BauSpacing.sm,
          horizontal: BauSpacing.md,
        ),
        decoration: BoxDecoration(
          color: selected ? BauColours.blueprintBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(BauSpacing.borderRadiusSm),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: BauTypography.headline3.copyWith(
                color: selected ? Colors.white : BauColours.darkText,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(height: 2),
              Text(
                badge,
                style: BauTypography.label.copyWith(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.8)
                      : BauColours.sage,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard() {
    final package = _selectedPackage;

    if (package == null) {
      return Container(
        padding: const EdgeInsets.all(BauSpacing.lg),
        decoration: BoxDecoration(
          color: BauColours.surface,
          borderRadius: BorderRadius.circular(BauSpacing.borderRadius),
          border: Border.all(color: BauColours.gridLine),
        ),
        child: Text(
          'Subscription options loading...',
          style: BauTypography.body.copyWith(color: BauColours.midGrey),
          textAlign: TextAlign.center,
        ),
      );
    }

    final price = package.storeProduct.priceString;
    final period = _isAnnual ? 'year' : 'month';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BauSpacing.lg),
      decoration: BoxDecoration(
        color: BauColours.surface,
        borderRadius: BorderRadius.circular(BauSpacing.borderRadius),
        border: Border.all(
          color: BauColours.blueprintBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            price,
            style: BauTypography.headline1.copyWith(
              color: BauColours.blueprintBlue,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: BauSpacing.xs),
          Text(
            'per $period',
            style: BauTypography.bodySmall,
          ),
          if (_isAnnual && _monthlyPackage != null) ...[
            const SizedBox(height: BauSpacing.xs),
            Text(
              'That\'s ${_monthlyEquivalent(package)} per month',
              style: BauTypography.bodySmall.copyWith(
                color: BauColours.sage,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _monthlyEquivalent(Package annual) {
    final price = annual.storeProduct.price;
    final monthly = price / 12;
    final symbol = annual.storeProduct.currencyCode == 'GBP'
        ? '£'
        : annual.storeProduct.currencyCode == 'EUR'
            ? '€'
            : '\$';
    return '$symbol${monthly.toStringAsFixed(2)}';
  }

  Widget _buildPurchaseButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _purchasing ? null : _handlePurchase,
        style: ElevatedButton.styleFrom(
          backgroundColor: BauColours.blueprintBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BauSpacing.borderRadius),
          ),
          elevation: 0,
        ),
        child: _purchasing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Become a Full Resident',
                style: BauTypography.headline3.copyWith(color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildRestoreButton() {
    return TextButton(
      onPressed: _purchasing ? null : _handleRestore,
      child: Text(
        'Restore previous purchase',
        style: BauTypography.bodySmall.copyWith(
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildLegalText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BauSpacing.md),
      child: Text(
        'Payment will be charged to your App Store or Google Play account. '
        'Subscriptions renew automatically unless cancelled at least '
        '24 hours before the current period ends.',
        style: BauTypography.label.copyWith(fontSize: 10, height: 1.4),
        textAlign: TextAlign.center,
      ),
    );
  }

  Future<void> _handlePurchase() async {
    final package = _selectedPackage;
    if (package == null) return;

    setState(() => _purchasing = true);

    final success =
        await ref.read(subscriptionProvider.notifier).purchase(package);

    if (mounted) {
      setState(() => _purchasing = false);
      if (success) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _purchasing = true);

    final success =
        await ref.read(subscriptionProvider.notifier).restore();

    if (mounted) {
      setState(() => _purchasing = false);
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No previous purchases found.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _Benefit {
  final IconData icon;
  final String title;
  final String subtitle;

  const _Benefit({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
