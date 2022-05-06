// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

interface IAnchor {
    function depositStable(address token, uint256 amount) external;
    function redeemStable(address token, uint256 amount) external;
}