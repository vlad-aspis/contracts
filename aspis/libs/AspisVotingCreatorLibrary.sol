/*
 * SPDX-License-Identifier:    MIT
 */
pragma solidity 0.8.10;
import "./../AspisPool.sol";
import "./../../votings/ERC20/ERC20Voting.sol";

library AspisVotingCreatorLibrary {
    struct VoteConfig {
        uint64 participationRequiredPct;
        uint64 supportRequiredPct;
        uint64 minDuration;
    }

    function createERC20Voting(
        DAO _dao,
        VoteConfig calldata _voteConfig,
        address _factory,
        GovernanceERC20 _token
    ) public returns (ERC20Voting erc20Voting) {
        erc20Voting = new ERC20Voting();

        erc20Voting.initialize(
            _dao,
            _dao.trustedForwarder(),
            _voteConfig.participationRequiredPct,
            _voteConfig.supportRequiredPct,
            _voteConfig.minDuration,
            _token
        );

        ACLData.BulkItem[] memory items = new ACLData.BulkItem[](3);
        items[0] = ACLData.BulkItem(ACLData.BulkOp.Grant, erc20Voting.UPGRADE_ROLE(), address(_dao));
        items[1] = ACLData.BulkItem(ACLData.BulkOp.Grant, erc20Voting.MODIFY_VOTE_CONFIG(), address(_dao));
        items[2] = ACLData.BulkItem(ACLData.BulkOp.Grant, erc20Voting.MODIFY_TRUSTED_FORWARDER(), address(_dao));
        _dao.bulk(address(erc20Voting), items);

        setDAOPermissions(_dao, address(erc20Voting), _factory, _token);
    }

    function setDAOPermissions(
        DAO _dao,
        address _voting,
        address _factory,
        GovernanceERC20 _token
    ) internal {
        _dao.grant(address(_token), address(_dao), _token.TOKEN_MINTER_ROLE());
        ACLData.BulkItem[] memory items = new ACLData.BulkItem[](9);
        items[0] = ACLData.BulkItem(ACLData.BulkOp.Grant, _dao.DAO_CONFIG_ROLE(), address(_dao));
        items[1] = ACLData.BulkItem(ACLData.BulkOp.Grant, _dao.WITHDRAW_ROLE(), address(_dao));
        items[2] = ACLData.BulkItem(ACLData.BulkOp.Grant, _dao.UPGRADE_ROLE(), address(_dao));
        items[3] = ACLData.BulkItem(ACLData.BulkOp.Grant, _dao.ROOT_ROLE(), address(_dao));
        items[4] = ACLData.BulkItem(ACLData.BulkOp.Grant, _dao.SET_SIGNATURE_VALIDATOR_ROLE(), address(_dao));
        items[5] = ACLData.BulkItem(ACLData.BulkOp.Grant, _dao.MODIFY_TRUSTED_FORWARDER(), address(_dao));
        items[6] = ACLData.BulkItem(ACLData.BulkOp.Grant, _dao.EXEC_ROLE(), _voting);
        items[7] = ACLData.BulkItem(ACLData.BulkOp.Revoke, _dao.ROOT_ROLE(), _factory);
        _dao.bulk(address(_dao), items);
    }
}
