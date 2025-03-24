// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserManagement {
    enum Role {
        Sender, 
        Courier, 
        Receiver
    }

    uint8 public constant DEFAULT_REPUTATION = 50;
    uint8 public constant MAX_REPUTATION = 150;
    uint8 public constant MIN_REPUTATION = 0;
    uint8 public constant REWARD_VALUE = 5;
    uint8 public constant PENALTY_VALUE = 10;

    mapping(address => Role) public userRoles;
    mapping(address => bool) public isRegistered;
    // Default reputaion is 0. Increased by finishing a order with higher rate.
    mapping(address => uint8) public courierReputation;

    event UserRegistered(address user, Role role, string message);
    event courierRewarded(address courierAddr);
    event courierPenalized(address courierAddr);

    function registerAsSender() external  {
        require(!isRegistered[msg.sender], "User already registered!");

        userRoles[msg.sender] = Role.Sender;
        isRegistered[msg.sender] = true;

        emit UserRegistered(msg.sender, Role.Sender, "Registered as Sender.");
    }

    function registerAsCourier() external  {
        require(!isRegistered[msg.sender], "User already registered!");

        userRoles[msg.sender] = Role.Courier;
        isRegistered[msg.sender] = true;
        courierReputation[msg.sender] = 0;

        emit UserRegistered(msg.sender, Role.Courier, "Registered as Courier");    
    }

    function registerAsReciever() external  {
        require(!isRegistered[msg.sender], "User already registered!");

        userRoles[msg.sender] = Role.Receiver;
        isRegistered[msg.sender] = true;

        emit UserRegistered(msg.sender, Role.Receiver, "Registered as Receiver");    
    }

    function rewardCourier(address _courierAddr) external {
        uint8 currentReputation = courierReputation[_courierAddr];

        if (currentReputation + REWARD_VALUE <= MAX_REPUTATION) {
            currentReputation += REWARD_VALUE;
        }

        emit courierRewarded(_courierAddr);
    }

    function penalizeCourier(address _courierAddr) external {
        uint8 currentReputation = courierReputation[_courierAddr];

        if (currentReputation - PENALTY_VALUE >= MIN_REPUTATION) {
            currentReputation -= PENALTY_VALUE;
        }

        emit courierPenalized(_courierAddr);
    }
}