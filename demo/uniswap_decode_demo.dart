import 'dart:convert';

import 'package:ethereum_codec/ethereum_codec.dart';
import 'package:convert/convert.dart';

void main() {
  initContractABIs('contract_abi');

  EthereumTransaction tx = EthereumTransaction(
    EthereumAddressHash.fromHex('621B2B1e5e1364fB014C5232E2bC9d30dd46c1f0'),
    EthereumAddressHash.fromHex('7a250d5630b4cf539739df2c5dacb4c659f2488d'),
    BigInt.parse('2386f26fc10000', radix:16),
    int.parse('4a0e6', radix: 16),
    0, // set gas price to 0 now
    0, // set nonce to 0 now
    input: hex.decode("7ff36ab50000000000000000000000000000000000000000000000003252c2b3aa38d9c60000000000000000000000000000000000000000000000000000000000000080000000000000000000000000621b2b1e5e1364fb014c5232e2bc9d30dd46c1f0000000000000000000000000000000000000000000000000000000005f8184870000000000000000000000000000000000000000000000000000000000000002000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2000000000000000000000000fc1e690f61efd961294b3e1ce3313fbd8aa4f85d")
  );
  
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
    print(contract['params']);
  }

  print('tx hash to sign: ${tx.hashToSign()}');
}