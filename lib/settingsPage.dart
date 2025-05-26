import 'package:cdapp/models/wallet_service_model.dart';
import 'package:flutter/material.dart';
import 'baseScaffold.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _publicController = TextEditingController();
  final TextEditingController _privateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    final public = await WalletService.getPublicAddress();
    final priv = await WalletService.getPrivateKey();
    if (public != null) _publicController.text = public;
    if (priv != null) _privateController.text = priv;
  }

  Future<void> _saveWallet() async {
    await WalletService.saveWallet(
      publicAddress: _publicController.text.trim(),
      privateKey: _privateController.text.trim(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wallet saved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      currentIndex: 3,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const SizedBox(height: 40),
            const Text('Public Address'),
            TextField(
              controller: _publicController,
              decoration: const InputDecoration(
                hintText: 'Enter your public address',
              ),
            ),
            const SizedBox(height: 20),
            const Text('Private Key'),
            TextField(
              controller: _privateController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Enter your private key',
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveWallet,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
