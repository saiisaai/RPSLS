// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;

contract TimeUnit { 
    uint256 public startTime;

    function setStartTime() public { 
        startTime = block.timestamp;
    }

    function elapsedSeconds() public view returns (uint256) { 
        return (block.timestamp - startTime);
    }

    function elapsedMinutes() public view returns (uint256) { 
        return (block.timestamp - startTime) / 1 minutes;
    }

    function hasTimedOut(uint256 timeoutMinutes) public view returns (bool) {
        return elapsedMinutes() >= timeoutMinutes;
    }

    function resetStartTime() public {
        startTime = block.timestamp;
    }
}
