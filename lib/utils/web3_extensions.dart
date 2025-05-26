import 'package:web3dart/web3dart.dart';

extension ReceiptPolling on Web3Client {
  /// Polls [getTransactionReceipt] every [pollInterval] until non-null.
  Future<TransactionReceipt> waitForReceipt(
    String txHash, {
    Duration pollInterval = const Duration(seconds: 1),
  }) =>
      Stream.periodic(pollInterval)
          .asyncMap((_) => getTransactionReceipt(txHash))
          .where((r) => r != null)
          .cast<TransactionReceipt>()
          .first;
}
