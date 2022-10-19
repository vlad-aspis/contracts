pragma solidity 0.8.10;


contract AspisFees {

    struct PoolFee {
        uint256 entranceFee;
        uint256 performanceFee;
        uint256 fundManagementFee;
        uint256 rageQuitFee;
    }

    PoolFee public fee;

    function initializeFees(
        uint256 _entranceFee, 
        uint256 _fundManagementFee, 
        uint256 _performanceFee, 
        uint256 _rageQuitFee) internal {
        
        fee = PoolFee(_entranceFee, _fundManagementFee, _performanceFee, _rageQuitFee);

    }

    function calculateEntranceFee(uint256 _value) public view returns (uint256) {
        return (_value * fee.entranceFee) / 10000;
    }

    function calculatePerformanceFee(uint256 _currentPrice, uint256 _depositPrice, uint256 _amountToBurn, uint256 _depositAmount) public view returns (uint256) {
        if(_currentPrice > _depositPrice) {
            return (_currentPrice - _depositPrice) * (minimum(_amountToBurn, _depositAmount)) * (fee.performanceFee) / (10000 * 100);
        }
    }

    function calculateFundManagementFee(uint256 _tokenSupply, uint256 _managerShare) public view returns (uint256) {
        return (fee.fundManagementFee * _tokenSupply) / (365 * (10000 - _managerShare) - fee.fundManagementFee);
    }

    function calculateRageQuitFee(uint256 _value) public view returns(uint256) {
        return (_value * fee.rageQuitFee) / 10000;
    }

    function minimum(uint256 a, uint256 b) public view returns(uint256) {
        if(a > b) {
            return b;
        } else {
            return a;
        }
    }

}