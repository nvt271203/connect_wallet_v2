import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:ecommerce_dapp/utils/Preference.dart';
import 'package:ecommerce_dapp/wallet_services/config/crypto/eip155.dart';
import 'package:ecommerce_dapp/wallet_services/config/models/chain_metadata.dart';

class WalletConnectHelperV2 {
  WalletConnectHelperV2() {
    _initWallet();
  }

  Web3App? web3App;
  SessionData? sessionData;

  ChainMetadata chain = const ChainMetadata(
    type: ChainTypeEnum.eip155,
    chainId: 'eip155:11155111',
    name: 'Polygon Mumbai',
    logo: '',
    color: Colors.transparent,
    isTestnet: true,
    rpc: ['https://sepolia.infura.io/v3/fe4d7549ddcb4d0ba9e2fca3a6a91508'],
  );

  Future<void> _initWallet() async {
    String? prefSessionData =
        Preference.shared.getString(Preference.sessionData);

    if (prefSessionData != null) {
      sessionData = SessionData.fromJson(jsonDecode(prefSessionData));
    }

    web3App = await Web3App.createInstance(
      projectId: 'b0d8a911a49ac8f8eb25a9513a316751',
      metadata: const PairingMetadata(
        name: 'Ercommerce Dapp',
        description: 'Magic shoes web3App mobile app',
        url: 'https://www.magicclub.io/',
        icons: [
          'https://firebasestorage.googleapis.com/v0/b/magic-club-dev-20a01.appspot.com/o/app_logo.png?alt=media&token=7f819657-cf78-441c-8294-ce1fbaf31580&_gl=1*1ruy4yv*_ga*MjU4NjA5MzQuMTY2MDY0MzgwMg..*_ga_CW55HF8NVT*MTY4NTUyODkwOS4xOS4xLjE2ODU1MjkxMTQuMC4wLjA.'
        ],
      ),
    );

    web3App?.onSessionUpdate.subscribe((args) {
      debugPrint("onSessionUpdate: ${args}");
    });


    web3App?.registerEventHandler(
        chainId: chain.chainId, event: EIP155.events.values.toList()[0]);

    web3App?.onSessionPing.subscribe(_onSessionPing);
    web3App?.onSessionEvent.subscribe(_onSessionEvent);
  }

  void _onSessionPing(SessionPing? args) {
    // Utils.showToast(Get.context!, 'Received Ping :::: ${args!.topic}');

    debugPrint("_onSessionPing$args");
  }

  void _onSessionEvent(SessionEvent? args) {
    // Utils.showToast(Get.context!,'Received Ping :::: Topic: ${args!.topic}\nEvent Name: ${args.name}\nEvent Data: ${args.data}');
    debugPrint("_onSessionEvent$args");
  }

  Future<String?> onWalletConnect() async {
    final Map<String, RequiredNamespace> requiredNamespaces = {};

    final String chainName = chain.chainId.split(':')[0]; // Trả về ID mạng : eip155
    // demo
    print("demo "+ chainName.toString());
    print("demo requiredNamespaces"+ requiredNamespaces.toString());

    if (requiredNamespaces.containsKey(chainName)) {
      requiredNamespaces[chainName]!.chains!.add(chain.chainId);
    }
    final RequiredNamespace rNamespace = RequiredNamespace(
      chains: [chain.chainId],
      methods: EIP155.methods.values.toList(),
      events: EIP155.events.values.toList(),
    );
    requiredNamespaces[chainName] = rNamespace;

    debugPrint('Required namespaces:' '$requiredNamespaces');



    final ConnectResponse res = await web3App!.connect(
      requiredNamespaces: requiredNamespaces,
    );
    debugPrint("ConnectResponse: ${res.toString()}");
    debugPrint("Pairing Topic: ${res.pairingTopic}");
    debugPrint("Session Future: ${res.session}");

    debugPrint("ConnectResponse" "$res");

    /// NAVIGATE URL INTO THE WALLET
    debugPrint("URI ${res.uri}");
    try {
      await moveToWalletApp(res.uri);
    } catch (e) {
      debugPrint("Không thể mở MetaMask: $e");
    }


    try {
      // sessionData = await res.session.future;
      try {
        debugPrint("Đang chờ kết nối với ví...");
        sessionData = await res.session.future;

        // temp
        debugPrint("ConnectResponse: ${res.toString()}");
        debugPrint("Pairing Topic: ${res.pairingTopic}");
        debugPrint("Session Future: ${res.session}");


        debugPrint("Kết nối thành công! Dữ liệu session: ${sessionData?.toJson()}");
        //-----------------
        debugPrint("Kết nối thành công!");
      } catch (e) {
        debugPrint("Lỗi khi lấy session: $e");
      }

      await Preference.shared
          .setString(Preference.sessionData, jsonEncode(sessionData));

      debugPrint("sessionData${sessionData?.toJson()}");

      var walletAddress =
          (sessionData?.namespaces[chainName]?.accounts.first ?? "")
              .split(":")
              .last;

      // WalletConnectSecureStorage().store(WalletConnectSession(
      //     accounts: sessionData?.namespaces[chainName]?.accounts ?? []));

      debugPrint("WALLET-ADDRESS FROM WALLET$walletAddress");

      return walletAddress;
    } catch (e) {
      debugPrint('Exexption: $e');
    }

    return null;
  }

  Future<void> moveToWalletApp(Uri? uri) async {
    Preference.shared.setString(Preference.connectionURL, uri.toString());

    bool isLaunch = await launchUrl(
      uri!,
      mode: LaunchMode.externalApplication,
    );
    if (!isLaunch) {
      throw 'Failure - Could not open URL $uri.';
    }
  }


  Future<void> disconnect() async {
    if (sessionData != null) {
      try {
        await web3App?.disconnectSession(
          topic: sessionData!.topic,
          reason: WalletConnectError(
            code: 6000, // Mã lỗi tuỳ chỉnh, bạn có thể đặt mã khác
            message: "User disconnected the wallet",
          ),
        );
        sessionData = null; // Xóa dữ liệu phiên kết nối
        await Preference.shared.remove(Preference.sessionData); // Xóa dữ liệu lưu trữ

        debugPrint("Wallet disconnected successfully");
      } catch (e) {
        debugPrint("Error disconnecting wallet: $e");
      }
    } else {
      debugPrint("No active wallet connection to disconnect.");
    }
  }



}
