import 'dart:async';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:decimal/decimal.dart';
import 'package:ethereum_codec/ethereum_codec.dart';
import 'package:eth_abi_codec/eth_abi_codec.dart';
import 'package:sprintf/sprintf.dart';
import 'package:test/test.dart';
import 'initialize.dart';

class ParsedResult {
  final String recipient;
  final List<dynamic> args;

  ParsedResult(this.recipient, this.args);
}

Future<ParsedResult> parseSwap(ContractCall callInfo, dynamic tx) async {
  final params = callInfo.callParams;
  final recipient = '0x' + params['to'].toString();
  print("---------------- $params");
  final amountInKey = params.keys.cast<String?>().firstWhere((k) {
    if(k == null) return false;
   return k.startsWith('amountIn');
  }, orElse: () => null);
  final amountIn = amountInKey != null ? Decimal.parse(params[amountInKey].toString()) : Decimal.parse(tx.value.toString());

  final amountOutKey = params.keys.firstWhere((k) => k.startsWith('amountOut'));
  final amountOut = Decimal.parse(params[amountOutKey].toString());

  final path = params['path'];
  final tokenInAddr = '0x' + path.first.toString();
  final tokenOutAddr = '0x' + path.last.toString();

  final tokenIn = getContractConfigByAddress(tokenInAddr);
  final tokenOut = getContractConfigByAddress(tokenOutAddr);
print("-------------tokenOut $tokenOut   tokenIn $tokenIn");
  if (tokenIn == null || tokenOut == null) {
    return ParsedResult(recipient, []);
  }

  var symbolIn = tokenIn.symbol;
  if (symbolIn == 'WETH' && callInfo.functionName.startsWith(RegExp(r'^swap[A-Za-z]*ETHFor'))) {
    symbolIn = 'ETH';
  }

  var symbolOut = tokenOut.symbol;
  if (symbolOut == 'WETH' && callInfo.functionName.contains(RegExp(r'For[A-Za-z]*ETH'))) {
    symbolOut = 'ETH';
  }

  final args = [
    [amountOutKey.endsWith('Min') ? '' : '≤', (amountIn / Decimal.parse('1e' + tokenIn.params?['decimal'])).toDecimal().toString(), symbolIn],
    [amountOutKey.endsWith('Min') ? '≥' : '', (amountOut / Decimal.parse('1e' + tokenOut.params?['decimal'])).toDecimal().toString(), symbolOut],
  ];

  return ParsedResult(recipient, ['swap', args[0], args[1]]);
}

List<dynamic> extractArgs(List<dynamic> args) {
  List<dynamic> result = [];

  try {
    final argIn = args[args.length - 2];
    if (argIn.length < 3) {
      result.add(sprintf("%s %s", argIn));
    } else {
      result.add(sprintf("%s%s %s", argIn));
    }

    final argOut = args.last;
    if (argOut.length < 3) {
      result.add(sprintf("%s %s", argOut));
    } else {
      result.add(sprintf("%s%s %s", argOut));
    }

    return result;
  } catch (e) {
    print(e);
    return [];
  }
}

void main() async {
  initAbi();

  // 0xe3e76bf84ff6cbaaaaf98b48c4fe4c5de7dae624845ec6e0bdc4bd646dd05c46
  test('test swapETHForExactTokens', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('a31dbf0435af02f3b68ec7f985c9388e8ab1e47b'),
        EthereumAddressHash.fromHex('d9e1ce17f2641f24ae83637ab66a2cca9c378b9f'),
        BigInt.parse('103ff879c8d83b31', radix: 16),
        int.parse('2d386', radix: 16),
        int.parse('11abfe1700', radix: 16),
        int.parse('536', radix: 16),
        input: Uint8List.fromList(hex.decode(
            "fb3bdb410000000000000000000000000000000000000000000000000522810a26e500000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000a31dbf0435af02f3b68ec7f985c9388e8ab1e47b000000000000000000000000000000000000000000000000000000006125eeba0000000000000000000000000000000000000000000000000000000000000002000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2000000000000000000000000114f1388fab456c4ba31b1850b244eedcd024136")));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseSwap(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final s = sprintf("Swap %s for %s", extractArgs(parsed.args));
    print(s);
    expect(s, "Swap ≤1.170927630083963697 ETH for 0.37 COOL");
  });

  // 0x7bb4568ef0ba1946070e72b124d86b2ece8b64688012699d6e24cd90dc732545
  test('test swapExactETHForTokens', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('87c8b347838d9d21a14aeb29cf3437098a87a80c'),
        EthereumAddressHash.fromHex('d9e1ce17f2641f24ae83637ab66a2cca9c378b9f'),
        BigInt.parse('853a0d2313c0000', radix: 16),
        int.parse('306bc', radix: 16),
        int.parse('f852e00a6', radix: 16),
        int.parse('2b3', radix: 16),
        input: Uint8List.fromList(hex.decode(
            "7ff36ab500000000000000000000000000000000000000000000000007aa585f0431278c000000000000000000000000000000000000000000000000000000000000008000000000000000000000000087c8b347838d9d21a14aeb29cf3437098a87a80c000000000000000000000000000000000000000000000000000000006125f5940000000000000000000000000000000000000000000000000000000000000002000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc200000000000000000000000098968f0747e0a261532cacc0be296375f5c08398")));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseSwap(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final s = sprintf("Swap %s for %s", extractArgs(parsed.args));
    print(s);
    expect(s, "Swap 0.6 ETH for ≥0.552351069421774732 MOONCAT");
  });

  // 0x0b0b2ba8a7658f9a8e6672dcb4cce908ebe1b9182edaf99bd1b1787fafacee64
  test('test swapExactTokensForETH', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('bab53f3f51e67a1b3da487631c88757addc0296c'),
        EthereumAddressHash.fromHex('d9e1ce17f2641f24ae83637ab66a2cca9c378b9f'),
        BigInt.parse('0', radix: 16),
        int.parse('29e33', radix: 16),
        int.parse('10c0837980', radix: 16),
        int.parse('11', radix: 16),
        input: Uint8List.fromList(hex.decode(
            "18cbafe500000000000000000000000000000000000000000000001b1ae4d6e2ef50000000000000000000000000000000000000000000000000000005be0fa12b2ce6d400000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000bab53f3f51e67a1b3da487631c88757addc0296c0000000000000000000000000000000000000000000000000000000061260da80000000000000000000000000000000000000000000000000000000000000002000000000000000000000000a80f2c8f61c56546001f5fc2eb8d6e4e72c45d4c000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2")));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseSwap(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final s = sprintf("Swap %s for %s", extractArgs(parsed.args));
    print(s);
    expect(s, "Swap 500 UNQT for ≥0.41378540065317858 ETH");
  });

  // 0x686c589f2ffa73ddcfcfe1c6ba16e62d0784c0b27d8552cd092c029f2bfdb83e
  test('test swapExactTokensForTokens', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('f746db80998cf53483c0a8ce895f6c69438fe847'),
        EthereumAddressHash.fromHex('d9e1ce17f2641f24ae83637ab66a2cca9c378b9f'),
        BigInt.parse('0', radix: 16),
        int.parse('3b8a6', radix: 16),
        int.parse('eab17b600', radix: 16),
        int.parse('2c', radix: 16),
        input: Uint8List.fromList(hex.decode(
            "38ed17390000000000000000000000000000000000000000000000182d7e4cfda0380000000000000000000000000000000000000000000000000000000000035378eefd00000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000f746db80998cf53483c0a8ce895f6c69438fe847000000000000000000000000000000000000000000000000000000006125f9ee00000000000000000000000000000000000000000000000000000000000000030000000000000000000000002e9d63788249371f1dfc918a52f8d799f4a38c94000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48")));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseSwap(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final s = sprintf("Swap %s for %s", extractArgs(parsed.args));
    print(s);
    expect(s, "Swap 446 TOKE for ≥14285.336317 USDC");
  });

  // 0xbe80d3da4c99a72cacbb3eca7eee53ff10967123a20f1fef42a90f088f3d085d
  test('test swapTokensForExactETH', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('af877d174d4c3a8de4f412a65dd089f94be37ed7'),
        EthereumAddressHash.fromHex('d9e1ce17f2641f24ae83637ab66a2cca9c378b9f'),
        BigInt.parse('0', radix: 16),
        int.parse('2a084', radix: 16),
        int.parse('e0fd67c49', radix: 16),
        int.parse('a', radix: 16),
        input: Uint8List.fromList(hex.decode(
            "4a25d94a00000000000000000000000000000000000000000000000006f05b59d3b200000000000000000000000000000000000000000000000001ea51418f1a706afff100000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000af877d174d4c3a8de4f412a65dd089f94be37ed7000000000000000000000000000000000000000000000000000000006125f34b000000000000000000000000000000000000000000000000000000000000000200000000000000000000000006f3c323f0238c72bf35011071f2b5b7f43a054c000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2")));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseSwap(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final s = sprintf("Swap %s for %s", extractArgs(parsed.args));
    print(s);
    expect(s, "Swap ≤9044.759714451956629489 MASQ for 0.5 ETH");
  });

  // 0x9c35bf4861ab58ccea6f923be29c6401c4d2d3b32d67e054866ac542a0f0db49
  test('test swapTokensForExactTokens', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('ea1fcb26d0f438e331559e17a07f94d478ad945a'),
        EthereumAddressHash.fromHex('d9e1ce17f2641f24ae83637ab66a2cca9c378b9f'),
        BigInt.parse('0', radix: 16),
        int.parse('82554', radix: 16),
        int.parse('faddb72e8', radix: 16),
        int.parse('8e5', radix: 16),
        input: Uint8List.fromList(hex.decode(
            "8803dbee000000000000000000000000000000000000000000000007e50ccc6899b00000000000000000000000000000000000000000000000000000000000011e110e5f00000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000ea1fcb26d0f438e331559e17a07f94d478ad945a000000000000000000000000000000000000000000000000000000006125fc270000000000000000000000000000000000000000000000000000000000000003000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec7000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2000000000000000000000000fca59cd816ab1ead66534d82bc21e7515ce441cf")));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseSwap(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final s = sprintf("Swap %s for %s", extractArgs(parsed.args));
    print(s);
    expect(s, "Swap ≤4799.401567 USDT for 145.632 RARI");
  });

  // 0xd770eb449e3276c20f660326895d3994ce302348df62cb0f6684790cc154bd9e
  test('test swapExactTokensForETHSupportingFeeOnTransferTokens', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('ae7861c80d03826837a50b45aecf11ec677f6586'),
        EthereumAddressHash.fromHex('d9e1ce17f2641f24ae83637ab66a2cca9c378b9f'),
        BigInt.parse('0', radix: 16),
        int.parse('6ddd0', radix: 16),
        int.parse('20fd78b5e1', radix: 16),
        int.parse('3215', radix: 16),
        input: Uint8List.fromList(hex.decode(
            "791ac9470000000000000000000000000000000000000000000000372579316ecf08ade6000000000000000000000000000000000000000000000000179a8d281873fe0000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000ae7861c80d03826837a50b45aecf11ec677f6586000000000000000000000000000000000000000000000000000000006125b9780000000000000000000000000000000000000000000000000000000000000002000000000000000000000000ae12c5930881c53715b369cec7606b70d8eb229f000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2")));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseSwap(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final s = sprintf("Swap %s for %s", extractArgs(parsed.args));
    print(s);
    expect(s, "Swap 1017.27116785760027799 C98 for ≥1.700827012634246656 ETH");
  });

  // 0xaa6c9fd60754eceebf93b6fd7acdd369608903a8ed66eb1e2a8ca6ad314a2445
  test('test swapExactTokensForTokensSupportingFeeOnTransferTokens', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('ae7861c80d03826837a50b45aecf11ec677f6586'),
        EthereumAddressHash.fromHex('d9e1ce17f2641f24ae83637ab66a2cca9c378b9f'),
        BigInt.parse('0', radix: 16),
        int.parse('6ddd0', radix: 16),
        int.parse('13532f7e01', radix: 16),
        int.parse('3112', radix: 16),
        input: Uint8List.fromList(hex.decode(
            "5c11d795000000000000000000000000000000000000000000000d80073b37fc0d9e39e200000000000000000000000000000000000000000000000000000001677f5af500000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000ae7861c80d03826837a50b45aecf11ec677f6586000000000000000000000000000000000000000000000000000000006125b3cc0000000000000000000000000000000000000000000000000000000000000002000000000000000000000000a487bf43cf3b10dffc97a9a744cbb7036965d3b9000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec7")));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseSwap(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final s = sprintf("Swap %s for %s", extractArgs(parsed.args));
    print(s);
    expect(s, "Swap 63752.468590477801568738 DERI for ≥6031.366901 USDT");
  });
}
