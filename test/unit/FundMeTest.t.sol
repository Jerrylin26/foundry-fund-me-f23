//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

//這個Test匯集了FundMe的測試
contract FundMeTest is Test {
    //uint256 number = 1;

    FundMe fundMe;
    address USER = makeAddr("user");
    address USER2 = makeAddr("user2");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARING_BALANCE = 10 ether;
    uint256 public GAS_PRICE = 1;

    // setUp 是最先跑的
    function setUp() external {
        //number = 2;
        //fundMe = new FundMe();
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();

        //為模擬帳戶餘額
        vm.deal(USER, STARING_BALANCE);
    }

    function testMinimumDollarIsFive() public view {
        /*console.log(number);
        assertEq(number, 2);*/
        console.log("Current chain ID:", block.chainid);

        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        console.log(fundMe.getOwner()); //新建立的address
        console.log(msg.sender); //FundMe的address
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); //hey, the next line, should revert
        // assert(This tx fails/reverts)
        fundMe.fund(); //這行要失敗 // send 0 value
    }

    //cheatCode
    function testFundUpadatesFundedDataStructure() public {
        vm.prank(USER); // The next TX will be sent by USER
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        //  vm.prank(USER);每過一個function都會reset
        vm.prank(USER); // The next TX will be sent by USER
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    //他的功能是，包裝一個modifier，只有USER可以fund
    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _; //接者，下面的程式繼續執行
    }

    function testOnlyOwnerCanWithdraw() public funded {
        console.log(msg.sender); //0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
        vm.expectRevert();
        fundMe.withdraw(); //捐款人不能withdraw
    }

    function testWithDrawWithASingleFunder() public funded {
        // Arrange 準備階段
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance; //合約地址
        //console.log("44", address(fundMe));

        // Act 執行階段
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert 驗證階段
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingOwnerBalance + startingFundMeBalance,
            endingOwnerBalance
        ); //因錢都匯到owner
    }

    function testWithdrawFromMulipleFunders() public funded {
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank & vm.deal combined
            hoax(address(i), SEND_VALUE); //模擬發送者及其餘額
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance; //合約地址

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //Assert
        assertEq(address(fundMe).balance, 0);
        assertEq(
            startingOwnerBalance + startingFundMeBalance,
            fundMe.getOwner().balance
        );
    }

    function testWithdrawFromMulipleFundersCheaper() public funded {
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank & vm.deal combined
            hoax(address(i), SEND_VALUE); //模擬發送者及其餘額
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance; //合約地址

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //Assert
        assertEq(address(fundMe).balance, 0);
        assertEq(
            startingOwnerBalance + startingFundMeBalance,
            fundMe.getOwner().balance
        );
    }
}
