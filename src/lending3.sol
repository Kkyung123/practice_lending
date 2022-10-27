// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import '../test/lending.t.sol';
import "../lib/forge-std/src/Test.sol";
import "./abdk.sol";
interface IPriceOracle {
     function getPrice(address token) external view returns (uint256);
     function setPrice(address token, uint256 price) external;
}

contract DreamAcademyLending {

    IPriceOracle public oracle; 
    address eth = address(0x0);
    address usdc;

    struct deposit_info {
        uint256 balance;
        uint256 profit;
    }
    uint256 totalFee;
    uint256 pre_totlaFee;
    mapping(address => uint) public total_supply;
    mapping(address => deposit_info) public depositor;
    address[] public depositor_index;

        
    struct borrow_info {
        uint256 collateral;
        uint256 debt;
        uint256 blockNum;    
    }
    
    mapping(address => borrow_info) public borrower;
    address[] public borrower_index;

    constructor(IPriceOracle _oracle, address _usdc) {
        usdc = _usdc;
        oracle = _oracle;
    }

    function initializeLendingProtocol(address token1) external payable{
        ERC20(token1).transferFrom(msg.sender, address(this), msg.value);
    }
    
    function getAccruedSupplyAmount(address usdc) public returns(uint256) {
        calc_fee();
        return depositor[msg.sender].balance +((depositor[msg.sender].profit + ((totalFee - pre_totlaFee) * depositor[msg.sender].balance / ERC20(usdc).balanceOf(address(this)))));
    }

    function getAllAccruedSupplyAmount(address usdc, address user) public returns(uint256) {
        calc_fee();
        pre_totlaFee = totalFee;
        return (totalFee * depositor[user].balance / ERC20(usdc).balanceOf(address(this)));
    }

    function updateProfit(address usdc) public {
        for(uint i=0; i < depositor_index.length; i++){
            address addr = depositor_index[i];
            depositor[addr].profit = getAllAccruedSupplyAmount(usdc, addr);      
        }
    }

    function deposit(address tokenAddress, uint256 amount) external payable {
        
        if(tokenAddress == usdc) {
            updateProfit(usdc);
            ERC20(usdc).transferFrom(msg.sender, address(this), amount);
            depositor[msg.sender].balance += amount;
            total_supply[usdc] += amount;
            depositor_index.push(msg.sender);
        } else {
            require(msg.value == amount);
            borrower[msg.sender].collateral += amount;
        }
    }

    function borrow(address tokenAddress, uint256 amount) external payable {
        
        uint eth_a = oracle.getPrice(eth);
        uint usdc_a = oracle.getPrice(usdc);
        
        require(eth_a * borrower[msg.sender].collateral / 2 >= usdc_a * (borrower[msg.sender].debt + amount), "");    
        ERC20(usdc).transfer(msg.sender, amount);
        borrower[msg.sender].debt += amount;
        borrower[msg.sender].blockNum = block.number;
        borrower_index.push(msg.sender);
    }

    function repay(address tokenAddress, uint256 amount) external payable {
        
        accrueInterest(msg.sender);
        ERC20(usdc).transferFrom(msg.sender, address(this), amount);
        borrower[msg.sender].debt -= amount;

    }

    function liquidate(address user, address tokenAddress, uint256 amount) external {
        uint256 current_value = oracle.getPrice(eth);
        uint256 current_uvalue = oracle.getPrice(usdc);
    
        require(current_value * borrower[user].collateral * 3/4 < borrower[user].debt * current_uvalue); 
        require(borrower[user].debt * 1/4 >= amount);
        
        ERC20(usdc).transferFrom(msg.sender, address(this), amount);
        payable(msg.sender).transfer(amount * borrower[user].collateral / borrower[user].debt);
        borrower[user].debt -= amount;
    }

    function withdraw(address tokenAddress, uint256 amount) external {
        
        require(depositor[msg.sender].balance != 0 || borrower[msg.sender].collateral != 0);
        accrueInterest(msg.sender);
        if(tokenAddress == usdc){
            amount = getAccruedSupplyAmount(tokenAddress) / 1e18 * 1e18;
            depositor[msg.sender].balance += amount - depositor[msg.sender].balance;  
            ERC20(usdc).transfer(msg.sender, amount);
            depositor[msg.sender].balance -= amount;
        } else {
            if(borrower[msg.sender].debt == 0){
                payable(msg.sender).transfer(amount);
                borrower[msg.sender].collateral -= amount;
            } else {
                uint256 current_value = oracle.getPrice(eth);
                uint256 current_uvalue = oracle.getPrice(usdc);
                require( current_value * ( borrower[msg.sender].collateral - amount ) * 3/4  > borrower[msg.sender].debt * current_uvalue); 
                payable(msg.sender).transfer(amount);
                borrower[msg.sender].collateral -= amount;
            }
        }

    }

    // function accrueInterest(address _borrower) public returns(uint){

    //     uint256 period = block.number - borrower[_borrower].blockNum;
    //     uint256 amount = borrower[_borrower].debt;

    //     for (uint i=0; i< period; i++){
    //         amount += amount / 1e11 * 13882;
    //     }
    //     uint256 fee = amount - borrower[_borrower].debt;
    //     borrower[_borrower].debt = amount;
    //     borrower[_borrower].blockNum = block.number;

    //     return fee;
    // }

    function calc_fee() public {
        for(uint i=0; i<borrower_index.length; i++){
            address borrower = borrower_index[i];
            totalFee += accrueInterest(borrower);
        }
    }

    function pow (int128 x, uint n) public pure returns (int128 r) {
        r = ABDKMath64x64.fromUInt (1);
        while (n > 0) {
        if (n % 2 == 1) {
            r = ABDKMath64x64.mul (r, x);
            n -= 1;
        } else {
        x = ABDKMath64x64.mul (x, x);
        n /= 2;
        }
        }
    }
    
    
    function compound (uint principal, uint ratio, uint n) public pure returns (uint) 
    {return ABDKMath64x64.mulu (
    pow (
        ABDKMath64x64.add (
        ABDKMath64x64.fromUInt (1), 
        ABDKMath64x64.divu (ratio,10**18)),
        n),
        principal);
    }

    function accrueInterest(address _borrower) public returns(uint){
        uint256 period = block.number - borrower[_borrower].blockNum;
        uint256 day = period / 7200;
        uint256 remain = period % 7200;

        uint amount;

        if(remain != 0) {
            uint256 amount2 = compound(borrower[_borrower].debt, 1e15, day);
            uint256 amount1 = compound(amount2, 1e15, 1);
            amount = amount2 + ((amount1 - amount2)/ 7200) * remain;
        } else {
            amount = compound(borrower[_borrower].debt, 1e15, day);        
        }
        
        uint256 fee = amount - borrower[_borrower].debt;
        borrower[_borrower].debt = amount;
        borrower[_borrower].blockNum = block.number;

        return fee;
    }
}
