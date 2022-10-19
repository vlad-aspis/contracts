/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity 0.8.10;

import "./ITokenValueCalculator.sol";
import "./IAggregator.sol";
import "../core/DAO.sol";

struct DataFeed {
    address erc20ContractAddress;
    address dataFeedAddress;
    uint256 decimals;
}

contract AspisLiquidityCalculator is ITokenValueCalculator {
    using SafeERC20 for ERC20;

    mapping(address => bytes32) _dataFeeds;

    uint256 public constant SUPPORTED_USD_DECIMALS = 4;

    // address[] _tokens;
    IAggregator _lpQuote; //can be made immutable

    //optimisation possibl
    //does datafeeds needs to be updated later?
    constructor(DataFeed [] memory dataFeeds, IAggregator quote) {
        _lpQuote = quote;
        for(uint64 i = 0; i < dataFeeds.length; i++) {
            _dataFeeds[dataFeeds[i].erc20ContractAddress] = bytes32(bytes20(dataFeeds[i].dataFeedAddress)) | bytes32(uint256(dataFeeds[i].decimals));
            //_tokens.push(dataFeeds[i].erc20ContractAddress);
        }
    }

    function getDerivedPrice(address _base, address _quote, uint8 _decimals)
        public
        view
        returns (int256, uint8)
    {
        require(_decimals > uint8(0) && _decimals <= uint8(18), "Invalid _decimals");
        
        int256 decimals = int256(10 ** uint256(_decimals));
        
        ( , int256 basePrice, , , ) = IAggregator(_base).latestRoundData();
        uint8 baseDecimals = IAggregator(_base).decimals();
        
        basePrice = scalePrice(basePrice, baseDecimals, _decimals);

        ( , int256 quotePrice, , , ) = IAggregator(_quote).latestRoundData();
        uint8 quoteDecimals = IAggregator(_quote).decimals();
        
        quotePrice = scalePrice(quotePrice, quoteDecimals, _decimals);

        return (basePrice * decimals / quotePrice, _decimals);
    }

    function getPrice(address _base, uint8 _decimals)
        public
        view
        returns (int256, uint8)
    {
        require(_decimals > uint8(0) && _decimals <= uint8(18), "Invalid _decimals");
        
        int256 decimals = int256(10 ** uint256(_decimals));
        
        ( , int256 basePrice, , , ) = IAggregator(_base).latestRoundData();
        uint8 baseDecimals = IAggregator(_base).decimals();
        
        // basePrice = scalePrice(basePrice, baseDecimals, _decimals);

        return (basePrice, baseDecimals);
    }

    function scalePrice(int256 _price, uint8 _priceDecimals, uint8 _decimals)
        internal
        pure
        returns (int256)
    {
        if (_priceDecimals < _decimals) {
            return _price * int256(10 ** uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10 ** uint256(_priceDecimals - _decimals));
        }
        return _price;
    }


    //add decimal places for the tokens (usdc and usdt have 6 decimal places)
    function convert(address _token, uint256 _amount) public view returns (uint256) {
        address datafeed = address(bytes20(_dataFeeds[_token]));
        uint8 _decimals = uint8(uint96(uint256(_dataFeeds[_token])));

        require(datafeed != address(0), "This token is not supported"); 

        (int256 _price, uint8 decimals) =  getPrice(datafeed, _decimals);

        return (_amount * uint256(_price)) /(10 ** (decimals + _decimals - SUPPORTED_USD_DECIMALS));
    }

    function convertUSDToWei(address _token, uint256 _amount) public view returns (uint256) {
        address datafeed = address(bytes20(_dataFeeds[_token]));
        uint8 _decimals = uint8(uint96(uint256(_dataFeeds[_token])));

        require(datafeed != address(0), "This token is not supported"); 

        (int256 _price, uint8 decimals) =  getDerivedPrice(datafeed, address(_lpQuote), 18);

        return _amount * (10 ** (decimals + _decimals)) / uint256(_price);
    }

}
