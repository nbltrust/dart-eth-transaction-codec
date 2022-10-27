import 'package:ethereum_codec/ethereum_codec.dart';
import 'initialize.dart';

void main() {
  initAbi();
  var cfg = getContractConfigByAddress('0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D');
  if(cfg == null){
    print("cfg is null");
    return;
  }
  var abi = getContractABIByType(cfg.type);
  if(abi == null){
    print("cfg is null");
    return;
  }
  abi.abis.forEach((element) {
    print('${element.name}, ${element.methodId}');
  });
}