/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity 0.8.10;

interface ITokenValueCalculator {
    //function calculateTotalLiquidity(address _account) external returns (uint256);
    function convert(address _token, uint256 _amount) external returns (uint256);
    function convertUSDToWei(address _token, uint256 _amount) external returns (uint256);
}
