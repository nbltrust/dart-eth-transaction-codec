import 'package:ethereum_codec/ethereum_codec.dart';
import 'package:dio/dio.dart';

import 'initialize.dart';

// Future<String> callInfura(String to, String data) async {
//   var dio = new Dio();
//   var response = await dio.post(
//     'https://mainnet.infura.io/v3/774b1e4252de48c3997d66ac5f5078d8',
//     data: {
//       'id': 1,
//       'jsonrpc': '2.0',
//       'method': 'eth_call',
//       'params': [
//         {
//           'to': to,
//           'data': data
//         },
//         'latest'
//       ]
//     });
//   return response.data['result'] as String;
// }

// void main() async {
//   initAbi();
//   // initContractABIs('contract_abi');
//   print(await callContract('0xdac17f958d2ee523a2206206994597c13d831ec7', 'name', {}, callInfura));
//   print(await callContract('0xdac17f958d2ee523a2206206994597c13d831ec7', 'symbol', {}, callInfura));
//   print(await callContract('0xdac17f958d2ee523a2206206994597c13d831ec7', 'balances', {'': 'dac17f958d2ee523a2206206994597c13d831ec7'}, callInfura));
//   print(await callContract('0xdac17f958d2ee523a2206206994597c13d831ec7', 'decimals', {}, callInfura));
//   print(await callContract('0xdac17f958d2ee523a2206206994597c13d831ec7', '_totalSupply', {}, callInfura));

//   print(await callContract('0xa5407eae9ba41422680e2e00537571bcc53efbfd', 'coins', {'arg0': 0}, callInfura));
//   // print(await callContract('0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e', 'resolver', {'node': 'c8485cc9d9d6e082fbf95eedb54a338198ce7dbbd24795ad2d8548b27d07b342'}, callInfura));
// }

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

  return response.data['result'] as String;
}

void main() async {
  initAbi();
  ETHRpc.createInstance(callInfura);
  print('call ERC20 name');
  print(await ETHRpc.instance().ethCall('0xdac17f958d2ee523a2206206994597c13d831ec7', 'name', {}));

  print('call ERC20 symbol');
  print(await ETHRpc.instance().ethCall('0xdac17f958d2ee523a2206206994597c13d831ec7', 'symbol', {}));

  print('call ERC20 decimals');
  print(await ETHRpc.instance().ethCall('0xdac17f958d2ee523a2206206994597c13d831ec7', 'decimals', {}));

  print('call unknown ERC20 name');
  print(await ETHRpc.instance().ethCall('0xdf5e0e81dff6faf3a7e52ba697820c5e32d806a8', 'name', {}, type: 'ERC20'));

  print('call unknown ERC20 symbol');
  print(await ETHRpc.instance().ethCall('0xdf5e0e81dff6faf3a7e52ba697820c5e32d806a8', 'symbol', {}, type: 'ERC20'));
  
  print('call unknown ERC20 decimals');
  print(await ETHRpc.instance().ethCall('0xdf5e0e81dff6faf3a7e52ba697820c5e32d806a8', 'decimals', {}, type: 'ERC20'));

  print('call contract by unexist method name');
  try {
    await ETHRpc.instance().ethCall('0x5ba5fcf1d81d4ce036bba16b36ba71577aa6ef89', 'name', {}, type: 'ERC20');
  } on Exception catch (e) {
    print("${e}");
  }

  print('aggregate call');
  print(await ETHRpc.instance().aggregateCall([
    ['0xdf5e0e81dff6faf3a7e52ba697820c5e32d806a8', 'name', Map<String, dynamic>(), 'ERC20'],
    ['0xdac17f958d2ee523a2206206994597c13d831ec7', 'symbol', Map<String, dynamic>()],
    ['0xdac17f958d2ee523a2206206994597c13d831ec7', 'decimals', Map<String, dynamic>()]
  ]));

  print('get ERC20 config');
  print(await ETHRpc.instance().getERC20Config('0xdf5e0e81dff6faf3a7e52ba697820c5e32d806a8'));

  print('get Gas price');
  print(await ETHRpc.instance().getGasPrice());

  print('estimate gas');
  print(await ETHRpc.instance().estimateGas('0x5ba5fcf1d81d4ce036bba16b36ba71577aa6ef89', BigInt.zero, 'approve', {'_spender': 'df5e0e81dff6faf3a7e52ba697820c5e32d806a8', '_value': '0x123456789'}, type: 'ERC20'));
}