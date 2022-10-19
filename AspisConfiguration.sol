pragma solidity 0.8.10;

import "./AspisFees.sol";

contract AspisConfiguration is AspisFees {
    

    struct PoolConfig {
        uint256 maxCap; //fundraising limit
        uint256 minDeposit; 
        uint256 maxDeposit;
        uint256 startTime; //fundraising start time
        uint256 finishTime;  //fundraising end time
        uint256 withdrawlWindow;
        uint256 freezePeriod;
        uint256 transactionDelay;
        uint256 lockLimit; //token lock up period
        uint256 earlyLimit;
        uint256 spendingLimit;
        uint256 initialPrice;
        bool isRefundable;
        bool hasWhitelist;
    }

    PoolConfig public configuration;

    address public voting;

    address[] public supportedTokens;
    address[] public whitelistUsersArray;
    address[] public trustedProtocolsArray;

    mapping(address => bool) public whitelistUsers;
    mapping(address => bool) public trustedProtocols;


    function _setConfiguration( 
        uint256[18] memory _poolconfig,
        address[] memory _whitelistUsers,
        address[] memory _trustedProtocols,
        address[] memory _supportedTokens
    ) internal {

        configuration.maxCap = _poolconfig[0];
        configuration.minDeposit = _poolconfig[1];
        configuration.maxDeposit = _poolconfig[2];

        configuration.startTime = _poolconfig[3];
        configuration.finishTime = _poolconfig[4];

        configuration.withdrawlWindow = _poolconfig[5];
        configuration.freezePeriod = _poolconfig[6];
        configuration.transactionDelay = _poolconfig[7];

        //no check on locklimit (it could be zero as well)
        configuration.lockLimit = _poolconfig[8];
        configuration.earlyLimit = _poolconfig[9];
        configuration.spendingLimit = _poolconfig[10];

        initializeFees(_poolconfig[11], _poolconfig[12], _poolconfig[13], _poolconfig[14]);

        configuration.initialPrice = _poolconfig[15];

        configuration.isRefundable = _poolconfig[16] > 0 ? true: false;
        configuration.hasWhitelist = _poolconfig[17] > 0 ? true: false;

        addSupportedTokens(_supportedTokens);

        addToWhitelist(_whitelistUsers);

        addToTrustedProtocols(_trustedProtocols);
        
    }

    function addSupportedTokens(address[] memory _tokenAddresses) public {
        //possible to add duplicate tokens
        for(uint8 i=0; i < _tokenAddresses.length; i++) {
            supportedTokens.push(_tokenAddresses[i]);
        }
    }


    function addToWhitelist(address[] memory _voters) public {

        for (uint64 i = 0; i < _voters.length; i++) {
            whitelistUsers[_voters[i]] = true;
            whitelistUsersArray.push(_voters[i]);
        }
    }

    function removeFromWhitelist(address[] memory _voters) public {

        for (uint64 i = 0; i < _voters.length; i++) {
            whitelistUsers[_voters[i]] = false;
        }
    }

    function addToTrustedProtocols(address[] memory _trustedProtocols) public {

        for (uint64 i = 0; i < _trustedProtocols.length; i++) {
            trustedProtocols[_trustedProtocols[i]] = true;
            trustedProtocolsArray.push(_trustedProtocols[i]);
        }
    }

    function removeFromTrustedProtocols(address[] memory _trustedProtocols) public {

        for (uint64 i = 0; i < _trustedProtocols.length; i++) {
            trustedProtocols[_trustedProtocols[i]] = false;
        }
    }

    function setWhitelistStatus(bool _enabled) public {
        configuration.hasWhitelist = _enabled;
    }

    function setFundraisingTarget(uint256 _newTarget) public {
        configuration.maxCap = _newTarget;
    }

    function setFundraisingStartTime(uint256 _newStartTime) public {
        // require(block.timestamp < configuration.startTime || block.timestamp > configuration.finishTime, "Fundraising ongoing");
        // require(_newStartTime > configuration.startTime, "Should be higher that current start time");
        configuration.startTime = _newStartTime;
    }

    function setFundraisingFinishTime(uint256 _newFinishTime) public {
        configuration.finishTime = _newFinishTime;
    }

    function setInitialTokenPrice(uint256 _newPrice) public {
        configuration.initialPrice = _newPrice;
    }

    function setDepositLimits(uint256 _newMaxLimit, uint256 _newMinLimit) public {
        configuration.maxDeposit = _newMaxLimit;
        configuration.minDeposit = _newMinLimit;
    }

    function setSpendingLimit(uint256 _newSpendingLimit) public {
        // require(_newSpendingLimit > 0, "Zero spending limit error");
        configuration.spendingLimit = _newSpendingLimit;
    }

    function setWithdrawlWindows(uint256 _newFreezePeriod, uint256 _newWithdrawlWindow) public {
        configuration.withdrawlWindow = _newWithdrawlWindow;
        configuration.freezePeriod = _newFreezePeriod;
    }

    function setTransactionDelay(uint256 _newTransactionDelay) public {
        configuration.transactionDelay = _newTransactionDelay;
    }


    function setLockLimit(uint256 _newLockLimit) public {
        configuration.lockLimit = _newLockLimit;
    }

    function setEntranceFee(uint256 _newEntranceFee) public {
        fee.entranceFee = _newEntranceFee;
    }

    function setVotingAddress(address _voting) public {
        voting = _voting;
    }

    function setPerformanceFee(uint256 _performanceFee) public {
        fee.performanceFee = _performanceFee;
    }

    function setFundManagementFee(uint256 _fundManagementFee) public {
        fee.fundManagementFee = _fundManagementFee;
    }

    function setRageQuitFee(uint256 _newRageQuitFee) public {
        fee.rageQuitFee = _newRageQuitFee;
    }

    function getWhiteListUsers() public view returns(address[] memory) {
        return whitelistUsersArray;
    }

    function getTrustedProtocols() public view returns(address[] memory) {
        return trustedProtocolsArray;
    }

    function getSupportedTokens() public view returns(address[] memory) {
        return supportedTokens;
    }

}
