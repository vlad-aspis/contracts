/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity 0.8.10;

interface ITokenValueCalculator {
    function calculateFee(uint256 _fee, uint256 _value) external pure returns (uint256);
    function calculateTotalLiquidity(address _account) external returns (uint256);
    function convert(address _token, uint256 _amount) external returns (uint256);
    function convertUSDToWei(address _token, uint256 _amount) external returns (uint256);
    function supportedTokens() external view returns (address[] memory);
}
