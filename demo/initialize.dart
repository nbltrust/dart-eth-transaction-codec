import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ethereum_codec/ethereum_codec.dart';

Future<dynamic> callInfura(String method, List<dynamic> args) async {
  var dio = new Dio();
  var response = await dio.post(
    'https://mainnet.infura.io/v3/774b1e4252de48c3997d66ac5f5078d8',
    data: {
      'id': 1,
      'jsonrpc': '2.0',
      'method': method,
      'params': args
    });
  if(response.data.containsKey('error')) {
    throw Exception(response.data['error']);
  }

  return response.data['result'];
}

/// initialize contract abis and translators
void initAbi() {
  var symbolFile = File('contract_abi/contract_symbols.json');
  var symbols = jsonDecode(symbolFile.readAsStringSync());
  var abis = (symbols as List).map((s) => <String, dynamic>{
    'type': s['type'] as String,
    'abi': jsonDecode(
      File('contract_abi/abi/${s['type'].toUpperCase()}.json').readAsStringSync())
  }).toList();

  var transFile = File('contract_abi/trx_trans.json');
  var translators = jsonDecode(transFile.readAsStringSync());
  initContractABIs(symbols, abis, translators: translators);

  ETHRpc.createInstance(callInfura);
}