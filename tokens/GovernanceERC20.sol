/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "../core/erc165/AdaptiveERC165.sol";
import "../core/component/Permissions.sol";
import "../core/IDAO.sol";


contract GovernanceERC20 is AdaptiveERC165, ERC20VotesUpgradeable, Permissions {

     /// @notice The role identifier to mint new tokens
    bytes32 public constant TOKEN_MINTER_ROLE = keccak256("TOKEN_MINTER_ROLE");
    
    function __GovernanceERC20_init(
        IDAO _dao, 
        string calldata _name, 
        string calldata _symbol
    ) internal onlyInitializing {
        __ERC20_init(_name, _symbol);
        __ERC20Permit_init(_name);
        __Permissions_init(_dao);

        _registerStandard(type(IERC20Upgradeable).interfaceId);
        _registerStandard(type(IERC20PermitUpgradeable).interfaceId);
        _registerStandard(type(IERC20MetadataUpgradeable).interfaceId);
    }

    function initialize(
        IDAO _dao, 
        string calldata _name, 
        string calldata _symbol
    ) external initializer {
        __GovernanceERC20_init(_dao,_name,_symbol);
    }

    function burn(address from, uint256 amount) external auth(TOKEN_MINTER_ROLE) {
        _burn(from, amount);
    }


    function mint(address to, uint256 amount) external auth(TOKEN_MINTER_ROLE) {
        _mint(to, amount);
    }

    // The functions below are overrides required by Solidity.
    // https://forum.openzeppelin.com/t/self-delegation-in-erc20votes/17501/12?u=novaknole
    function _afterTokenTransfer(address from, address to, uint256 amount) internal override {
        super._afterTokenTransfer(from, to, amount);
        // reduce _delegate calls only when minting
        if(from == address(0) && to != address(0) && delegates(to) == address(0)) {
            _delegate(to, to);
        }
    }

    function _mint(address to, uint256 amount) internal override {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override{
        super._burn(account, amount);
    }

}
