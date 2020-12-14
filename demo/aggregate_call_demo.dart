import 'package:ethereum_codec/ethereum_codec.dart';
import 'initialize.dart';

void main() async {
  initAbi();
  print(await ETHRpc.instance().aggregateCall([
    ['0xdac17f958d2ee523a2206206994597c13d831ec7', 'name', Map<String, dynamic>(), 'ERC20'],
    ['0xdac17f958d2ee523a2206206994597c13d831ec7', 'symbol', Map<String, dynamic>()],
    ['0xdac17f958d2ee523a2206206994597c13d831ec7', 'decimals', Map<String, dynamic>()]
  ]));
}
