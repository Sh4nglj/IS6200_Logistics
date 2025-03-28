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

    mapping(address => Role)    public userRoles;
    mapping(address => bool)    public isRegistered;
    mapping(address => uint8)   public courierReputation;

    event UserRegistered(address user, Role role, string message);
    event CourierRewarded(address courierAddr);
    event CourierPenalized(address courierAddr);

    function registerAsSender(address _courierAddr) external  {
        require(!isRegistered[_courierAddr], "User already registered!");

        userRoles[_courierAddr] = Role.Sender;
        isRegistered[_courierAddr] = true;

        emit UserRegistered(_courierAddr, Role.Sender, "Registered as Sender.");
    }

    function registerAsReciever(address _courierAddr) external  {
        require(!isRegistered[_courierAddr], "User already registered!");

        userRoles[_courierAddr] = Role.Receiver;
        isRegistered[_courierAddr] = true;

        emit UserRegistered(_courierAddr, Role.Receiver, "Registered as Receiver");    
    }

    function registerAsCourier(address _courierAddr) external  {
        require(!isRegistered[_courierAddr], "User already registered!");

        userRoles[_courierAddr] = Role.Courier;
        isRegistered[_courierAddr] = true;
        courierReputation[_courierAddr] = DEFAULT_REPUTATION;

        emit UserRegistered(_courierAddr, Role.Courier, "Registered as Courier");    
    }

    function rewardCourier(address _courierAddr) external {
        require(userRoles[_courierAddr] == Role.Courier, "Only courier can be rewarded!");
        
        if (courierReputation[_courierAddr] + REWARD_VALUE <= MAX_REPUTATION) {
            courierReputation[_courierAddr] += REWARD_VALUE;
        }

        emit CourierRewarded(_courierAddr);
    }

    function penalizeCourier(address _courierAddr) external {
        require(userRoles[_courierAddr] == Role.Courier, "Only courier can be penalized!");
        
        if (courierReputation[_courierAddr] - PENALTY_VALUE >= MIN_REPUTATION) {
            courierReputation[_courierAddr] -= PENALTY_VALUE;
        }

        emit CourierPenalized(_courierAddr);
    }
}