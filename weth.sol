// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


contract WETH is ERC20, Ownable {
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    constructor() ERC20("Wrapped Ether", "WETH") Ownable(_msgSender()) {}

    function deposit() public payable {
        require(msg.value > 0, "Must send ETH to deposit");
        _mint(_msgSender(), msg.value);
        emit Deposit(_msgSender(), msg.value);

    }

    function withdraw(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(_msgSender()) >= amount, "Insufficient WETH balance");

        _burn(_msgSender(), amount);
        payable(_msgSender()).transfer(amount);
        emit Withdrawal(_msgSender(), amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(amount <= balanceOf(_msgSender()), "Insufficient balance");
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(amount <= balanceOf(sender), "Insufficient balance");
        return super.transferFrom(sender, recipient, amount);
    }

    receive() external payable {
        deposit();
    }

}