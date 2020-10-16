library ethereum_codec.contracts;

import 'dart:convert';
import 'dart:io';
import 'package:eth_abi_codec/eth_abi_codec.dart';

class ContractConfig {
  final String address;
  final String symbol;
  final String type;
  final Map<String, dynamic> params;

  ContractConfig.fromJson(Map<String, dynamic> json):
    address = json['address'],
    symbol = json['symbol'],
    type = json['type'],
    params = json['params'];
}

class AddressConfig {
  List<ContractConfig> configs;
  Map<String, ContractABI> abis; // maps from type to abi, e.g. 'ERC20' => abi

  AddressConfig(this.configs, this.abis);

  ContractConfig getContractConfigByAddress(String address) {
    return configs.firstWhere(
      (element) => element.address == address,
      orElse: () => null);
  }

  ContractABI getContractABIByType(String type) => abis[type];

  static AddressConfig get instance => _getInstance();
  static AddressConfig _getInstance() => _instance;
  static AddressConfig _instance;
  static void createInstance(String configDir) {
    var config_fn = './${configDir}/contract_symbols.json';
    File f = new File(config_fn);
    if(!f.existsSync()) {
      throw "can not find ${config_fn}";
    }
    String config_str = f.readAsStringSync();
    var configs = List<ContractConfig>.from(jsonDecode(config_str).map((i) => ContractConfig.fromJson(i)));
    Map<String, ContractABI> abis = new Map();
    configs.forEach((element) {
      if(abis.containsKey(element.address)) {
        throw "duplicated address entry in contract_symbols.json";
      }
      var abi_fn = './${configDir}/abi/${element.type}.json';
      File abi_file = new File(abi_fn);
      if(!abi_file.existsSync()) {
        throw "abi file ${abi_fn} not found";
      }
      var abi_str = abi_file.readAsStringSync();
      abis[element.type] = ContractABI.fromJson(jsonDecode(abi_str));
    });
    _instance = AddressConfig(configs, abis);
  }
}

/// Init contract abi from configurations in configDir
/// 
/// * configDir file structure
/// ```bash
/// ./contract_symbols.json
/// ./abi/ERC20.json  
/// ./abi/UNISWAP.json  
/// ...
/// ```
/// 
/// * contract_symbols.json format
/// ```json
/// [
///   {
///     "address": "hex address of contract",
///     "symbol": "human readable symbol of contract",
///     "type": "$CONTRACT_TYPE"
///   }
/// ]
/// ```
/// 
/// * ./abi/$CONTRACT_TYPE.json   
/// 
/// Each type in contract_symbols.json need to have corresponding json file in abi
/// the abi json file can be found in
/// https://etherscan.io/address/$CONTRACT_ADDRESS#code
void initContractABIs(String configDir) {
  AddressConfig.createInstance(configDir);
}

/// Returns the [ContractConfig] for required contract address
/// 
/// If no matching contract found, return null
ContractConfig getContractConfigByAddress(String address) {
  return AddressConfig.instance.getContractConfigByAddress(address);
}

ContractABI getContractABIByType(String type) {
  return AddressConfig.instance.getContractABIByType(type);
}
