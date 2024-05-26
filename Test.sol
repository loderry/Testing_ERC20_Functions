// contracts/Test.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol';

contract Test {
    address payable owner;

    constructor()
    {
        owner = payable(msg.sender);
    }

    /**
        Testing basic ERC20 token functions.
     */

    function getTokenBalance(
        address _tokenAddress
    ) external view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    function approveTokenAmount(
        address _tokenAddress,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_tokenAddress).approve(msg.sender, _amount);
    }

    function depositTokenAmount(
        address _tokenAddress, 
        uint256 _amount
    ) external onlyOwner {
      IERC20 token = IERC20(_tokenAddress);
      uint256 allowance = token.allowance(
                                msg.sender,
                                address(this)
      );
      require(allowance >= _amount, 'msg.sender allowance too low.');
      token.transferFrom(
        msg.sender,
        address(this),
        _amount
      );
    }

    function withdrawTokenBalance(
        address _tokenAddress
    ) external onlyOwner {
        IERC20(_tokenAddress).transfer(
            msg.sender,
            IERC20(_tokenAddress).balanceOf(address(this))
        );
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }

    receive() external payable {}
}
