// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;
pragma abicoder v2;

import 'https://github.com/cryptoalgebra/Algebra/blob/master/src/core/contracts/interfaces/IAlgebraFactory.sol';
import 'https://github.com/cryptoalgebra/Algebra/blob/master/src/core/contracts/interfaces/callback/IAlgebraFlashCallback.sol';
import 'https://github.com/cryptoalgebra/Algebra/blob/master/src/core/contracts/libraries/LowGasSafeMath.sol';
import 'https://github.com/cryptoalgebra/Algebra/blob/master/src/periphery/contracts/base/PeripheryPayments.sol';
import 'https://github.com/cryptoalgebra/Algebra/blob/master/src/periphery/contracts/base/PeripheryImmutableState.sol';
import 'https://github.com/cryptoalgebra/Algebra/blob/master/src/periphery/contracts/libraries/PoolAddress.sol';
import 'https://github.com/cryptoalgebra/Algebra/blob/master/src/periphery/contracts/libraries/CallbackValidation.sol';
import 'https://github.com/cryptoalgebra/Algebra/blob/master/src/periphery/contracts/libraries/TransferHelper.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol';

/// @title Flash contract implementation
/// @notice An example contract using the Algebra flash function
/// @custom:dev-run-script /scripts/deploy_with_ethers.ts
contract Flash is IAlgebraFlashCallback, PeripheryImmutableState, PeripheryPayments {
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;

    address payable owner;

    constructor(
        address _factory,
        address _WMATIC,
        address _poolDeployer
    ) PeripheryImmutableState(
        _factory, 
        _WMATIC, 
        _poolDeployer
        ) {
        owner = payable(msg.sender);
    }

    /// @param fee0 The fee from calling flash for token0
    /// @param fee1 The fee from calling flash for token1
    /// @param data The data needed in the callback passed as FlashCallbackData from `initFlash`
    /// @notice implements the callback called from flash
    /// @dev fails if the flash is not profitable, meaning the amountOut from the flash is less than the amount borrowed
    function algebraFlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external override {
        FlashCallbackData memory decoded = abi.decode(data, (FlashCallbackData));
        //CallbackValidation.verifyCallback(factory, decoded.poolKey);

        require (decoded.initiator == address(this), 'Only this contract can call this contract.');

        address token0 = decoded.token0;
        address token1 = decoded.token1;

// TO DO ADD ARBITRAGE LOGIC

        if (decoded.amount0 > 0) {
            // Requires approval for the wallet, the pool and this contract first.
            pay(token0, address(this), decoded.payer, decoded.amount0);
            uint256 amount0Owed = LowGasSafeMath.add(decoded.amount0, fee0);
            pay(token0, decoded.payer, address(this), amount0Owed);
            TransferHelper.safeApprove(token0, address(this), amount0Owed);
            pay(token0, address(this), msg.sender, amount0Owed);
        }   
        
        if (decoded.amount1 > 0) {
            // Requires approval for the wallet, the pool and this contract first.
            pay(token1, address(this), decoded.payer, decoded.amount1);
            uint256 amount1Owed = LowGasSafeMath.add(decoded.amount1, fee1);
            pay(token1, decoded.payer, address(this), amount1Owed);
            TransferHelper.safeApprove(token1, address(this), amount1Owed);
            pay(token1, address(this), msg.sender, amount1Owed);
        }
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
    _;
    }

    event Fallback(address source, uint256 amount, bytes userData);

    fallback() external payable {  //
        emit Fallback(msg.sender, msg.value, msg.data);
    }

    struct FlashCallbackData {
        address initiator;
        address token0;
        address token1;
        uint256 amount0;
        uint256 amount1;
        address payer;
    }

    // /// @param _factoryAddres the address of the Camelot V3 Factory
    // /// @param _token0 the address of token0 in the pool
    // /// @param _token1 the address of token0 in the pool
    // /// @param _amount0 the amount of token0 to flash loan
    // /// @param _amount1 the amount of token1 to flash loan
    // /// @notice Calls the pools flash function with data needed for the callback in `algebraFlashCallback`
    function initFlash(
        address _factoryAddress,
        address _token0, 
        address _token1,
        uint8 _tokenToBorrow
    ) external {

        // sort the tokens if needed
        //PoolAddress.PoolKey memory poolKey =
        //    PoolAddress.PoolKey({token0: _token0, token1: _token1});

        // Get the address of the associated pool from the factory
        address pool = IAlgebraFactory(_factoryAddress).poolByPair(_token0, _token1);

        // Get half the amount of token0 in the pool so we don't drain it by accident.
        uint256 amount0 = 0;
        uint256 amount1 = 0;
        if (_tokenToBorrow == 0) {
            amount0 = IERC20(_token0).balanceOf(address(pool)) / 2;
        } else {
            amount1 = IERC20(_token0).balanceOf(address(pool)) / 2;
        }   

        // recipient of borrowed amounts
        // amount of token0 requested to borrow
        // amount of token1 requested to borrow
        // need amount 0 and amount1 in callback to pay back pool
        // recipient of flash should be THIS contract
        IAlgebraPool(pool).flash(
            address(this),
            amount0,
            amount1,
            abi.encode(
                FlashCallbackData({
                    initiator: address(this),
                    token0: _token0,
                    token1: _token1,
                    amount0: amount0,
                    amount1: amount1,
                    payer: msg.sender
                })
            )
        );
    }

   function getTokenBalance(address _token) external view onlyOwner returns (uint256 tokenBalance) {
        IERC20 token = IERC20(_token);
        tokenBalance = token.balanceOf(address(this));
    }

    function getTokenAmount(
        address _token, 
        uint256 _amount
    ) external payable onlyOwner {
        TransferHelper.safeTransfer(_token, msg.sender, _amount);
    }

    function sweepToken(address _token) external payable onlyOwner {
        IERC20 token = IERC20(_token);
        TransferHelper.safeTransfer(_token, msg.sender, token.balanceOf(address(this)));
    }

}
