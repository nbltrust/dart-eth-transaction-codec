// import 'dart:convert';
// import 'package:walletconnect/walletconnect.dart';
import 'package:ethereum_codec/ethereum_codec.dart';
import 'initialize.dart';

void main() async {
  initAbi();

  var trxJson = await ETHRpc.instance()?.getTransactionByHash('0x493aadbfe79cd624ac05fa36e7ae224f57ec44327ea5cdbc11448a263428d599');
  if(trxJson == null){
    print("trxJson is null");
  } else {
    var trx = EthereumTransaction.fromJson(trxJson);
    print(await trx.getDescription());
  }

}