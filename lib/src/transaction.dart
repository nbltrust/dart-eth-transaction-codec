library ethereum_codec.transaction;

import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:eth_abi_codec/eth_abi_codec.dart';
import 'package:pointycastle/src/utils.dart' as pointy;
import 'package:pointycastle/digests/sha3.dart';
import 'package:ethereum_util/src/rlp.dart' as eth_rlp;
import './checksum_address.dart' as cks_addr;
import './contracts.dart';

class EthereumAddressHash {
  final Uint8List data;
  static const int size = 20;

  /// Fully specified constructor used by JSON deserializer.
  EthereumAddressHash(this.data) {
    if (data.length != size) throw FormatException();
  }
  EthereumAddressHash.fromHex(String hexStr):
    data = hex.decode(hexStr);

  String toJson() => '0x' + hex.encode(data);
  String toString() => toJson();
  String toChecksumAddress() =>
    cks_addr.toChecksumAddress(toJson());
}

class EthereumTransactionId {
  final Uint8List data;
  static const int size = 32;

  /// Fully specified constructor used by JSON deserializer.
  EthereumTransactionId(this.data) {
    if (data.length != size) throw FormatException();
  }

  /// Computes the hash of [transaction] - not implemented.
  EthereumTransactionId.compute(Uint8List rlpEncodedTransaction)
      : data = SHA3Digest(256, true).process(rlpEncodedTransaction);

  /// Marshals [EthereumTransactionId] as a hex string.
  @override
  String toString() => hex.encode(data);

  String toJson() => '0x' + hex.encode(data);
}

class EthereumTransaction {
  /// Address of the sender.
  EthereumAddressHash from;
  /// Address of the receiver. null when its a contract creation transaction.
  EthereumAddressHash to;
  BigInt value;
  int gas;
  int gasPrice;
  int nonce;
  Uint8List input;
  int sigV;
  Uint8List sigR;
  Uint8List sigS;
  int chainId;

  EthereumTransaction(
      this.from, this.to, this.value, this.gas, this.gasPrice, this.nonce,
      {this.input, this.sigR, this.sigS, this.sigV, this.chainId = 1});

  /// Unmarshals a RLP-encoded Uint8List to [EthereumTransaction].
  factory EthereumTransaction.fromRlp(Uint8List rlp) {
    List<dynamic> t = eth_rlp.decode(rlp);
    if (t.length != 9) throw FormatException('Invalid length ${t.length}');
    int sigV = pointy.decodeBigInt(t[6]).toInt();
    return EthereumTransaction(
        null,
        EthereumAddressHash(t[3]),
        pointy.decodeBigInt(t[4]),
        pointy.decodeBigInt(t[2]).toInt(),
        pointy.decodeBigInt(t[1]).toInt(),
        pointy.decodeBigInt(t[0]).toInt(),
        input: t[5],
        sigV: sigV,
        sigR: t[7],
        sigS: t[8],
        chainId: sigV);
  }

  Uint8List toRlp({bool withSignature = true}) {
    return ((sigV != chainId * 2 + 35) &&
            (sigV != chainId * 2 + 36) &&
            withSignature == false)
        ? eth_rlp.encode(<dynamic>[nonce, gasPrice, gas, to.data, value, input])
        : eth_rlp.encode(<dynamic>[
            nonce,
            gasPrice,
            gas,
            to.data,
            value,
            input,
            withSignature ? sigV : chainId,
            withSignature ? sigR : Uint8List(0),
            withSignature ? sigS : Uint8List(0)
          ]);
  }

  Uint8List hashToSign() {
    return SHA3Digest(256, true).process(
      eth_rlp.encode(<dynamic>[nonce, gasPrice, gas, to.data, value, input, chainId, Uint8List(0), Uint8List(0)])
    );
  }

  /// Returns a dict
  /// ```json
  /// {
  ///   "name": "contract name",
  ///   "type": "contract type",
  ///   "method": "contract method",
  ///   "params": [
  ///     {
  ///       "name": "param name",
  ///       "value": "param value"
  ///     }
  ///   ]
  /// }
  /// ```
  /// if transaction does not contain a contract call, return null
  /// if contract call target address can not be recognized, throw exception
  Map<String, dynamic> getContractInfo() {
    var contractCfg = getContractConfigByAddress(to.toString());

    if(contractCfg == null) {
      if(input.length == 0) {
        return null;
      } else {
        throw "unknown contract call to address ${to.toString()}";
      }
    }
  
    var abi = getContractABIByType(contractCfg.type);
    var call_info = ContractCall.fromBinary(input, abi);
    return {
      'name': contractCfg.symbol,
      'type': contractCfg.type,
      'contract_params': contractCfg.params,
      'method': call_info.functionName,
      'params': call_info.callParams
    };
  }
}