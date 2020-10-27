import 'package:ethereum_codec/ethereum_codec.dart';
import 'package:dio/dio.dart';

Future<String> callInfura(Map<String, dynamic> param) async {
  var dio = new Dio();
  var response = await dio.post(
    'https://mainnet.infura.io/v3/774b1e4252de48c3997d66ac5f5078d8',
    data: {
      'id': 1,
      'jsonrpc': '2.0',
      'method': 'eth_call',
      'params': [
        param,
        'latest'
      ]
    });
  return response.data['result'] as String;
}

void main() async {
  initContractABIs('contract_abi');
  print(await callContract('0xcd62b1c403fa761baadfc74c525ce2b51780b184', 'name', {}, callInfura));
  print(await callContract('0xdac17f958d2ee523a2206206994597c13d831ec7', 'balances', {'': 'dac17f958d2ee523a2206206994597c13d831ec7'}, callInfura));
  print(await callContract('0xdac17f958d2ee523a2206206994597c13d831ec7', 'decimals', {}, callInfura));
  print(await callContract('0xdac17f958d2ee523a2206206994597c13d831ec7', '_totalSupply', {}, callInfura));
}