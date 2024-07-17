// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "hardhat/console.sol";
import "./interfaces/IERC20.sol";
import "./libraries/SafeERC20.sol";
import "./interfaces/IUniswapV3Pool.sol";
import "./libraries/PoolAddress.sol";
import "./interfaces/ISwapRouter02.sol";

contract TriArbFlashloan {
    using SafeERC20 for IERC20;

    address public FACTORY;
    ISwapRouter02 public ROUTER;

    constructor(address _factory, address _swapRouter) {
        FACTORY = _factory;
        ROUTER = ISwapRouter02(_swapRouter);
    }

    uint256 private constant MAX_INT =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    struct FlashCallbackData {
        uint256 amount0;
        uint256 amount1;
        address caller;
        address tokenA;
        address tokenB;
        address tokenC;
        uint24 feeA;
        uint24 feeB;
        uint24 feeC;
        address myAddress;
    }

    // Check profitability of triangular arbitrage
    function checkProfitability(
        uint256 _input,
        uint256 _output
    ) private pure returns (bool) {
        return _output > _input;
    }

    IERC20 token0;
    IERC20 private token1;
    IUniswapV3Pool private pool;

    // Swaps tokens -> Triangular Arbitrage
    function swapExactInputMultiHop(
        uint256 _amountIn,
        address _token1,
        address _token2,
        address _token3,
        uint24 _fee1,
        uint24 _fee2,
        uint24 _fee3
    ) public returns (uint256) {
        IERC20(_token1).safeApprove(address(ROUTER), MAX_INT);
        IERC20(_token2).safeApprove(address(ROUTER), MAX_INT);
        IERC20(_token3).safeApprove(address(ROUTER), MAX_INT);

        bytes memory path = abi.encodePacked(
            _token1,
            _fee1,
            _token2,
            _fee2,
            _token3,
            _fee3,
            _token1
        );

        ISwapRouter02.ExactInputParams memory params = ISwapRouter02
            .ExactInputParams({
                path: path,
                recipient: address(this),
                amountIn: _amountIn,
                amountOutMinimum: 0 // used for testing, change it for real world use
            });

        uint256 out = ROUTER.exactInput(params);

        return out;
    }

    // Main function of this contract to start flashloan in Uniswap V3
    function initFlashLoanPool(
        address _token0,
        address _token1,
        uint24 _fee,
        uint256 amount0,
        uint256 amount1,
        address tokenA,
        address tokenB,
        address tokenC,
        uint24 feeA,
        uint24 feeB,
        uint24 feeC
    ) external {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);

        pool = IUniswapV3Pool(getPool(_token0, _token1, _fee));

        flash(amount0, amount1, tokenA, tokenB, tokenC, feeA, feeB, feeC);
    }

    // Finds Pool Address
    function getPool(
        address _token0,
        address _token1,
        uint24 _fee
    ) private view returns (address) {
        PoolAddress.PoolKey memory poolKey = PoolAddress.getPoolKey(
            _token0,
            _token1,
            _fee
        );

        return PoolAddress.computeAddress(FACTORY, poolKey);
    }

    // Starts flashloan in Uniswap V3
    function flash(
        uint256 amount0,
        uint256 amount1,
        address tokenA,
        address tokenB,
        address tokenC,
        uint24 feeA,
        uint24 feeB,
        uint24 feeC
    ) private {
        bytes memory data = abi.encode(
            FlashCallbackData({
                amount0: amount0,
                amount1: amount1,
                caller: address(this),
                tokenA: tokenA,
                tokenB: tokenB,
                tokenC: tokenC,
                feeA: feeA,
                feeB: feeB,
                feeC: feeC,
                myAddress: msg.sender
            })
        );

        // When flash is called it looks for functio uniswapV3FlashCallback
        // https://docs.uniswap.org/contracts/v3/guides/flash-integrations/inheritance-constructors
        pool.flash(address(this), amount0, amount1, data);
    }

    // Makes triangular arbitrage then pays back the loan
    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external {
        FlashCallbackData memory decoded = abi.decode(
            data,
            (FlashCallbackData)
        );

        // Triangular Arbitrage
        uint256 amoutOutArbitrage = swapExactInputMultiHop(
            decoded.amount0,
            decoded.tokenA,
            decoded.tokenB,
            decoded.tokenC,
            decoded.feeA,
            decoded.feeB,
            decoded.feeC
        );

        uint256 amountToRepay0 = decoded.amount0 + fee0;
        uint256 amountToRepay1 = decoded.amount1 + fee1;

        // Checks profit
        bool profCheck = checkProfitability(amountToRepay0, amoutOutArbitrage);
        require(profCheck, "Arbitrage not profitable");

        uint256 myProfit = amoutOutArbitrage - amountToRepay0;

        // Pay profit to myself
        IERC20 otherToken = IERC20(token0);
        otherToken.safeTransfer(decoded.myAddress, myProfit);

        // Pays back loan + fees
        if (fee0 > 0) {
            IERC20(token0).safeTransfer(address(pool), amountToRepay0);
        }
        if (fee1 > 0) {
            IERC20(token1).safeTransfer(address(pool), amountToRepay1);
        }
    }

    // Check balance of token in this contract
    function tokenBalance(
        address tokenAddress
    ) external view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }
}
