pragma solidity 0.8.10;


contract AspisManager {

    address public manager;
    uint256 public shadowBalance;

    function withdrawCommission() internal {

    }

    function increaseShadowBalance(uint256 _amount) internal {
        shadowBalance += _amount;
    }

    function decreaseShadowBalance(uint256 _amount) internal {
        shadowBalance -=_amount;
    }

    function updateManager(address _manager) public {
        manager = _manager;
    }

}