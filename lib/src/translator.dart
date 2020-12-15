import 'dart:async';
import 'dart:math';

import 'package:eth_abi_codec/eth_abi_codec.dart';
import 'package:sprintf/sprintf.dart';

import 'checksum_address.dart';
import 'transaction.dart';
import 'contracts.dart';
import 'rpc.dart';

/// get ERC20 configurations of given address
/// 
/// 
/// return a list of [name, symbol, decimals] of ERC20
/// if address is configured locally, will just fetch
Future<List<dynamic>> _getERC20Config(String address) async {
  var localConfig = getContractConfigByAddress(address);
  if( localConfig != null && 
      localConfig.type == 'ERC20' &&
      localConfig.params != null &&
      localConfig.params.containsKey('name') &&
      localConfig.params.containsKey('decimal')) {
    return [localConfig.params['name'], localConfig.symbol, localConfig.params['decimal']];
  }

  return (await ETHRpc.instance().getERC20Config(address)).sublist(0, 3);
}

class CallTrans {
  String desc_en;
  List<String> translators;

  CallTrans(this.desc_en, this.translators);

  Future<String> doTranslate(String command, BigInt ethVal, String toAddr, Map<String, dynamic> inputArgs) async {
    List<dynamic> stack = [];
    var commands = command.split(' ');
    for(var i = 0; i < commands.length; i++) {
      var op = commands[i];
      // print("${command}: ${op}: ${stack}");
      
      var stackAdd = (dynamic val) {
        if(val is BigInt || val is num)
          stack.add(val.toString());
        else
          stack.add(val);
      };

      if(op.startsWith('ARG-')) { // Push argument to stack, e.g. ARG-_spender will push inputArgs['_spender']
        var argName = op.substring(4);
        stackAdd(inputArgs[argName]);
        continue;
      }

      if(op.startsWith('IMMED-')) { // Push immediate value to stack
        var immedVal = op.substring(6);
        stackAdd(immedVal);
        continue;
      }

      if(op.startsWith('LSTITEM')) { // Pop index and list from stack and push list item back to stack
        var idx = int.parse(stack.removeLast() as String);
        var lst = stack.removeLast() as List;
        while(idx < 0) {
          idx += lst.length;
        }

        if(idx >= lst.length) {
          throw Exception("List index out of range");
        }

        stackAdd(lst[idx]);
        continue;
      }

      if(op.startsWith('TST')) { // Pop true-value, false-value and bool from stack and push back according to test result
        var condition = stack.removeLast() as bool;
        var falseVal = stack.removeLast() as String;
        var trueVal = stack.removeLast() as String;
        stackAdd(condition ? trueVal : falseVal);
        continue;
      }

      if(op.startsWith('CMP')) { // Pop two strings from stack and push back true if they are equal, else push back false
        var s1 = stack.removeLast() as String;
        var s2 = stack.removeLast() as String;
        stackAdd(s1 == s2);
        continue;
      }

      if(op.startsWith('OR')) { // Pop two boolean value from stack and push back logic-or result
        var b1 = stack.removeLast() as bool;
        var b2 = stack.removeLast() as bool;
        stackAdd(b1 || b2);
        continue;
      }

      if(op.startsWith('AND')) { // Pop two boolean value from stack and push back logic-and result
        var b1 = stack.removeLast() as bool;
        var b2 = stack.removeLast() as bool;
        stackAdd(b1 && b2);
        continue;
      }

      if(op == 'LIST') { // Pop list length, and items one by one from stack, and push back list object
        var len = int.parse(stack.removeLast());
        List<String> obj = [];
        for(var i = 0; i < len; i++) {
          obj.add(stack.removeLast() as String);
        }
        stackAdd(obj);
      }
  
      if(op == 'CALL') {
        // Pop sequence:
        // 1. call target address
        // 2. call function name
        // 3. argument count
        // for i in argument count
        //     pops agument valus
        //     pops argument name
        // 4. result data field
        // and push result back
        var targetAddr = stack.removeLast() as String;
        var method = stack.removeLast() as String;
        var argumentCount = int.parse(stack.removeLast());
        Map<String, dynamic> argMap = {};
        for(var i = 0; i < argumentCount; i++) {
          var argName = stack.removeLast() as String;
          var argVal = stack.removeLast();
          argMap[argName] = argVal;
        }
        var resField = stack.removeLast() as String;
        var res = await ETHRpc.instance().ethCall(targetAddr, method, argMap);
        stackAdd(res[resField]);
        continue;
      }

      if(op == 'TO') { // Push toAddr to top of stack
        stackAdd(toAddr);
        continue;
      }

      if(op == 'ETHAMT') { // Push ethVal to top of stack
        stackAdd(ethVal.toString());
        continue;
      }

      if(op == 'SYMBOL') { // Pops erc20 address from stack and push back symbol
        var addr = stack.removeLast() as String;
        var cfg = await _getERC20Config(addr);
        stackAdd(cfg[1]);
        continue;
      }

      if(op == 'SYMBOL_EXCEPT') { // Pops erc20 address from stack and push back symbol, if exception is raised, push back empty string
        var addr = stack.removeLast() as String;
        try {
          var cfg = await _getERC20Config(addr);
          stackAdd(cfg[1].toString());
        } on Exception {
          stackAdd("");
        }
        continue;
      }

      if(op == 'DECIMAL') { // Pops erc20 address from stack and push back decimal
        var addr = stack.removeLast() as String;
        var cfg = await _getERC20Config(addr);
        stackAdd(cfg[2].toString());
        continue;
      }

      if(op == 'DECIMAL_EXCEPT') { // Pops erc20 address from stack and push back decimal, if exception is raised, push back 0
        var addr = stack.removeLast() as String;
        try {
          var cfg = await _getERC20Config(addr);
          stackAdd(cfg[2].toString());
        } on Exception {
          stackAdd("0");
        }
        continue;
      }

      if(op == 'FMTAMT') { // Pops decimal and amount from stack and push back human readable amount
        var decimal = int.parse(stack.removeLast());
        var amount = BigInt.parse(stack.removeLast());
        if(amount == BigInt.parse('ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff', radix: 16)) {
          stackAdd('all');
          continue;
        }
        var r = amount / BigInt.from(pow(10, decimal));
        if(r >= 10) {
          stackAdd(r.toStringAsFixed(2));
        } else if(r >= 1) {
          stackAdd(r.toStringAsFixed(4));
        } else {
          stackAdd(r.toStringAsPrecision(6));
        }
        continue;
      }

      if(op == 'FMTADDR') { // Pops address from stack and push back checked encode of address.
        var addr = toChecksumAddress(stack.removeLast() as String);
        stackAdd(addr.substring(0, 4) + '...' + addr.substring(addr.length - 4));
        continue;
      }
    }

    if(stack.length != 1) {
      throw Exception("Invalid command");
    }

    return stack[0] as String;
  }

  Future<String> translate(BigInt ethVal, String toAddr, Map<String, dynamic> inputArgs) async {
    List<String> res = [];
    for(var i = 0; i < translators.length; i++) {
      res.add(await doTranslate(translators[i], ethVal, toAddr, inputArgs));
    }
    return sprintf(desc_en, res);
  }
}

/// Single class provides translate for eth transactions
/// 
/// Usage:
/// Translator.createInstance(configs, erc20_cb, ethcall_cb);
/// var description = await Translator.instance().translate()
class Translator {
  static Translator __instance = null;
  static void createInstance(List<dynamic> configs) {
    __instance = Translator(configs);
  }

  static bool get initialized => __instance != null;

  static Translator instance() {
    if(__instance == null)
      throw Exception('translator not initialized');
    return __instance;
  }

  final Map<String, CallTrans> transConfig;

  Translator(List<dynamic> configs):
    transConfig = Map<String, CallTrans>.fromEntries(
      configs.map((i) => MapEntry(i['id'], CallTrans(i['desc_en'], (i['translators'] as List).map((i) => i as String).toList())))
    );

  /// try to translate transaction into human readable sentence
  /// if unable to translate, return null
  static Future<String> translate(EthereumTransaction tx) async {
    if(!initialized) {
      return null;
    }

    try {
      if(tx.input.length != 0) {
        var cfg = getContractConfigByAddress(tx.to.toString());
        if(cfg == null)
          return null;
        var abi = getContractABIByType(cfg.type);
        if(abi == null)
          return null;
        var callInfo = ContractCall.fromBinary(tx.input, abi);
        var methodId = '${cfg.type}_${callInfo.functionName}';
        // print(methodId);
        if(!instance().transConfig.containsKey(methodId)) {
          return null;
        }
        // print(callInfo.callParams);
        return await instance().transConfig[methodId].translate(tx.value, tx.to.toString(), callInfo.callParams);
      } else {
        return await instance().transConfig['ETH_transfer'].translate(tx.value, tx.to.toString(), {});
      }
    } catch (e) {
    }
    return null;
  }
}
