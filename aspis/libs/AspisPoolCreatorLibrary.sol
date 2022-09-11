/*
 * SPDX-License-Identifier:    MIT
 */
pragma solidity 0.8.10;
import "./../AspisPool.sol";

library AspisPoolCreatorLibrary {
    struct DAOConfig {
        AspisPoolConfig pool;
        ITokenValueCalculator calculator;
        bytes metadata;
    }

    function createPool(
        DAOConfig calldata _daoConfig,
        address _gsnForwarder,
        address _factory
    ) public returns (AspisPool) {
        AspisPool aDao = new AspisPool(tx.origin);
        aDao.initialize(_daoConfig.metadata, _factory, _gsnForwarder);
        return aDao;
    }
}
