// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error TransferFailed();
error NeedsMoreThanZero();

contract Lending is ReentrancyGuard, Ownable {
  constructor() Ownable(msg.sender) {}

  // Account -> Token -> Amount
  mapping(address => mapping(address => uint256)) public s_accountToTokenDeposits;
  // Account -> Token -> Amount
  mapping(address => mapping(address => uint256)) public s_accountToTokenBorrows;

  event Deposit(address indexed account, address indexed token, uint256 indexed amount);
  event Withdraw(address indexed account, address indexed token, uint256 indexed amount);
  event Borrow(address indexed account, address indexed token, uint256 indexed amount);
  event Repay(address indexed account, address indexed token, uint256 indexed amount);

  function deposit(address token, uint256 amount) external nonReentrant moreThanZero(amount) {
    emit Deposit(msg.sender, token, amount);
    s_accountToTokenDeposits[msg.sender][token] += amount;
    require(IERC20(token).balanceOf(msg.sender) >= amount, "Not enough tokens to deposit");
    bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
    if (!success) revert TransferFailed();
  }

  function withdraw(address token, uint256 amount) external nonReentrant moreThanZero(amount) {
    require(s_accountToTokenDeposits[msg.sender][token] >= amount, "Not enough funds");
    emit Withdraw(msg.sender, token, amount);
    s_accountToTokenDeposits[msg.sender][token] -= amount;
    bool success = IERC20(token).transfer(msg.sender, amount);
    if (!success) revert TransferFailed();
  }

  function borrow(address token, uint256 amount) external nonReentrant moreThanZero(amount) {
    require(IERC20(token).balanceOf(address(this)) >= amount, "Not enough tokens to borrow");
    s_accountToTokenBorrows[msg.sender][token] += amount;
    emit Borrow(msg.sender, token, amount);
    bool success = IERC20(token).transfer(msg.sender, amount);
    if (!success) revert TransferFailed();
  }

  function repay(address token, uint256 amount) external nonReentrant moreThanZero(amount) {
    emit Repay(msg.sender, token, amount);
    s_accountToTokenBorrows[msg.sender][token] -= amount;
    bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
    if (!success) revert TransferFailed();
  }

  modifier moreThanZero(uint256 amount) {
    if (amount == 0) {
      revert NeedsMoreThanZero();
    }
    _;
  }
}
