pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../core/erc1271/ERC1271.sol";
import "../core/erc165/AdaptiveERC165.sol";
import "../core/acl/ACL.sol";
import "./ITokenValueCalculator.sol";
import "./IAspisPool.sol";
import "../tokens/AspisGovernanceERC20.sol";
import "./AspisManager.sol";
import "./AspisConfiguration.sol";


contract AspisPool is IAspisPool, Initializable, UUPSUpgradeable, ACL, ERC1271, AdaptiveERC165, AspisConfiguration, AspisManager {

    using SafeERC20 for ERC20;
    using Address for address;
    using SafeMath for uint256;

    //Todo: Add fixed point math library (Critical)

    uint8 internal constant DECIMAL_PLACES = 2;
    uint256 public constant SUPPORTED_USD_DECIMALS = 4;

    // Roles
    bytes32 public constant UPGRADE_ROLE = keccak256("UPGRADE_ROLE");
    bytes32 public constant DAO_CONFIG_ROLE = keccak256("DAO_CONFIG_ROLE");
    bytes32 public constant EXEC_ROLE = keccak256("EXEC_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
    bytes32 public constant SET_SIGNATURE_VALIDATOR_ROLE = keccak256("SET_SIGNATURE_VALIDATOR_ROLE");
    bytes32 public constant MODIFY_TRUSTED_FORWARDER = keccak256("MODIFY_TRUSTED_FORWARDER");
    bytes32 public constant SET_GOVERNANCE_TOKEN = keccak256("SET_GOVERNANCE_TOKEN");


    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    string private constant ERROR_MINT_FAILED = "Minting the required LP_TOKENs has failed.";
    string private constant ERROR_BURN_FAILED = "Burning the required LP_TOKENs has failed.";
    string private constant ERROR_LOCKED = "The liquidity is locked.";
    string private constant ERROR_NOT_WHITELISTED = "Address not whitelisted.";
    string private constant ERROR_SOFT_CAP = "The total liquidity of the DAO doesn't fit the soft cap requirements.";
    string private constant ERROR_NO_PERMISSION = "You don't have the permission to call this function";
    string private constant ERROR_TOKEN_NO_INIT = "The token was not initialized.";
    string private constant ERROR_TOKEN_ALREADY_INIT = "The token was already initialized.";
    string private constant ERROR_PRICE_NOT_CORRECT = "The token price cannot be 0";

    ITokenValueCalculator public calculator;
    AspisGovernanceERC20 public token;

    bool internal isInitialised;

    ERC1271 signatureValidator;

    address internal _trustedForwarder;

    struct Deposit {
        uint256 price;
        uint256 amount;
    }

    mapping(address => uint256) private lockedUntil;
    mapping(address => uint256) private worthOfAsset;

    mapping(address => Deposit[]) private depositsOfUser;

    mapping(address => int256) private worthOfUserAsset; // why keep worth of asset

    event Test(uint256, uint256, uint256);

    // Error msg's
    /// @notice Thrown if action execution has failed
    error ActionFailed();

    /// @notice Thrown if the deposit or withdraw amount is zero
    error ZeroAmount();

    /// @notice Thrown if the expected and actually deposited ETH amount mismatch
    /// @param expected ETH amount
    /// @param actual ETH amount
    error ETHDepositAmountMismatch(uint256 expected, uint256 actual);

    /// @notice Thrown if an ETH withdraw fails
    error ETHWithdrawFailed();

    event SetTrustedForwarder(address _newForwarder);


    function initialize(
        bytes calldata _metadata,
        uint256[18] calldata _poolconfig,
        address[] calldata _whitelistUsers,
        address[] calldata _trustedProtocols,
        address[] calldata _supportedTokens,
        address[5] calldata _configurationAddresses
    ) external initializer {
        _registerStandard(ASPIS_INTERFACE_ID);
        _registerStandard(type(ERC1271).interfaceId);

        _setMetadata(_metadata);
        _setTrustedForwarder(_configurationAddresses[1]);
        _setAspisCalculator(_configurationAddresses[3]);
        _setGovernanceToken(_configurationAddresses[2]);
        _setInvestmentManager(_configurationAddresses[4]);
        _setConfiguration(_poolconfig, _whitelistUsers, _trustedProtocols, _supportedTokens);
        __ACL_init(_configurationAddresses[0]);
    }

     /// @dev Used to check the permissions within the upgradability pattern implementation of OZ
    function _authorizeUpgrade(address) internal virtual override auth(address(this), UPGRADE_ROLE) {}

    /// @notice set trusted forwarder on the DAO
    /// @param _forwarder address of the forwarder
    function setTrustedForwarder(address _forwarder) external auth(address(this), MODIFY_TRUSTED_FORWARDER) {
        _setTrustedForwarder(_forwarder);
    }

    /// @notice virtual function to get DAO's current trusted forwarder
    /// @return address trusted forwarder's address
    function trustedForwarder() public view virtual returns (address) {
        return _trustedForwarder;
    }

    /// @notice Checks if the current callee has the permissions for.
    /// @dev Wrapper for the willPerform method of ACL to later on be able to use it in the modifier of the sub components of this DAO.
    /// @param _where Which contract does get called
    /// @param _who Who is calling this method
    /// @param _role Which role is required to call this
    /// @param _data Additional data used in the ACLOracle
    function hasPermission(
        address _where,
        address _who,
        bytes32 _role,
        bytes memory _data
    ) external override returns (bool) {
        return willPerform(_where, _who, _role, _data);
    }

    /// @notice Update the DAO metadata
    /// @dev Sets a new IPFS hash
    /// @param _metadata The IPFS hash of the new metadata object
    function setMetadata(bytes calldata _metadata) external override auth(address(this), DAO_CONFIG_ROLE) {
        _setMetadata(_metadata);
    }

    /// @dev Fallback to handle future versions of the ERC165 standard.
    fallback() external {
        _handleCallback(msg.sig, msg.data); // WARN: does a low-level return, any code below would be unreacheable
    }

    /// @notice Setter to set the signature validator contract of ERC1271
    /// @param _signatureValidator ERC1271 SignatureValidator
    function setSignatureValidator(ERC1271 _signatureValidator)
        external
        auth(address(this), SET_SIGNATURE_VALIDATOR_ROLE)
    {
        signatureValidator = _signatureValidator;
    }

    /// @notice Method to validate the signature as described in ERC1271
    /// @param _hash Hash of the data to be signed
    /// @param _signature Signature byte array associated with _hash
    /// @return bytes4
    function isValidSignature(bytes32 _hash, bytes memory _signature) external view override returns (bytes4) {
        if (address(signatureValidator) == address(0)) return bytes4(0); // invalid magic number
        return signatureValidator.isValidSignature(_hash, _signature); // forward call to set validation contract
    }

    /// Private/Internal Functions

    function _setMetadata(bytes calldata _metadata) internal {
        emit SetMetadata(_metadata);
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;

        emit SetTrustedForwarder(_forwarder);
    }

    function _setAspisCalculator(address _calculator) internal {
        calculator = ITokenValueCalculator(_calculator);
    }

    function _setGovernanceToken(address _token) internal {
        token = AspisGovernanceERC20(_token);
    }

    function _setInvestmentManager(address _investmentManager) internal {
        updateManager(_investmentManager);
    }

    //Todo: Add setters for updating the pool configuration. Discuss about the permission and validators for the configuration parameters

    function deposit(
        address _token,
        uint256 _amount
    ) external payable override {

        if (_amount == 0) revert ZeroAmount();

        //Discuss: should we add hasWhitelist to pool configuration?
        if (configuration.hasWhitelist) {
            require(whitelistUsers[msg.sender], "User not whitelisted");
        }

        require(isFundraisingActive() == true, "Fundraing over or not started yet");

        uint256 _depositValue = calculator.convert(_token, _amount);

        require((_depositValue.div(10 ** SUPPORTED_USD_DECIMALS)) >= configuration.minDeposit, "minimum deposit error");
        require((_depositValue.div(10 ** SUPPORTED_USD_DECIMALS)) <= configuration.maxDeposit, "maximum deposit error");

        lockedUntil[msg.sender] = block.timestamp + (1 hours * configuration.lockLimit);

        uint256 _price = getCurrentTokenPrice();

        if(!isInitialised) {
            isInitialised = true;
        }

        if (_token == address(ETH)) {
            if (msg.value != _amount) revert ETHDepositAmountMismatch({expected: _amount, actual: msg.value});
        } else {
            if (msg.value != 0) revert ETHDepositAmountMismatch({expected: 0, actual: msg.value});
            
            ERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }

        worthOfAsset[_token] += _depositValue;
        
        uint256 _mintTokens = (_depositValue.div(_price)).mul(10 ** token.decimals());
        uint256 _fee = calculateEntranceFee(_mintTokens);

        //should we reduce the worth of user if we are already reducing the tokens as fee
        worthOfUserAsset[msg.sender] += int256(_depositValue);
        
        token.mint(msg.sender, _mintTokens.sub(_fee));
        increaseShadowBalance(_fee);

        depositsOfUser[msg.sender].push(Deposit(_price, _mintTokens.sub(_fee)));

        // emit Test(_price, _fee, _depositValue);

        emit Deposited(msg.sender, _token, _amount, '');

    }

    function withdraw(
        address[] calldata _tokens,
        address _to,
        uint256 _amount) external override {

        if (_amount == 0) revert ZeroAmount();
        require(token.balanceOf(msg.sender) >= _amount, "Insufficient balance");
        require(lockedUntil[msg.sender] < block.timestamp, "Assets currently locked");

        for (uint8 i = 0; i < _tokens.length; i++) {
            require(
                _tokens[i] != address(token),
                "Cannot use LP token"
            );
        }
        
        uint256 _LPTokenSupply = token.totalSupply() + shadowBalance;
        uint256 _currentLPTokenPrice = getCurrentTokenPrice();
        uint256 _performanceFee = 0;
        uint256 _rageQuitFee = checkWithdrawlWindow() ? 0: calculateRageQuitFee(_amount);

        Deposit[] memory _deposits = depositsOfUser[msg.sender];

        for(uint64 i = 0; i<_deposits.length; i++) {
            uint256 _tokenPrice = _deposits[i].price;
            uint256 _tokenAmount = _deposits[i].amount;

            _performanceFee += calculatePerformanceFee(_currentLPTokenPrice, _tokenPrice, _amount, _tokenAmount);
        }

        address previousToken;
        uint256 poolTokenBalance;

        //this wont work if user enter duplicate addresses 

        //burning with rage quit fee
        token.burn(msg.sender, _amount.sub(_performanceFee));
        increaseShadowBalance(_performanceFee);

        uint256 _userShare = _amount.sub(_performanceFee).sub(_rageQuitFee);

        for (uint8 i = 0; i < _tokens.length; i++) {
            require(
                _tokens[i] > previousToken,
                "tokens[] is out of order or contains a duplicate"
            );

            if (_tokens[i] == address(ETH)) {
                
                poolTokenBalance = address(this).balance;
                
                (bool ok, ) = _to.call{value: getProRataShare(poolTokenBalance, _userShare, _LPTokenSupply)}("");
                if (!ok) revert ETHWithdrawFailed();

            } else {

                poolTokenBalance = ERC20(_tokens[i]).balanceOf(address(this));

                ERC20(_tokens[i]).safeTransfer(_to, getProRataShare(poolTokenBalance, _userShare, _LPTokenSupply));
            }
            previousToken = _tokens[i];
        }

        emit Withdrawn(_to, _amount);
    }

    /// @notice If called, the list of provided actions will be executed.
    /// @dev It run a loop through the array of acctions and execute one by one.
    /// @dev If one acction fails, all will be reverted.
    /// @param _actions The aray of actions
    function execute(uint256 callId, Action[] memory _actions)
        external
        override
        auth(address(this), EXEC_ROLE)
        returns (bytes[] memory)
    {
        bytes[] memory execResults = new bytes[](_actions.length);

        for (uint256 i = 0; i < _actions.length; i++) {
            (bool success, bytes memory response) = _actions[i].to.call{value: _actions[i].value}(_actions[i].data);

            if (!success) revert ActionFailed();

            execResults[i] = response;
        }

        emit Executed(msg.sender, callId, _actions, execResults);

        return execResults;
    }

    function execute(address _target, uint256 _ethValue, bytes calldata _data)
        external // This function MUST always be external as the function performs a low level return, exiting the Agent app execution context
    {   
        require(msg.sender == _trustedForwarder, ERROR_NO_PERMISSION);

        require(trustedProtocols[_target] == true, ERROR_NOT_WHITELISTED);

        (bool result, ) = _target.call{value: _ethValue}(_data);

        if (result) {
            //emit Execute(msg.sender, _target, _ethValue, _data);
        }

        assembly {
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, returndatasize())

            // revert instead of invalid() bc if the underlying call failed with invalid() it already wasted gas.
            // if the call returned error data, forward it
            switch result case 0 { revert(ptr, returndatasize()) }
            default { return(ptr, returndatasize()) }
        }
    }

    function terminatePool() public {

    }

    function getCurrentTokenPrice() internal returns(uint256 _price) {
        if(!isInitialised) {
            _price = configuration.initialPrice;
        } else {
            _price = (getPoolValue()).div((token.totalSupply()).div(10 ** token.decimals()));
        }
    }

    function getPoolValue() internal returns (uint256 _poolValue) {
        for (uint64 i = 0; i < supportedTokens.length; i++) {
            _poolValue += calculator.convert(supportedTokens[i],ERC20(supportedTokens[i]).balanceOf(address(this)));
        }
    }

    function getProRataShare(uint256 _balance, uint256 _amount, uint256 _totalSupply) public pure returns(uint256) {
        return (_amount.mul(_balance)).div(_totalSupply);
    }

    function checkWithdrawlWindow() public view returns(bool) {

        uint256 _fundraisingFinishTime = configuration.finishTime;
        uint256 _currentTime = block.timestamp;

        if(_fundraisingFinishTime > _currentTime) {
            return false;
        }

        uint256 _countPastDays = (_currentTime.sub(_fundraisingFinishTime)).div(1 hours);

        uint256 _withdrawlWindow = configuration.withdrawlWindow;
        uint256 _freezePeriod = configuration.freezePeriod;

        uint256 _currentRelativeDay = _countPastDays.mod(_withdrawlWindow.add(_freezePeriod));

        if(_currentRelativeDay > 0) {

            if(_currentRelativeDay > _freezePeriod) {
                return true;
            } else {
                return false;
            }
        } else {

            if(_countPastDays > _freezePeriod) {
                return true;
            } else {
                return false;
            }
        }
    }

    function isFundraisingActive() public view returns(bool) {
        if(block.timestamp > configuration.startTime && configuration.finishTime > block.timestamp) {
            return true;
        }
    }
}
