library ethereum_codec.contracts;

import 'dart:async';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:eth_abi_codec/eth_abi_codec.dart';

import 'translator.dart';
import 'util/strip0x.dart';

class ContractConfig {
  final String address;
  final String symbol;
  final String type;
  final Map<String, dynamic> params;

  ContractConfig.fromJson(Map<String, dynamic> json)
      : address = (json['address'] as String).toLowerCase(),
        symbol = json['symbol'],
        type = json['type'],
        params = json['params'];

  ContractConfig(this.address, this.symbol, this.type, this.params);
}

class AddressConfig {
  Map<String, List<ContractConfig>> configsMap;
  Map<String, ContractABI> abis; // maps from type to abi, e.g. 'ERC20' => abi

  AddressConfig(List<ContractConfig> configs, Map<String, ContractABI> abis, [int chainId = 0]) {
    configsMap = new Map<String, List<ContractConfig>>();
    configsMap['chainId:$chainId'] = configs;

    this.abis = abis;
  }

  AddressConfig.fromJson(Map<String, dynamic> json, [int chainId = 0]) {
    abis = new Map<String, ContractABI>();
    json['abis'].forEach((abi) {
      abis[abi['type']] = ContractABI.fromJson(abi['abi']);
    });

    final configs = List<ContractConfig>.from((json['contracts'] as List).map((i) => ContractConfig.fromJson(i)));
    configsMap = new Map<String, List<ContractConfig>>();
    configsMap['chainId:$chainId'] = configs;
  }

  void append(List<dynamic> configs, [int chainId = 0]) {
    final old = configsMap['chainId:$chainId'];
    if (old == null) {
      configsMap['chainId:$chainId'] = List<ContractConfig>.from((configs).map((i) => ContractConfig.fromJson(i)));
      return;
    }

    configsMap['chainId:$chainId'].addAll(List<ContractConfig>.from((configs).map((i) => ContractConfig.fromJson(i))));
  }

  ContractConfig getContractConfigByAddress(String address, [int chainId = 0]) {
    var addr = append0x(address.toLowerCase());
    return configsMap['chainId:$chainId'].firstWhere((element) => element.address == addr, orElse: () => null);
  }

  ContractConfig getContractConfigBySymbol(String symbol, [chainId = 0]) {
    return configsMap['chainId:$chainId'].firstWhere((element) => element.symbol == symbol, orElse: () => null);
  }

  ContractABI getContractABIByType(String type) => abis[type];

  static AddressConfig get instance => _getInstance();
  static AddressConfig _getInstance() => _instance;
  static AddressConfig _instance;
  static void createInstanceFromJson(Map<String, dynamic> json, [int chainId = 0]) {
    _instance = AddressConfig.fromJson(json, chainId);
  }

  static void createInstance(List<dynamic> contractSymbols, List<Map<String, dynamic>> abis, [int chainId = 0]) {
    final configs = List<ContractConfig>.from(contractSymbols.map((i) => ContractConfig.fromJson(i)));

    final abiMap =
        Map<String, ContractABI>.fromEntries(abis.map((i) => MapEntry(i['type'], ContractABI.fromJson(i['abi']))));

    configs.forEach((element) {
      if (!abiMap.containsKey(element.type)) {
        throw Exception("abi ${element.type} not configured");
      }
    });

    _instance = AddressConfig(configs, abiMap, chainId);
  }
}

/// Init contract abi from configurations
///
/// * contract_symbols format
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
/// * abis format
/// ```json
/// [
///   {
///     "type": "ERC20",
///     "abi": [
///       {
///         "constant": true,
///         "inputs": [],
///         "name": "name",
///         "outputs": [
///            {
///                "name": "",
///                "type": "string"
///            }
///        ],
///        "payable": false,
///        "stateMutability": "view",
///        "type": "function"
///       }
///     ]
///   }
/// ]
/// ```
/// Each type in contract_symbols.json need to have corresponding json file in abi
/// the abi json file can be found in
/// https://etherscan.io/address/$CONTRACT_ADDRESS#code
///
/// * translators format
/// if translators is null, transaction can not be translated into description
/// [
///   {
///        "id": "UNISWAP_swapTokensForExactTokens",
///        "desc_en": "swap %s %s for %s %s to %s",
///        "translators": [
///            "ARG-amountInMax ARG-path IMMED-0 LSTITEM DECIMAL FMTAMT",
///            "ARG-path IMMED-0 LSTITEM SYMBOL",
///            "ARG-amountOut ARG-path IMMED--1 LSTITEM DECIMAL FMTAMT",
///            "ARG-path IMMED--1 LSTITEM SYMBOL",
///            "ARG-to FMTADDR"
///        ]
///    }
/// ]
void initContractABIs(List<dynamic> contractSymbols, List<Map<String, dynamic>> abis,
    {List<dynamic> translators = null, int chainId = 0}) {
  AddressConfig.createInstance(contractSymbols, abis, chainId);

  if (translators != null) {
    Translator.createInstance(translators);
  }
}

void initContractABIsFromJson(Map<String, dynamic> abi_cfg) {
  AddressConfig.createInstanceFromJson(abi_cfg);
}

/// Returns the [ContractConfig] for required contract address
///
/// If no matching contract found, return null
ContractConfig getContractConfigByAddress(String address, [int chainId = 0]) {
  return AddressConfig.instance.getContractConfigByAddress(address, chainId);
}

/// Returns the [ContractConfig] for required contract symbol
///
/// If no matching contract found, return null
ContractConfig getContractConfigBySymbol(String symbol, [int chainId = 0]) {
  return AddressConfig.instance.getContractConfigBySymbol(symbol, chainId);
}

ContractABI getContractABIByType(String type) {
  return AddressConfig.instance.getContractABIByType(type);
}

Uint8List getContractCallPayload(ContractABI abi, String method, Map<String, dynamic> params) {
  var call = ContractCall(method);
  params.forEach((key, value) {
    call.setCallParam(key, value);
  });
  return call.toBinary(abi);
}
