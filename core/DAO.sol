/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./erc1271/ERC1271.sol";
import "./erc165/AdaptiveERC165.sol";
import "./acl/ACL.sol";
import "./IDAO.sol";

/// @title The public interface of the Aragon DAO framework.
/// @author Samuel Furter - Aragon Association - 2021
/// @notice This contract is the entry point to the Aragon DAO framework and provides our users a simple and use to use public interface.
/// @dev Public API of the Aragon DAO framework
contract DAO is IDAO, Initializable, UUPSUpgradeable, ACL, ERC1271, AdaptiveERC165 {
    using SafeERC20 for ERC20;
    using Address for address;

    // Roles
    bytes32 public constant UPGRADE_ROLE = keccak256("UPGRADE_ROLE");
    bytes32 public constant DAO_CONFIG_ROLE = keccak256("DAO_CONFIG_ROLE");
    bytes32 public constant EXEC_ROLE = keccak256("EXEC_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
    bytes32 public constant SET_SIGNATURE_VALIDATOR_ROLE = keccak256("SET_SIGNATURE_VALIDATOR_ROLE");
    bytes32 public constant MODIFY_TRUSTED_FORWARDER = keccak256("MODIFY_TRUSTED_FORWARDER");

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

    ERC1271 signatureValidator;

    address internal _trustedForwarder;

    /// @dev Used for UUPS upgradability pattern
    /// @param _metadata IPFS hash that points to all the metadata (logo, description, tags, etc.) of a DAO
    function initialize(
        bytes calldata _metadata,
        address _initialOwner,
        address _forwarder
    ) external initializer {
        _registerStandard(DAO_INTERFACE_ID);
        _registerStandard(type(ERC1271).interfaceId);

        _setMetadata(_metadata);
        _setTrustedForwarder(_forwarder);
        __ACL_init(_initialOwner);
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

    /// @dev Emit ETHDeposited event to track ETH deposits that weren't done over the deposit method.
    receive() external payable {
        emit ETHDeposited(msg.sender, msg.value);
    }

    /// @dev Fallback to handle future versions of the ERC165 standard.
    fallback() external {
        _handleCallback(msg.sig, msg.data); // WARN: does a low-level return, any code below would be unreacheable
    }

    /// @notice Deposit ETH or any token to this contract with a reference string
    /// @dev Deposit ETH (token address == 0) or any token with a reference
    /// @param _token The address of the token and in case of ETH address(0)
    /// @param _amount The amount of tokens to deposit
    /// @param _reference The deposit reference describing the reason of it
    function deposit(
        address _token,
        uint256 _amount,
        string calldata _reference
    ) external payable virtual override {
        if (_amount == 0) revert ZeroAmount();

        if (_token == address(0)) {
            if (msg.value != _amount) revert ETHDepositAmountMismatch({expected: _amount, actual: msg.value});
        } else {
            if (msg.value != 0) revert ETHDepositAmountMismatch({expected: 0, actual: msg.value});

            ERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }

        emit Deposited(msg.sender, _token, _amount, _reference);
    }

    /// @notice Withdraw tokens or ETH from the DAO with a withdraw reference string
    /// @param _token The address of the token and in case of ETH address(0)
    /// @param _to The target address to send tokens or ETH
    /// @param _amount The amount of tokens to deposit
    /// @param _reference The deposit reference describing the reason of it
    function withdraw(
        address _token,
        address _to,
        uint256 _amount,
        string memory _reference
    ) external virtual override auth(address(this), WITHDRAW_ROLE) {
        if (_amount == 0) revert ZeroAmount();

        if (_token == address(0)) {
            (bool ok, ) = _to.call{value: _amount}("");
            if (!ok) revert ETHWithdrawFailed();
        } else {
            ERC20(_token).safeTransfer(_to, _amount);
        }

        emit Withdrawn(_token, _to, _amount, _reference);
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
}
