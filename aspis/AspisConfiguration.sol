/*
 * SPDX-License-Identifier:    MIT
 */

import "../tokens/GovernanceERC20.sol";
import "../core/IDAO.sol";

pragma solidity 0.8.10;

struct AspisPoolConfig {
    string name;
    string symbol;
    uint256 maxCap;
    uint256 minInvestment;
    uint256 maxInvestment;
    uint256 startTime;
    uint256 finishTime;
    uint256 softCap;
    uint256 lockLimit;
    uint256 earlyLimit;
    uint256 entranceFee;
    uint256 txFee;
    uint256 earlyExitFee;
    uint256 spendingLimit;
    uint256 initialPrice;
}

contract AspisConfiguration {
    string private constant ERROR_TOKEN_NO_INIT = "The token was not initialized.";
    string private constant ERROR_NO_PERMISSION = "This function can only be accessed by the DAO that it's bound to.";
    string private constant ERROR_TOKEN_ALREADY_INIT = "The token was already initialized.";
    string private constant ERROR_PRICE_NOT_CORRECT = "The token price cannot be 0";

    uint256 internal maxCap;
    uint256 internal minInvestment;
    uint256 internal maxInvestment;
    uint256 internal startTime;
    uint256 internal finishTime;
    uint256 internal softCap;
    uint256 internal lockLimit;
    uint256 internal earlyLimit;
    uint256 internal entranceFee;
    uint256 internal txFee;
    uint256 internal earlyExitFee;
    uint256 internal spendingLimit;
    uint256 initialPrice;
    address gsnForwarder;
    string internal name;
    GovernanceERC20 internal token;
    bool private tokenInitialized;
    IDAO dao;

    address private configurator;
    bool private configurated;

    constructor(IDAO _parentDao, address _configurator) {
        dao = _parentDao;
        configurator = _configurator;
    }

    function initializeToken(AspisPoolConfig memory _config) public {
        require(!tokenInitialized, ERROR_TOKEN_ALREADY_INIT);
        require(tx.origin == configurator);
        token = new GovernanceERC20();
        token.initialize(dao, _config.name, _config.symbol);
        tokenInitialized = true;
    }

    function configure(AspisPoolConfig memory _config, address _gsnForwarder) public {
        // TODO: Add validation in configuration
        if (configurated) {
            require(msg.sender == address(dao), ERROR_NO_PERMISSION);
        } else {
            require(tx.origin == configurator);
            configurated = true;
        }
        require(_config.initialPrice >0, ERROR_PRICE_NOT_CORRECT);

        name = _config.name;
        maxCap = _config.maxCap;
        txFee = _config.txFee;
        minInvestment = _config.minInvestment;
        maxInvestment = _config.maxInvestment;
        startTime = _config.startTime;
        finishTime = _config.finishTime;
        softCap = _config.softCap;
        lockLimit = _config.lockLimit;
        earlyLimit = _config.earlyLimit;
        entranceFee = _config.entranceFee;
        earlyExitFee = _config.earlyExitFee;
        spendingLimit = _config.spendingLimit;
        initialPrice = _config.initialPrice;
        gsnForwarder = _gsnForwarder;
    }

    // Getters
    function getToken() public view returns (GovernanceERC20) {
        require(tokenInitialized, ERROR_TOKEN_NO_INIT);
        return token;
    }

    // function getDecimals() public view returns (uint256) {
    //     return decimals;
    // }

    function getMaxCap() public view returns (uint256) {
        return maxCap;
    }

    function getMinInvestment() public view returns (uint256) {
        return minInvestment;
    }

    function getMaxInvestment() public view returns (uint256) {
        return maxInvestment;
    }

    function getStartTime() public view returns (uint256) {
        return startTime;
    }

    function getSoftCap() public view returns (uint256) {
        return softCap;
    }

    function getLockLimit() public view returns (uint256) {
        return lockLimit;
    }

    function getEarlyLimit() public view returns (uint256) {
        return earlyLimit;
    }

    function getEntranceFee() public view returns (uint256) {
        return entranceFee;
    }

    function getTxFee() public view returns (uint256) {
        return txFee;
    }

    function getEarlyExitFee() public view returns (uint256) {
        return earlyExitFee;
    }

    function getSpendingLimit() public view returns (uint256) {
        return spendingLimit;
    }

    function getName() public view returns (string memory) {
        return name;
    }

    function getInitialPrice() public view returns (uint256) {
        return initialPrice;
    }

    function getGsnForwarded() public view returns (address) {
        return gsnForwarder;
    }

    // Setters
    function setMaxCap(uint256 newMaxCap) public returns (uint256) {
        // TODO: require only voting to change this one
        maxCap = newMaxCap;
        return maxCap;
    }

    function setMinInvestment(uint256 newMinInvestment) public returns (uint256) {
        minInvestment = newMinInvestment;
        return minInvestment;
    }

    function setMaxInvestment(uint256 newMaxInvestment) public returns (uint256) {
        maxInvestment = newMaxInvestment;
        return maxInvestment;
    }

    function setStartTime(uint256 newStartTime) public returns (uint256) {
        startTime = newStartTime;
        return startTime;
    }

    function setSoftCap(uint256 newSoftCap) public returns (uint256) {
        softCap = newSoftCap;
        return softCap;
    }

    function setLockLimit(uint256 newLockLimit) public returns (uint256) {
        lockLimit = newLockLimit;
        return lockLimit;
    }

    function setEarlyLimit(uint256 newEarlyLimit) public returns (uint256) {
        earlyLimit = newEarlyLimit;
        return earlyLimit;
    }

    function setEntranceFee(uint256 newEntranceFee) public returns (uint256) {
        entranceFee = newEntranceFee;
        return entranceFee;
    }

    function setTxFee(uint256 newTxFee) public returns (uint256) {
        txFee = newTxFee;
        return txFee;
    }

    function setEarlyExitFee(uint256 newEarlyExitFee) public returns (uint256) {
        earlyExitFee = newEarlyExitFee;
        return earlyExitFee;
    }

    function setSpendingLimit(uint256 newSpendingLimit) public returns (uint256) {
        spendingLimit = newSpendingLimit;
        return spendingLimit;
    }

    function setInitialPrice(uint256 newInitialPrice) public returns (uint256) {
        initialPrice = newInitialPrice;
        return initialPrice;
    }
}
