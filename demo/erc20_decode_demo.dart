import 'dart:convert';

import 'package:ethereum_codec/ethereum_codec.dart';
import 'package:convert/convert.dart';

import 'contract_abi_to_json.dart';

void main() {
  //initContractABIs('contract_abi');
  var abi_json = contractAbiToJson('contract_abi');
  initContractABIsFromJson(abi_json);

  String tx_hex = 'f8ab82058f8513ac97ad0082db8594dac17f958d2ee523a2206206994597c13d831ec780b844a9059cbb000000000000000000000000f7fe3eee8c6d97d9f5029e62255b66c8ad17024e0000000000000000000000000000000000000000000000000000000011e1a30025a01250065c4925402220997f2c9dd6da93d6378797d86ed7271ac8976a11633b79a02397a95761c0a301fdf296bfb59e380c82157541ec07e59b5a388c4730fb7904';

  EthereumTransaction tx = EthereumTransaction.fromRlp(hex.decode(tx_hex));
  
  print('tx value: ${tx.value}');
  print('tx to: ${tx.to.toJson()}');
  print('tx gas: ${tx.gas}');
  print('tx gas pr: ${tx.gasPrice}');
  print('tx hashed: ${hex.encode(tx.hashToSign())}');
  print('tx input: ${hex.encode(tx.input)}');

  var contract = tx.getContractInfo();
  if(contract != null) {
    // it's a contract call
    print('contract name: ${contract['name']}');
    print('contract type: ${contract['type']}');
    print('contract method: ${contract['method']}');
    print('contract params: ${contract['contract_params']}');
    print('to address: ${contract['params']['_to']}');
    print('value: ${contract['params']['_value']}');
  }

  print('tx hash to sign: ${tx.hashToSign()}');
}