import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ethereum_codec/ethereum_codec.dart';

Future<dynamic> callInfura(String method, List<dynamic> args) async {
  var dio = new Dio();
  var response = await dio.post(
    'https://mainnet.infura.io/v3/12a9161db1dd4fce8290ab19ea9128d5',
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
  List<dynamic> contracts = symbols["contracts"];
  var abis = contracts.map((s) => <String, dynamic>{
    'type': s['type'] as String,
    'abi': jsonDecode(
      File('contract_abi/abi/${s['type'].toUpperCase()}.json').readAsStringSync())
  }).toList();

  // var transFile = File('contract_abi/trx_trans.json');
  // var translators = jsonDecode(transFile.readAsStringSync());
  initContractABIs(contracts, abis,);

  ETHRpc.createInstance(callInfura);
}