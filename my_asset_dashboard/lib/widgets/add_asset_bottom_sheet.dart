import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/portfolio_provider.dart';

class AddAssetBottomSheet extends StatefulWidget {
  const AddAssetBottomSheet({super.key});

  @override
  State<AddAssetBottomSheet> createState() => _AddAssetBottomSheetState();
}

class _AddAssetBottomSheetState extends State<AddAssetBottomSheet> {
  final _apiIdController = TextEditingController();
  final _symbolController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _apiIdController.dispose();
    _symbolController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submitData() {
    final enteredApiId = _apiIdController.text;
    final enteredSymbol = _symbolController.text;
    final enteredAmount = double.tryParse(_amountController.text) ?? 0.0;

    if (enteredApiId.isEmpty || enteredSymbol.isEmpty || enteredAmount <= 0) {
      return;
    }

    Provider.of<PortfolioProvider>(context, listen: false).addAsset(
      enteredApiId.toLowerCase().trim(),
      enteredApiId.trim(), // 이름은 API ID와 동일하게 사용 (임시)
      enteredSymbol.toUpperCase().trim(),
      enteredAmount,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Add New Asset',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _apiIdController,
            decoration: const InputDecoration(
              labelText: 'Coin API ID (ex: bitcoin, dogecoin)',
              hintText: 'coingecko ID 입력',
            ),
          ),
          TextField(
            controller: _symbolController,
            decoration: const InputDecoration(
              labelText: 'Symbol (ex: BTC, DOGE)',
            ),
          ),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Amount'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitData,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Asset'),
          ),
        ],
      ),
    );
  }
}
