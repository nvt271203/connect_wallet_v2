import 'package:flutter/services.dart';
import 'package:ecommerce_dapp/contract/contarct_address_constant.dart';
import 'package:web3dart/web3dart.dart';

class ContractService {
  late final DeployedContract mctContract;

  ContractService() {
    _init();
  }

  Future<void> _init() async {
    mctContract = await _loadABI(
      'assets/contract_abi/MCT.json',
      'MCT',
      ContractAddressConstant.mctAddress,
    );
  }

  Future<DeployedContract> _loadABI(
    String path,
    String name,
    String contractAddress,
  ) async {
    String abiString = await rootBundle.loadString(path);

    final contract = DeployedContract(
      ContractAbi.fromJson(abiString, name),
      EthereumAddress.fromHex(contractAddress),
    );

    return contract;
  }
}
