// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "forge-std/console.sol";
import "forge-std/stdlib.sol";
import "forge-std/Vm.sol";
import "src/integrations/aUSTVault.sol";
import "./TestERC20.sol";
import "./Utils.sol";

contract TestaUSTVault is DSTest {
    Vm public constant vm = Vm(HEVM_ADDRESS);

    uint constant ADMIN_FEE = 1000;
    uint constant CALLER_FEE = 10;

    uint constant MAX_REINVEST_STALE = 1 hours;
    uint constant MAX_INT = 2 ** 256 - 1;

    aUSTVault public vault;

    address constant WAVAX = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c;

    address constant anchor = 0x95aE712C309D33de0250Edd0C2d7Cb1ceAFD4550;
    address constant wUST = 0xb599c3590F42f8F995ECfa0f85D2980B76862fc1;
    address constant aUST = 0xaB9A04808167C170A9EC4f8a87a0cD781ebcd55e;
    
    // aUST / UST
    address constant priceFeedAggregator = 0x9D5024F957AfD987FdDb0a7111C8c5352A3F274c;

    address constant wUSTHolder = 0xc7388D98Fa86B6639d71A0A6d410D5cDfc63A1d0;
    address constant wUSTHolder2 = 0xeCD6D33555183Bc82264dbC8bebd77A1f02e421E;
    address constant wUSTHolderAdditional = 0xD79138c49c49200a1Afc935171D1bDAd084FDc95;
    address constant wUSTHolder2Additional = 0xE1f75E2E74BA938abD6C3BE18CCc5C7f71925C4B;
    address constant wUSTHolder2Additional2 = 0x9D563afF8B0017868DbA57eB3E04298C157d0aF5;
    address constant wUSTHolder2Additional3 = 0xcb11EE4B70d73e38a383b8691cAFb221059669cC;
    address constant wUSTHolder2Additional4 = 0xbC1631afCB916bda28aF42955Fc970Bf004596F8;
    address constant wUSTHolder2Additional5 = 0x0a02Fc4aD3aD1D3F4c4Da8F492907E74Cf056017;
    
    address constant aUSTHolder = 0xaD0135AF20fa82E106607257143d0060A7eB5cBf;
    address constant aUSTHolderAdditional = 0xf3f5C252e8ACd60671f92c7F72cf33661221Ef42;
    address constant aUSTHolderAdditional2 = 0x31d3243CfB54B34Fc9C73e1CB1137124bD6B13E1;
    
    string constant name = "UST Vault";
    string constant symbol = "vUST";

    uint public FIRST_DONATION;
    uint public decimalCorrection;

    function setUp() public {
        vault = new aUSTVault();
        vault.initialize(
            wUST,
            name,
            symbol,
            ADMIN_FEE,
            CALLER_FEE,
            MAX_REINVEST_STALE,
            WAVAX,
            anchor,
            aUST,
            priceFeedAggregator
        );

        vm.startPrank(wUSTHolder);
        IERC20(wUST).transfer(address(this), IERC20(wUST).balanceOf(wUSTHolder));
        vm.stopPrank();
        vm.startPrank(wUSTHolderAdditional);
        IERC20(wUST).transfer(address(this), IERC20(wUST).balanceOf(wUSTHolderAdditional));
        vm.stopPrank();

        vm.startPrank(aUSTHolder);
        IERC20(aUST).transfer(address(2), IERC20(aUST).balanceOf(aUSTHolder));
        vm.stopPrank();
        vm.startPrank(aUSTHolderAdditional);
        IERC20(aUST).transfer(address(2), IERC20(aUST).balanceOf(aUSTHolderAdditional));
        vm.stopPrank();
        vm.startPrank(aUSTHolderAdditional2);
        IERC20(aUST).transfer(address(2), IERC20(aUST).balanceOf(aUSTHolderAdditional2));
        vm.stopPrank();

        vm.startPrank(wUSTHolder2);
        IERC20(wUST).transfer(address(3), IERC20(wUST).balanceOf(wUSTHolder2));
        vm.stopPrank();
        vm.startPrank(wUSTHolder2Additional);
        IERC20(wUST).transfer(address(3), IERC20(wUST).balanceOf(wUSTHolder2Additional));
        vm.stopPrank();
        vm.startPrank(wUSTHolder2Additional2);
        IERC20(wUST).transfer(address(3), IERC20(wUST).balanceOf(wUSTHolder2Additional2));
        vm.stopPrank();
        vm.startPrank(wUSTHolder2Additional3);
        IERC20(wUST).transfer(address(3), IERC20(wUST).balanceOf(wUSTHolder2Additional3));
        vm.stopPrank();
        vm.startPrank(wUSTHolder2Additional4);
        IERC20(wUST).transfer(address(3), IERC20(wUST).balanceOf(wUSTHolder2Additional4));
        vm.stopPrank();
        vm.startPrank(wUSTHolder2Additional5);
        IERC20(wUST).transfer(address(3), IERC20(wUST).balanceOf(wUSTHolder2Additional5));
        vm.stopPrank();

        IERC20(wUST).approve(address(vault), MAX_INT);
        decimalCorrection = IERC20(aUST).decimals();
     } 
    
    function testDeposit(uint96 amount) public returns (uint) {
        if (amount < vault.MIN_FIRST_MINT() || 
        amount > IERC20(wUST).balanceOf(address(this)) || 
        amount > IERC20(wUST).balanceOf(address(3)) || 
        amount > IERC20(aUST).balanceOf(address(2))) {
            return 0;
        }
        uint256 preBalance = vault.balanceOf(address(this));
        vault.deposit(amount);

        // simulate Anchor behavior on deposit (providing aUST as depository receipt for wUST)
        (,int price,,,) = vault.priceFeed().latestRoundData();
        uint256 depositoryReceiptAmount = 1e18 * uint256(amount) / uint256(price);
        vm.startPrank(address(2));
        IERC20(aUST).transfer(address(vault), depositoryReceiptAmount);
        vm.stopPrank();

        uint256 postBalance = vault.balanceOf(address(this));
        uint256 amt = (vault.receiptPerUnderlying() * amount) / 1e18;

        Utils.assertSmallDiff(postBalance, preBalance + amt - vault.FIRST_DONATION());
        assertTrue(vault.totalUnderlyingDeposits() == uint256(amount));
        return amount;
    }

    function testDepositAndRedeem(uint96 amount) public {
        if (amount < vault.MIN_FIRST_MINT() || 
        amount > IERC20(wUST).balanceOf(address(this)) || 
        amount > IERC20(wUST).balanceOf(address(3)) || 
        amount > IERC20(aUST).balanceOf(address(2))) {
            return;
        }
        uint256 preBalanceVault = vault.balanceOf(address(this));
        uint256 preBalanceToken = IERC20(wUST).balanceOf(address(this));
        vault.deposit(amount);
        uint256 postBalanceVault = vault.balanceOf(address(this));
        uint256 postBalanceToken = IERC20(wUST).balanceOf(address(this));
        
        // simulate Anchor behavior on deposit (providing aUST as depository receipt for wUST)
        (,int price,,,) = vault.priceFeed().latestRoundData();
        uint256 depositoryReceiptAmount = 1e18 * uint256(amount) / uint256(price);
        vm.startPrank(address(2));
        IERC20(aUST).transfer(address(vault), depositoryReceiptAmount);
        vm.stopPrank(); 

        // preload vault with underlying to simulate anchor behavior on redeem (providing wUST for depository receipt)
        vm.startPrank(address(3));
        IERC20(wUST).transfer(address(vault), IERC20(wUST).balanceOf(address(3)));
        vm.stopPrank();
        IERC20(wUST).transfer(address(vault), IERC20(wUST).balanceOf(address(this)));

        preBalanceVault = vault.balanceOf(address(this));
        preBalanceToken = IERC20(wUST).balanceOf(address(this));
        vault.redeem(preBalanceVault);
        
        postBalanceVault = vault.balanceOf(address(this));
        postBalanceToken = IERC20(wUST).balanceOf(address(this));

        uint256 amt = (vault.receiptPerUnderlying() * amount) / 1e18;
        assertTrue(postBalanceVault == 0);
        Utils.assertSmallDiff(postBalanceToken, preBalanceToken + amount);
    }
}