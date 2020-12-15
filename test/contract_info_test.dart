import 'package:ethereum_codec/ethereum_codec.dart';
import 'package:test/test.dart';
import 'initialize.dart';

void main() async {
  initAbi();

  var getContractInfo = (String trxHash) async {
    var trxJson = await ETHRpc.instance().getTransactionByHash(trxHash);
    var trx = EthereumTransaction.fromJson(trxJson);
    return trx.getContractInfo();
  };

  test('test plain eth transfer', () async {
    var info = await getContractInfo('0x6a87019b97c81356af1e249db5f02d280635667d7092a9be2725ae302592bb3a');
    expect(info, {});
  });

  test('test ERC20 approve', () async {
    var info = await getContractInfo('0x493aadbfe79cd624ac05fa36e7ae224f57ec44327ea5cdbc11448a263428d599');
    expect(info['symbol'], 'aDAI');
    expect(info['type'], 'ERC20');
    expect(info['method'], 'approve');
  });

  test('test UNISWAP swapETHForExactTokens', () async {
    var info = await getContractInfo('0x71665eec814d811c0dfc9488566bc7dbde73616f6f3ea2e1b81b1626f0f0011d');
    expect(info['symbol'], 'UNISWAP');
    expect(info['type'], 'UNISWAP');
    expect(info['method'], 'swapETHForExactTokens');
  });

  test('test ERC20 transfer', () async {
    var info = await getContractInfo('0x3dc84ea3a2f2e641d8f0a5a722cbc9fde930e67bcfc1a8d4fa494b7979da79b9');
    expect(info['symbol'], 'USDT');
    expect(info['type'], 'ERC20');
    expect(info['method'], 'transfer');
  });

  test('test unconfigured contract address', () async {
    var info = await getContractInfo('0xd1e55a30e83e1c24387240aa4de8fe98452552451ae7bddf283f7373b7e272de');
    expect(info, null);
  });
}