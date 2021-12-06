import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ethereum_codec/ethereum_codec.dart';

Future<dynamic> callInfura(String method, List<dynamic> args) async {
  var dio = new Dio();
  var response = await dio.post('https://geth:Ushu764Yshdl73jsd@eth-node-wookong.nbltrust.com',
      data: {'id': 1, 'jsonrpc': '2.0', 'method': method, 'params': args});
  if (response.data.containsKey('error')) {
    throw Exception(response.data['error']);
  }

  return response.data['result'];
}

/// initialize contract abis and translators
void initAbi() {
  var symbolFile = File('../demo/contract_abi/contract_symbols.json');
  var symbols = jsonDecode(symbolFile.readAsStringSync())['contracts'];
  var abis = (symbols as List)
      .map((s) => <String, dynamic>{
            'type': s['type'] as String,
            'abi': jsonDecode(File('../demo/contract_abi/abi/${s['type'].toUpperCase()}.json').readAsStringSync())
          })
      .toList();

  initContractABIs(symbols, abis);

  final rinkebyConfig = jsonDecode(File('../demo/contract_abi/evm_symbols/rinkeby.json').readAsStringSync());
  symbols = jsonDecode(symbolFile.readAsStringSync())['contracts'];
  AddressConfig.instance.append(rinkebyConfig['contracts'], rinkebyConfig['chainId']);

  ETHRpc.createInstance(callInfura);
}
