// SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import "../lib/forge-std/src/Test.sol";
// import "../src/lending2.sol";
// import "../src/oracle.sol";
// import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";


// contract USDC is ERC20 {
//     constructor(string memory tokenName) ERC20(tokenName,tokenName) {}

//     function mint(address to,uint256 amount) public {
//         _mint(to,amount);
//     }
// }


// contract CounterTest is Test {
//     Lends lending;
//     Oracles oracle;
//     USDC usdc;
//     address eth;
    
//     address depositor1;
//     address borrower1;

//     function setUp() public {
//         eth = address(0x444444);
//         usdc = new USDC("USDC");
//         oracle = new Oracles();
//         lending = new Lends(address(usdc), address(oracle));

//         oracle.setPrice(eth, 1350 * 10 ** 6);
//         depositor1 = address(0x11);
//         borrower1 = address(0x10);
//         vm.deal(borrower1, 100 ether);
//         usdc.mint(depositor1, 100 ether);

//     }
//     function testDeposit1() public {
//         vm.prank(borrower1);
//         lending.deposit{value : 10 ether}(address(eth),0);
//         vm.startPrank(depositor1);
//         usdc.approve(address(lending), 100 * 10 ** 6);
//         lending.deposit(address(usdc), 100 * 10 ** 6); 

//         assertEq(address(lending).balance, 10 ether);
//         assertEq(usdc.balanceOf(address(lending)), 100 * 10 ** 6); 
//         vm.stopPrank(); 
//     }

//     function testBorrow1() public {
//         uint256 amount = 10 ether;

//         // deposit
//         vm.startPrank(depositor1);
//         usdc.approve(address(lending), 10000 * 10 ** 6); //10000 usdc 인출승인
//         console.log("lender usdc amount : ", usdc.balanceOf(address(depositor1)));
//         lending.deposit(address(usdc), 7000 * 10 ** 6); // 7000 usdc 예금
//         console.log("existed amount in usdc pool  : ", usdc.balanceOf(address(lending))); //예금 확인
//         vm.stopPrank();
//         // borrow
//         vm.startPrank(borrower1); 
//         usdc.approve(address(lending), 100 * 10 ** 6); //100 usdc
//         lending.deposit{value : amount}(address(eth),0); //10 ether 담보
//         lending.borrow(address(usdc), (amount * 1350 * 10 ** 6 / 10 ** 18) / 2 );  
//         console.log("borrower usdc amount : ", usdc.balanceOf(address(borrower1)));
//         console.log("lending usdc pool amount : ", usdc.balanceOf(address(lending)));
//         assertEq(usdc.balanceOf(address(borrower1)),(amount * 1350 * 10 ** 6/10 ** 18/2));
//         vm.stopPrank();

//     }


//     function testRepay1() public {
//         uint256 amount = 10 ether;
//         usdc.mint(borrower1, 40000000); // usdc
        
//         // deposit
//         vm.startPrank(depositor1); 
//         usdc.approve(address(lending), 10000 * 10 ** 6); //10000 usdc 인출승인
//         console.log("lender usdc amount : ", usdc.balanceOf(address(depositor1)));
//         lending.deposit(address(usdc), 7000 * 10 ** 6); // 7000000000 usdc 예금
//         console.log("existed amount in usdc pool  : ", usdc.balanceOf(address(lending))); //예금 확인
//         vm.stopPrank();
        
//         // borrow
//         vm.startPrank(borrower1); 
//         usdc.approve(address(lending), 100 * 10 ** 6); //100 usdc
//         lending.deposit{value : amount}(address(eth),0); 
//         console.log("borrower usdc amount : ", usdc.balanceOf(address(borrower1)));
//         lending.borrow(address(usdc), (amount * 1350 * 10 ** 6 / 10 ** 18)/2 );
//         assertEq(usdc.balanceOf(address(borrower1)),(amount * 1350 * 10 ** 6 / 10 ** 18)/2 + 40000000);
//         vm.stopPrank();
        
//         // repay
//         vm.startPrank(borrower1); 
//         usdc.approve(address(lending), 100 ether);
//         vm.warp(block.timestamp + 5 days);
//         console.log("existed amount in usdc pool: ", usdc.balanceOf(address(lending)));
//         console.log("borrower has amount : ", usdc.balanceOf(address(borrower1)));
//         lending.repay(address(usdc), (amount * 1350 * 10 ** 6 / 10 ** 18) /2 );
//         console.log(usdc.balanceOf(address(lending)));       
//         vm.stopPrank();

//     }
    
//     function testWithdraw1() public {
//         // deposit
//         vm.startPrank(depositor1);
//         usdc.approve(address(lending), 10000 * 10 ** 6);
//         lending.deposit(address(usdc), 7000 * 10 ** 6);    

//         vm.warp(block.timestamp + 5 days);
//         console.log("before : ", usdc.balanceOf(depositor1));
//         lending.withdraw(address(usdc), 3000 * 10 ** 6 );
//         console.log("after : ", usdc.balanceOf(depositor1));
//         console.log("pool amount : ", usdc.balanceOf(address(lending)));
//     }

//     function testWithdraw2() public {
//         uint256 amount = 10 ether;
//         usdc.mint(borrower1, 40000000);
//         // deposit
//         vm.startPrank(depositor1);
//         usdc.approve(address(lending), 10000 * 10 **6);
//         console.log("before deposit" , usdc.balanceOf(depositor1));
//         lending.deposit(address(usdc), 7000 *10 **6);
//         vm.stopPrank();
//         // borrow
//         vm.startPrank(borrower1);
//         usdc.approve(address(lending),100 * 10 **6);
//         lending.deposit{value : amount }(address(eth),0);
//         lending.borrow(address(usdc), (amount * 1350 * 10 ** 6 / 10 ** 18)/2 );
//         vm.stopPrank();

//         // repay
//         vm.startPrank(borrower1); 
//         usdc.approve(address(lending), 100 ether);
//         vm.warp(block.timestamp + 3 days);
//         lending.repay(address(usdc), (amount * 1350 * 10 ** 6 / 10 ** 18)/2  + 200000);
//         console.log(usdc.balanceOf(address(lending)));       
//         vm.stopPrank();    

//         //withdraw
//         vm.startPrank(depositor1);
//         console.log("before : ", usdc.balanceOf(depositor1));
//         lending.withdraw(address(usdc), 7000 * 10 **6 );
//         console.log("after : ", usdc.balanceOf(depositor1));
//         console.log("withdraw usdc", usdc.balanceOf(address(depositor1)));

//     }
//     function testWithdraw3() public {
//         uint256 amount = 10 ether;
//         usdc.mint(borrower1, 40000000);
        
//         // deposit
//         vm.startPrank(depositor1);
//         usdc.approve(address(lending), 10000 * 10 **6);
//         lending.deposit(address(usdc), 7000 *10 **6);
//         vm.stopPrank();

//         // borrow
//         vm.startPrank(borrower1);
//         usdc.approve(address(lending), 100 * 10 **6);
//         lending.deposit{value : amount }(address(eth),0);
//         lending.borrow(address(usdc), (amount * 1350 * 10 ** 6 / 10 ** 18)/2 );
        
//         // repay
//         usdc.approve(address(lending), 100 ether);
//         vm.warp(block.timestamp + 5 days);
//         lending.repay(address(usdc), (amount * 1350 * 10 ** 6 / 10 ** 18)/2  + 200000);
//         console.log(usdc.balanceOf(address(lending)));  
//         vm.stopPrank();

//         // withdraw collateral
//         vm.startPrank(depositor1);
//         lending.withdraw(address(usdc),0);
//         console.log("pool collateral" , address(usdc).balance);
        
//         vm.stopPrank();     
//     }


//     function testLiquidate1() public {
//        uint256 amount = 10 ether;
//         usdc.mint(borrower1, 40000000);

//         // deposit
//         vm.startPrank(depositor1);
//         usdc.approve(address(lending), 10000 * 10 **6);
//         lending.deposit(address(usdc), 7000 *10 **6);
//         vm.stopPrank();

//         // borrow
//         vm.startPrank(borrower1);
//         usdc.approve(address(lending), 100 * 10 ** 6);
//         lending.deposit{value : amount}(address(eth),0);
//         console.log("borrower usdc amount : ", usdc.balanceOf(address(borrower1)));
//         lending.borrow(address(usdc), (amount * 1350 * 10 ** 6 / 10 ** 18)/2 );
//         console.log("borrower1 usdc", usdc.balanceOf(address(borrower1)));

//         // liquidate
//         address liquidator1 = payable(address(0x90));
//         usdc.mint(liquidator1, 5000 * 10 ** 6); 
//         console.log("liquidator's balanceOf usdc", usdc.balanceOf(address(liquidator1)));

//         assertEq(liquidator1.balance , 0 ether, "liquidator ether balance is not 0");
//         // Threshold 75%
//         // oracle.setPrice (eth, 1000 * 10 ** 6);
//         vm.warp(block.timestamp + 5 days);
//         usdc.approve(address(lending), 3500 * 10 ** 6);
//         vm.stopPrank();
//         vm.startPrank(liquidator1);
//         lending.liquidate(borrower1, address(usdc), 3300 * 10 ** 6);
//         console.log("lending pool remain eth amount : ", address(lending).balance);
//         console.log("liquidator1 receive eth amount : ", liquidator1.balance);


//         vm.stopPrank();
//     }

//     receive() external payable
//     {

//     }
// }