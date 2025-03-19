// lib/features/payment/widgets/payment_method_selector.dart
import 'package:flutter/material.dart';

class PaymentMethodSelector extends StatelessWidget {
  final String? selectedMethod;
  final Function(String) onMethodSelected;

  const PaymentMethodSelector({
    Key? key,
    required this.selectedMethod,
    required this.onMethodSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Credit/Debit Card
        _buildPaymentOption(
          context: context,
          value: 'card',
          title: 'Credit/Debit Card',
          subtitle: 'Visa, Mastercard, Amex, Discover',
          icon: Icons.credit_card,
        ),
        
        const Divider(),
        
        // PayPal
        _buildPaymentOption(
          context: context,
          value: 'paypal',
          title: 'PayPal',
          subtitle: 'Pay securely using PayPal',
          icon: Icons.paypal,
        ),
        
        const Divider(),
        
        // Mobile Money
        _buildPaymentOption(
          context: context,
          value: 'mobile_money',
          title: 'Mobile Money',
          subtitle: 'M-Pesa, EcoCash, and more',
          icon: Icons.phone_android,
        ),
        
        const Divider(),
        
        // Bank Transfer
        _buildPaymentOption(
          context: context,
          value: 'bank_transfer',
          title: 'Bank Transfer',
          subtitle: 'Direct bank transfer (processing time: 2-3 business days)',
          icon: Icons.account_balance,
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required BuildContext context,
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return RadioListTile<String>(
      title: Row(
        children: [
          Icon(icon, color: selectedMethod == value ? Theme.of(context).primaryColor : Colors.grey),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(left: 36.0),
        child: Text(subtitle),
      ),
      value: value,
      groupValue: selectedMethod,
      onChanged: (value) {
        if (value != null) {
          onMethodSelected(value);
        }
      },
      contentPadding: EdgeInsets.zero,
          activeColor: Theme.of(context).primaryColor,
        );
      }
    }