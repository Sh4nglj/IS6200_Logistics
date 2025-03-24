// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FeeManagement {
    uint256 public constant BASE_REWARD = 10 ether;
    uint256 public constant DISTANCE_RATE = 0.1 ether;
    uint256 public constant REPUTATION_FACTOR = 0.1 ether;

    event RewardCalculated(string message);

    function calculateLTKReward(string memory _senderLoc, string memory _receiverLoc, uint256 _courierReputaion) external returns (uint256) {
        uint256 temp_senderLoc = 10;
        uint256 temp_receiverLoc = 20;
        uint256 distance;

        if (temp_senderLoc >= temp_receiverLoc) {
            distance = temp_senderLoc - temp_receiverLoc;
        }
        else {
            distance = temp_receiverLoc - temp_senderLoc;
        }

        uint256 distanceBonus = distance * DISTANCE_RATE;

        uint256 reputationBonus = _courierReputaion * REPUTATION_FACTOR;

        emit RewardCalculated("WARNING : Returning a testing number!");
        
        return BASE_REWARD + distanceBonus + reputationBonus;
    }
}