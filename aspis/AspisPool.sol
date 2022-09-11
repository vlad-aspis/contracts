/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity 0.8.10;

import "../core/DAO.sol";
import "./AspisConfiguration.sol";
import "./ITokenValueCalculator.sol";

import "../votings/whitelist/WhitelistVoting.sol";

contract AspisPool is DAO {
    string private constant ERROR_MINT_FAILED = "Minting the required LP_TOKENs has failed.";
    string private constant ERROR_BURN_FAILED = "Burning the required LP_TOKENs has failed.";
    string private constant ERROR_LOCKED = "The liquidity is locked.";
    string private constant ERROR_NOT_WHITELISTED = "Address not whitelisted.";
    string private constant ERROR_SOFT_CAP = "The total liquidity of the DAO doesn't fit the soft cap requirements.";
    string private constant ERROR_NO_PERMISSION = "You don't have the permission to call this function";

    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;


    using SafeERC20 for ERC20;
    ITokenValueCalculator private calculator;
    AspisConfiguration private configuration;
    IMajorityVoting private voting;

    address private configurator;
    bool private configurated;
    bool private hasWhitelist;
    bool private isInitialised;
    
    mapping(address => bool) private whitelist;
    mapping(address => bool) private trustedTransfers;
    mapping(address => uint256) private lockedUntil;
    mapping(address => uint256) private totalAssetsValue;
    mapping(address => int256) private worthOf;
    
    constructor(address _configurator) {
        configurator = _configurator;
    }

    function getConfiguration() public view returns (AspisConfiguration) {
        return configuration;
    }

    function getCalculator() public view returns (ITokenValueCalculator) {
        return calculator;
    }

    function getVoting() public view returns (IMajorityVoting) {
        return voting;
    }

    function initConfig(
        AspisConfiguration _configuration,
        ITokenValueCalculator _calculator,
        IMajorityVoting _voting,
        address[] calldata _whiteListVoters,
        address[] calldata _trustedTransfers
    ) external {
        if (configurated) {
            require(msg.sender == address(this));
        } else {
            require(tx.origin == configurator);
            configurated = true;
        }
        calculator = _calculator;
        configuration = _configuration;
        voting = _voting;
        hasWhitelist = _whiteListVoters.length > 0;
    
        for (uint64 i = 0; i < _whiteListVoters.length; i++) {
            whitelist[_whiteListVoters[i]] = true;
        }

         for (uint64 i = 0; i < _trustedTransfers.length; i++) {
            trustedTransfers[_trustedTransfers[i]] = true;
        }
    }

    function calculateTotalAssetsValue() public view returns (uint256) {
        uint256 _totalAssetsValue = 0;
        address[] memory _supportedTokens = calculator.supportedTokens();

        for (uint64 i = 0; i < _supportedTokens.length; i++) {
            _totalAssetsValue += totalAssetsValue[_supportedTokens[i]];
        }
        return _totalAssetsValue;
    }

    function deposit(
        address _token,
        uint256 _amount,
        string calldata _reference
    ) external payable override {
        // TODO: Add ethereum 
        // TOOD: Include SafeMath
        // TOOD: refactor smart contracts
        uint256 _price;

        if (hasWhitelist) {
            require(whitelist[msg.sender], ERROR_NOT_WHITELISTED);
        }
        
        lockedUntil[msg.sender] = block.timestamp + (24 hours * configuration.getLockLimit());

        if(!isInitialised) {
            isInitialised = true;
            _price = configuration.getInitialPrice();
        } else {
            // TODO: Add a configuration on decimals
            _price = calculateTotalAssetsValue() / (configuration.getToken().totalSupply() / (10 ** 18));
        }

        if (_amount == 0) revert ZeroAmount();
        if (_token == address(0)) {
            if (msg.value != _amount) revert ETHDepositAmountMismatch({expected: _amount, actual: msg.value});
        } else {
            if (msg.value != 0) revert ETHDepositAmountMismatch({expected: 0, actual: msg.value});
            ERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }

        uint256 _calcValue = calculator.convert(_token, _amount);
        totalAssetsValue[_token] += _calcValue;
    
        if (configuration.getMinInvestment() != 0) {
            require(_calcValue >= configuration.getMinInvestment());
        }

        if (configuration.getMaxInvestment() != 0) {
            require(_calcValue <= configuration.getMaxInvestment());
        }

        // TODO: Add a configuration on decimals
        uint256 _mintedTokenAmount = (_calcValue / _price) * (10 ** 18);
        uint256 _feeAmount = calculator.calculateFee(configuration.getEntranceFee(), _mintedTokenAmount);
        uint256 _subMintTokenAmount = _mintedTokenAmount - _feeAmount;
    
        worthOf[msg.sender] += int256(_calcValue);
    
        configuration.getToken().mint(msg.sender, _subMintTokenAmount);
        configuration.getToken().mint(configuration.getGsnForwarded(), _feeAmount);

        emit Deposited(msg.sender, _token, _amount, _reference);
    }

    function addToWhitelist(address[] memory _voters) public {
        require(msg.sender == address(this));
        require(_voters.length > 0);
        for (uint64 i = 0; i < _voters.length; i++) {
            whitelist[_voters[i]] = true;
        }
    }

    function removeFromWhitelist(address[] memory _voters) public {
        require(msg.sender == address(this));
        require(_voters.length > 0);
        for (uint64 i = 0; i < _voters.length; i++) {
            whitelist[_voters[i]] = false;
        }
    }

    function setWhitelistStatus(bool _enabled) public {
        require(msg.sender == address(this));
        hasWhitelist = _enabled;
    }

    function addTrustedTransferAddresses(address[] memory _trustedAddresses) public {
        require(msg.sender == address(this));
        for (uint64 i = 0; i < _trustedAddresses.length; i++) {
            trustedTransfers[_trustedAddresses[i]] = true;
        }
    }

    function removeTrustedTransferAddresses(address[] memory _trustedAddresses) public {
        require(msg.sender == address(this));
        for (uint64 i = 0; i < _trustedAddresses.length; i++) {
            trustedTransfers[_trustedAddresses[i]] = false;
        }
    }

    function transferTo(
        address _token,
        address _to,
        uint256 _amount,
        string memory _reference
    ) public {
        require(msg.sender == _trustedForwarder);
        require(trustedTransfers[_to]);

        if (_amount == 0) revert ZeroAmount();

        if (_token == address(0)) {
            (bool ok, ) = _to.call{value: _amount}("");
            if (!ok) revert ETHWithdrawFailed();
        } else {
            ERC20(_token).safeTransfer(_to, _amount);
        }

        emit Withdrawn(_token, _to, _amount, _reference);
    }

    function withdraw(uint256 _amount) external {
        
        require(configuration.getToken().balanceOf(msg.sender) >= _amount, "Insufficient balance");

        require(lockedUntil[msg.sender] < block.timestamp, ERROR_LOCKED);

        uint256 currentPoolLiquidityValue = calculator.calculateTotalLiquidity(address(this));

        require(currentPoolLiquidityValue > configuration.getSoftCap(), ERROR_SOFT_CAP);
        
        uint256 _fee = 0;

        if (block.timestamp < configuration.getEarlyLimit()) {
            _fee += (_amount * configuration.getEarlyExitFee()) / 100;
        }

        uint256 pooledAssetsValue = calculateTotalAssetsValue();

        uint256 profit = currentPoolLiquidityValue - pooledAssetsValue;

        uint256 currentLPTokenPrice = pooledAssetsValue / (configuration.getToken().totalSupply() / (10 ** 18));

        uint256 currentWithdrawValue = ((_amount - _fee) / (10 ** 18)) * currentLPTokenPrice;

         if(profit > 0) {
            //performance fee
            _fee += (configuration.getTxFee() * (profit / currentLPTokenPrice) * (10 ** 18))/ 1000;
        }

        //user pro rata share
        // (10/100) * (200 USD) = 20 USD
        uint256 _userValue = (currentWithdrawValue * currentPoolLiquidityValue) / pooledAssetsValue;
        
        worthOf[msg.sender] -= int256(_userValue);
        //deduct the withdraw fees
        //transfer tokens by using the current price of token
        address[] memory _supportedTokens = calculator.supportedTokens();

        for (uint64 i = 0; i < _supportedTokens.length; i++) {
            uint256 _tokenValue = calculator.convert(_supportedTokens[i],ERC20(_supportedTokens[i]).balanceOf(address(this)));
            if(_tokenValue > _userValue) {
                
                transferTokens(_supportedTokens[i], msg.sender, _userValue);
                _userValue = 0;
                totalAssetsValue[_supportedTokens[i]] -= _userValue;

            } else {
                transferTokens(_supportedTokens[i], msg.sender, _tokenValue);
                _userValue -= _tokenValue;
                totalAssetsValue[_supportedTokens[i]] -= _tokenValue;
            }
        }

        configuration.getToken().burn(msg.sender, _amount);
        configuration.getToken().mint(_trustedForwarder, uint256(_fee));
    }

    function transferTokens(address _token, address _receiver, uint256 _value) internal {

        uint256 _amount = calculator.convertUSDToWei(_token, _value);

        ERC20(_token).safeTransfer(_receiver, _amount);
    }
}
