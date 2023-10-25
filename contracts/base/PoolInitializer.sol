// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

import './PeripheryImmutableState.sol';
import '../interfaces/IPoolInitializer.sol';

/// @title Creates and initializes V3 Pools
// 这里虽然createAndInitializePoolIfNecessary方法已经被实现了，但这个contract还是声明成了abstract
// 我觉得这里的目的就是为了不让这个合约单独被实例化，只用来被继承，所以凡是只想被继承的合约，都可以声明称abstract
// 这里把WETH9和工厂合约的地址独立写在了PeripheryImmutableState合约中，这也是软件项目有结构层次的写法
abstract contract PoolInitializer is IPoolInitializer, PeripheryImmutableState {
    /// @inheritdoc IPoolInitializer
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        // sqrtPriceX96是自己定义的价格，这个价格定多少都没关系，因为LP只在他们认为合适的价格去提供流动性
        // 所以当swap的时候，只会到有流动性的地方才交易，也就是只有到合适的价格点才会交易
        // 那在这里设置初始价格的目的是什么呢？初始价格是不能为0的，估计会在后面方法中使用
        uint160 sqrtPriceX96
    ) external payable override returns (address pool) {
        require(token0 < token1);
        // 复习一下mapping的原理，是slot的值加上key取hash作为存data的位置
        // 并且，如果没有设置值的话，那么返回的就是value类型的默认值，下面这个的默认值就是address
        pool = IUniswapV3Factory(factory).getPool(token0, token1, fee);

        if (pool == address(0)) {
            pool = IUniswapV3Factory(factory).createPool(token0, token1, fee);
            IUniswapV3Pool(pool).initialize(sqrtPriceX96);
        } else {
            (uint160 sqrtPriceX96Existing, , , , , , ) = IUniswapV3Pool(pool).slot0();
            if (sqrtPriceX96Existing == 0) {
                IUniswapV3Pool(pool).initialize(sqrtPriceX96);
            }
        }
    }
}
