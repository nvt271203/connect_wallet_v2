import 'dart:math';

import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:ecommerce_dapp/main.dart';
import 'package:ecommerce_dapp/utils/Constant.dart';
import 'package:ecommerce_dapp/utils/Preference.dart';
import 'package:ecommerce_dapp/wallet_services/config/crypto/eip155.dart';
import 'package:ecommerce_dapp/wallet_services/config/eth/ethereum_transaction.dart';
import 'package:web3dart/web3dart.dart';

import 'contarct_address_constant.dart';

class ContractFunctionsName {
  static const String executeInstantOrder = "executeInstantOrder";
  static const String createInstantOrder = "createInstantOrder";
  static const String cancelInstantOrder = "cancelInstantOrder";
  static const String transfer = "transfer";
  static const String balanceOf = "balanceOf";
  static const String ownerOf = "ownerOf";
  static const String approve = "approve";
  static const String allowance = "allowance";
  static const String increaseAllowance = "increaseAllowance";
  static const String totalSupply = "totalSupply";
  static const String claimMagicBoxReward = "claimMagicBoxReward";
  static const String claimWeeklyReward = "claimWeeklyReward";
  static const String blend = "blend";
}

class ContractFunctions {
  final client = Web3Client(Constant.netWorkEndpoints, Client());

  final String chainName =
      MyHomePage.walletConnectHelper.chain.chainId.split(':')[0];

  int chainId = int.parse(
      MyHomePage.walletConnectHelper.chain.chainId.split(':')[1].toString());

  ContractFunctions();

  _initGoToWallet() async {
    String prfURI = Preference.shared.getString(Preference.connectionURL) ?? "";

    debugPrint("prfURI$prfURI");

    Uri uri = Uri.parse(prfURI);
    await MyHomePage.walletConnectHelper.moveToWalletApp(uri);
  }

  Future<bool> getMCTApproval() async {
    double price = 20000.00;

    String? transactionId;

    try {
      String walletAddress = (MyHomePage.walletConnectHelper.sessionData
                  ?.namespaces[chainName]?.accounts.first ??
              "")
          .split(":")
          .last;

      /// MAKE TRANSACTION USING web3dart
      Transaction transaction = Transaction.callContract(
        from: EthereumAddress.fromHex(walletAddress),
        contract: contractService.mctContract,
        function:
            contractService.mctContract.function(ContractFunctionsName.approve),
        parameters: [
          EthereumAddress.fromHex(ContractAddressConstant.marketplaceAddress),
          BigInt.from((price) * pow(10, 18))
        ],
      );

      /// MAKE ETHEREUM TRANSACTION USING THE walletconnect_flutter_v2
      EthereumTransaction ethereumTransaction = EthereumTransaction(
        from: walletAddress,
        to: ContractAddressConstant.mctAddress,
        value: "0x0",
        data: hex.encode(List<int>.from(transaction.data!)),
      );

      await _initGoToWallet();

      ///  REQUEST TO WALLET FOR TRANSACTION USING vwalletconnect_flutter_v2

      transactionId = await MyHomePage.walletConnectHelper.web3App?.request(
        topic: MyHomePage.walletConnectHelper.sessionData?.topic ?? "",
        chainId: MyHomePage.walletConnectHelper.chain.chainId,
        request: SessionRequestParams(
          method: EIP155.methods[EIP155Methods.ethSendTransaction] ?? "",
          params: [ethereumTransaction.toJson()],
        ),
      );

      debugPrint("transactionId   $transactionId");
    } on Exception catch (_, e) {
      debugPrint("Catch E    $e");
    }
    bool isApproved = transactionId != null;

    return isApproved;
  }
}
