// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

contract TokenTransfer {
    address _token = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831; // USDC

    // token = MyToken's contract address
    constructor() {
    }

    // Modifier to check token allowance
    modifier checkAllowance(uint amount) {
        require(IERC20(_token).allowance(msg.sender, address(this)) >= amount, "Error");
        _;
    }

    function approveTokenAmount(uint256 _amount) external {
        IERC20(_token).approve(address(this), _amount);
    }

    // In your case, Account A must to call this function and then deposit an amount of tokens 
    function depositTokens(uint _amount) public checkAllowance(_amount) {
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        uint refund = _amount / 2;
        IERC20(_token).transfer(msg.sender, refund);
    }
    
    // to = Account B's address
    function stake(address to, uint amount) public {
        IERC20(_token).transfer(to, amount);
    }

    // Allow you to show how many tokens owns this smart contract
    function getSmartContractBalance() external view returns(uint) {
        return IERC20(_token).balanceOf(address(this));
    }
    
}
