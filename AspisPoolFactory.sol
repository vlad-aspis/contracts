/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity 0.8.10;

import "./AspisPool.sol";
import "../utils/Proxy.sol";
import "../registry/AspisRegistry.sol";
import "./ITokenValueCalculator.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./../votings/ERC20/ERC20Voting.sol";
import "../tokens/AspisGovernanceERC20.sol";


contract AspisPoolFactory {

    using Address for address;
    using Clones for address;

    address public erc20VotingBase;
    address public daoBase;

    AspisRegistry public registry;
    address public calculator;

    struct VoteConfig {
        uint64 quorum;
        uint64 minimalApproval;
        uint64 minDuration;
        uint256 minLPTokenShare; //Percentage (not used in voting contract, check how to do that)
    }

    struct AspisPoolConfig {
        uint256[18] poolConfig;
        string name;
        string symbol;
        bytes metadata;
        address gsnForwarder;
    }

    constructor(AspisRegistry _registry, address _calculator) {
        registry = _registry;
        calculator = _calculator;
        setupBases();
    }

    event DAOCreated(address pool, string name, address indexed token, address indexed voting);

    function newERC20AspisPoolDAO(
        AspisPoolConfig calldata _aspisPoolConfig,
        uint64[4] calldata _voteConfig,
        address[] calldata _whitelistVoters,
        address[] calldata _trustedTransfers,
        address[] calldata _supportedTokens) external returns(AspisPool _pool, ERC20Voting _voting, AspisGovernanceERC20 _token) {
        
        _pool = AspisPool(createProxy(daoBase, bytes("")));

        _token = new AspisGovernanceERC20();

        _token.initialize(_pool, _aspisPoolConfig.name, _aspisPoolConfig.symbol);

        createDAO(_aspisPoolConfig,_whitelistVoters,_trustedTransfers, _supportedTokens, _pool, address(_token));

        _pool.grant(address(_token), address(_pool), _token.TOKEN_MINTER_ROLE());
        
        registry.register(_aspisPoolConfig.name, _pool, msg.sender, address(_token));

        _voting = createERC20Voting(
            _pool,
             _token,
            _voteConfig
        );

        _pool.setVotingAddress(address(_voting));

        setDAOPermissions(_pool, address(_voting));

        emit DAOCreated(address(_pool), _aspisPoolConfig.name, address(_token), address(_voting));
    }


    function createDAO(
        AspisPoolConfig calldata _aspisPoolConfig, 
        address[] memory _whitelistVoters,
        address[] memory _trustedTransfers,
        address[] memory _supportedTokens,
        AspisPool _pool,
        address _token) internal  {
        
        _pool.initialize(_aspisPoolConfig.metadata, _aspisPoolConfig.poolConfig, _whitelistVoters, _trustedTransfers, 
                        _supportedTokens, [address(this), _aspisPoolConfig.gsnForwarder, _token, calculator, msg.sender]);
        
    }

    /// @dev internal helper method to create ERC20Voting
    function createERC20Voting(
        AspisPool _dao, 
        AspisGovernanceERC20 _token, 
        uint64[4] calldata _voteConfig
    ) internal returns (ERC20Voting erc20Voting) {
        erc20Voting = ERC20Voting(
            createProxy(
                erc20VotingBase,
                abi.encodeWithSelector(
                    ERC20Voting.initialize.selector,
                    _dao,
                    _dao.trustedForwarder(),
                    _voteConfig[0],
                    _voteConfig[1],
                    _voteConfig[2],
                    _token
                )
            )
        );

        // Grant dao the necessary permissions for ERC20Voting
        ACLData.BulkItem[] memory items = new ACLData.BulkItem[](3);
        items[0] = ACLData.BulkItem(ACLData.BulkOp.Grant, erc20Voting.UPGRADE_ROLE(), address(_dao));
        items[1] = ACLData.BulkItem(ACLData.BulkOp.Grant, erc20Voting.MODIFY_VOTE_CONFIG(), address(_dao));
        items[2] = ACLData.BulkItem(ACLData.BulkOp.Grant, erc20Voting.MODIFY_TRUSTED_FORWARDER(), address(_dao));

        _dao.bulk(address(erc20Voting), items);

    }

    function setDAOPermissions(
        AspisPool _dao,
        address _voting
    ) internal {
        
        ACLData.BulkItem[] memory items = new ACLData.BulkItem[](8);

        items[0] = ACLData.BulkItem(ACLData.BulkOp.Grant, _dao.DAO_CONFIG_ROLE(), address(_dao));
        items[1] = ACLData.BulkItem(ACLData.BulkOp.Grant, _dao.WITHDRAW_ROLE(), address(_dao));
        items[ 2] = ACLData.BulkItem(ACLData.BulkOp.Grant, _dao.UPGRADE_ROLE(), address(_dao));
        items[3] = ACLData.BulkItem(ACLData.BulkOp.Grant, _dao.ROOT_ROLE(), address(_dao));
        items[4] = ACLData.BulkItem(ACLData.BulkOp.Grant, _dao.SET_SIGNATURE_VALIDATOR_ROLE(), address(_dao));
        items[5] = ACLData.BulkItem(ACLData.BulkOp.Grant, _dao.MODIFY_TRUSTED_FORWARDER(), address(_dao));
        items[6] = ACLData.BulkItem(ACLData.BulkOp.Grant, _dao.EXEC_ROLE(), _voting);
        
        items[7] = ACLData.BulkItem(ACLData.BulkOp.Revoke, _dao.ROOT_ROLE(), address(this));
        
        _dao.bulk(address(_dao), items);
    }

    function setupBases() private {
        erc20VotingBase = address(new ERC20Voting());
        daoBase = address(new AspisPool());
    }
}
