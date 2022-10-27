// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
// import '../test/lending.t.sol';
// // import './oracle.sol';
// import "../lib/forge-std/src/Test.sol";

// interface IPriceOracle {
//      function getPrice(address token) external view returns (uint256);
//      function setPrice(address token, uint256 price) external;
// }

// contract DreamAcademyLending {

//     IPriceOracle public oracle; 
//     address eth = address(0x0);
//     address usdc;
    
//     mapping (address => mapping(address => uint256)) public debts; // 빌린 계좌 => 빌린 사람, usdc, usdc amount
//     mapping (address => mapping(address => uint256)) public lends; // 빌려준 계좌 => 빌려준 사람, usdc, usdc amount
//     mapping (address => mapping(address => uint256)) public assures; // 맡긴 담보 => 맡긴 사람, eth, eth amount
//     mapping (address => mapping(address => uint256)) public collateral; // 남은 담보 => 맡긴 사람, eth, remain eth amount

//     mapping (address => uint256) public deposit_time;    
//     mapping (address => uint256) public times; // 대출자의 빌린 시간 저장
   
//     constructor(IPriceOracle _oracle, address _usdc) {
//         usdc = _usdc;
//         oracle = _oracle;
//     }

//     function interests_rate(address user, address tokenAddress, uint256 lend_time) internal returns(uint256 money) { 
//         lend_time = times[user];
//         uint256 day = (block.timestamp - lend_time) / 1 days; 

//         for (uint i=0; i<day; i++) { //for문에서 날짜 계산
//             debts[user][tokenAddress] = debts[user][tokenAddress] * 1001 / 1000;
//         }
//         money = debts[user][tokenAddress]; // 대출자의 이자+원금 반환

//     }
//     function initializeLendingProtocol(address token1) external payable{
//         ERC20(token1).transferFrom(msg.sender,address(this),msg.value);
//     }

//     function getAccruedSupplyAmount(address usdc) external returns(uint256 x) {
//         x= 1;
//     }
//     function interests_lends_rate(address user, address tokenAddress, uint256 time) internal returns(uint256 amount) { 
//         time = deposit_time[user];
//         uint256 day = (block.timestamp - time) / 1 days; 

//         for (uint i=0; i<day; i++) { //for문에서 날짜 계산
//            lends[user][tokenAddress] = lends[user][tokenAddress] * 1001 / 1000; 
//         }
//         amount = lends[user][tokenAddress]; // 예금자의 이자+원금 반환
//     }

//     function deposit(address tokenAddress, uint256 amount) external payable {
//         require(tokenAddress == eth || tokenAddress == usdc, "invalid Address");

//         if(tokenAddress == eth){ //eth 담보 맡김, 맡겼을 때 eth value 저장
//             assures[msg.sender][tokenAddress] += msg.value;
//             collateral[msg.sender][tokenAddress] += msg.value;
//         } else { // usdc 예치, contract 
//             require(IERC20(tokenAddress).balanceOf(msg.sender) >= amount, "no blance");
//             ERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
//             lends[msg.sender][tokenAddress] += amount; //msg.sender가 예금한 양
//             deposit_time[msg.sender] = block.timestamp; //예금 이자 계산하기 위한 시간
//         }
//     }

//     function borrow(address tokenAddress, uint256 amount) external payable {
//         require(tokenAddress == usdc, "invalid Address");
//         require(ERC20(tokenAddress).balanceOf(address(this)) >= amount, "no balance"); 
//         require(collateral[msg.sender][eth] > 0);
//         uint256 values = oracle.getPrice(eth); //eth -> usdc 계산
//         require( amount * 2 <= values * assures[msg.sender][eth] / 10 ** 18 , "Exceed LTV" ); //빌릴 수 있는 usdc 계산

//         ERC20(tokenAddress).transfer(msg.sender, amount); // usdc 전달
//         debts[msg.sender][tokenAddress] += amount; // + 대출금 +
//         times[msg.sender] = block.timestamp; // 빌린 시간 저장
//         collateral[msg.sender][eth] -= msg.value; //빌릴 수 있는 담보 감소

//     }

//     function repay(address tokenAddress, uint256 amount) external payable {
//         require(tokenAddress == usdc, "invalid Address"); 

//         uint lend_times = times[msg.sender]; //빌린 시간 받아와서  
//         uint256 repayments = interests_rate(msg.sender, tokenAddress, lend_times); // usdc 상환금 계산
    
//         if ( repayments == amount ) { //전체 상환 시
//             ERC20(usdc).transferFrom(msg.sender, address(this), amount); //msg.sender가 컨트랙트로 amount만큼의 usdc 전달
//             debts[msg.sender][tokenAddress] = 0; // 빚 삭감
//             payable(msg.sender).transfer(assures[msg.sender][eth]); //담보로 맡긴 eth 돌려줌
            
//             assures[msg.sender][eth] = 0; // msg.sender가 맡긴 eth = 0
//         } else { //부분 상환 (repayments > amount)
//             require(repayments > amount, "can't repay over the repayments");  
//             ERC20(usdc).transferFrom(msg.sender, address(this), amount); // 상환금 전달
//             debts[msg.sender][tokenAddress] -= amount; //갚은 만큼 차감
//         }
//     }


//     function liquidate(address user, address tokenAddress, uint256 amount) external {
//         require(tokenAddress == usdc, "invalid Address");
//         require(user != address(0), "user is zero address"); 
    
//         uint256 values = oracle.getPrice(eth); //eth -> usdc 계산
//         uint lend_times = times[user];
//         uint256 money= interests_rate(user, tokenAddress, lend_times);

//         require( money <= (values * assures[user][eth]) / 10**18 * 3/4, "liquidation threshold");
//         require( money * 1/2 >= amount, "exceed liquidation limit");

//         uint256 fee = assures[user][eth] * 5 / 100; // 수수료 0.5% 계산
//         uint256 liqui_amount = fee + (assures[user][eth] * 1/2); // 청산해서 받는 eth 가격
//         payable(msg.sender).transfer(liqui_amount); // 전달
//         assures[user][eth] -= liqui_amount; // 담보 차감 
                
//         ERC20(usdc).transferFrom(user, address(this), amount);
//     }

//     function withdraw(address tokenAddress, uint256 amount) external {
//         require(tokenAddress == usdc, "invalid Address");
//         uint deposit_times = deposit_time[msg.sender]; 
//         uint256 money = interests_lends_rate(msg.sender, tokenAddress, deposit_times);
        
//         if( money - amount == 0 ) { // 이자가 없을 때
//             require(lends[msg.sender][tokenAddress] > 0, "Not lenders");
//             lends[msg.sender][tokenAddress] -= amount;
//             ERC20(usdc).transfer(msg.sender, amount);
//             lends[msg.sender][tokenAddress] = 0;
//         } else { // money > amount
//             require(lends[msg.sender][tokenAddress] > 0, "Not lenders");
//             lends[msg.sender][tokenAddress] -= amount;
//             ERC20(usdc).transfer(msg.sender, amount);
//         }
//     }
// }    


