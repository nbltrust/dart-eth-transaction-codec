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

Future<ParsedResult> parseAddLiquidityETH(ContractCall callInfo, dynamic tx) async {
  final params = callInfo.callParams;
  final recipient = '0x' + params['to'].toString();

  final tokenAddr = params['token'].toString();
  final token = getContractConfigByAddress(tokenAddr);
  if (token == null) {
    return ParsedResult(recipient, []);
  }

  final amountMin = Decimal.parse(params['amountTokenMin'].toString());
  final valueDecimal = Decimal.parse(tx.value.toString());

  final args = [
    ['≥', (amountMin / Decimal.parse('1e' + token.params?['decimal'])).toDecimal().toString(), token.symbol],
    ['≤', valueDecimal / Decimal.parse('1e18'), 'ETH'],
  ];

  return ParsedResult(recipient, ['addLiquidity', args[0], args[1]]);
}

Future<ParsedResult> parseRemoveLiquidityETH(ContractCall callInfo, dynamic tx) async {
  final params = callInfo.callParams;
  final recipient = '0x' + params['to'].toString();

  final tokenAddr = params['token'].toString();
  final token = getContractConfigByAddress(tokenAddr);

  if (token == null) {
    return ParsedResult(recipient, []);
  }

  final amountMin = Decimal.parse(params['amountTokenMin'].toString());
  final valueDecimal = Decimal.parse(params['amountETHMin'].toString());

  final args = [
    ['≥', (amountMin / Decimal.parse('1e' + token.params?['decimal'])).toDecimal().toString(), token.symbol],
    ['≥', valueDecimal / Decimal.parse('1e18'), 'ETH'],
  ];

  return ParsedResult(recipient, ['removeLiquidity', args[0], args[1]]);
}

Future<ParsedResult> parseAddLiquidity(ContractCall callInfo, dynamic tx) async {
  final params = callInfo.callParams;
  final recipient = '0x' + params['to'].toString();

  final token0Addr = params['tokenA'].toString();
  final token1Addr = params['tokenB'].toString();
  final token0 = getContractConfigByAddress(token0Addr);
  final token1 = getContractConfigByAddress(token1Addr);

  if (token0 == null || token1 == null) {
    return ParsedResult(recipient, []);
  }

  final amount0Min = Decimal.parse(params['amountAMin'].toString());
  final amount1Min = Decimal.parse(params['amountBMin'].toString());

  final args = [
    ['≥', (amount0Min / Decimal.parse('1e' + token0.params?['decimal'])).toDecimal().toString(), token0.symbol],
    ['≥', (amount1Min / Decimal.parse('1e' + token1.params?['decimal'])).toDecimal().toString(), token1.symbol],
  ];

  return ParsedResult(recipient, ['addLiquidity', args[0], args[1]]);
}

Future<ParsedResult> parseRemoveLiquidity(ContractCall callInfo, dynamic tx) async {
  final params = callInfo.callParams;
  final recipient = '0x' + params['to'].toString();

  final token0Addr = params['tokenA'].toString();
  final token1Addr = params['tokenB'].toString();
  final token0 = getContractConfigByAddress(token0Addr);
  final token1 = getContractConfigByAddress(token1Addr);

  if (token0 == null || token1 == null) {
    return ParsedResult(recipient, []);
  }

  final amount0Min = Decimal.parse(params['amountAMin'].toString());
  final amount1Min = Decimal.parse(params['amountBMin'].toString());

  final args = [
    ['≥', (amount0Min / Decimal.parse('1e' + token0.params?['decimal'])).toDecimal().toString(), token0.symbol],
    ['≥', (amount1Min / Decimal.parse('1e' + token1.params?['decimal'])).toDecimal().toString(), token1.symbol],
  ];

  return ParsedResult(recipient, ['removeLiquidity', args[0], args[1]]);
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

  // 0x49e46f90ba774c5bae43f2bafd2cb3a9e0522ff3c3c9fa600c17a5c9c5c6caac
  test('test addLiquidityETH', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('90560b4ee0633f7d39d4426b7d5ab276a5b2ef9b'),
        EthereumAddressHash.fromHex('d9e1ce17f2641f24ae83637ab66a2cca9c378b9f'),
        BigInt.parse('cb9d0b3ffc8c5e6', radix: 16),
        int.parse('3bcdf', radix: 16),
        int.parse('182ccec97f', radix: 16),
        int.parse('5b', radix: 16),
        input: Uint8List.fromList(hex.decode(
            "f305d7190000000000000000000000002e9d63788249371f1dfc918a52f8d799f4a38c94000000000000000000000000000000000000000000000004ea93e2035aaddc3e000000000000000000000000000000000000000000000004e448e748751b122e0000000000000000000000000000000000000000000000000ca986b31962a63000000000000000000000000090560b4ee0633f7d39d4426b7d5ab276a5b2ef9b000000000000000000000000000000000000000000000000000000006125fe9d")));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});
    print("---------------------- $contract");
    final parsed = await parseAddLiquidityETH(callInfo, tx);
    print("---------------------- ${parsed.recipient} ${parsed.args} ${tx.from.toString()}");
    expect(parsed.recipient, tx.from.toString());

    final s = sprintf("Add Liquidity %s and %s", extractArgs(parsed.args));
    print(s);
    expect(s, "Add Liquidity ≥90.23662823219731307 TOKE and ≤0.916993470655677926 ETH");
  });

  // 0xd2bbbe23282eb90aa1c4b9b159da2c2a5cd9a39020db9fd4705312d7c4d81fa8
  test('test addLiquidity', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('d5198f31c6206e5fcad59ebea38d6425539fd24d'),
        EthereumAddressHash.fromHex('d9e1ce17f2641f24ae83637ab66a2cca9c378b9f'),
        BigInt.parse('0', radix: 16),
        int.parse('36ade', radix: 16),
        int.parse('12a05f2000', radix: 16),
        int.parse('a2', radix: 16),
        input: Uint8List.fromList(hex.decode(
            "e8e33700000000000000000000000000f88b137cfa667065955abd17525e89edcf4d6426000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000000000000000000000000771159e9eca6308ef1900000000000000000000000000000000000000000000000000000002cf55db4d0000000000000000000000000000000000000000000007678f1c8c139d6b730500000000000000000000000000000000000000000000000000000002cbbd1b7c000000000000000000000000d5198f31c6206e5fcad59ebea38d6425539fd24d000000000000000000000000000000000000000000000000000000006125fd4a")));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseAddLiquidity(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final s = sprintf("Add Liquidity %s and %s", extractArgs(parsed.args));
    print(s);
    expect(s, "Add Liquidity ≥34966.892290942245237509 ITG and ≥12008.10278 USDC");
  });

  // 0xc68bbd01c8dacf0748b993d6da892a207011df0be19ff33e1f169a90077a92fe
  test('test removeLiquidityETHWithPermit', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('6fbe6eab3053fef0da871807346b0b40e989840f'),
        EthereumAddressHash.fromHex('d9e1ce17f2641f24ae83637ab66a2cca9c378b9f'),
        BigInt.parse('0', radix: 16),
        int.parse('5b129', radix: 16),
        int.parse('f9982de00', radix: 16),
        int.parse('13e0', radix: 16),
        input: Uint8List.fromList(hex.decode(
            "ded9382a000000000000000000000000c7a8b45e184138114e6085c82936a8db93dd156a0000000000000000000000000000000000000000000000002d4441a44dc3b3420000000000000000000000000000000000000000000000003012eb5406b43a480000000000000000000000000000000000000000000000002b4fc36ed31691a60000000000000000000000006fbe6eab3053fef0da871807346b0b40e989840f00000000000000000000000000000000000000000000000000000000612606ad0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001b23704074473f9afe7a9f06163c7a71dfc1b7b09c040702407c6cff92319da98266e42f502aa10282d0d2ef1bce8d0fd4da509890e5c938398615cb63a2793ca7")));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseRemoveLiquidityETH(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final s = sprintf("Remove Liquidity %s and %s", extractArgs(parsed.args));
    print(s);
    expect(s, "Remove Liquidity ≥3.464089809523587656 MASK and ≥3.120927947546333606 ETH");
  });

  // 0xe5f2bb9a34d2dfb1cd8c24e04071ee3a05d28de8708cee2a583528f6bbdb62fd
  test('test removeLiquidityWithPermit', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('2c7f8156a82c4a8040dbdcd96ba025b25ddbf9fa'),
        EthereumAddressHash.fromHex('d9e1ce17f2641f24ae83637ab66a2cca9c378b9f'),
        BigInt.parse('0', radix: 16),
        int.parse('6a314', radix: 16),
        int.parse('102a15e34b', radix: 16),
        int.parse('5e', radix: 16),
        input: Uint8List.fromList(hex.decode(
            "2195995c0000000000000000000000002260fac5e5542a773aa44fbcfedf7c193bc2c5990000000000000000000000003472a5a71965499acd81997a54bba8d852c6e53d00000000000000000000000000000000000000000000000000009f1a48963f6e000000000000000000000000000000000000000000000000000000000259636b00000000000000000000000000000000000000000000002f6794ae3f323695eb0000000000000000000000002c7f8156a82c4a8040dbdcd96ba025b25ddbf9fa00000000000000000000000000000000000000000000000000000000612606f50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001b0a66ba0eedc79cab8139d624c6786bdfea9e8a00674f266df86563d89a5ec1f055614bc85293191a3b950537131ce98ea01cad0c02388d6631de6ed2f4377dff")));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseRemoveLiquidity(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final s = sprintf("Remove Liquidity %s and %s", extractArgs(parsed.args));
    print(s);
    expect(s, "Remove Liquidity ≥0.39412587 WBTC and ≥874.460753533257291243 BADGER");
  });
}
