/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity 0.8.10;
import "../registry/Registry.sol";
import "./ITokenValueCalculator.sol";
import "./libs/AspisVotingCreatorLibrary.sol";
import "./libs/AspisPoolCreatorLibrary.sol";
import "./libs/AspisPoolConfigurationLibrary.sol";

contract AspisPoolFactory {
    Registry public registry;

    constructor(Registry _registry) {
        registry = _registry;
    }

    event DAOCreated(string name, address indexed token, address indexed voting);

    function newPool(
        AspisPoolCreatorLibrary.DAOConfig calldata _daoConfig,
        AspisVotingCreatorLibrary.VoteConfig calldata _voteConfig,
        address[] calldata _whitelistVoters,
        address[] calldata _trustedTransfers,
        address _gsnForwarder
    ) external returns (
        AspisPool pool,
        IMajorityVoting voting
    ) {
        pool = AspisPoolCreatorLibrary.createPool(_daoConfig, _gsnForwarder, address(this));

        AspisConfiguration configuration = AspisPoolConfigurationLibrary.configuratePool(_daoConfig, pool, _gsnForwarder);
        voting = AspisVotingCreatorLibrary.createERC20Voting(
            pool,
            _voteConfig,
            address(this),
            configuration.getToken()
        );
        pool.initConfig(configuration, _daoConfig.calculator, voting, _whitelistVoters, _trustedTransfers);
        address tokenAddress = address(configuration.getToken());
        registry.register(_daoConfig.pool.name, pool, msg.sender, tokenAddress);
        emit DAOCreated(_daoConfig.pool.name, tokenAddress, address(voting));
    }
}
