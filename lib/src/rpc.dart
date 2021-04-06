import 'dart:async';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:eth_abi_codec/eth_abi_codec.dart';

import 'contracts.dart';
import 'util/my_hexdecode.dart';
import 'util/strip0x.dart';

/// ETHCallback is set by caller
/// Caller need to send json rpc to his connected fullnode in this format:
/// curl -X POST {"jsonrpc": "2.0", "method": "$method", "params": $params, "id": 1} localhost:8545
/// and return the result field of node response
typedef Future<dynamic> ETHCallback(String method, List<dynamic> params);

class ETHRpc {
  static ETHRpc __instance;
  static void createInstance(ETHCallback cb) {
    __instance = ETHRpc(cb);
  }
  static ETHRpc instance() => __instance;

  ETHCallback callback;
  ETHRpc(this.callback): ethCallCache = {}, erc20Cache = {};
  Map<String, Map<String, dynamic>> ethCallCache;
  Map<String, List<dynamic>> erc20Cache;

  ContractABI _getContractABI(String address, String type) {
    var cfg = getContractConfigByAddress(address);
    if(cfg == null && type == null) {
      throw Exception("Unconfigured contract address 0x${address}");
    }

    var abiType = cfg == null ? type : cfg.type;
    var abi = getContractABIByType(abiType);
    if(abi == null) {
      throw Exception("Unconfigured abi type ${abiType}");
    }

    return abi;
  }

  /// Call eth rpc method eth_gasPrice
  ///
  /// return current gasPrice in ETH
  Future<int> getGasPrice() async {
    var res = (await callback('eth_gasPrice', [])) as String;
    return int.parse(strip0x(res), radix: 16);
  }

  Future<int> estimateGas(String address, BigInt value, String method, Map<String, dynamic> args,
      {String type = null}) async {
    var abi = _getContractABI(strip0x(address), type);
    var payload = hex.encode(getContractCallPayload(abi, method, args));
    return estimateGasRaw(append0x(address), "0x" + value.toRadixString(16), "0x" + payload);
  }

  Future<int> estimateGasRaw(String to, String value, String data) async {
    var result = (await callback('eth_estimateGas', [
      {"to": to, "value": value, "data": data},
      "latest"
    ])) as String;
    return int.parse(strip0x(result), radix: 16);
  }

  Future<Map<String, dynamic>> getTransactionByHash(String hash) async {
    return await callback('eth_getTransactionByHash', [append0x(hash)]);
  }

  /// Call eth rpc method "eth_call"
  /// 
  /// if type == null, address must be configured in abi directory
  /// 
  /// if timeout == -1, result is cached permenently
  /// else, result is cached for ${timeout} seconds
  Future<Map<String, dynamic>> ethCall(String address, String method, Map<String, dynamic> args, {String type = null, int timeout = -1}) async {
    var cacheKey = '';
    cacheKey += strip0x(address).toLowerCase();
    cacheKey += '|$method';
    var sortedKeys = args.keys.toList();
    sortedKeys.sort();
    sortedKeys.forEach((element) {
      cacheKey += '|$element|${args[element]}';
    });
    if(ethCallCache.containsKey(cacheKey)) {
      return ethCallCache[cacheKey];
    }

    var abi = _getContractABI(strip0x(address), type);
    var payload = hex.encode(getContractCallPayload(abi, method, args));
    var result = (await callback('eth_call', [{"to": append0x(address), "data": "0x" + payload}, "latest"])) as String;
    result = strip0x(result);
    
    if(result == '') { // no such method
      throw Exception("No such method");
    }

    var res = abi.decomposeResult(method, my_hexdecode(result));
    ethCallCache[cacheKey] = res;
    return res;
  }

  /// Calls contract to get name, symbol, decimals and totalSupply of given ERC20 token
  /// 
  /// Will not check whether the contract deployed at [address] is real ERC20 or not
  Future<List<dynamic>> getERC20Config(String address) async {
    address = strip0x(address).toLowerCase();
    if(erc20Cache.containsKey(address)) {
      return erc20Cache[address];
    }

    var res = await aggregateCall([
      [address, 'name', <String, dynamic>{}, 'ERC20'],
      [address, 'symbol', <String, dynamic>{}, 'ERC20'],
      [address, 'decimals', <String, dynamic>{}, 'ERC20'],
      [address, 'totalSupply', <String, dynamic>{}, 'ERC20']
    ]);
    var ret = [res[0][''], res[1][''], res[2][''], res[3]['']];
    erc20Cache[address] = ret;
    return ret;
  }

  /// Calls aggregate function of multicall contract, return a list of data
  /// 
  /// Pass a list of request
  /// request format:
  /// 1. for configured contract: [contract address, method, params]
  /// 2. for unconfigured contract: [contract address, method, params, abi type]
  /// 
  /// Return a list of results
  Future<List<Map<String, dynamic>>> aggregateCall(List<List<dynamic>> args) async {
    var multicallCfg = getContractConfigBySymbol('MULTICALL');
    if(multicallCfg == null) {
      throw Exception('MULTICALL contract not configured, can not use aggregate call');
    }

    List<List<dynamic>> callArgs = [];
    List<ContractABI> callAbis = [];
    List<String> callMethods = [];

    args.forEach((call) {
      if(call.length != 3 && call.length != 4) {
        throw Exception("Invalid call format");
      }

      String address = call[0];
      String method = call[1];
      Map<String, dynamic>  params = call[2];
      address = strip0x(address);
      var callAbi = _getContractABI(address, call.length == 3 ? null : call[3]);
      var callPayload = getContractCallPayload(callAbi, method, params);
      callArgs.add([
        address,
        callPayload
      ]);
      callAbis.add(callAbi);
      callMethods.add(method);
    });

    var r = await ethCall(multicallCfg.address, 'aggregate', {'calls': callArgs});
    var returnData = r['returnData'] as List;
    if(returnData.length != callAbis.length) {
      throw Exception("Unmatched call and return data");
    }

    List<Map<String, dynamic>> results = [];
    for(var i = 0; i < callAbis.length; i++) {
      results.add(callAbis[i].decomposeResult(callMethods[i], Uint8List.fromList(returnData[i] as List<int>)));
    }
    return results;
  }
}