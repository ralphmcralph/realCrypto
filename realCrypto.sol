// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RealCrypto is ERC20, Ownable {

    uint256 public sellFee = 5; // 5% Base Sell Fee
    uint256 public transferFee = 1; // 1% Base Buy and Transfer Fee
    address public treasuryWallet;
    address public feesWallet;

    mapping(address => bool) public isExcludedFromFees;
    mapping(address => bool) private holders;
    mapping(address => uint256) private holderIndex; // Index for fast removal
    address[] private holderList; // Dynamic list of active holders

    uint256 public lastDistributionTimestamp;
    uint256 public accumulationPeriod = 7 days;

    event TransferWithFee(address indexed from, address indexed to, uint256 amount, uint256 fee);
    event FeesDistributed(uint256 toHolders, uint256 toBurn, uint256 toLiquidity);
    event FeesCollected(address indexed from, uint256 amount);


    constructor(string memory name_, string memory symbol_, address feesWallet_) ERC20(name_, symbol_) Ownable(msg.sender) {
        _mint(msg.sender, 1_000_000_000 * 10 ** decimals()); // Assign initial supply to owner
        treasuryWallet = msg.sender;
        feesWallet = feesWallet_;
        isExcludedFromFees[msg.sender] = true; // Owner pays no fees
    }

    // Transfer and fees handling
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 fee = isExcludedFromFees[msg.sender] ? 0 : ((recipient == treasuryWallet) ? (amount * sellFee) / 100 : (amount * transferFee) / 100);
        uint256 amountAfterFee = amount - fee;

        super.transfer(recipient, amountAfterFee);
        _updateHolders(msg.sender, recipient);

        if (fee > 0) {
            super.transfer(feesWallet, fee);
            emit FeesCollected(msg.sender, fee);
        }

        emit TransferWithFee(msg.sender, recipient, amount, fee);
        
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 fee = isExcludedFromFees[sender] ? 0 : ((recipient == treasuryWallet) ? (amount * sellFee) / 100 : (amount * transferFee) / 100);
        uint256 amountAfterFee = amount - fee;

        super.transferFrom(sender, recipient, amountAfterFee);
        _updateHolders(sender, recipient);

        if (fee > 0) {
            super.transferFrom(sender, feesWallet, fee);
            emit FeesCollected(sender, fee);
        }

        emit TransferWithFee(sender, recipient, amount, fee);
        
        return true;
    }



    // Distribute fees

    function distributeFees() external onlyOwner {
        require(block.timestamp > lastDistributionTimestamp + accumulationPeriod, "Accumulation period not reached");
        require(balanceOf(feesWallet) > 0, "No fees to distribute");

        uint256 totalFee = balanceOf(feesWallet);

        uint256 distributeToHolders = (totalFee * 30) / 100;
        uint256 burnAmount = (totalFee * 30) / 100;
        uint256 liquidityAmount = (totalFee * 40) / 100;

        lastDistributionTimestamp = block.timestamp;

        _burn(feesWallet, burnAmount);
        super.transfer(treasuryWallet, liquidityAmount);

        _distributeToHolders(distributeToHolders);


        emit FeesDistributed(distributeToHolders, burnAmount, liquidityAmount);

    }

    function _updateHolders(address sender, address recipient) internal {
        if (balanceOf(sender) == 0 && holders[sender]) {
        _removeHolder(sender);
        }
        if (balanceOf(recipient) > 0 && !holders[recipient]) {
            _addHolder(recipient);
        }
    }

    function _addHolder(address account) internal {
        if (!holders[account]) {
            holders[account] = true;
            holderIndex[account] = holderList.length; // Store index
            holderList.push(account);
        }
    }

    function _removeHolder(address account) internal {
        if (!holders[account]) return;

        uint256 index = holderIndex[account];
        uint256 lastIndex = holderList.length - 1;

        if (index != lastIndex) { 
            address lastHolder = holderList[lastIndex];
            holderList[index] = lastHolder; 
            holderIndex[lastHolder] = index; 
        }

        holderList.pop();
        delete holders[account];
        delete holderIndex[account];
    }

    function _distributeToHolders(uint256 distributeToHolders) internal {
        uint256 totalValidBalance = 0;

        // Count valid holders

        for (uint256 i = 0; i < holderList.length; i++) {
            address holder = holderList[i];
            uint256 balance = balanceOf(holder);

            if (balance > 0) {
                totalValidBalance += balance;
            } else {
                _removeHolder(holder);
            }
        }

        // Avoid division by zero

        if (totalValidBalance == 0) return;

        // Distribute rewards

        for (uint256 i = 0; i < holderList.length; i++) {
            address holder = holderList[i];
            uint256 holderBalance = balanceOf(holder);

            if (holderBalance > 0) {
                uint256 reward = (distributeToHolders * holderBalance) / totalValidBalance;
                super.transfer(holder, reward);
            } else {
                _removeHolder(holder);
            }
        }
    }
}
