// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract Helper {
    
    function getTimestamp() external view returns (uint) {
        return block.timestamp;
    }
    
    function getBlockNumber() external view returns (uint) {
        return block.number;
    }
}
