import 'dart:async';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:decimal/decimal.dart';
import 'package:ethereum_codec/ethereum_codec.dart';
import 'package:eth_abi_codec/eth_abi_codec.dart';
import 'package:intl/intl.dart';
import 'package:sprintf/sprintf.dart';
import 'package:test/test.dart';
import 'initialize.dart';

final UINT256MAX =
    Decimal.parse('115792089237316195423570985008687907853269984665640564039457584007913129639935');

class ParsedResult {
  final String? recipient;
  final List<dynamic> args;

  ParsedResult(this.recipient, this.args);
}

Future<ParsedResult> parseMint(ContractCall callInfo, dynamic tx) async {
  final tokenOut = getContractConfigByAddress(tx.to.toString());
  final symbolIn = tokenOut?.symbol.substring(1);

  var decimal = '18';
  if (symbolIn != 'ETH') {
    final tokenIn = getContractConfigBySymbol(symbolIn!);
    decimal = tokenIn?.params?['decimal']?.toString() ?? decimal;
  }

  final mintAmount = callInfo.callParams['mintAmount'];

  Decimal amount;
  if (mintAmount == null) {
    amount = Decimal.parse(tx.value.toString());
  } else {
    amount = Decimal.parse(mintAmount.toString());
  }
  final a = (amount/Decimal.parse('1e' + decimal)).toDecimal().toString();
  return ParsedResult(tx.from.toString(), [a, symbolIn]);
}

Future<ParsedResult> parseBorrow(ContractCall callInfo, dynamic tx) async {
  final tokenOut = getContractConfigByAddress(tx.to.toString());
  final symbolIn = tokenOut?.symbol.substring(1);

  var decimal = '18';
  if (symbolIn != 'ETH') {
    final tokenIn = getContractConfigBySymbol(symbolIn!);
    decimal = tokenIn?.params?['decimal']?.toString() ?? decimal;
  }

  final borrowAmount = callInfo.callParams['borrowAmount'];
  final amount = Decimal.parse(borrowAmount.toString());

  return ParsedResult(tx.from.toString(), [(amount / Decimal.parse('1e' + decimal)).toDecimal().toString(), symbolIn]);
}

Future<ParsedResult> parseRepayBorrow(ContractCall callInfo, dynamic tx) async {
  final tokenOut = getContractConfigByAddress(tx.to.toString());
  final symbolIn = tokenOut?.symbol.substring(1);
  if(tokenOut == null){
    return ParsedResult('error', []);
  }
  var decimal = '18';
  if (symbolIn != 'ETH') {
    final tokenIn = getContractConfigBySymbol(symbolIn!);
    decimal = tokenIn?.params?['decimal']?.toString() ?? decimal;
  }

  final repayAmount = callInfo.callParams['repayAmount'];

  Decimal amount;
  if (repayAmount == null) {
    amount = Decimal.parse(tx.value.toString());
  } else {
    amount = Decimal.parse(repayAmount.toString());
  }

  if (amount >= UINT256MAX) {
    return ParsedResult(tx.from.toString(), ['all', symbolIn]);
  }

  return ParsedResult(tx.from.toString(), [(amount / Decimal.parse('1e' + decimal)).toDecimal().toString(), symbolIn]);
}

Future<ParsedResult> parseRedeem(ContractCall callInfo, dynamic tx) async {
  final recipient = tx.from.toString();
  final tokenOut = getContractConfigByAddress(tx.to.toString());
  final symbolIn = tokenOut?.symbol.substring(1);
  if(tokenOut == null){
    return ParsedResult('error', []);
  }
  final redeemTokens = Decimal.parse(callInfo.callParams['redeemTokens'].toString());

  if (redeemTokens >= UINT256MAX) {
    return ParsedResult(recipient, ['', 'all', symbolIn]);
  }

  var exchangeRateStored;
  try {
    final res = (await ETHRpc.instance()?.ethCall(tx.to.toString(), 'exchangeRateStored', {}));
    final rate = res?.values.first;
    exchangeRateStored = Decimal.parse(rate.toString());
  } catch (e) {
    return ParsedResult(recipient, []);
  }

  var decimal = 18;
  if (symbolIn != 'ETH') {
    final tokenIn = getContractConfigBySymbol(symbolIn!);
    final d = tokenIn?.params?['decimal']?.toString() ?? '18';
    decimal = int.parse(d);
  }

  final Decimal amount = (exchangeRateStored / Decimal.parse('1e18')) *
      redeemTokens /
      Decimal.parse('1e' + decimal.toString());

  NumberFormat formatter = NumberFormat();
  formatter.minimumFractionDigits = 0;
  formatter.maximumFractionDigits = decimal;
  final amountStr = formatter.format(amount.toDouble());

  return ParsedResult(recipient, ['≈', amountStr, symbolIn]);
}

Future<ParsedResult> parseRedeemUnderlying(ContractCall callInfo, dynamic tx) async {
  final tokenOut = getContractConfigByAddress(tx.to.toString());
  final symbolIn = tokenOut?.symbol.substring(1);
  if(tokenOut == null){
    return ParsedResult('error', []);
  }
  var decimal = '18';
  if (symbolIn != 'ETH') {
    final tokenIn = getContractConfigBySymbol(symbolIn!);
    decimal = tokenIn?.params?['decimal']?.toString() ?? decimal;
  }

  final redeemAmount = callInfo.callParams['redeemAmount'];
  final amount = Decimal.parse(redeemAmount.toString());

  if (amount >= UINT256MAX) {
    return ParsedResult(tx.from.toString(), ['all', symbolIn]);
  }

  return ParsedResult(tx.from.toString(), [(amount / Decimal.parse('1e' + decimal)).toDecimal().toString(), symbolIn]);
}

Future<ParsedResult> parseTransfer(ContractCall callInfo, dynamic tx) async {
  final token = getContractConfigByAddress(tx.to.toString());

  final dst = callInfo.callParams['dst'].toString();
  final amount = Decimal.parse(callInfo.callParams['amount'].toString());
  final decimal = token?.params?['decimal'].toString() ?? '';

  return ParsedResult(
      dst, [(amount / Decimal.parse('1e' + decimal)).toDecimal().toString(), token?.symbol, toChecksumAddress(dst)]);
}

Future<ParsedResult> parseApprove(ContractCall callInfo, dynamic tx) async {
  final token = getContractConfigByAddress(tx.to.toString());

  final amount = Decimal.parse(callInfo.callParams['amount'].toString());
  final decimal = token?.params?['decimal'].toString() ??'';

  final spender = getContractConfigByAddress(callInfo.callParams['spender'].toString());
  return ParsedResult(spender?.symbol, [
    toChecksumAddress(callInfo.callParams['spender'].toString()),
    token?.symbol,
    (amount / Decimal.parse('1e' + decimal)).toDecimal().toString()
  ]);
}

Future<ParsedResult> parseEnterMarkets(ContractCall callInfo, dynamic tx) async {
  final cTokenAddresses = callInfo.callParams['cTokens'].map((a) => a.toString()).toList();
  List<dynamic> cTokens = cTokenAddresses.map((addr) => getContractConfigByAddress(addr)).toList();
  final tokenSymbols = cTokens.map((t) => t.symbol.substring(1)).toList();

  return ParsedResult(tx.from.toString(), [tokenSymbols.join(',')]);
}

Future<ParsedResult> parseClaimComp(ContractCall callInfo, dynamic tx) async {
  final holder = callInfo.callParams['holder'].toString();

  return ParsedResult(tx.from.toString(), [toChecksumAddress(holder)]);
}

Future<ParsedResult> parseExitMarket(ContractCall callInfo, dynamic tx) async {
  final cTokenAddresses = [callInfo.callParams['cTokenAddress'].toString()];
  List<dynamic> cTokens = cTokenAddresses.map((addr) => getContractConfigByAddress(addr)).toList();
  final tokenSymbols = cTokens.map((t) => t.symbol.substring(1)).toList();

  return ParsedResult(tx.from.toString(), [tokenSymbols.join(',')]);
}

void main() async {
  initAbi();

  // 0xee1b56b590efe0bc1a86893e53c76ec32e11af9fa3b1dabfcec7c5ff90489e2e
  test('test compound mint cETH', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('80163501977fa19aab6570f66012afd5212a5282'),
        EthereumAddressHash.fromHex('4ddc2d193948926d02f9b1fe9e1daa0718270ed5'),
        BigInt.parse('c72813502107fb', radix: 16),
        int.parse('28f61', radix: 16),
        int.parse('4190ab000', radix: 16),
        int.parse('9', radix: 16),
        input: Uint8List.fromList(hex.decode("1249c58b")));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseMint(callInfo, tx);

    final s = sprintf("Supply %s %s to Compound", parsed.args);
    print(s);
    expect(s, "Supply 0.056057583779252219 ETH to Compound");
  });

  // 0xd2633505807f2f16a3b2b6e33498a2ced9fd31de9435c94f79b937798be463ac
  test('test compound mint cUSDT', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('1bfcb9c1ca25f87e8d6409fc9af7aedc01a0b8ec'),
        EthereumAddressHash.fromHex('f650c3d88d12db855b8bf7d11be6c55a4e07dcc9'),
        BigInt.parse('0', radix: 16),
        int.parse('3d0be', radix: 16),
        int.parse('4b4038a00', radix: 16),
        int.parse('1c', radix: 16),
        input:
            Uint8List.fromList(hex.decode("a0712d6800000000000000000000000000000000000000000000000000000001637c00ca")));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseMint(callInfo, tx);

    final s = sprintf("Supply %s %s to Compound", parsed.args);
    print(s);
    expect(s, "Supply 5964.038346 USDT to Compound");
  });

  // 0x9ae2f773150f749aba981aa296baf083f8c0d79ec6d28c52c929395e7a511f72
  test('test compound mint cCOMP', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('241e1aac00ef9b5f8f22a9bd63c8e6b05bc709ba'),
        EthereumAddressHash.fromHex('70e36f6bf80a52b3b46b3af8e106cc0ed743e8e4'),
        BigInt.parse('0', radix: 16),
        int.parse('38a54', radix: 16),
        int.parse('131794b400', radix: 16),
        int.parse('70', radix: 16),
        input:
            Uint8List.fromList(hex.decode("a0712d680000000000000000000000000000000000000000000000012631eb45d8e624ab")));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseMint(callInfo, tx);

    final s = sprintf("Supply %s %s to Compound", parsed.args);
    print(s);
    expect(s, "Supply 21.198983606233867435 COMP to Compound");
  });

  // 0xcbe50032497b49ef56fee3490abb3678d846968d7753944b7f29313987704600
  test('test compound borrow cETH', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('e16ea27a69c63bcf73959497d142b19813da0ec8'),
        EthereumAddressHash.fromHex('4ddc2d193948926d02f9b1fe9e1daa0718270ed5'),
        BigInt.parse('0', radix: 16),
        int.parse('67084', radix: 16),
        int.parse('35458af00', radix: 16),
        int.parse('60', radix: 16),
        input:
            Uint8List.fromList(hex.decode("c5ebeaec00000000000000000000000000000000000000000000000000b1a2bc2ec50000")));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseBorrow(callInfo, tx);

    final s = sprintf("Borrow %s %s from Compound", parsed.args);
    print(s);
    expect(s, "Borrow 0.05 ETH from Compound");
  });

  // 0x93cacb39c668fe49127055d99273fc21b799ff1f7ed4fd80f0233bd58bb82d66
  test('test compound borrow cUSDT', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('4c44ea0ad64a44c2311ec74dd15e05e80481fb13'),
        EthereumAddressHash.fromHex('f650c3d88d12db855b8bf7d11be6c55a4e07dcc9'),
        BigInt.parse('0', radix: 16),
        int.parse('5ad34', radix: 16),
        int.parse('4a817c800', radix: 16),
        int.parse('153', radix: 16),
        input:
            Uint8List.fromList(hex.decode("c5ebeaec000000000000000000000000000000000000000000000000000000012a05f200")));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseBorrow(callInfo, tx);

    final s = sprintf("Borrow %s %s from Compound", parsed.args);
    print(s);
    expect(s, "Borrow 5000 USDT from Compound");
  });

  // 0xc72ebe4eeb972c4ea28b22c35b715512c8d1f971d1300330cdbb29a621c564f0
  test('test compound repay cETH', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('5b0d50230e6009e8199752867a135a586c53b003'),
        EthereumAddressHash.fromHex('4ddc2d193948926d02f9b1fe9e1daa0718270ed5'),
        BigInt.parse('2c68af0bb140000', radix: 16),
        int.parse('2511d', radix: 16),
        int.parse('342770c00', radix: 16),
        int.parse('1a', radix: 16),
        input: Uint8List.fromList(hex.decode("4e4d9fea")));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseRepayBorrow(callInfo, tx);

    final s = sprintf("Repay %s %s to Compound", parsed.args);
    print(s);
    expect(s, "Repay 0.2 ETH to Compound");
  });

  // 0xdca3f87f42e5401e35cc8f79a42fef014add928fe61c5ad2fc278f1a3b2bf124
  test('test compound repay cUSDT', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('71e73b703ce0c3d3cb3cf4c6df53b4ef01e49e9b'),
        EthereumAddressHash.fromHex('f650c3d88d12db855b8bf7d11be6c55a4e07dcc9'),
        BigInt.parse('0', radix: 16),
        int.parse('33c34', radix: 16),
        int.parse('4fbc54646', radix: 16),
        int.parse('126', radix: 16),
        input:
            Uint8List.fromList(hex.decode("0e75270200000000000000000000000000000000000000000000000000000000e12f28ab")));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseRepayBorrow(callInfo, tx);

    final s = sprintf("Repay %s %s to Compound", parsed.args);
    print(s);
    expect(s, "Repay 3777.964203 USDT to Compound");
  });

  // 0x11853bdb8fc3499014b60d58198848dc8366700b289baada9e26f88d1730dd49
  test('test compound repay cCOMP', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('9645c7802344a641eb8d33c5577d6c167d61ec82'),
        EthereumAddressHash.fromHex('70e36f6bf80a52b3b46b3af8e106cc0ed743e8e4'),
        BigInt.parse('0', radix: 16),
        int.parse('33c34', radix: 16),
        int.parse('4fbc54646', radix: 16),
        int.parse('126', radix: 16),
        input:
            Uint8List.fromList(hex.decode("0e752702ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff")));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseRepayBorrow(callInfo, tx);

    final s = sprintf("Repay %s %s to Compound", parsed.args);
    print(s);
    expect(s, "Repay all COMP to Compound");
  });

  // 0xf3a37592e801f29121956e1878c2364bbb617961080cf594185a44138a6fa27f
  test('test compound redeem cUSDT', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('37cbf7bac049f668347fe91283b2abef0f4da38d'),
        EthereumAddressHash.fromHex('f650c3d88d12db855b8bf7d11be6c55a4e07dcc9'),
        BigInt.parse('0', radix: 16),
        int.parse('38a54', radix: 16),
        int.parse('41314cf00', radix: 16),
        int.parse('b8', radix: 16),
        input:
            Uint8List.fromList(hex.decode("db006a75000000000000000000000000000000000000000000000000000000a02a0d4814")));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseRedeem(callInfo, tx);

    final s = sprintf("Withdraw %s%s %s from Compound", parsed.args);
    print(s);
  });

  // 0xd947b40d20885b8d9d7c39570c7a655220fcf443bad4837362bb692c89fe9139
  test('test compound redeem cETH', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('d628c79a538452949d0eb0e6dff6834b91055b4b'),
        EthereumAddressHash.fromHex('4ddc2d193948926d02f9b1fe9e1daa0718270ed5'),
        BigInt.parse('0', radix: 16),
        int.parse('55f14', radix: 16),
        int.parse('342770c00', radix: 16),
        int.parse('225', radix: 16),
        input:
            Uint8List.fromList(hex.decode("db006a75000000000000000000000000000000000000000000000000000000001dbc088a")));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseRedeem(callInfo, tx);

    final s = sprintf("Withdraw %s%s %s from Compound", parsed.args);
    print(s);
  });

  // 0xfa2368177f8c829093571d8e224261786090910ed0d9f34a19d75949396bd163
  test('test compound redeem cSAI', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('6cbf891ec109e6e9e1893dd33f145719540cd834'),
        EthereumAddressHash.fromHex('f5dce57282a584d2746faf1593d3121fcac444dc'),
        BigInt.parse('0', radix: 16),
        int.parse('7d014', radix: 16),
        int.parse('737be7600', radix: 16),
        int.parse('8', radix: 16),
        input:
            Uint8List.fromList(hex.decode("db006a750000000000000000000000000000000000000000000000000000025722ceece0")));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseRedeem(callInfo, tx);

    final s = sprintf("Withdraw %s%s %s from Compound", parsed.args);
    print(s);
  });

  // 0xc15d8c4255ceef970a02c500a8332e04c7ef7599ccde2b03aacc01003242b1cc
  test('test compound redeemUnderlying cETH', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('a9e69d7573d20c629c1f2e27c1f2b4f414339535'),
        EthereumAddressHash.fromHex('4ddc2d193948926d02f9b1fe9e1daa0718270ed5'),
        BigInt.parse('0', radix: 16),
        int.parse('44da4', radix: 16),
        int.parse('2cb417800', radix: 16),
        int.parse('34', radix: 16),
        input:
            Uint8List.fromList(hex.decode("852a12e30000000000000000000000000000000000000000000000001904506451e633ed")));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseRedeemUnderlying(callInfo, tx);

    final s = sprintf("Withdraw %s %s from Compound", parsed.args);
    print(s);
    expect(s, "Withdraw 1.802654142656033773 ETH from Compound");
  });

  // 0x0a5dd0c1b96f6f561fe0eb712fb690df5d659f0bae8113e1330170237a23eb11
  test('test compound redeemUnderlying cUSDT', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('b463d9b48d0f32b5a4bf206359e01bd3d9e3e805'),
        EthereumAddressHash.fromHex('f650c3d88d12db855b8bf7d11be6c55a4e07dcc9'),
        BigInt.parse('0', radix: 16),
        int.parse('3337e', radix: 16),
        int.parse('3b9aca000', radix: 16),
        int.parse('8', radix: 16),
        input:
            Uint8List.fromList(hex.decode("852a12e30000000000000000000000000000000000000000000000000000000053724e00")));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseRedeemUnderlying(callInfo, tx);

    final s = sprintf("Withdraw %s %s from Compound", parsed.args);
    print(s);
    expect(s, "Withdraw 1400 USDT from Compound");
  });

  // 0xb0bb9f1793d7f8374b8cc2912319c1ceed0a0c2e2bc8bc129ce3ed6934046d60
  test('test compound transfer cZRX', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('706c7ab545d33c3bfcca5634cf1a1e4e3e402f4f'),
        EthereumAddressHash.fromHex('b3319f5d18bc0d84dd1b4825dcde5d5f7266d407'),
        BigInt.parse('0', radix: 16),
        int.parse('37051', radix: 16),
        int.parse('312c80400', radix: 16),
        int.parse('1a', radix: 16),
        input: Uint8List.fromList(hex.decode(
            "a9059cbb0000000000000000000000006094f978eeba9b7ff2f9713efdec1d252ca6ed1a0000000000000000000000000000000000000000000000000000008d0ff2579d")));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseTransfer(callInfo, tx);

    final s = sprintf("Transfer %s %s to %s", parsed.args);
    print(s);
    expect(s, "Transfer 6058.57929117 cZRX to 0x6094f978EebA9b7fF2f9713eFDEc1D252Ca6ed1a");
  });

  // 0x67312eeb67fe6a8be6b9eb9425de84d2d36f9f7c1396d2a86eba2787c5bceb95
  test('test compound approve cZRX', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('cd062483e6aa9a5375dd2d74d20021b254003e29'),
        EthereumAddressHash.fromHex('b3319f5d18bc0d84dd1b4825dcde5d5f7266d407'),
        BigInt.parse('0', radix: 16),
        int.parse('b548', radix: 16),
        int.parse('45a9b5b00', radix: 16),
        int.parse('a2', radix: 16),
        input: Uint8List.fromList(hex.decode(
            "095ea7b3000000000000000000000000e66b31678d6c16e9ebf358268a790b763c133750ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff")));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseApprove(callInfo, tx);

    final s = parsed.recipient == null
        ? sprintf("ERC20 approve unknown contract %s", parsed.args)
        : sprintf("Approve %s to use %s", [parsed.recipient, parsed.args[1]]);
    print(s);
    expect(s, "ERC20 approve unknown contract 0xe66B31678d6C16E9ebf358268a790B763C133750");
  });

  test('test compound approve cZRX 2', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('cd062483e6aa9a5375dd2d74d20021b254003e29'),
        EthereumAddressHash.fromHex('b3319f5d18bc0d84dd1b4825dcde5d5f7266d407'),
        BigInt.parse('0', radix: 16),
        int.parse('b548', radix: 16),
        int.parse('45a9b5b00', radix: 16),
        int.parse('a2', radix: 16),
        input: Uint8List.fromList(hex.decode(
            "095ea7b30000000000000000000000007a250d5630B4cF539739dF2C5dAcb4c659F2488Dffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff")));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseApprove(callInfo, tx);

    final s = parsed.recipient == null
        ? sprintf("ERC20 approve unknown contract %s", parsed.args)
        : sprintf("Approve %s to use %s", [parsed.recipient, parsed.args[1]]);
    print(s);
    expect(s, "Approve Uniswap V2 to use cZRX");
  });

  // 0x955c281b5b59db32963d2547fe37d0ea519cfee89fbafdd25f054aa211c4a597
  test('test compound enterMarkets', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('489d6a379bcf7c232e4fbf8038ee34d97bdbbd7d'),
        EthereumAddressHash.fromHex('3d9819210a31b4961b30ef54be2aed79b9c9cd3b'),
        BigInt.parse('0', radix: 16),
        int.parse('1dca4', radix: 16),
        int.parse('36c31cd28', radix: 16),
        int.parse('a2', radix: 16),
        input: Uint8List.fromList(hex.decode(
            "c2998238000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000004ddc2d193948926d02f9b1fe9e1daa0718270ed5")));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseEnterMarkets(callInfo, tx);

    final s = sprintf("Enable %s as collateral", parsed.args);
    print(s);
    expect(s, "Enable ETH as collateral");
  });

  // 0x2c0b4ae572bb7170f98b383cd8c0597e0c60a07b6863d8d074926976f0e105f2
  test('test compound claimComp', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('9da6ca884f24dc29b320cc9075d769909a55a544'),
        EthereumAddressHash.fromHex('3d9819210a31b4961b30ef54be2aed79b9c9cd3b'),
        BigInt.parse('0', radix: 16),
        int.parse('16e360', radix: 16),
        int.parse('91494c600', radix: 16),
        int.parse('546', radix: 16),
        input:
            Uint8List.fromList(hex.decode("e9af02920000000000000000000000009da6ca884f24dc29b320cc9075d769909a55a544")));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseClaimComp(callInfo, tx);

    final s = sprintf("Claim COMP to %s", parsed.args);
    print(s);
    // expect(s, "Enable ETH as collateral");
  });

  test('test compound exitMarket', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('d66d41209d7674c8d954c30066cf86cc0ea67862'),
        EthereumAddressHash.fromHex('3d9819210a31b4961b30ef54be2aed79b9c9cd3b'),
        BigInt.parse('0', radix: 16),
        int.parse('29ff4', radix: 16),
        int.parse('826299e00', radix: 16),
        int.parse('5', radix: 16),
        input:
            Uint8List.fromList(hex.decode("ede4edd00000000000000000000000005d3a536e4d6dbd6114cc1ead35777bab948e3643")));

    final contract = tx.getContractInfo();
    final callInfo =
        ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseExitMarket(callInfo, tx);

    final s = sprintf("Disable %s as collateral", parsed.args);
    print(s);
    expect(s, "Disable DAI as collateral");
  });
}
