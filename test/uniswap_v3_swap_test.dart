import 'dart:async';

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

Future<ParsedResult> parseExactInput(ContractCall callInfo, dynamic tx) async {
  final params = callInfo.callParams['params'];
  final recipient = '0x' + params[1].toString();

  final path = hex.encode(params[0]);
  final tokenInAddr = path.substring(0, 40);
  final tokenOutAddr = path.substring(path.length - 40);

  final amountIn = Decimal.parse(params[3].toString());
  final amountOutMinimum = Decimal.parse(params[4].toString());

  final tokenIn = getContractConfigByAddress(tokenInAddr);
  final tokenOut = getContractConfigByAddress(tokenOutAddr);

  if (tokenIn == null || tokenOut == null) {
    return ParsedResult(recipient, []);
  }

  var symbolIn = tokenIn.symbol;
  if (tokenIn.symbol == 'WETH' && tx.value > BigInt.zero) {
    symbolIn = 'ETH';
  }

  final args = [
    [amountIn / Decimal.parse('1e' + tokenIn.params['decimal']), symbolIn],
    ['≥', amountOutMinimum / Decimal.parse('1e' + tokenOut.params['decimal']), tokenOut.symbol],
  ];

  return ParsedResult(recipient, ['exactInput', args[0], args[1]]);
}

Future<ParsedResult> parseExactInputSingle(ContractCall callInfo, dynamic tx) async {
  final params = callInfo.callParams['params'];
  final recipient = '0x' + params[3].toString();

  final tokenInAddr = params[0];
  final tokenOutAddr = params[1];

  final amountIn = Decimal.parse(params[5].toString());
  final amountOutMinimum = Decimal.parse(params[6].toString());

  final tokenIn = getContractConfigByAddress(tokenInAddr);
  final tokenOut = getContractConfigByAddress(tokenOutAddr);

  if (tokenIn == null || tokenOut == null) {
    return ParsedResult(recipient, []);
  }

  var symbolIn = tokenIn.symbol;
  if (tokenIn.symbol == 'WETH' && tx.value > BigInt.zero) {
    symbolIn = 'ETH';
  }

  final args = [
    [amountIn / Decimal.parse('1e' + tokenIn.params['decimal']), symbolIn],
    ['≥', amountOutMinimum / Decimal.parse('1e' + tokenOut.params['decimal']), tokenOut.symbol],
  ];

  return ParsedResult(recipient, ['exactInputSingle', args[0], args[1]]);
}

Future<ParsedResult> parseExactOutput(ContractCall callInfo, dynamic tx) async {
  final params = callInfo.callParams['params'];
  final recipient = '0x' + params[1].toString();

  final path = hex.encode(params[0]);
  final tokenOutAddr = path.substring(0, 40);
  final tokenInAddr = path.substring(path.length - 40);

  final amountOut = Decimal.parse(params[3].toString());
  final amountInMaximum = Decimal.parse(params[4].toString());

  final tokenIn = getContractConfigByAddress(tokenInAddr);
  final tokenOut = getContractConfigByAddress(tokenOutAddr);

  if (tokenIn == null || tokenOut == null) {
    return ParsedResult(recipient, []);
  }

  var symbolIn = tokenIn.symbol;
  if (tokenIn.symbol == 'WETH' && tx.value > BigInt.zero) {
    symbolIn = 'ETH';
  }

  final args = [
    ['≤', amountInMaximum / Decimal.parse('1e' + tokenIn.params['decimal']), symbolIn],
    [amountOut / Decimal.parse('1e' + tokenOut.params['decimal']), tokenOut.symbol],
  ];

  return ParsedResult(recipient, ['exactOutput', args[0], args[1]]);
}

Future<ParsedResult> parseExactOutputSingle(ContractCall callInfo, dynamic tx) async {
  final params = callInfo.callParams['params'];
  final recipient = '0x' + params[3].toString();

  final tokenInAddr = params[0];
  final tokenOutAddr = params[1];

  final amountOut = Decimal.parse(params[5].toString());
  final amountInMaximum = Decimal.parse(params[6].toString());

  final tokenIn = getContractConfigByAddress(tokenInAddr);
  final tokenOut = getContractConfigByAddress(tokenOutAddr);

  if (tokenIn == null || tokenOut == null) {
    return ParsedResult(recipient, []);
  }

  var symbolIn = tokenIn.symbol;
  if (tokenIn.symbol == 'WETH' && tx.value > BigInt.zero) {
    symbolIn = 'ETH';
  }

  final args = [
    ['≤', amountInMaximum / Decimal.parse('1e' + tokenIn.params['decimal']), symbolIn],
    [amountOut / Decimal.parse('1e' + tokenOut.params['decimal']), tokenOut.symbol],
  ];

  return ParsedResult(recipient, ['exactOutputSingle', args[0], args[1]]);
}

Future<ParsedResult> parseMulticall(ContractCall callInfo, dynamic tx) async {
  final abi = getContractABIByType('UNISWAP V3');

  final bytesArray = callInfo.callParams['data'];
  final subcallArray = bytesArray.map((bytes) => abi.decomposeCall(bytes)).toList();

  Set<String> recipients = Set();
  List<dynamic> stack = [];
  for (final callInfo in subcallArray) {
    switch (callInfo.functionName) {
      case 'exactInput':
        {
          final parsed = await parseExactInput(callInfo, tx);
          recipients.add(parsed.recipient);
          stack.addAll(parsed.args);
        }
        continue;
      case 'exactInputSingle':
        {
          final parsed = await parseExactInputSingle(callInfo, tx);
          recipients.add(parsed.recipient);
          stack.addAll(parsed.args);
        }
        continue;
      case 'exactOutput':
        {
          final parsed = await parseExactOutput(callInfo, tx);
          recipients.add(parsed.recipient);
          stack.addAll(parsed.args);
        }
        continue;
      case 'exactOutputSingle':
        {
          final parsed = await parseExactOutputSingle(callInfo, tx);
          recipients.add(parsed.recipient);
          stack.addAll(parsed.args);
        }
        continue;
      // case 'refundETH':
      //   {
      //     final first = stack.first;
      //     if (first != null && first.last == 'WETH') {
      //       first.last = 'ETH';
      //     }
      //   }
      //   continue;
      case 'unwrapWETH9':
        {
          final weth =
              stack.lastWhere((item) => item is List && item.last == 'WETH', orElse: () => null);
          if (weth != null) {
            weth.last = 'ETH';

            final recipient = '0x' + callInfo.callParams['recipient'].toString();
            recipients.add(recipient);

            final amountMinimum = Decimal.parse(callInfo.callParams['amountMinimum'].toString());
            weth[weth.length - 2] = amountMinimum / Decimal.parse('1e18');
          }
        }
        continue;
      default:
        continue;
    }
  }

  recipients.remove('0x0000000000000000000000000000000000000000');

  return ParsedResult(recipients.join(','), stack);
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

  test('test uniswap v3 exactInput', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('35b3a5601888971afc0b2cadb3630f473332f86b'),
        EthereumAddressHash.fromHex('e592427a0aece92de3edee1f18e0157c05861564'),
        BigInt.parse('0', radix: 16),
        int.parse('40141', radix: 16),
        int.parse('35458b44e', radix: 16),
        int.parse('33', radix: 16),
        input: hex.decode(
            "c04b8d59000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000035b3a5601888971afc0b2cadb3630f473332f86b0000000000000000000000000000000000000000000000000000000060ebfda20000000000000000000000000000000000000000000000000000000000004e20000000000000000000000000000000000000000000000000000000015b8aaead0000000000000000000000000000000000000000000000000000000000000042cc8fa225d80b9c7d42f96e9570156c65d6caaa25000bb8c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20001f4dac17f958d2ee523a2206206994597c13d831ec7000000000000000000000000000000000000000000000000000000000000"));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract['method'], 'params': contract['params']});

    final parsed = await parseExactInput(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final s = sprintf("Swap %s for %s", extractArgs(parsed.args));
    print(s);
    expect(s, "Swap 20000 SLP for ≥5830.782637 USDT");
  });

  test('test uniswap v3 exactInput 2', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('f12e87fbb4cf2b441ff64a2afe7a027d4e2ed3cf'),
        EthereumAddressHash.fromHex('e592427a0aece92de3edee1f18e0157c05861564'),
        BigInt.parse('38d7ea4c68000', radix: 16),
        int.parse('3fe52', radix: 16),
        int.parse('35458b44e', radix: 16),
        int.parse('33', radix: 16),
        input: hex.decode(
            "c04b8d59000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000f12e87fbb4cf2b441ff64a2afe7a027d4e2ed3cf0000000000000000000000000000000000000000000000000000000060efe39200000000000000000000000000000000000000000000000000038d7ea4c680000000000000000000000000000000000000000000000000001b05057b507073860000000000000000000000000000000000000000000000000000000000000042c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20001f42260fac5e5542a773aa44fbcfedf7c193bc2c599000bb86b175474e89094c44da98b954eedeac495271d0f000000000000000000000000000000000000000000000000000000000000"));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract['method'], 'params': contract['params']});

    final parsed = await parseExactInput(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final s = sprintf("Swap %s for %s", extractArgs(parsed.args));
    print(s);
    expect(s, "Swap 0.001 ETH for ≥1.946968441096270726 DAI");
  });

  test('test uniswap v3 exactInputSingle', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('884f4e65b069fc01b2374066f068c2840e9b151d'),
        EthereumAddressHash.fromHex('e592427a0aece92de3edee1f18e0157c05861564'),
        BigInt.parse('1717b72f0a4000', radix: 16),
        int.parse('2dd3b', radix: 16),
        int.parse('3d432cf59', radix: 16),
        int.parse('3', radix: 16),
        input: hex.decode(
            "414bf389000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec700000000000000000000000000000000000000000000000000000000000001f4000000000000000000000000884f4e65b069fc01b2374066f068c2840e9b151d0000000000000000000000000000000000000000000000000000000060ebfe0c000000000000000000000000000000000000000000000000001717b72f0a40000000000000000000000000000000000000000000000000000000000000bdfe8e0000000000000000000000000000000000000000000000000000000000000000"));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract['method'], 'params': contract['params']});

    final parsed = await parseExactInputSingle(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final s = sprintf("Swap %s for %s", extractArgs(parsed.args));
    print(s);
    expect(s, "Swap 0.0065 ETH for ≥12.45147 USDT");
  });

  test('test uniswap v3 exactOutput', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('6f7b3ec82a000c5a310636d7f7549df425666666'),
        EthereumAddressHash.fromHex('e592427a0aece92de3edee1f18e0157c05861564'),
        BigInt.parse('0', radix: 16),
        int.parse('334da', radix: 16),
        int.parse('324a9a700', radix: 16),
        int.parse('139', radix: 16),
        input: hex.decode(
            "f28c0498000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000006f7b3ec82a000c5a310636d7f7549df4256666660000000000000000000000000000000000000000000000000000000060ec0bf8000000000000000000000000000000000000000000000000000000000000038400000000000000000000000000000000000000000000000e869fa41467bc36750000000000000000000000000000000000000000000000000000000000000042cc8fa225d80b9c7d42f96e9570156c65d6caaa25002710c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20001f46b175474e89094c44da98b954eedeac495271d0f000000000000000000000000000000000000000000000000000000000000"));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract['method'], 'params': contract['params']});

    final parsed = await parseExactOutput(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final s = sprintf("Swap %s for %s", extractArgs(parsed.args));
    print(s);
    expect(s, "Swap ≤267.955069561859749493 DAI for 900 SLP");
  });

  test('test uniswap v3 exactOututSingle', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('ba3eb54e93621ec4995fc8a0d8543356b78a01b1'),
        EthereumAddressHash.fromHex('e592427a0aece92de3edee1f18e0157c05861564'),
        BigInt.parse('0', radix: 16),
        int.parse('2c679', radix: 16),
        int.parse('2540be400', radix: 16),
        int.parse('1', radix: 16),
        input: hex.decode(
            "db3e2198000000000000000000000000b5fe099475d3030dde498c3bb6f3854f762a48ad000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec70000000000000000000000000000000000000000000000000000000000000bb8000000000000000000000000ba3eb54e93621ec4995fc8a0d8543356b78a01b10000000000000000000000000000000000000000000000000000000060e9511c0000000000000000000000000000000000000000000000000000000002fdfdc00000000000000000000000000000000000000000000000023801a23e5dc9aa4e0000000000000000000000000000000000000000000000000000000000000000"));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract['method'], 'params': contract['params']});

    final parsed = await parseExactOutputSingle(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final s = sprintf("Swap %s for %s", extractArgs(parsed.args));
    print(s);
    expect(s, "Swap ≤40.92917327726494779 FNK for 50.2 USDT");
  });

  test('test uniswap v3 multicall: exactOutputSingle -> refundETH', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('a18fb9312ef2d98219f169653d8ad9e21df1fabc'),
        EthereumAddressHash.fromHex('e592427a0aece92de3edee1f18e0157c05861564'),
        BigInt.parse('854de5996b3c58', radix: 16),
        int.parse('30cf4', radix: 16),
        int.parse('9502f9000', radix: 16),
        int.parse('25', radix: 16),
        input: hex.decode(
            "ac9650d800000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000104db3e2198000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000009355372396e3f6daf13359b7b607a3374cc638e00000000000000000000000000000000000000000000000000000000000000bb8000000000000000000000000a18fb9312ef2d98219f169653d8ad9e21df1fabc0000000000000000000000000000000000000000000000000000000060ee624f00000000000000000000000000000000000000000000000000000000000186a000000000000000000000000000000000000000000000000000854de5996b3c58000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000412210e8a00000000000000000000000000000000000000000000000000000000"));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract['method'], 'params': contract['params']});

    final parsed = await parseMulticall(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final s = sprintf("Swap %s for %s", extractArgs(parsed.args));
    print(s);
    expect(s, "Swap ≤0.037521820419308632 ETH for 10 WHALE");
  });

  test('test uniswap v3 multicall: selfPermit -> exactInputSingle', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('0d68b16b9c686fe2660c22fa0f01116555147dc7'),
        EthereumAddressHash.fromHex('e592427a0aece92de3edee1f18e0157c05861564'),
        BigInt.parse('0', radix: 16),
        int.parse('32952', radix: 16),
        int.parse('773594000', radix: 16),
        int.parse('fd', radix: 16),
        input: hex.decode(
            "ac9650d8000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000000c4f3995c67000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb480000000000000000000000000000000000000000000000000000000047a7ed540000000000000000000000000000000000000000000000000000000060efb7ee000000000000000000000000000000000000000000000000000000000000001b7e01e9453c1deaea33180c6ef2dab3659fd844bcf7dcf52bda88bda4c032b8b635273d39a4923755444518a5cf049b2f5b4e4f583d57c24d23fecb7cbf267e76000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000104414bf389000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000c221b7e65ffc80de234bbb6667abdd46593d34f00000000000000000000000000000000000000000000000000000000000000bb80000000000000000000000000d68b16b9c686fe2660c22fa0f01116555147dc70000000000000000000000000000000000000000000000000000000060efb3440000000000000000000000000000000000000000000000000000000047a7ed54000000000000000000000000000000000000000000000054c13c6b81f3a66ef5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract['method'], 'params': contract['params']});

    final parsed = await parseMulticall(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final s = sprintf("Swap %s for %s", extractArgs(parsed.args));
    print(s);
    expect(s, "Swap 1202.187604 USDC for ≥1563.450624545407790837 wCFG");
  });

  test('test uniswap v3 multicall: selfPermit -> exactInput -> unwrapWETH9', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('916c2cd2f87c0e9d7a02b76aa8ba6cb6586187d4'),
        EthereumAddressHash.fromHex('e592427a0aece92de3edee1f18e0157c05861564'),
        BigInt.parse('0', radix: 16),
        int.parse('54206', radix: 16),
        int.parse('df8475800', radix: 16),
        int.parse('90b', radix: 16),
        input: hex.decode(
            "ac9650d8000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000002e000000000000000000000000000000000000000000000000000000000000000c4f3995c67000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb480000000000000000000000000000000000000000000000000000000084e57a320000000000000000000000000000000000000000000000000000000060ee6b26000000000000000000000000000000000000000000000000000000000000001cc6b0986f2aefb2705902e9a570a6a381984987184dc961608204eba25dba2bd23a25f0d4234f7ac6512175dd73060f93d0f2d0fe3b6e03f557f183fc3aed904c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000144c04b8d59000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060ee66760000000000000000000000000000000000000000000000000000000084e57a32000000000000000000000000000000000000000000000000105dd2eee13177830000000000000000000000000000000000000000000000000000000000000042a0b86991c6218b36c1d19d4a2e9eb0ce3606eb480001f46b175474e89094c44da98b954eedeac495271d0f0001f4c02aaa39b223fe8d0a0e5c4f27ead9083c756cc200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004449404b7c000000000000000000000000000000000000000000000000105dd2eee1317783000000000000000000000000916c2cd2f87c0e9d7a02b76aa8ba6cb6586187d400000000000000000000000000000000000000000000000000000000"));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract['method'], 'params': contract['params']});

    final parsed = await parseMulticall(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final s = sprintf("Swap %s for %s", extractArgs(parsed.args));
    print(s);
    expect(s, "Swap 2229.631538 USDC for ≥1.179330600863102851 ETH");

    // final data = callInfo.callParams['data'];
    // expect(data.length, 3);

    // final abi = getContractABIByType(contract['type']);

    // final callInfoArray = data.map((bytes) => abi.decomposeCall(bytes)).toList();
    // expect(callInfoArray[0].functionName, 'selfPermit');
    // expect(callInfoArray[1].functionName, 'exactInput');
    // expect(callInfoArray[2].functionName, 'unwrapWETH9');

    // List<dynamic> stack = [];
    // for (final item in callInfoArray) {
    //   final callInfo = ContractCall(item.functionName, item.callParams);

    //   switch (callInfo.functionName) {
    //     case 'exactInput':
    //       stack.addAll(parseExactInput(callInfo, tx.value));
    //       continue;
    //     case 'exactInputSingle':
    //       stack.addAll(parseExactInputSingle(callInfo, tx.value));
    //       continue;
    //     case 'exactOutput':
    //       stack.addAll(parseExactOutput(callInfo, tx.value));
    //       continue;
    //     case 'exactOututSingle':
    //       stack.addAll(parseExactOutputSingle(callInfo, tx.value));
    //       continue;
    //     case 'refundETH':
    //       {
    //         final first = stack.first;
    //         if (first != null && first.last == 'WETH') {
    //           first.last = 'ETH';
    //         }
    //       }
    //       continue;
    //     case 'unwrapWETH9':
    //       {
    //         final last = stack.last;
    //         if (last != null && last.last == 'WETH') {
    //           last.last = 'ETH';
    //         }
    //       }
    //       continue;
    //     default:
    //       continue;
    //   }
    // }

    // final s = sprintf("Swap %s for %s", extractArgs(stack));
    // print(s);
  });
}
