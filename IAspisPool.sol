pragma solidity 0.8.10;


abstract contract IAspisPool {
    
    bytes4 internal constant ASPIS_INTERFACE_ID = type(IAspisPool).interfaceId;

    struct Action {
        address to; // Address to call.
        uint256 value; // Value to be sent with the call. for example (ETH)
        bytes data; // FuncSig + arguments
    }

    /// @dev Required to handle the permissions within the whole DAO framework accordingly
    /// @param _where The address of the contract
    /// @param _who The address of a EOA or contract to give the permissions
    /// @param _role The hash of the role identifier
    /// @param _data The optional data passed to the ACLOracle registered.
    /// @return bool
    function hasPermission(
        address _where,
        address _who,
        bytes32 _role,
        bytes memory _data
    ) external virtual returns (bool);

    /// @notice Update the DAO metadata
    /// @dev Sets a new IPFS hash
    /// @param _metadata The IPFS hash of the new metadata object
    function setMetadata(bytes calldata _metadata) external virtual;

    event SetMetadata(bytes metadata);

    /// @notice If called, the list of provided actions will be executed.
    /// @dev It run a loop through the array of acctions and execute one by one.
    /// @dev If one acction fails, all will be reverted.
    /// @param _actions The aray of actions
    function execute(uint256 callId, Action[] memory _actions) external virtual returns (bytes[] memory);

    event Executed(address indexed actor, uint256 callId, Action[] actions, bytes[] execResults);

    /// @notice Deposit ETH or any token to this contract with a reference string
    /// @dev Deposit ETH (token address == 0) or any token with a reference
    /// @param _token The address of the token and in case of ETH address(0)
    /// @param _amount The amount of tokens to deposit
    function deposit(
        address _token,
        uint256 _amount
    ) external payable virtual;

    event Deposited(address indexed sender, address indexed token, uint256 amount, string _reference);
    // ETHDeposited and Deposited are both needed. ETHDeposited makes sure that whoever sends funds
    // with `send/transfer`, receive function can still be executed without reverting due to gas cost
    // increases in EIP-2929. To still use `send/transfer`, access list is needed that has the address
    // of the contract(base contract) that is behind the proxy.
    event ETHDeposited(address sender, uint256 amount);

    /// @notice Withdraw tokens or ETH from the DAO with a withdraw reference string
    /// @param _token The address of the token and in case of ETH address(0)
    /// @param _to The target address to send tokens or ETH
    /// @param _amount The amount of tokens to deposit
    function withdraw(
        address[] calldata _token,
        address _to,
        uint256 _amount
    ) external virtual;

    event Withdrawn(address indexed to, uint256 amount);
}
