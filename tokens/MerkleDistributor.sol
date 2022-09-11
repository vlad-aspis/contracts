/*
 * SPDX-License-Identifier:    GPL-3.0
 */

// Copied and modified from: https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol

pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./GovernanceERC20.sol";

contract MerkleDistributor is Initializable {
    
    using SafeERC20Upgradeable for GovernanceERC20;

    GovernanceERC20 public token;
    bytes32 public merkleRoot;

    // This is a packed array of booleans.
    mapping (uint256 => uint256) private claimedBitMap;

    error DistTokenClaimedAlready(uint256 index);
    error DistTokenClaimInvalid(uint256 index, address to, uint256 amount);

    event Claimed(uint256 indexed index, address indexed to, uint256 amount);

    function initialize(GovernanceERC20 _token, bytes32 _merkleRoot) external initializer {
        token = _token;
        merkleRoot = _merkleRoot;
    }

    function claim(uint256 _index, address _to, uint256 _amount, bytes32[] calldata _merkleProof) external {
        if(isClaimed(_index)) revert DistTokenClaimedAlready({index: _index});
        if(!_verifyBalanceOnTree(_index, _to, _amount, _merkleProof))
            revert DistTokenClaimInvalid({index: _index, to: _to, amount: _amount});

        _setClaimed(_index);
        token.safeTransfer(_to, _amount);

        emit Claimed(_index, _to, _amount);
    }

    function unclaimedBalance(uint256 _index, address _to, uint256 _amount, bytes32[] memory _proof) public view returns (uint256) {
        if (isClaimed(_index)) return 0;
        return _verifyBalanceOnTree(_index, _to, _amount, _proof) ? _amount : 0;
    }

    function _verifyBalanceOnTree(uint256 _index, address _to, uint256 _amount, bytes32[] memory _proof) internal view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(_index, _to, _amount));
        return MerkleProof.verify(_proof, merkleRoot, node);
    }

    function isClaimed(uint256 _index) public view returns (bool) {
        uint256 claimedWord_index = _index / 256;
        uint256 claimedBit_index = _index % 256;
        uint256 claimedWord = claimedBitMap[claimedWord_index];
        uint256 mask = (1 << claimedBit_index);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 _index) private {
        uint256 claimedWord_index = _index / 256;
        uint256 claimedBit_index = _index % 256;
        claimedBitMap[claimedWord_index] = claimedBitMap[claimedWord_index] | (1 << claimedBit_index);
    }
}
