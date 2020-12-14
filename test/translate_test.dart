import 'package:ethereum_codec/ethereum_codec.dart';
import 'package:test/test.dart';
import 'initialize.dart';

void main() async {
  initAbi();

  var runTrans = (String tag, String trxHash, String expected) {
    test(tag, () async{
      var trxJson = await ETHRpc.instance().getTransactionByHash(trxHash);
      var trx = EthereumTransaction.fromJson(trxJson);
      expect(await trx.getDescription(), expected);
    });
  };

  
  runTrans('test ETH transfer',
    '0x6a87019b97c81356af1e249db5f02d280635667d7092a9be2725ae302592bb3a',
    'Transfer 0.0986045 ETH to 0xA8...98Fd');

  runTrans('test ERC20 approve ulimited',
    '0x493aadbfe79cd624ac05fa36e7ae224f57ec44327ea5cdbc11448a263428d599',
    'Approve 0x7a...488D use all aDAI');

  runTrans('test UNISWAP swapETHForExactTokens',
    '0x71665eec814d811c0dfc9488566bc7dbde73616f6f3ea2e1b81b1626f0f0011d',
    'swap 0.00167330 ETH for 1.0000 DAI to 0xA8...98Fd');

  runTrans('test UNISWAP swapExactTokensForTokens',
    '0x413d85b2040c4fad56b87fc1b4984f8fa0b32499e388cc0c7b669f8fe85de115',
    'swap 0.0915967 aDAI for 0.000158257 WETH to 0xA8...98Fd');

  runTrans('test UNISWAP swapTokensForExactTokens',
    '0x13bfa9ac16cfc403ae9f73edc1c2beb4fbca580aaf3af9f24c14d0981896f1ab',
    'swap 274.53 USDT for 20.00 MS to 0x67...8c90'
    );

  runTrans('test UNISWAP swapExactETHForTokens',
    '0xdfb2cc7617702f845d642475a50fa5c782eba814824165490eab3c660a14ed36',
    'swap 0.0100000 ETH for 0.000319010 WBTC to 0xA8...98Fd');

  runTrans('test UNISWAP swapExactTokensForETH', 
    '0x43389c13577235582077487cda4bb7e6298b3829dc93f22dff4dab354575900c',
    'swap 0.306831 OMG for 0.00212369 ETH to 0xA8...98Fd');

  runTrans('test UNISWAP swapTokensForExactETH', 
    '0x38b74bcf5fe007ee0216dbe07a128f17d03dd6e4a713ca02560f5ec25f6f69f6',
    'swap 1432.76 METRIC for 1.0000 ETH to 0x11...e3A1');

  runTrans('test UNISWAP swapExactTokensForTokensSupportingFeeOnTransferTokens', 
    '0xa50074da01a8f954b3361e4086578eb8cd5ab13a6e35238bc7860db76f9ed242',
    'swap 2.0000 WETH for 4727.43 EPAN to 0x0D...8588');

  runTrans('test UNISWAP swapExactTokensForETHSupportingFeeOnTransferTokens', 
    '0xad8c2f1f46dced87f07447e22078c93ac7e957eb6a9e12ee9bf3cea96de5a68a',
    'swap 22.95 ITS for 0.736715 ETH to 0x0F...6edb');

  runTrans('test UNISWAP addLiquidityETH',
    '0xee42575e7a9eecacf1b907f4b0ffba6c38141a187d3ba6845ee5ef6e6765fa24',
    'add 1.0436 ETH and 573199.08 COL to 0x98...5795');

  runTrans('test UNISWAP addLiquidity',
    '0x69a3519796c50877f540dc6862612d250d552c93d4dbf93192eef081893f0f5c',
    'add 33.00 USDT and 1127.71 GENE to 0x68...3DA5');

  runTrans('test UNISWAP removeLiquidityETH',
    '0x0d3d92fb63682e990fc16cea1f86eb3a34bc498fbc5ebde5819d0df3c921a68b',
    'remove 0.291435 ETH and 900.47 FREE from pool to 0xaB...2aa1');

  runTrans('test UNISWAP removeLiquidity', 
    '0x20f7d1a128f7d5a260caa63dfea2490f37f15989442297f9728f6b3e9ff1c04b',
    'remove 178.59 SUSHI, 0.666932 WETH from pool to 0x38...C279');

  runTrans('test WRAP deposit', 
    '0xc2836ce091c45c48cf003e35c399547dee09b488f74415dc9b861a90e048efa8',
    'wrap 0.0100000 ETH into 0.0100000 WETH');

  runTrans('test WRAP approve', 
    '0xec7b10b3f4d920b5eb6118bd43eae43fb5ee8eaeb44dded1a15afc5f6219aa3a',
    'Approve 0xB8...07D8 use all WETH');

  runTrans('test WRAP withdraw', 
    '0x308213372b94b61b3c6a79e748f71a5a4b95248cad8685273ef5d41a3be96223',
    'unwrap 0.0100000 WETH into 0.0100000 ETH');
  
  runTrans('test aUSDT redeem',
    '0x0a0760035919a01faa045dd4606a2e9ab1161f88ac4e3b5f6b21456d4c37cd60',
    'redeem all aUSDT');

  runTrans('test AAVE deposit',
    '0xd3b2298a57e8bdea73068c26e8c3ecdf1a89366670e979ca8a0baea243c89e7b',
    'deposit 0.100000 USDT for 0x62...c1f0');

  runTrans('test AAVE withdraw',
    '0x68da725d8ef5a6130227e850b540f816183b199eedd5cb6305489c36b2e9a708',
    'withdraw 0.100000 USDC to 0x62...c1f0');

  runTrans('test AAVE withdraw all', 
    '0x5a858c2c546e6d7a3bedb8a9f2533aeb79239bd334d0bdd1ae63999022b083e9',
    'withdraw all DAI to 0xCb...4BA4');

  runTrans('test AAVE repay', 
    '0x2ab96124afbeb6ffb945c792fd3025ac9a36e9faa32be23af8e1ee58dbbc8652',
    'repay 363.00 USDT for 0xde...f915');

  runTrans('test AAVE repay all',
    '0xab9ade1496b30dc97f5faa991e25cbec6741077223fa03e1f340639598707edb',
    'repay all USDC for 0x50...A068');

  runTrans('test AAVE borrow',
    '0x07fcf4893db394c7b3ca1ba3f39f94f05356fbe8a930e8aebc7691320a8789e8',
    'borrow 4000.00 USDC for 0xD8...f48C');

  runTrans('test AAVE setUserUseReserveAsCollateral enable',
    '0x56be381339ed4b09348ad212c91af306b7fa34d48f44cdcb6b41fe6b26c99030',
    'enable LINK as collateral');

  runTrans('test AAVE setUserUseReserveAsCollateral disable',
    '0x0809adba8d5c836a2e1a04826ca0efacf6a2bcd3607a6bfd5e0e41ae0c222c43',
    'disable LINK as collateral');

  runTrans('test CURVEFIYSWAP exchange_underlying',
    '0x5bcc98a8020db0c842e6fbff84fa7ab11c355a20d6c0e3b1e07114ae543f401f',
    'sell 23737.46 USDT for 23496.16 TUSD');

  runTrans('test CURVEFIYSWAP add_liquidity',
    '0x7d66d1962929a5e64299fffa7d5c38a922a00cf28336232f56623af9d31f2b1d',
    'add 354.01 DAI, 0.00000 USDC, 0.00000 USDT, 0.00000 TUSD to y Swap');

  runTrans('test CURVEFIDAIPOOL exchange',
    '0xa122e98efaf7ad723a1e4e3d4ac5f2aa7f6d0ba070e4755e97eedb1f820128a9',
    'sell 21400.00 USDC for 21185.47 USDT');

  runTrans('test CURVEFIDAI add_liquidity',
    '0x6d4ded20f944d54ba5a23b5ad2c99d37e64848bb8cdddcc0a9fcc89b4e3a1d56',
      'add 0.00000 DAI, 0.00000 USDC, 20000.00 USDT to DAI/USDC/USDT pool');

  runTrans('test CURVEFIDAI remove_liquidity_one_coin',
    '0x00b404788fe0d7f94cc44e3999172f8da8be3185871b8f53096e26d57e894ecf',
    'remove 530.55 USDT from DAI/USDC/USDT pool');

  runTrans('test CURVEFIDAIGAUGE withdraw',
    '0x4a60e0d192b6ea8cd4d48d372a181bb332910b33880acc82d8a3a3e8874d0099',
    'withdraw 6460332.94 3Crv from DAI/USDC/USDT Gauge');

  runTrans('test CURVEFIDAIGAUGE deposit',
    '0xfd0b7a6c494600ac6963a47199773a54aed3cd9824e07511472c5b01c8a0ee2b',
    'deposit 125.39 3Crv to DAI/USDC/USDT Gauge');

  runTrans('test CURVEFIUSDNPOOL add_liquidity',
    '0x6366016af4c5e015741d9813bb3ad85a60e398c496f354ffe7125bece6d0cc3b',
    'add 46.56 USDN, 1357.48 3Crv to USDN pool');

  runTrans('test CURVEFIUSDNPOOL exchange_underlying',
    '0x55b97aa0e15f402e8754f29a4e7d63432f0fa088507778e5d4ed54f638248f27',
    'sell 1.0000 USDN for 0.984393 USDC');

  runTrans('test CURVEFIUSDNPOOL remove_liquidity_imbalance',
    '0xbaf342b0ed175cb324215f0bb873b1f200a99f22d9130e88a2a30e80574ac480',
    'remove 0.0100221 USDN/3Crv for 0.0100000 USDN, 0.00000 3Crv');

  runTrans('test CURVEFIUSDNPOOL remove_liquidity_one_coin',
    '0x8dfb902f009760e841ec0238d98dfde9027949bc834a8c40a1b3fd910ff9a668',
    'withdraw 30057.98 3Crv from USDN pool');

  runTrans('test CURVEFIUSDNDEPOSIT add_liquidity',
    '0x3ed48d4bdceaed731ae17876867b2a9e02118bb6e87aa9ee37dc24cb7bea7e43',
    'add 10.00 USDN, 0.00000 DAI, 0.00000 USDC, 100.00 USDT to USDN deposit pool for 108.51 USDN/3Crv');

  runTrans('test CURVEFIUSDNDEPOSIT remove_liquidity_one_coin',
    '0xf3ae9ec3c4512ed11fd936c6dacd34c2e09396aadf8e514e061edbcbb824201f',
    'withdraw 21955.15 USDN from USDN deposit pool');

  runTrans('test CURVEFIUSDNDEPOSIT remove_liquidity',
    '0x6c3178ca773cb27784529e1394507fb1e9ec8a0ee1857c11bc53d5f9d2c06a7a',
    'pay 1012.86 USDN/3Crv to remove at least 0.00124904 USDN, 0.000127935 DAI, 0.000308000 USDC, 0.000254000 USDT from USDN deposit pool');
}