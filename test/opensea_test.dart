import 'dart:async';
import 'dart:convert';
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

Future<ContractConfig?> getTokenInfo(String addr, [allowUnsafe = false]) async {
  var token = getContractConfigByAddress(addr);
  if (token != null) {
    return token;
  }

  if (!allowUnsafe) {
    return null;
  }

  try {
    final props = await ETHRpc.instance()?.getERC20Config(addr);
    return new ContractConfig(addr, props?[1], 'ERC20', {'decimal': props?[2].toString()});
  } catch (e) {
    return null;
  }
}

Future<ParsedResult> parseAtomicMatch(ContractCall callInfo, dynamic tx) async {
  final addrs = callInfo.callParams['addrs'];
  final uints = callInfo.callParams['uints'];

  final recipient = '0x' + addrs[1].toString();

  String? type;
  if (tx.from.toString().contains(addrs[1])) {
    type = 'Buy';
  } else if (tx.from.toString().contains(addrs[8])) {
    type = 'Sell';
  }

  if (type == null) {
    return ParsedResult(recipient, []);
  }

  final exchangeTokenAddr = addrs[13].toString();
  final amount = uints[13].toString();

  var symbol = 'ETH';
  var decimal = '18';
  if (exchangeTokenAddr != '0000000000000000000000000000000000000000') {
    final exchangeToken = await getTokenInfo(exchangeTokenAddr, true);
    if(exchangeToken?.symbol != null){
      symbol = exchangeToken!.symbol;
    }
   if(exchangeToken?.params?['decimal'] != null){
     decimal = exchangeToken!.params!['decimal'];
   }

  }

  return ParsedResult(recipient, [
    type,
    (Decimal.parse(amount.toString()) / Decimal.parse('1e' + decimal)).toDecimal().toString(),
    symbol,
  ]);
}

Future<ParsedResult> parseCancelOrder(ContractCall callInfo, dynamic tx) async {
  final addrs = callInfo.callParams['addrs'];
  final recipient = '0x' + addrs[1].toString();

  return ParsedResult(recipient, []);
}

Future<ParsedResult> parseRegisterProxy(ContractCall callInfo, dynamic tx) async {
  return ParsedResult(tx.from.toString(), []);
}

Future<ParsedResult> parseSafeTransferFrom(ContractCall callInfo, dynamic tx) async {
  final recipient = '0x' + callInfo.callParams['to'].toString();

  return ParsedResult(recipient, [recipient]);
}

void main() async {
  initAbi();

  // 0xec3a5d80a85bac965eac73ef4d9348cd46a02a8a3e44c6cede1cfd18d4ea3707
  test('test opensea atomicMatch_buy', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('56340c11d6f522eaaa0043dfe5874ff42a38d178'),
        EthereumAddressHash.fromHex('7be8076f4ea4a4ad08075c2508e481d6c946d12b'),
        BigInt.parse('4db732547630000', radix: 16),
        int.parse('39724', radix: 16),
        int.parse('117108fb09', radix: 16),
        int.parse('69', radix: 16),
        input: Uint8List.fromList(hex.decode('ab834bab0000000000000000000000007be8076f4ea4a4ad08075c2508e481d6c946d12b00000000000000000000000056340c11d6f522eaaa0043dfe5874ff42a38d17800000000000000000000000035bdb91ab447be1b294d876166b5eaf9ca6f57cc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000986aea67c7d6a15036e18678065eb663fc5be883000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007be8076f4ea4a4ad08075c2508e481d6c946d12b00000000000000000000000035bdb91ab447be1b294d876166b5eaf9ca6f57cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000005b3256965e7c3cf26e11fcaf296dfc8807c01073000000000000000000000000986aea67c7d6a15036e18678065eb663fc5be8830000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002ee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004db73254763000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000061add66b000000000000000000000000000000000000000000000000000000000000000032e7f8b66f2ad717cf57c2068f90f156614625d7a991553641e38d9df655844600000000000000000000000000000000000000000000000000000000000002ee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004db73254763000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000061add3ef000000000000000000000000000000000000000000000000000000006292ea5207c02ae793152ab50bd65dbcf93730d23e99c3a31956be8eadb323660b45d5990000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006a0000000000000000000000000000000000000000000000000000000000000074000000000000000000000000000000000000000000000000000000000000007e0000000000000000000000000000000000000000000000000000000000000088000000000000000000000000000000000000000000000000000000000000009200000000000000000000000000000000000000000000000000000000000000940000000000000000000000000000000000000000000000000000000000000001b000000000000000000000000000000000000000000000000000000000000001b061707695203422d4856ae87933aec7e3e1393a5f9ce32700dd1645aee54a88f7a894d0a76e2f0594d4d4feaed0e38fba72e854e5bcec9c0f9dbb29e136e9bae061707695203422d4856ae87933aec7e3e1393a5f9ce32700dd1645aee54a88f7a894d0a76e2f0594d4d4feaed0e38fba72e854e5bcec9c0f9dbb29e136e9bae0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006423b872dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056340c11d6f522eaaa0043dfe5874ff42a38d1780000000000000000000000000000000000000000000000000000000000001ec800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006423b872dd00000000000000000000000035bdb91ab447be1b294d876166b5eaf9ca6f57cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001ec800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006400000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000064000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000')));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseAtomicMatch(callInfo, tx);

    final s = sprintf("%s 1 NFT for %s %s", parsed.args);
    print(s);
    expect(s, "Buy 1 NFT for 0.35 ETH");
  });

  // 0x88f183cfb6e50986c89ff83c935b3e147ca81ee298a76cd3cb39803196e50934
  test('test opensea atomicMatch_sell', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('1b123ba1388281a2974c1607adc6eac54b37e914'),
        EthereumAddressHash.fromHex('7be8076f4ea4a4ad08075c2508e481d6c946d12b'),
        BigInt.parse('0', radix: 16),
        int.parse('4036b', radix: 16),
        int.parse('19a01f1ba8', radix: 16),
        int.parse('3ec', radix: 16),
        input: Uint8List.fromList(hex.decode(
            "ab834bab0000000000000000000000007be8076f4ea4a4ad08075c2508e481d6c946d12b000000000000000000000000314754b51f9c068a8d4ab9807e2505cc9ec56bc100000000000000000000000000000000000000000000000000000000000000000000000000000000000000005b3256965e7c3cf26e11fcaf296dfc8807c01073000000000000000000000000236672ed575e1e479b8e101aeeb920f32361f6f90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000007be8076f4ea4a4ad08075c2508e481d6c946d12b0000000000000000000000001b123ba1388281a2974c1607adc6eac54b37e914000000000000000000000000314754b51f9c068a8d4ab9807e2505cc9ec56bc10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000236672ed575e1e479b8e101aeeb920f32361f6f90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004e20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e6ed27d666800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000061adac2a0000000000000000000000000000000000000000000000000000000061aeedd4bd672f0273f38190932b4d338410bf11e9691cf7f0af4f04ce3ccbdbbc066428000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004e20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e6ed27d666800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000061adda8c0000000000000000000000000000000000000000000000000000000000000000d7043f47bd4fb35a1d0cb329ff1691b4813bef84971dab582e318bfd9e13ce0a0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006a000000000000000000000000000000000000000000000000000000000000007a000000000000000000000000000000000000000000000000000000000000008a000000000000000000000000000000000000000000000000000000000000009a00000000000000000000000000000000000000000000000000000000000000aa00000000000000000000000000000000000000000000000000000000000000ac0000000000000000000000000000000000000000000000000000000000000001b000000000000000000000000000000000000000000000000000000000000001bd0f74031e1a86ffa42b64dd3502d91842cd5ddc69e9d73c954637e6a933cd24647cef67c094c89e40def685aaaa52549b67207a7ab492e88e50005a2f56608bed0f74031e1a86ffa42b64dd3502d91842cd5ddc69e9d73c954637e6a933cd24647cef67c094c89e40def685aaaa52549b67207a7ab492e88e50005a2f56608be000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c4f242432a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000314754b51f9c068a8d4ab9807e2505cc9ec56bc1000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c4f242432a0000000000000000000000001b123ba1388281a2974c1607adc6eac54b37e9140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c400000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c4000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000")));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseAtomicMatch(callInfo, tx);

    final s = sprintf("%s 1 NFT for %s %s", parsed.args);
    print(s);
    expect(s, "Sell 1 NFT for 0.065 WETH");
  });

  // 0x6a801d71b2de0a9f817d89fcfa876606d60074dc6ae5220daafdb7d1d78930a4
  test('test opensea atomicMatch_buy 2', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('10cc08c32744761a78782c3879603abc478487df'),
        EthereumAddressHash.fromHex('7be8076f4ea4a4ad08075c2508e481d6c946d12b'),
        BigInt.parse('0', radix: 16),
        int.parse('4fdc8', radix: 16),
        int.parse('12d8ebbf33', radix: 16),
        int.parse('4', radix: 16),
        input: Uint8List.fromList(hex.decode('ab834bab0000000000000000000000007be8076f4ea4a4ad08075c2508e481d6c946d12b00000000000000000000000010cc08c32744761a78782c3879603abc478487df000000000000000000000000060950d041bf0402b973c8e62793b2b561f8c64a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eb113c5d09bfc3a7b27a75da4432fb3484f90c6a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007be8076f4ea4a4ad08075c2508e481d6c946d12b000000000000000000000000060950d041bf0402b973c8e62793b2b561f8c64a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000005b3256965e7c3cf26e11fcaf296dfc8807c01073000000000000000000000000eb113c5d09bfc3a7b27a75da4432fb3484f90c6a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003e8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000061ade6bf00000000000000000000000000000000000000000000000000000000000000001c0f08776c0478115d3d4a62ad2bed7d38e92e82de5d30012ee122744052784a00000000000000000000000000000000000000000000000000000000000003e8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000061adbb470000000000000000000000000000000000000000000000000000000061b6f6172a0719fcd27aff09df94ccf46ab63d7cf805f6fc86c298e2a2c7ea22b4dc317b0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006a0000000000000000000000000000000000000000000000000000000000000074000000000000000000000000000000000000000000000000000000000000007e0000000000000000000000000000000000000000000000000000000000000088000000000000000000000000000000000000000000000000000000000000009200000000000000000000000000000000000000000000000000000000000000940000000000000000000000000000000000000000000000000000000000000001c000000000000000000000000000000000000000000000000000000000000001cdf57ab6b2b498f873d4165b52d4a56feb9a78865d5289c2a584a742ffa8f203d608dd99b5264313508b81cb6012d521e3f691cb61a19afb501d969d12d0544c3df57ab6b2b498f873d4165b52d4a56feb9a78865d5289c2a584a742ffa8f203d608dd99b5264313508b81cb6012d521e3f691cb61a19afb501d969d12d0544c30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006423b872dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010cc08c32744761a78782c3879603abc478487df000000000000000000000000000000000000000000000000000000000000037d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006423b872dd000000000000000000000000060950d041bf0402b973c8e62793b2b561f8c64a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006400000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000064000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000')));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseAtomicMatch(callInfo, tx);

    final s = sprintf("%s 1 NFT for %s %s", parsed.args);
    print(s);
    expect(s, "Buy 1 NFT for 0 ETH");
  });

  // 0x4a12a3a7c5cab591b29f76ca8b5f8dfbd1a15f75666db294a27ad8153843fa9f
  test('test opensea cancelOrder_', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('fa3788c6eecbb5bdec01556a2454c39d154a69f3'),
        EthereumAddressHash.fromHex('7be8076f4ea4a4ad08075c2508e481d6c946d12b'),
        BigInt.parse('0', radix: 16),
        int.parse('4fdc8', radix: 16),
        int.parse('12d8ebbf33', radix: 16),
        int.parse('4', radix: 16),
        input: Uint8List.fromList(hex.decode('a8a41c700000000000000000000000007be8076f4ea4a4ad08075c2508e481d6c946d12b000000000000000000000000fa3788c6eecbb5bdec01556a2454c39d154a69f300000000000000000000000000000000000000000000000000000000000000000000000000000000000000005b3256965e7c3cf26e11fcaf296dfc8807c010730000000000000000000000009bf252f97891b907f002f2887eff9246e30540800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002ee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000034bc4fdde27c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000061aa4ff200000000000000000000000000000000000000000000000000000000629a331eb1d274841624f2ac43cc4c4b4e3527ade766794cb1054258087c412b63c6aee50000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000034000000000000000000000000000000000000000000000000000000000000003e00000000000000000000000000000000000000000000000000000000000000480000000000000000000000000000000000000000000000000000000000000001b20304bf802ed5a6cfe1ce9bb270f367de021dc26636e2816bec4538d209b88452f35b59fbb63867442ebdf6d1be2c35246b2d0dc8557351cb7381116e0e67000000000000000000000000000000000000000000000000000000000000000006423b872dd000000000000000000000000fa3788c6eecbb5bdec01556a2454c39d154a69f3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010e5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000064000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000')));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseCancelOrder(callInfo, tx);

    final s = sprintf("Cancel listing", parsed.args);
    print(s);
    expect(s, "Cancel listing");
  });

  // 0xea61d8731a663ab1c731af263127963c8c462f7b530f075ed2e5f7e2e56f5f9e
  test('test opensea registerProxy', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('c76ddaad7be40da759fb659272c6115f25c63a7d'),
        EthereumAddressHash.fromHex('a5409ec958c83c3f309868babaca7c86dcb077c1'),
        BigInt.parse('0', radix: 16),
        int.parse('7e313', radix: 16),
        int.parse('1697dbf3a5', radix: 16),
        int.parse('0', radix: 16),
        input: Uint8List.fromList(hex.decode("ddd81f82")));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseRegisterProxy(callInfo, tx);

    final s = sprintf("Mint NFT", parsed.args);
    print(s);
    expect(s, "Mint NFT");
  });

  // 0xbd286a34a717918c4fc0b13e346309f0033f26408afa9f3d577dee023c2d86f0
  test('test opensea safeTransferFrom', () async {
    EthereumTransaction tx = EthereumTransaction(
        EthereumAddressHash.fromHex('47d2797f8e35ed3c8170f59e85cb5f196669af59'),
        EthereumAddressHash.fromHex('495f947276749ce646f68ac8c248420045cb7b5e'),
        BigInt.parse('0', radix: 16),
        int.parse('1fdf2', radix: 16),
        int.parse('1286ffd29e', radix: 16),
        int.parse('0', radix: 16),
        input: Uint8List.fromList(hex.decode('f242432a00000000000000000000000047d2797f8e35ed3c8170f59e85cb5f196669af59000000000000000000000000128f29dbf7b2b2bb218eb139f6a5804aa751154f47d2797f8e35ed3c8170f59e85cb5f196669af59000000000000300000000001000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000')));

    final contract = tx.getContractInfo();
    final callInfo = ContractCall.fromJson({'function': contract?['method'], 'params': contract?['params']});

    final parsed = await parseSafeTransferFrom(callInfo, tx);

    final s = sprintf("Transfer 1 NFT to %s", parsed.args);
    print(s);
    expect(s, "Transfer 1 NFT to 0x128f29dbf7b2b2bb218eb139f6a5804aa751154f");
  });
}
