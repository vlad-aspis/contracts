/*
 * SPDX-License-Identifier:    MIT
 */
pragma solidity 0.8.10;
import "./../AspisPool.sol";
import "./../AspisConfiguration.sol";
import "./AspisPoolCreatorLibrary.sol";

library AspisPoolConfigurationLibrary {
    function configuratePool(AspisPoolCreatorLibrary.DAOConfig calldata _daoConfig, AspisPool pool, address gsnForwarder)
        public
        returns (AspisConfiguration)
    {
        AspisConfiguration configuration = new AspisConfiguration(pool, tx.origin);
        configuration.initializeToken(_daoConfig.pool);
        configuration.configure(_daoConfig.pool, gsnForwarder);
        return configuration;
    }
}
