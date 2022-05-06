// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "src/Vault.sol";
import {IAnchor} from "src/interfaces/IAnchor.sol";
import {IAggregatorV3} from "src/interfaces/IAggregatorV3.sol";
import {IERC20} from "src/interfaces/IERC20.sol";

contract aUSTVault is Vault {

    IAnchor public anchor;
    IERC20 public aUST;
    IAggregatorV3 public priceFeed;
    uint256 public totalUnderlyingDeposits;

    function initialize(
        address _underlying,
        string memory _name,
        string memory _symbol,
        uint256 _adminFee,
        uint256 _callerFee,
        uint256 _maxReinvestStale,
        address _WAVAX,
        address _anchor,
        address _aUST,
        address _priceFeedAggregator
    ) public {
        initialize(_underlying,
                    _name,
                    _symbol,
                    _adminFee,
                    _callerFee,
                    _maxReinvestStale,
                    _WAVAX
                    );
    
        anchor = IAnchor(_anchor);
        aUST = IERC20(_aUST);
        priceFeed = IAggregatorV3(_priceFeedAggregator);

        underlying.approve(_anchor, MAX_INT);
        aUST.approve(_anchor, MAX_INT);
    }

    function generatedYield() public view returns (uint256) {
        uint256 underlyingBalance = IERC20(aUST).balanceOf(address(this));
        if (underlyingBalance < totalUnderlyingDeposits) {
            return 0;
        }
        return underlyingBalance - totalUnderlyingDeposits;
    }

    function receiptPerUnderlying() public view override returns (uint256) {
        if (totalSupply == 0) {
            return 10 ** (18 + 18 - underlyingDecimal);
        }
        (,int price,,,) = priceFeed.latestRoundData();
        return (1e18 * totalSupply) / (aUST.balanceOf(address(this)) * uint256(price) / 1e18);
    }

    function underlyingPerReceipt() public view override returns (uint256) {
        if (totalSupply == 0) {
            return 10 ** underlyingDecimal;
        }
        (,int price,,,) = priceFeed.latestRoundData();
        return 1e18 * (aUST.balanceOf(address(this)) * uint256(price) / 1e18) / totalSupply; 
    }

    function totalHoldings() public view override returns (uint256) {
        (,int price,,,) = priceFeed.latestRoundData();
        return aUST.balanceOf(address(this)) * uint256(price) / 1e18;
    }

    function _getValueOfUnderlyingPost() internal override returns (uint256) {
        (,int price,,,) = priceFeed.latestRoundData();
        return aUST.balanceOf(address(this)) * uint256(price) / 1e18;
    }
    
    function _triggerDepositAction(uint256 _amt) internal override {
        totalUnderlyingDeposits += _amt;
        anchor.depositStable(address(underlying), _amt);
    }

    function _triggerWithdrawAction(uint256 amtToReturn) internal override {
        totalUnderlyingDeposits -= amtToReturn;
        (,int price,,,) = priceFeed.latestRoundData();
        uint256 redeemAmount = (amtToReturn / uint256(price)) / 1e18;
        // console.log(amtToReturn, uint256(price));
        // console.log(redeemAmount, "redeem amount");
        anchor.redeemStable(address(aUST), redeemAmount);
    }
}
