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

Future<ContractConfig> getTokenInfo(String addr, [allowUnsafe = false]) async {
  var token = getContractConfigByAddress(addr);
  if (token != null) {
    return token;
  }

  if (!allowUnsafe) {
    return null;
  }

  try {
    final props = await ETHRpc.instance().getERC20Config(addr);
    return new ContractConfig(addr, props[1], 'ERC20', {'decimal': props[2].toString()});
  } catch (e) {
    return null;
  }
}

Future<String> getCoinAddr(String contractAddr, dynamic index) async {
  final rpc = ETHRpc.instance();

  try {
    final result = await rpc.ethCall(contractAddr, 'underlying_coins', {'arg0': index});
    return result['out'];
  } catch (e) {
    //
  }

  final result = await rpc.ethCall(contractAddr, 'coins', {'arg0': index});
  return result['out'];
}

Future<ParsedResult> parseAddLiquidity(ContractCall callInfo, dynamic tx) async {
  final contractAddr = tx.to.toString();
  final recipient = tx.from.toString();
  final params = callInfo.callParams;

  final amounts = params['amounts'];
  final indexs = [];
  for (var i = 0; i < amounts.length; i++) {
    if (amounts[i] > BigInt.zero) {
      indexs.add(i);
    }
  }

  final tokenAddrs = await Future.wait(indexs.map((index) => getCoinAddr(contractAddr, index)));
  final tokens = await Future.wait(tokenAddrs.map((addr) => getTokenInfo(addr, true)));

  final args = tokens.asMap().entries.map((e) {
    final token = e.value;
    final amount = amounts[indexs[e.key]];
    return [Decimal.parse(amount.toString()) / Decimal.parse('1e' + token.params['decimal']), token.symbol];
  }).toList();

  List<dynamic> result = ['addLiquidity'];
  result.addAll(args);

  return ParsedResult(recipient, result);
}

Future<ParsedResult> parseRemoveLiquidity(ContractCall callInfo, dynamic tx) async {
  final params = callInfo.callParams;
  final contractAddr = tx.to.toString();

  var recipient = params['receiver']?.toString() ?? tx.from.toString();
  recipient = recipient.startsWith('0x') ? recipient : ('0x' + recipient);

  final amounts = params['min_amounts'];
  final indexs = [];
  for (var i = 0; i < amounts.length; i++) {
    if (amounts[i] > BigInt.zero) {
      indexs.add(i);
    }
  }

  final tokenAddrs = await Future.wait(indexs.map((index) => getCoinAddr(contractAddr, index)));
  final tokens = await Future.wait(tokenAddrs.map((addr) => getTokenInfo(addr, true)));

  final args = tokens.asMap().entries.map((e) {
    final token = e.value;
    final amount = amounts[indexs[e.key]];
    return ['≥', Decimal.parse(amount.toString()) / Decimal.parse('1e' + token.params['decimal']), token.symbol];
  }).toList();

  List<dynamic> result = ['removeLiquidity'];
  result.addAll(args);

  return ParsedResult(recipient, result);
}

Future<ParsedResult> parseRemoveLiquidityImbalance(ContractCall callInfo, dynamic tx) async {
  final params = callInfo.callParams;
  final contractAddr = tx.to.toString();

  var recipient = params['receiver']?.toString() ?? tx.from.toString();
  recipient = recipient.startsWith('0x') ? recipient : ('0x' + recipient);

  final amounts = params['amounts'];
  final indexs = [];
  for (var i = 0; i < amounts.length; i++) {
    if (amounts[i] > BigInt.zero) {
      indexs.add(i);
    }
  }

  final tokenAddrs = await Future.wait(indexs.map((index) => getCoinAddr(contractAddr, index)));
  final tokens = await Future.wait(tokenAddrs.map((addr) => getTokenInfo(addr, true)));

  final args = tokens.asMap().entries.map((e) {
    final token = e.value;
    final amount = amounts[indexs[e.key]];
    return [Decimal.parse(amount.toString()) / Decimal.parse('1e' + token.params['decimal']), token.symbol];
  }).toList();

  List<dynamic> result = ['removeLiquidity'];
  result.addAll(args);

  return ParsedResult(recipient, result);
}

Future<ParsedResult> parseRemoveLiquidityOneCoin(ContractCall callInfo, dynamic tx) async {
  final params = callInfo.callParams;
  final contractAddr = tx.to.toString();

  var recipient = params['receiver']?.toString() ?? tx.from.toString();
  recipient = recipient.startsWith('0x') ? recipient : ('0x' + recipient);

  final amount = params['min_amount'];
  final index = params['i'];

  final tokenAddr = await getCoinAddr(contractAddr, index);
  final token = await getTokenInfo(tokenAddr, true);

  final args = [
    ['≥', Decimal.parse(amount.toString()) / Decimal.parse('1e' + token.params['decimal']), token.symbol]
  ];

  List<dynamic> result = ['removeLiquidity'];
  result.addAll(args);

  return ParsedResult(recipient, result);
}

Future<ParsedResult> parseExchange(ContractCall callInfo, dynamic tx) async {
  final recipient = tx.from.toString();
  final contractAddr = tx.to.toString();
  final params = callInfo.callParams;

  final amounts = [params['dx'], params['min_dy']];
  final indexs = [params['i'], params['j']];

  final tokenAddrs = await Future.wait(indexs.map((index) => getCoinAddr(contractAddr, index)));
  final tokens = await Future.wait(tokenAddrs.map((addr) => getTokenInfo(addr, true)));

  final args = [
    [Decimal.parse(amounts[0].toString()) / Decimal.parse('1e' + tokens[0].params['decimal']), tokens[0].symbol],
    ['≥', Decimal.parse(amounts[1].toString()) / Decimal.parse('1e' + tokens[1].params['decimal']), tokens[1].symbol]
  ];

  List<dynamic> result = ['swap'];
  result.addAll(args);

  return ParsedResult(recipient, result);
}

Future<ParsedResult> parseExchangeUnderlying(ContractCall callInfo, dynamic tx) async {
  final recipient = tx.from.toString();
  final contractAddr = tx.to.toString();
  final params = callInfo.callParams;

  final amounts = [params['dx'], params['min_dy']];
  final indexs = [params['i'], params['j']];

  final tokenAddrs = await Future.wait(indexs.map((index) => getCoinAddr(contractAddr, index)));
  final tokens = await Future.wait(tokenAddrs.map((addr) => getTokenInfo(addr, true)));

  final args = [
    [Decimal.parse(amounts[0].toString()) / Decimal.parse('1e' + tokens[0].params['decimal']), tokens[0].symbol],
    ['≥', Decimal.parse(amounts[1].toString()) / Decimal.parse('1e' + tokens[1].params['decimal']), tokens[1].symbol]
  ];

  List<dynamic> result = ['swap'];
  result.addAll(args);

  return ParsedResult(recipient, result);
}

Future<ParsedResult> parseWithdraw(ContractCall callInfo, dynamic tx) async {
  final recipient = tx.from.toString();
  final contractAddr = tx.to.toString();
  final params = callInfo.callParams;

  final amount = params['value'];
  final tokenAddr = (await ETHRpc.instance().ethCall(contractAddr, 'lp_token', {})).values.first;
  final token = await getTokenInfo(tokenAddr, true);

  return ParsedResult(recipient, [
    'withdraw',
    [Decimal.parse(amount.toString()) / Decimal.parse('1e' + token.params['decimal']), token.symbol]
  ]);
}

Future<ParsedResult> parseDeposit(ContractCall callInfo, dynamic tx) async {
  final recipient = tx.from.toString();
  final contractAddr = tx.to.toString();
  final params = callInfo.callParams;

  final amount = params['value'];
  final tokenAddr = (await ETHRpc.instance().ethCall(contractAddr, 'lp_token', {})).values.first;
  final token = await getTokenInfo(tokenAddr, true);

  return ParsedResult(recipient, [
    'deposit',
    [Decimal.parse(amount.toString()) / Decimal.parse('1e' + token.params['decimal']), token.symbol]
  ]);
}

Future<ParsedResult> parseClaimRewards(ContractCall callInfo, dynamic tx) async {
  final params = callInfo.callParams;

  var recipient = params['addr']?.toString() ?? tx.from.toString();
  recipient = recipient.startsWith('0x') ? recipient : ('0x' + recipient);

  return ParsedResult(recipient, ['claim']);
}

List<dynamic> extractArgs(List<dynamic> args) {
  try {
    return args.skip(1).map((arg) {
      if (arg.length < 3) {
        return sprintf("%s %s", arg);
      } else {
        return sprintf("%s%s %s", arg);
      }
    }).toList();
  } catch (e) {
    print(e);
    return [];
  }
}

void main() async {
  initAbi();

  // 0x6da326c2e077652c689befd579cf0a2d7f421c89f363a444096c98a3474dc935
  test('test addLiquidity sETH', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('a4b72881d99502dbced3021e1df604604a7a141e'),
        EthereumAddressHash.fromHex('c5424b857f758e906013f3555dad202e4bdb4567'),
        BigInt.parse('4c53ecdc18a60000', radix: 16),
        int.parse('146f6e', radix: 16),
        int.parse('1229c05369', radix: 16),
        int.parse('2a', radix: 16),
        input: hex.decode(
            "0b4c7e4d0000000000000000000000000000000000000000000000004c53ecdc18a6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004b0f65b038aac568"));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract['method'], 'params': contract['params']});

    final parsed = await parseAddLiquidity(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final args = extractArgs(parsed.args);
    final argStr = args.length > 1 ? [args.sublist(0, args.length - 1).join(', '), args.last].join(' and ') : args.join('');
    final s = sprintf("Supply %s", [argStr]);
    print(s);
    // expect(s, "Supply 500 USDT");
  });

  // 0x2b8b6d083fc57dbeb19e59f4573c7fca2f38b067312b971f82a82a31b4790c9d
  test('test removeLiquidity sETH', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('a4b72881d99502dbced3021e1df604604a7a141e'),
        EthereumAddressHash.fromHex('c5424b857f758e906013f3555dad202e4bdb4567'),
        BigInt.parse('0', radix: 16),
        int.parse('146f6e', radix: 16),
        int.parse('1229c05369', radix: 16),
        int.parse('2a', radix: 16),
        input: hex.decode(
            "1a4d01d2000000000000000000000000000000000000000000000002275ff731470dfe2b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000229a86a3fe8e26513"));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract['method'], 'params': contract['params']});

    final parsed = await parseRemoveLiquidityOneCoin(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final args = extractArgs(parsed.args);
    final argStr = args.length > 1 ? [args.sublist(0, args.length - 1).join(', '), args.last].join(' and ') : args.join('');
    final s = sprintf("Withdraw %s", [argStr]);
    print(s);
    // expect(s, "Supply 500 USDT");
  });

  // 0xfbda4101e7c4bf598ff48d983feb3ae66c51e109866b2f21b26b20386b1bd577
  test('test addLiquidity USDT', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('684dc924470d0ee0fde2761ea9b5a4d0df13ad5f'),
        EthereumAddressHash.fromHex('b6c057591e073249f2d9d88ba59a46cfc9b59edb'),
        BigInt.parse('0', radix: 16),
        int.parse('146f6e', radix: 16),
        int.parse('1229c05369', radix: 16),
        int.parse('2a', radix: 16),
        input: hex.decode(
            "029b2f3400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001dcd65000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000017f4e935a01f344ef2"));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract['method'], 'params': contract['params']});

    final parsed = await parseAddLiquidity(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final args = extractArgs(parsed.args);
    final argStr = args.length > 1 ? [args.sublist(0, args.length - 1).join(', '), args.last].join(' and ') : args.join('');
    final s = sprintf("Supply %s", [argStr]);
    print(s);
    expect(s, "Supply 500 USDT");
  });

  // 0xf9a9842501b0ca4a1b96670c2ab92dfb7efc4cc123b38dabb64292da28c9c125
  test('test addLiquidity BUSD', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('39e6506b31525d11905b2b34ff26b64579d4c402'),
        EthereumAddressHash.fromHex('b6c057591e073249f2d9d88ba59a46cfc9b59edb'),
        BigInt.parse('0', radix: 16),
        int.parse('1433cc', radix: 16),
        int.parse('3b8c6e6991', radix: 16),
        int.parse('9', radix: 16),
        input: hex.decode(
            "029b2f3400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b7ff8af88168e5cc000000000000000000000000000000000000000000000000a28fc595bfe53b69a253"));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract['method'], 'params': contract['params']});

    final parsed = await parseAddLiquidity(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final args = extractArgs(parsed.args);
    final argStr = args.length > 1 ? [args.sublist(0, args.length - 1).join(', '), args.last].join(' and ') : args.join('');
    final s = sprintf("Supply %s", [argStr]);
    print(s);
    // expect(s, "Supply 868907 BUSD");
  });

  //0xb2250b04571fecbf5bb09c97432a770a96aace27ab1206f05b1af810aa725695
  test('test addLiquidity USDC', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('dd84ce1adcb3a4908db61a1dfa3353c3974c5a2b'),
        EthereumAddressHash.fromHex('eb21209ae4c2c9ff2a86aca31e123764a3b6bc06'),
        BigInt.parse('0', radix: 16),
        int.parse('e5e44', radix: 16),
        int.parse('131794b400', radix: 16),
        int.parse('b7', radix: 16),
        input: hex.decode(
            "0b4c7e4d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a246d4200000000000000000000000000000000000000000000003e235434e50b26a3b23"));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract['method'], 'params': contract['params']});

    final parsed = await parseAddLiquidity(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final args = extractArgs(parsed.args);
    final argStr = args.length > 1 ? [args.sublist(0, args.length - 1).join(', '), args.last].join(' and ') : args.join('');
    final s = sprintf("Supply %s", [argStr]);
    print(s);
    expect(s, "Supply 19902.42 USDC");
  });

  // 0x338c4654afd4262e646c15476e2f2c4e65b137a7bbf65a497e7796dfee9e829c
  test('test addLiquidity DAI&USDC&&USDT&BUSD', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('a5493656b559ac046a302e8efa7c64d5ad4c9302'),
        EthereumAddressHash.fromHex('b6c057591e073249f2d9d88ba59a46cfc9b59edb'),
        BigInt.parse('0', radix: 16),
        int.parse('227959', radix: 16),
        int.parse('844d4c513', radix: 16),
        int.parse('9', radix: 16),
        input: hex.decode(
            "029b2f34000000000000000000000000000000000000000000005385e1db7db3f1e7730400000000000000000000000000000000000000000000000000000101fa244d2b00000000000000000000000000000000000000000000000000000091e416d700000000000000000000000000000000000000000000016574ca1b3ee809d2000000000000000000000000000000000000000000000002d0ee6eaad56a2c495588"));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract['method'], 'params': contract['params']});

    final parsed = await parseAddLiquidity(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final args = extractArgs(parsed.args);
    final argStr = args.length > 1 ? [args.sublist(0, args.length - 1).join(', '), args.last].join(' and ') : args.join('');
    final s = sprintf("Supply %s", [argStr]);
    print(s);
  });

  // 0x9dce87ffa8bd5d8c98ca42e1fdbf94c97929827e2363e12b2af0b758c2eb0c8f
  test('test addLiquidity BUSD 2', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('9fa0e944b45453769e1a9ab9ff88a7f26ac76cb2'),
        EthereumAddressHash.fromHex('79a8c46dea5ada233abaffd40f3a0a2b1e5a4f27'),
        BigInt.parse('0', radix: 16),
        int.parse('e80ae', radix: 16),
        int.parse('46c7cfe00', radix: 16),
        int.parse('14d', radix: 16),
        input: hex.decode(
            "029b2f340000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000023ca9ae4709deb23b6000000000000000000000000000000000000000000000021c3a9ddb09bb564ed48"));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract['method'], 'params': contract['params']});

    final parsed = await parseAddLiquidity(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final args = extractArgs(parsed.args);
    final argStr = args.length > 1 ? [args.sublist(0, args.length - 1).join(', '), args.last].join(' and ') : args.join('');
    final s = sprintf("Supply %s", [argStr]);
    print(s);
    // expect(s, "Supply 169020.230372927 BUSD");
  });

  // 0x0702712b287b9d5cd1ca2aec8bbe9d9b68cf42bdffaf2d234d13f2e6b8b33cda
  test('test removeLiquidity', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('b4b19962880c7934d0d2899eb4cd48776668ca1b'),
        EthereumAddressHash.fromHex('b6c057591e073249f2d9d88ba59a46cfc9b59edb'),
        BigInt.parse('0', radix: 16),
        int.parse('2a31f7', radix: 16),
        int.parse('550e250ef', radix: 16),
        int.parse('2ae', radix: 16),
        input: hex.decode(
            "7d49d875000000000000000000000000000000000000000000010455a486bcc8665614d20000000000000000000000000000000000000000000038bc6875e64ef03e04fd00000000000000000000000000000000000000000000000000000056d335ef1400000000000000000000000000000000000000000000000000000049096827800000000000000000000000000000000000000000000053912a9796611890b8aa"));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract['method'], 'params': contract['params']});

    final parsed = await parseRemoveLiquidity(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final args = extractArgs(parsed.args);
    final argStr = args.length > 1 ? [args.sublist(0, args.length - 1).join(', '), args.last].join(' and ') : args.join('');
    final s = sprintf("Withdraw %s", [argStr]);
    print(s);
  });

  // 0x02022c08c03aed4434b44cef09e640816306942dc89e4085a568c3c570eb62c5
  test('test removeLiquidity 2', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('12c2febc4f4b34320b4af07ce03b926eb31944d1'),
        EthereumAddressHash.fromHex('eb21209ae4c2c9ff2a86aca31e123764a3b6bc06'),
        BigInt.parse('0', radix: 16),
        int.parse('e2310', radix: 16),
        int.parse('1fc3628580', radix: 16),
        int.parse('35', radix: 16),
        input: hex.decode(
            "5b36389c00000000000000000000000000000000000000000000c4a240715f99ddf661d600000000000000000000000000000000000000000000347a750864c391ef7da8000000000000000000000000000000000000000000000000000000abedd36214"));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract['method'], 'params': contract['params']});

    final parsed = await parseRemoveLiquidity(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final args = extractArgs(parsed.args);
    final argStr = args.length > 1 ? [args.sublist(0, args.length - 1).join(', '), args.last].join(' and ') : args.join('');
    final s = sprintf("Withdraw %s", [argStr]);
    print(s);
    expect(s, "Withdraw ≥247821.992987307497455016 DAI and ≥738429.461012 USDC");
  });

  test('test removeLiquidity 3', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('b4b19962880c7934d0d2899eb4cd48776668ca1b'),
        EthereumAddressHash.fromHex('b6c057591e073249f2d9d88ba59a46cfc9b59edb'),
        BigInt.parse('0', radix: 16),
        int.parse('2a31f7', radix: 16),
        int.parse('550e250ef', radix: 16),
        int.parse('2ae', radix: 16),
        input: hex.decode(
            "7d49d875000000000000000000000000000000000000000000010455a486bcc8665614d20000000000000000000000000000000000000000000038bc6875e64ef03e04fd00000000000000000000000000000000000000000000000000000056d335ef1400000000000000000000000000000000000000000000000000000049096827800000000000000000000000000000000000000000000053912a9796611890b8aa"));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract['method'], 'params': contract['params']});

    final parsed = await parseRemoveLiquidity(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final args = extractArgs(parsed.args);
    final argStr = args.length > 1 ? [args.sublist(0, args.length - 1).join(', '), args.last].join(' and ') : args.join('');
    final s = sprintf("Withdraw %s", [argStr]);
    print(s);
  });

  // 0x2e92c7638b574bdb4c666b72ebbfd48986df627dfeaf63457f139b5aa0a05a41
  test('test remove_liquidity_imbalance', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('ba5b4e56b4793714507320e88e3fe7f7e56ed9a0'),
        EthereumAddressHash.fromHex('b6c057591e073249f2d9d88ba59a46cfc9b59edb'),
        BigInt.parse('0', radix: 16),
        int.parse('13c284', radix: 16),
        int.parse('a57fe2c86', radix: 16),
        int.parse('4f', radix: 16),
        input: hex.decode(
            "18a7bd76000000000000000000000000000000000000000000000001158e460913d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f8733bbf08bcc9a0"));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract['method'], 'params': contract['params']});

    final parsed = await parseRemoveLiquidityImbalance(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final args = extractArgs(parsed.args);
    final argStr = args.length > 1 ? [args.sublist(0, args.length - 1).join(', '), args.last].join(' and ') : args.join('');
    final s = sprintf("Withdraw %s", [argStr]);
    print(s);
  });

  // 0xddd2781b9a39e771c1855690f1e3e75234de92da8ea8e2a9b38951874b7cc1a8
  test('test remove_liquidity_one_coin', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('26c60b38fe7e55d699c8102c18cc5d7152e0762e'),
        EthereumAddressHash.fromHex('b6c057591e073249f2d9d88ba59a46cfc9b59edb'),
        BigInt.parse('0', radix: 16),
        int.parse('1a2ecd', radix: 16),
        int.parse('16a32602cb', radix: 16),
        int.parse('a', radix: 16),
        input: hex.decode(
            "517a55a300000000000000000000000000000000000000000000481637e078a078075ec30000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000588e15ecff0000000000000000000000000000000000000000000000000000000000000001"));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract['method'], 'params': contract['params']});

    final parsed = await parseRemoveLiquidityOneCoin(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final args = extractArgs(parsed.args);
    final s = sprintf("Withdraw %s", args);
    print(s);
  });

  // 0xc0a1fbd0618b6cd61d9e6d29d2eaa63d54baeac5e519c1d23c185d809b412f83
  test('test exchange_underlying', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('f65312bd492729b06ec42589ded755d63193bbf4'),
        EthereumAddressHash.fromHex('79a8c46dea5ada233abaffd40f3a0a2b1e5a4f27'),
        BigInt.parse('0', radix: 16),
        int.parse('f823e', radix: 16),
        int.parse('95f6a8a4b', radix: 16),
        int.parse('231', radix: 16),
        input: hex.decode(
            "a6417ed60000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002540be40000000000000000000000000000000000000000000000021ad6ff48cdbb24d345"));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract['method'], 'params': contract['params']});

    final parsed = await parseExchangeUnderlying(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final s = sprintf("Swap %s for %s", extractArgs(parsed.args));
    print(s);
  });

  // 0x5d11232242543e6540dd782bdeebd60ef8caa7c54bd89e04998c40b145ef17bf
  test('test exchange', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('b0cf98ef1dcae360d0f22d21983acf8008b30ae9'),
        EthereumAddressHash.fromHex('bebc44782c7db0a1a60cb6fe97d0b483032ff1c7'),
        BigInt.parse('0', radix: 16),
        int.parse('75ef2', radix: 16),
        int.parse('28fa6ae00', radix: 16),
        int.parse('12c', radix: 16),
        input: hex.decode(
            "3df021240000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000009896800000000000000000000000000000000000000000000000000000000000970fe0"));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract['method'], 'params': contract['params']});

    final parsed = await parseExchange(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final s = sprintf("Swap %s for %s", extractArgs(parsed.args));
    print(s);
  });

  // 0xeaf15c060ce0eec4fe5346bdf14e01f601715c9bf16f5befa4f1929e5bdef8b1
  test('test withdraw', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('b4246437f8670406d27ff9240e3450d43d34d68c'),
        EthereumAddressHash.fromHex('7ca5b0a2910b33e9759dc7ddb0413949071d7575'),
        BigInt.parse('0', radix: 16),
        int.parse('f4240', radix: 16),
        int.parse('109a44cb7c', radix: 16),
        int.parse('a', radix: 16),
        input: hex.decode("2e1a7d4d000000000000000000000000000000000000000000000a170e6c869e13af7bf3"));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract['method'], 'params': contract['params']});

    final parsed = await parseWithdraw(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final s = sprintf("Withdraw %s", extractArgs(parsed.args));
    print(s);
  });

  // 0x6bfdc32ffb6c008dcaa952a64124f1f98994fcc64ccebebb24e39e47a36ff45f
  test('test deposit', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('5bc6f1bb6766d792a8b9e264a4a1ce6c369615eb'),
        EthereumAddressHash.fromHex('7ca5b0a2910b33e9759dc7ddb0413949071d7575'),
        BigInt.parse('0', radix: 16),
        int.parse('6391c', radix: 16),
        int.parse('e26bb37fd', radix: 16),
        int.parse('762', radix: 16),
        input: hex.decode("b6b55f250000000000000000000000000000000000000000000001d7bdb58df4daaf218b"));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract['method'], 'params': contract['params']});

    final parsed = await parseDeposit(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final s = sprintf("Deposit %s", extractArgs(parsed.args));
    print(s);
  });

  test('test addLiquidity USDT', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('684dc924470d0ee0fde2761ea9b5a4d0df13ad5f'),
        EthereumAddressHash.fromHex('bebc44782c7db0a1a60cb6fe97d0b483032ff1c7'),
        BigInt.parse('0', radix: 16),
        int.parse('146f6e', radix: 16),
        int.parse('1229c05369', radix: 16),
        int.parse('2a', radix: 16),
        input: hex.decode(
            "4515cef30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003d090000000000000000000000000000000000000000000000000035f132ad946ad800"));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract['method'], 'params': contract['params']});

    final parsed = await parseAddLiquidity(callInfo, tx);
    expect(parsed.recipient, tx.from.toString());

    final args = extractArgs(parsed.args);
    final argStr = args.length > 1 ? [args.sublist(0, args.length - 1).join(', '), args.last].join(' and ') : args.join('');
    final s = sprintf("Supply %s", [argStr]);
    print(s);
    // expect(s, "Supply 500 USDT");
  });
}
