import 'package:flutter/material.dart';
import 'package:ecommerce_dapp/contract/contract_service.dart';
import 'package:ecommerce_dapp/utils/Preference.dart';

import 'contract/contract_function.dart';
import 'wallet_services/helpers/wallet_connect_helper_v2.dart';

late ContractService contractService;

Future<void> main() async {
  /// Initialize Widgets binding
  WidgetsFlutterBinding.ensureInitialized();

  /// Initialize Shared Preference
  await Preference().instance();

  /// Intialize All Contract
  contractService = ContractService();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Multi Wallet Connect",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  static WalletConnectHelperV2 walletConnectHelper = WalletConnectHelperV2();

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? chainName;
  String? walletAddress;

  @override
  void initState() {
    MyHomePage.walletConnectHelper = WalletConnectHelperV2();

    chainName = MyHomePage.walletConnectHelper.chain.chainId.split(':')[0];
    walletAddress = (MyHomePage.walletConnectHelper.sessionData
                ?.namespaces[chainName]?.accounts.first ??
            "")
        .split(":")
        .last;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Connected Wallet Address is \n ${(walletAddress != null) ? walletAddress : "null"}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                    Colors.blue.withOpacity(0.12)),
                foregroundColor: MaterialStateProperty.all<Color>(Colors.blue),
                overlayColor: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) {
                    return Colors.blue.withOpacity(0.12);
                  },
                ),
              ),
              onPressed: () {
                connectWallet();
              },
              child: const Text('Connect to Wallet'),
            ),
            const SizedBox(height: 20),
            if (walletAddress != null)
              TextButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                      Colors.blue.withOpacity(0.12)),
                  foregroundColor:
                      MaterialStateProperty.all<Color>(Colors.blue),
                  overlayColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                      return Colors.blue.withOpacity(0.12);
                    },
                  ),
                ),
                onPressed: () {
                  ContractFunctions().getMCTApproval();
                },
                child: const Text('Transaction'),
              ),
          ],
        ),
      ),
    );
  }

  void connectWallet() async {
    await MyHomePage.walletConnectHelper.onWalletConnect().then((value) async {
      if (value != null) {
        chainName = MyHomePage.walletConnectHelper.chain.chainId.split(':')[0];
        walletAddress = value;
        setState(() {});
      }
    });
  }
}
