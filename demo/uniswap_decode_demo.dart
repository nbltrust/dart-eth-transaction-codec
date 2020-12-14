import 'package:ethereum_codec/ethereum_codec.dart';
import 'package:convert/convert.dart';

import 'initialize.dart';

void main() {
  initAbi();

  // EthereumTransaction tx = EthereumTransaction(
  //   EthereumAddressHash.fromHex('621B2B1e5e1364fB014C5232E2bC9d30dd46c1f0'),
  //   EthereumAddressHash.fromHex('7a250d5630b4cf539739df2c5dacb4c659f2488d'),
  //   BigInt.parse('2386f26fc10000', radix:16),
  //   int.parse('4a0e6', radix: 16),
  //   0, // set gas price to 0 now
  //   0, // set nonce to 0 now
  //   input: hex.decode("7ff36ab50000000000000000000000000000000000000000000000003252c2b3aa38d9c60000000000000000000000000000000000000000000000000000000000000080000000000000000000000000621b2b1e5e1364fb014c5232e2bc9d30dd46c1f0000000000000000000000000000000000000000000000000000000005f8184870000000000000000000000000000000000000000000000000000000000000002000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2000000000000000000000000fc1e690f61efd961294b3e1ce3313fbd8aa4f85d")
  // );
  

  String tx_hex = 'f90151038505879c3d808303da77947a250d5630b4cf539739df2c5dacb4c659f2488d872386f26fc10000b8e47ff36ab500000000000000000000000000000000000000000000000009d0e2dd77e75f400000000000000000000000000000000000000000000000000000000000000080000000000000000000000000621b2b1e5e1364fb014c5232e2bc9d30dd46c1f0000000000000000000000000000000000000000000000000000000005f9810830000000000000000000000000000000000000000000000000000000000000002000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2000000000000000000000000ba11d00c5f74255f56a5e366f4f77f5a186d7f551ba040c55c4f73ee2236297d3dcf61c7f934aabf0eaeff0ef240f7b9f2eccdfd563ca04572d4bbadcdb7ea87c743b7fab9c3ebc6d1f37d75945ff613df5cf04db48875';

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
    print(contract['params']);
  }

  print('tx hash to sign: ${tx.hashToSign()}');
}