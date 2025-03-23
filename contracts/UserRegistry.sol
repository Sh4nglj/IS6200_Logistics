// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserRegistry {
    enum Role {
        Sender, 
        Courier, 
        Receiver
    }

    mapping(address => Role) public userRoles;
    mapping(address => bool) public isRegistered;

    event UserRegistered(address user, Role role);

    function registerAsSender() external {
        require(!isRegistered[msg.sender], "User already registered!");

        userRoles[msg.sender] = Role.Sender;
        isRegistered[msg.sender] = true;
        emit UserRegistered(msg.sender, Role.Sender);
    }

    function registerAsCourier() external {
        require(!isRegistered[msg.sender], "User already registered!");

        userRoles[msg.sender] = Role.Courier;
        isRegistered[msg.sender] = true;
        emit UserRegistered(msg.sender, Role.Courier);    
    }

    function registerAsReciever() external {
        require(!isRegistered[msg.sender], "User already registered!");

        userRoles[msg.sender] = Role.Receiver;
        isRegistered[msg.sender] = true;
        emit UserRegistered(msg.sender, Role.Receiver);    
    }
}