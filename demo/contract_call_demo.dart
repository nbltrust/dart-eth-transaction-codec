import 'package:ethereum_codec/ethereum_codec.dart';
import 'package:dio/dio.dart';

Future<String> callInfura(String to, String data) async {
  var dio = new Dio();
  var response = await dio.post(
    'https://mainnet.infura.io/v3/774b1e4252de48c3997d66ac5f5078d8',
    data: {
      'id': 1,
      'jsonrpc': '2.0',
      'method': 'eth_call',
      'params': [
        {
          'to': to,
          'data': data
        },
        'latest'
      ]
    });
  return response.data['result'] as String;
}

void main() async {
  initContractABIs('contract_abi');
  print(await callContract('0xdac17f958d2ee523a2206206994597c13d831ec7', 'name', {}, callInfura));
  print(await callContract('0xdac17f958d2ee523a2206206994597c13d831ec7', 'balances', {'': 'dac17f958d2ee523a2206206994597c13d831ec7'}, callInfura));
  print(await callContract('0xdac17f958d2ee523a2206206994597c13d831ec7', 'decimals', {}, callInfura));
  print(await callContract('0xdac17f958d2ee523a2206206994597c13d831ec7', '_totalSupply', {}, callInfura));

  print(await callContract('0xa5407eae9ba41422680e2e00537571bcc53efbfd', 'coins', {'arg0': 0}, callInfura));
}