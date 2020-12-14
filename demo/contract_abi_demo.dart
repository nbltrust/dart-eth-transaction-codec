import 'package:ethereum_codec/ethereum_codec.dart';
import 'initialize.dart';

void main() {
  initAbi();
  var cfg = getContractConfigByAddress('0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D');
  var abi = getContractABIByType(cfg.type);
  abi.abis.forEach((element) {
    print('${element.name}, ${element.methodId}');
  });
}