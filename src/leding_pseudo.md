// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './oracle.sol';
import "../lib/forge-std/src/Test.sol";

contract Lends is IERC20, ERC20 {

    address public usdc; // usdc contract 
    mapping (address => uint256) public assures; // 담보로 맡긴 금액
    mapping (address => mapping(address => uint256)) public debts; // 빌린 계좌

    mapping (address => mapping(address => uint256)) public lends; // 빌려준 계좌, 빌려준 금액 저장
    uint256 public deposits; // 총 예금 금액 
    
    mapping (address => mapping(address => uint256)) public money; // 이자 저장 
    uint256 time; // 빌린 시간
    mapping (address => uint256) public times;
    uint256 public interests; // 이자총액(이자수익)
    mapping (address => uint256) public principles; // 원금(원금 총액)
    

    // constructor(address _usdc) ERC20("USDC", "usdc") {
    //   
    // }

    function deposit(address tokenAddress, uint256 amount) external payable {
        // ETH, USDC 입금하는 함수
        // 1. contract 주소로 담보로 맡기는 eth deposit
        // 2. usdc 예치 전, usdc 예치하는 사람의 잔액 확인
        // 3. contract 주소에 usdc를 amount 만큼 예치
        // 4. 빌려주는 계좌에 amount 만큼 예치금액 저장
    }

    function borrow(address tokenAddress, uint256 amount) external {
        // 담보만큼 USDC 대출해주는 함수
        // 1. 빌려주는 건 usdc 계좌만 가능 -> require 확인 (tokenAddress(usdc))
        // 2. 빌려주는 usdc 계좌의 잔액을 확인한 후 (balance >= amount)
        // 3. LTV를 50%로 지정했으니 내가 가지고 있는 ETH의 50%까지만 빌려줌 
        //    -> oracle에서 eth 가격 받아와서, 담보로 맡긴 eth * value를 계산해주고 LTV < eth * value / 2
        // 4. 빌린 시간 기록 (repay에서 이자율 계산하기 위함) -> 빌린 계좌에 usdc를 amount 만큼 전달
        // 5. 빌려준 계좌의 예치한 금액에서 빌린만큼 차감
    }

    function repay(address tokenAddress, uint256 amount) external {
        // 대출 상환하는 함수
        // 1. usdc 빌렸으니, usdc 갚아야 함 -> require 확인 
        // 2. 갚으려고 하는 usdc가 amount만큼 있는지 확인
        // 3. oracle에서 usdc 가격 받아와서 value * amount 게산 
        // 4. 이자율 계산 -> interests_rate
        // 5. 상환하는 값 contract에서 전달 
        // 6. 상환한 만큼 빌린 값을 차감
    }

    function interests_rate(address tokenAddress, uint256 lend_time, uint256 current_time) internal { //이자율 계산
        // 이자율 계산하는 함수, 1일당 복리 0.1% 증가  
        // 1. 이자율 = (갚는 시간 - 빌린 시간 / 1일)
        // 2. 빌린 돈 = 원금 + (원금 * 0.1%)
    }

    function liquidate(address user, address tokenAddress, uint256 amount) external {
        // 담보청산, USDC 확보
        // 1. 청산하려는 주소 확인
        // 2. eth value를 oracle에서 받아와서, 담보 값계산 
        // 3. 빚이 어디까지 늘어나서 청산을 언제 할지 결정 
        //    -> liquidation threshold 75%(3/4) 
        // 4. bad debt를 발생시키지 않기 위해서 
        //    -> usdc 갚은 만큼 담보 차감한 후에 부분청산 .. ? 
    }

    function withdraw(address tokenAddress, uint256 amount) external {
        // 회수하는 함수
        // 1. 24시간 이내로 갚아서 이자가 0원일 때, 원금 회수
        // 2. 24시간이 지나서 이자율이 늘어나 -> 원금 + 예치자가 전체 예치금액에서 예치한 금액만큼 이자율 회수
        // 3. 예치 금액(받아야 하는 금액)에서 회수한만큼 차감 
    }
}