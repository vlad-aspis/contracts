/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity 0.8.10;

import "../core/DAO.sol";
import "./AspisConfiguration.sol";
import "./ITokenValueCalculator.sol";

import "../votings/whitelist/WhitelistVoting.sol";

contract AspisPoolOld {

    // string private constant ERROR_MINT_FAILED = "Minting the required LP_TOKENs has failed.";
    // string private constant ERROR_BURN_FAILED = "Burning the required LP_TOKENs has failed.";
    // string private constant ERROR_LOCKED = "The liquidity is locked.";
    // string private constant ERROR_NOT_WHITELISTED = "Address not whitelisted.";
    // string private constant ERROR_SOFT_CAP = "The total liquidity of the DAO doesn't fit the soft cap requirements.";
    // string private constant ERROR_NO_PERMISSION = "You don't have the permission to call this function";
    // string private constant ERROR_TOKEN_NO_INIT = "The token was not initialized.";
    // string private constant ERROR_NO_PERMISSION = "This function can only be accessed by the DAO that it's bound to.";
    // string private constant ERROR_TOKEN_ALREADY_INIT = "The token was already initialized.";
    // string private constant ERROR_PRICE_NOT_CORRECT = "The token price cannot be 0";

    // address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;


    // using SafeERC20 for ERC20;
    // ITokenValueCalculator private calculator;
    // AspisConfiguration private configuration;
    // IMajorityVoting private voting;

    // address private configurator;
    // bool private configurated;
    // bool private hasWhitelist;
    // bool private isInitialised;

    // uint256 internal maxCap;
    // uint256 internal minInvestment;
    // uint256 internal maxInvestment;
    // uint256 internal startTime;
    // uint256 internal finishTime;
    // uint256 internal softCap;
    // uint256 internal lockLimit;
    // uint256 internal earlyLimit;
    // uint256 internal entranceFee;
    // uint256 internal txFee;
    // uint256 internal earlyExitFee;
    // uint256 internal spendingLimit;
    
    // mapping(address => bool) private whitelist;
    // mapping(address => bool) private trustedTransfers;
    // mapping(address => uint256) private lockedUntil;
    // mapping(address => uint256) private totalAssetsValue;
    // mapping(address => int256) private worthOf;

    // event WithdrawTokens(uint256, uint256, uint256, uint256, uint256);
    
    // constructor(address _configurator) {
    //     configurator = _configurator;
    // }

    // function getConfiguration() public view returns (AspisConfiguration) {
    //     return configuration;
    // }

    // function getCalculator() public view returns (ITokenValueCalculator) {
    //     return calculator;
    // }

    // function getVoting() public view returns (IMajorityVoting) {
    //     return voting;
    // }

    
    // function initConfig(
    //     AspisConfiguration _configuration,
    //     ITokenValueCalculator _calculator,
    //     IMajorityVoting _voting,
    //     address[] calldata _whiteListVoters,
    //     address[] calldata _trustedTransfers
    // ) external {
    //     if (configurated) {
    //         require(msg.sender == address(this));
    //     } else {
    //         require(tx.origin == configurator);
    //         configurated = true;
    //     }
    //     calculator = _calculator;
    //     configuration = _configuration;
    //     voting = _voting;
    //     hasWhitelist = _whiteListVoters.length > 0;
    
    //     for (uint64 i = 0; i < _whiteListVoters.length; i++) {
    //         whitelist[_whiteListVoters[i]] = true;
    //     }

    //      for (uint64 i = 0; i < _trustedTransfers.length; i++) {
    //         trustedTransfers[_trustedTransfers[i]] = true;
    //     }
    // }

    // function calculateTotalAssetsValue() public view returns (uint256) {
    //     uint256 _totalAssetsValue = 0;
    //     address[] memory _supportedTokens = calculator.supportedTokens();

    //     for (uint64 i = 0; i < _supportedTokens.length; i++) {
    //         _totalAssetsValue += totalAssetsValue[_supportedTokens[i]];
    //     }
    //     return _totalAssetsValue;
    // }

    // function deposit(
    //     address _token,
    //     uint256 _amount,
    //     string calldata _reference
    // ) external payable override {
    //     // TODO: Add ethereum 
    //     // TOOD: Include SafeMath
    //     // TOOD: refactor smart contracts
    //     uint256 _price;

    //     if (hasWhitelist) {
    //         require(whitelist[msg.sender], ERROR_NOT_WHITELISTED);
    //     }
        
    //     lockedUntil[msg.sender] = block.timestamp + (24 hours * configuration.getLockLimit());

    //     if(!isInitialised) {
    //         isInitialised = true;
    //         _price = configuration.getInitialPrice();
    //     } else {
    //         // TODO: Add a configuration on decimals
    //         _price = calculateTotalAssetsValue() / (configuration.getToken().totalSupply() / (10 ** 18));
    //     }

    //     if (_amount == 0) revert ZeroAmount();
    //     if (_token == address(0)) {
    //         if (msg.value != _amount) revert ETHDepositAmountMismatch({expected: _amount, actual: msg.value});
    //     } else {
    //         if (msg.value != 0) revert ETHDepositAmountMismatch({expected: 0, actual: msg.value});
    //         ERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    //     }

    //     uint256 _calcValue = calculator.convert(_token, _amount);
    //     totalAssetsValue[_token] += _calcValue;
    
    //     if (configuration.getMinInvestment() != 0) {
    //         require(_calcValue >= configuration.getMinInvestment());
    //     }

    //     if (configuration.getMaxInvestment() != 0) {
    //         require(_calcValue <= configuration.getMaxInvestment());
    //     }

    //     // TODO: Add a configuration on decimals
    //     uint256 _mintedTokenAmount = (_calcValue / _price) * (10 ** 18);
    //     uint256 _feeAmount = calculator.calculateFee(configuration.getEntranceFee(), _mintedTokenAmount);
    //     uint256 _subMintTokenAmount = _mintedTokenAmount - _feeAmount;

    //     //should we reduce the worth of user if we are already reducing the tokens as fee
    //     worthOf[msg.sender] += int256(_calcValue);
    
    //     configuration.getToken().mint(msg.sender, _subMintTokenAmount);
    //     configuration.getToken().mint(configuration.getGsnForwarded(), _feeAmount);

    //     emit Deposited(msg.sender, _token, _amount, _reference);
    // }

    // function addToWhitelist(address[] memory _voters) public {
    //     require(msg.sender == address(this));
    //     require(_voters.length > 0);
    //     for (uint64 i = 0; i < _voters.length; i++) {
    //         whitelist[_voters[i]] = true;
    //     }
    // }

    // function removeFromWhitelist(address[] memory _voters) public {
    //     require(msg.sender == address(this));
    //     require(_voters.length > 0);
    //     for (uint64 i = 0; i < _voters.length; i++) {
    //         whitelist[_voters[i]] = false;
    //     }
    // }

    // function setWhitelistStatus(bool _enabled) public {
    //     require(msg.sender == address(this));
    //     hasWhitelist = _enabled;
    // }

    // function addTrustedTransferAddresses(address[] memory _trustedAddresses) public {
    //     require(msg.sender == address(this));
    //     for (uint64 i = 0; i < _trustedAddresses.length; i++) {
    //         trustedTransfers[_trustedAddresses[i]] = true;
    //     }
    // }

    // function removeTrustedTransferAddresses(address[] memory _trustedAddresses) public {
    //     require(msg.sender == address(this));
    //     for (uint64 i = 0; i < _trustedAddresses.length; i++) {
    //         trustedTransfers[_trustedAddresses[i]] = false;
    //     }
    // }

    // function transferTo(
    //     address _token,
    //     address _to,
    //     uint256 _amount,
    //     string memory _reference
    // ) public {
    //     require(msg.sender == _trustedForwarder);
    //     require(trustedTransfers[_to]);

    //     if (_amount == 0) revert ZeroAmount();

    //     if (_token == address(0)) {
    //         (bool ok, ) = _to.call{value: _amount}("");
    //         if (!ok) revert ETHWithdrawFailed();
    //     } else {
    //         ERC20(_token).safeTransfer(_to, _amount);
    //     }

    //     emit Withdrawn(_token, _to, _amount, _reference);
    // }

    // function withdraw(
    //     address _token,
    //     address _to,
    //     uint256 _amount,
    //     string memory _reference) external override {

    //         _token;
    //         _to;
    //         _reference;
        
    //     require(configuration.getToken().balanceOf(msg.sender) >= _amount, "Insufficient balance");

    //     require(lockedUntil[msg.sender] < block.timestamp, ERROR_LOCKED);

    //     uint256 _LPTokenSupply = configuration.getToken().totalSupply();

    //     uint256 currentPoolLiquidityValue = calculator.calculateTotalLiquidity(address(this));

    //     require(currentPoolLiquidityValue > configuration.getSoftCap(), ERROR_SOFT_CAP);
        
    //     uint256 _fee = 0;

    //     if (block.timestamp < configuration.getEarlyLimit()) {
    //         _fee += (_amount * configuration.getEarlyExitFee()) / 100;
    //     }

    //     uint256 pooledAssetsValue = calculateTotalAssetsValue();

    //     uint256 profit = currentPoolLiquidityValue - pooledAssetsValue;

    //     uint256 _price = pooledAssetsValue / (_LPTokenSupply / (10 ** 18));

    //     if(profit > 0) {
    //         //performance fee
    //         _fee += (configuration.getTxFee() * (profit / _price) * (10 ** 18))/ 1000;
    //     }

    //     //  //multiplying by thousand to handle the decimals
    //     uint256 _userShare = ((_amount - _fee) * 1000) / _LPTokenSupply;
        
    //     uint256 _userValue = _amount * _price / (10**18);
    //     //needs to be calculated using the LP token price
    //     worthOf[msg.sender] -= int256(_userValue);
    //     //deduct the withdraw fees
    //     //transfer tokens by using the current price of token
    //     address[] memory _supportedTokens = calculator.supportedTokens();

    //     for (uint64 i = 0; i < _supportedTokens.length; i++) {
            
    //         uint256 _tokenBalance = ERC20(_supportedTokens[i]).balanceOf(address(this));

    //         uint256 _amountToTransfer = (_userShare * _tokenBalance) / 1000;

    //         uint256 _calcValue = calculator.convert(_supportedTokens[i], _amountToTransfer);
    //         totalAssetsValue[_supportedTokens[i]] -= _calcValue;

    //         ERC20(_supportedTokens[i]).safeTransfer(msg.sender, _amountToTransfer);
            
    //     }

    //     configuration.getToken().burn(msg.sender, _amount);
    //     configuration.getToken().mint(_trustedForwarder, uint256(_fee));

    //     emit WithdrawTokens(_LPTokenSupply, currentPoolLiquidityValue, _fee, pooledAssetsValue, _userShare);
    // }

   
    // function execute(address _target, uint256 _ethValue, bytes calldata _data)
    //     external // This function MUST always be external as the function performs a low level return, exiting the Agent app execution context
    // {   
    //     require(msg.sender == configuration.getGsnForwarded(), ERROR_NO_PERMISSION);

    //     require(trustedTransfers[_target] == true, ERROR_NOT_WHITELISTED);

    //     (bool result, ) = _target.call{value: _ethValue}(_data);

    //     if (result) {
    //         //emit Execute(msg.sender, _target, _ethValue, _data);
    //     }

    //     assembly {
    //         let ptr := mload(0x40)
    //         returndatacopy(ptr, 0, returndatasize())

    //         // revert instead of invalid() bc if the underlying call failed with invalid() it already wasted gas.
    //         // if the call returned error data, forward it
    //         switch result case 0 { revert(ptr, returndatasize()) }
    //         default { return(ptr, returndatasize()) }
    //     }
    // }

}
