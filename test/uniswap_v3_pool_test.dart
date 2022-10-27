import 'dart:async';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:decimal/decimal.dart';
import 'package:ethereum_codec/ethereum_codec.dart';
import 'package:eth_abi_codec/eth_abi_codec.dart';
import 'package:sprintf/sprintf.dart';
import 'package:test/test.dart';
import 'initialize.dart';

final UINT128MAX = Decimal.parse('340282366920938463463374607431768211455');

class ParsedResult {
  final String recipient;
  final List<dynamic> args;

  ParsedResult(this.recipient, this.args);
}

Future<ParsedResult> parseMint(ContractCall callInfo, dynamic tx) async {
  final params = callInfo.callParams['params'];
  final token0Addr = params[0];
  final token1Addr = params[1];
  final recipient = '0x' + params[9].toString();

  final token0 = getContractConfigByAddress(token0Addr);
  final token1 = getContractConfigByAddress(token1Addr);

  if (token0 == null || token1 == null) {
    return ParsedResult(recipient, []);
  }

  final amount0Min = Decimal.parse(params[7].toString());
  final amount1Min = Decimal.parse(params[8].toString());
  final valueDecimal = Decimal.parse(tx.value.toString());

  var token0Symbol = token0.symbol;
  var token1Symbol = token1.symbol;
  if (token0Symbol == 'WETH' && valueDecimal >= amount0Min) {
    token0Symbol = 'ETH';
  } else if (token1Symbol == 'WETH' && valueDecimal >= amount1Min) {
    token1Symbol = 'ETH';
  }

  final amount0Desired = Decimal.parse(params[5].toString());
  final amount1Desired = Decimal.parse(params[6].toString());

  final args = [[], []];

  if (amount0Min <= Decimal.zero || amount0Min == amount0Desired) {
    args[0].addAll([(amount0Desired / Decimal.parse('1e' + token0.params?['decimal'])).toDecimal().toString(), token0Symbol]);
  } else {
    args[0]
        .addAll(['≥', (amount0Min / Decimal.parse('1e' + token0.params?['decimal'])).toDecimal().toString(), token0Symbol]);
  }

  if (amount1Min <= Decimal.zero || amount0Min == amount0Desired) {
    args[1].addAll([(amount1Desired / Decimal.parse('1e' + token1.params?['decimal'])).toDecimal().toString(), token1Symbol]);
  } else {
    args[1]
        .addAll(['≥', (amount1Min / Decimal.parse('1e' + token1.params?['decimal'])).toDecimal().toString(), token1Symbol]);
  }

  return ParsedResult(recipient, ['mint', args[0], args[1]]);
}

Future<ParsedResult> parseIncreaseLiquidity(ContractCall callInfo, dynamic tx) async {
  final recipient = tx.from.toString();

  final params = callInfo.callParams['params'];
  final tokenId = params[0];

  var positions;
  try {
    positions = await ETHRpc.instance()?.ethCall('0xc36442b4a4522e871399cd717abdd847ab11fe88', 'positions', {'tokenId': tokenId});
  } catch (e) {
    return ParsedResult(recipient, []);
  }
  print("---------------- positions $positions");
  final token0Addr = positions["token0"];
  final token1Addr = positions["token1"];

  final token0 = getContractConfigByAddress(token0Addr);
  final token1 = getContractConfigByAddress(token1Addr);

  if (token0 == null || token1 == null) {
    return ParsedResult(recipient, []);
  }

  final amount0Min = Decimal.parse(params[3].toString());
  final amount1Min = Decimal.parse(params[4].toString());
  final valueDecimal = Decimal.parse(tx.value.toString());

  var token0Symbol = token0.symbol;
  var token1Symbol = token1.symbol;
  if (token0Symbol == 'WETH' && valueDecimal >= amount0Min) {
    token0Symbol = 'ETH';
  } else if (token1Symbol == 'WETH' && valueDecimal >= amount1Min) {
    token1Symbol = 'ETH';
  }

  final amount0Desired = Decimal.parse(params[1].toString());
  final amount1Desired = Decimal.parse(params[2].toString());

  final args = [[], []];

  if (amount0Min <= Decimal.zero || amount0Min == amount0Desired) {
    args[0].addAll([(amount0Desired / Decimal.parse('1e' + token0.params?['decimal'])).toDecimal().toString(), token0Symbol]);
  } else {
    args[0]
        .addAll(['≥', (amount0Min / Decimal.parse('1e' + token0.params?['decimal'])).toDecimal().toString(), token0Symbol]);
  }

  if (amount1Min <= Decimal.zero || amount1Min == amount1Desired) {
    args[1].addAll([(amount1Desired / Decimal.parse('1e' + token1.params?['decimal'])).toDecimal(), token1Symbol]);
  } else {
    args[1]
        .addAll(['≥', (amount1Min / Decimal.parse('1e' + token1.params?['decimal'])).toDecimal().toString(), token1Symbol]);
  }

  return ParsedResult(recipient, ['increaseLiquidity', args[0], args[1]]);
}

Future<ParsedResult> parseDecreaseLiquidity(ContractCall callInfo, dynamic tx) async {
  final recipient = tx.from.toString();

  final params = callInfo.callParams['params'];
  final tokenId = params[0];

  var positions;
  try {
    positions = await ETHRpc.instance()?.ethCall('0xc36442b4a4522e871399cd717abdd847ab11fe88', 'positions', {'tokenId': tokenId});
  } catch (e) {
    return ParsedResult(recipient, []);
  }

  final token0Addr = positions["token0"];
  final token1Addr = positions["token1"];

  final token0 = getContractConfigByAddress(token0Addr);
  final token1 = getContractConfigByAddress(token1Addr);

  if (token0 == null || token1 == null) {
    return ParsedResult(recipient, []);
  }

  final amount0Min = Decimal.parse(params[2].toString());
  final amount1Min = Decimal.parse(params[3].toString());

  final args = [[], []];

  args[0].addAll(['≥', (amount0Min / Decimal.parse('1e' + token0.params?['decimal'])).toDecimal().toString(), token0.symbol]);
  args[1].addAll(['≥', (amount1Min / Decimal.parse('1e' + token1.params?['decimal'])).toDecimal().toString(), token1.symbol]);

  return ParsedResult(recipient, ['decreaseLiquidity', args[0], args[1]]);
}

Future<ParsedResult> parseCollect(ContractCall callInfo, dynamic tx) async {
  final params = callInfo.callParams['params'];
  final tokenId = params[0];
  final recipient = '0x' + params[1].toString();

  var positions;
  try {
    positions = await ETHRpc.instance()?.ethCall('0xc36442b4a4522e871399cd717abdd847ab11fe88', 'positions', {'tokenId': tokenId});
  } catch (e) {
    return ParsedResult(recipient, []);
  }

  final token0Addr = positions["token0"];
  final token1Addr = positions["token1"];

  final token0 = getContractConfigByAddress(token0Addr);
  final token1 = getContractConfigByAddress(token1Addr);

  if (token0 == null || token1 == null) {
    return ParsedResult(recipient, []);
  }

  final amount0Max = Decimal.parse(params[2].toString());
  final amount1Max = Decimal.parse(params[3].toString());
  final tokensOwed0 = Decimal.parse(positions["tokensOwed0"].toString());
  final tokensOwed1 = Decimal.parse(positions["tokensOwed1"].toString());

  final args = [[], []];

  if (amount0Max >= tokensOwed0 || amount0Max >= UINT128MAX) {
    args[0].addAll(['all', token0.symbol]);
  } else {
    args[0]
        .addAll(['≤', (amount0Max / Decimal.parse('1e' + token0.params?['decimal'])).toDecimal().toString(), token0.symbol]);
  }

  if (amount1Max >= tokensOwed1 || amount1Max >= UINT128MAX) {
    args[1].addAll(['all', token1.symbol]);
  } else {
    args[1]
        .addAll(['≤', (amount0Max / Decimal.parse('1e' + token1.params?['decimal'])).toDecimal().toString(), token1.symbol]);
  }

  return ParsedResult(recipient, ['collect', args[0], args[1]]);
}

Future<ParsedResult> parseMulticall(ContractCall callInfo, dynamic tx) async {
  final abi = getContractABIByType('UNISWAP V3 POOL');

  final bytesArray = callInfo.callParams['data'];
  final subcallArray = bytesArray.map((bytes) => abi?.decomposeCall(bytes)).toList();

  Set<String> recipients = Set();
  List<dynamic> stack = [];
  for (final callInfo in subcallArray) {
    switch (callInfo.functionName) {
      case 'mint':
        {
          final parsed = await parseMint(callInfo, tx);
          recipients.add(parsed.recipient);
          stack.addAll(parsed.args);
        }
        continue;
      case 'increaseLiquidity':
        {
          final parsed = await parseIncreaseLiquidity(callInfo, tx);
          recipients.add(parsed.recipient);
          stack.addAll(parsed.args);
        }
        continue;
      case 'decreaseLiquidity':
        {
          final parsed = await parseDecreaseLiquidity(callInfo, tx);
          recipients.add(parsed.recipient);
          stack.addAll(parsed.args);
        }
        continue;
      case 'collect':
        {
          if (stack.isNotEmpty) {
            continue;
          }

          final parsed = await parseCollect(callInfo, tx);
          recipients.add(parsed.recipient);
          stack.addAll(parsed.args);
        }
        continue;
      case 'unwrapWETH9':
        {
          final weth =
              stack.lastWhere((item) => item is List && item.last == 'WETH', orElse: () => null);
          if (weth != null) {
            weth.last = 'ETH';

            final recipient = '0x' + callInfo.callParams['recipient'].toString();
            recipients.add(recipient);

            final amountMinimum = Decimal.parse(callInfo.callParams['amountMinimum'].toString());
            weth[weth.length - 2] = (amountMinimum / Decimal.parse('1e18')).toDecimal().toString();
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

  // 0x6207c6a852278b7d032394b9867072df836865503254bd553077bd0967af1d6f
  test('test uniswap v3 mint', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('a4de56c4ca6d5303f29e0d1c53abb51427bfe590'),
        EthereumAddressHash.fromHex('c36442b4a4522e871399cd717abdd847ab11fe88'),
        BigInt.parse('0', radix: 16),
        int.parse('75c43', radix: 16),
        int.parse('165a0bc00', radix: 16),
        int.parse('8', radix: 16),
        input: Uint8List.fromList(hex.decode(
            "88316456000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec700000000000000000000000000000000000000000000000000000000000001f4ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe2000000000000000000000000000000000000000000000000000000000000001e0000000000000000000000000000000000000000000000000000000005e679480000000000000000000000000000000000000000000000000000000006c25b9300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a4de56c4ca6d5303f29e0d1c53abb51427bfe5900000000000000000000000000000000000000000000000000000000060e37edb")));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseMint(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final s = sprintf("Add Liquidity %s and %s", extractArgs(parsed.args));
    print(s);
    expect(s, "Add Liquidity 98.990408 USDC and 113.400723 USDT");
  });

  test('test uniswap v3 mint 2', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('d1cb9c1be330cfbc8b87e8d0d8352295ab4e9665'),
        EthereumAddressHash.fromHex('c36442b4a4522e871399cd717abdd847ab11fe88'),
        BigInt.parse('0', radix: 16),
        int.parse('91ede', radix: 16),
        int.parse('6bc5cc480', radix: 16),
        int.parse('27', radix: 16),
        input: Uint8List.fromList(hex.decode(
            "88316456000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec70000000000000000000000000000000000000000000000000000000000000bb8fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffcd3a8fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffce50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002faf08000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002faf080000000000000000000000000d1cb9c1be330cfbc8b87e8d0d8352295ab4e96650000000000000000000000000000000000000000000000000000000060f1591e")));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseMint(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final s = sprintf("Add Liquidity %s and %s", extractArgs(parsed.args));
    print(s);
    expect(s, "Add Liquidity 0 ETH and 50 USDT");
  });

  // 0xea35139adc2c24a13fafc1f50196d29819e530d5e43475d4edf9bc852f304e5c
  test('test uniswap v3 increaseLiquidity', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('9f38af25f2320e8203f0079aa11a07288231fece'),
        EthereumAddressHash.fromHex('c36442b4a4522e871399cd717abdd847ab11fe88'),
        BigInt.parse('0', radix: 16),
        int.parse('5c763', radix: 16),
        int.parse('832156000', radix: 16),
        int.parse('1a', radix: 16),
        input: Uint8List.fromList(hex.decode(
            "219f5d1700000000000000000000000000000000000000000000000000000000000147320000000000000000000000000000000000000000000000001142529a60652714000000000000000000000000000000000000000000000000000000000c49019d000000000000000000000000000000000000000000000000111daf0412b440c8000000000000000000000000000000000000000000000000000000000c3363320000000000000000000000000000000000000000000000000000000060f10a70")));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseIncreaseLiquidity(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final s = sprintf("Add Liquidity %s and %s", extractArgs(parsed.args));
    print(s);
    expect(s, "Add Liquidity ≥1.233334304997916872 MM and ≥204.694322 USDC");
  });

  // 0x64994e45ac19ccefac890e70fc5baf94c17547e2bcd5d9196fa29898371c0400
  test('test uniswap v3 collect', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('a6c6d80734dc5469a8d1cd790653fb3e1f971700'),
        EthereumAddressHash.fromHex('c36442b4a4522e871399cd717abdd847ab11fe88'),
        BigInt.parse('0', radix: 16),
        int.parse('75c43', radix: 16),
        int.parse('165a0bc00', radix: 16),
        int.parse('8', radix: 16),
        input: Uint8List.fromList(hex.decode(
            "fc6f786500000000000000000000000000000000000000000000000000000000000113ac000000000000000000000000a6c6d80734dc5469a8d1cd790653fb3e1f97170000000000000000000000000000000000ffffffffffffffffffffffffffffffff00000000000000000000000000000000ffffffffffffffffffffffffffffffff")));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseCollect(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final s = sprintf("Collect %s and %s", extractArgs(parsed.args));
    print(s);
    expect(s, 'Collect all FNK and all USDT');
  });

  // 0xd7cbd739c24622d7c79aaba1ef0e161a053c7617357fd9e94b8207c07d7cbbb2
  test('test uniswap v3 multicall: decreaseLiquidity -> collect -> unwrapWETH9 -> sweepToken',
      () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('d1cb9c1be330cfbc8b87e8d0d8352295ab4e9665'),
        EthereumAddressHash.fromHex('c36442b4a4522e871399cd717abdd847ab11fe88'),
        BigInt.parse('0', radix: 16),
        int.parse('4c592', radix: 16),
        int.parse('4a817c800', radix: 16),
        int.parse('28', radix: 16),
        input: Uint8List.fromList(hex.decode(
            "ac9650d80000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000022000000000000000000000000000000000000000000000000000000000000002a000000000000000000000000000000000000000000000000000000000000000a40c49ccbe0000000000000000000000000000000000000000000000000000000000014bb6000000000000000000000000000000000000000000000000000005ff270116cd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002faf07f0000000000000000000000000000000000000000000000000000000060f4f14a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000084fc6f78650000000000000000000000000000000000000000000000000000000000014bb6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffff00000000000000000000000000000000ffffffffffffffffffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004449404b7c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1cb9c1be330cfbc8b87e8d0d8352295ab4e9665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000064df2ab5bb000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec70000000000000000000000000000000000000000000000000000000002faf07f000000000000000000000000d1cb9c1be330cfbc8b87e8d0d8352295ab4e966500000000000000000000000000000000000000000000000000000000")));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseMulticall(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final s = sprintf("Remove Liquidity %s and %s", extractArgs(parsed.args));
    print(s);
    expect(s, 'Remove Liquidity ≥0 ETH and ≥49.999999 USDT');
  });

  // 0x550435dfab7d079b90027e07845ef4a0d78a80fa56f8167b91ba49c3906e7225
  test('test uniswap v3 multicall: decreaseLiquidity -> collect', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('d1cb9c1be330cfbc8b87e8d0d8352295ab4e9665'),
        EthereumAddressHash.fromHex('c36442b4a4522e871399cd717abdd847ab11fe88'),
        BigInt.parse('0', radix: 16),
        int.parse('44bbe', radix: 16),
        int.parse('342770c00', radix: 16),
        int.parse('2b', radix: 16),
        input: Uint8List.fromList(hex.decode(
            "ac9650d8000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000000a40c49ccbe0000000000000000000000000000000000000000000000000000000000015af10000000000000000000000000000000000000000000000000000020e3cdff679000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000017d783f0000000000000000000000000000000000000000000000000000000060f4f826000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000084fc6f78650000000000000000000000000000000000000000000000000000000000015af1000000000000000000000000d1cb9c1be330cfbc8b87e8d0d8352295ab4e966500000000000000000000000000000000ffffffffffffffffffffffffffffffff00000000000000000000000000000000ffffffffffffffffffffffffffffffff00000000000000000000000000000000000000000000000000000000")));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseMulticall(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final s = sprintf("Remove Liquidity %s and %s", extractArgs(parsed.args));
    print(s);
    expect(s, 'Remove Liquidity ≥0 WETH and ≥24.999999 USDT');
  });
}
