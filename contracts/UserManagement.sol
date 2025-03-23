// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserManagement {
    enum Role {
        Sender, 
        Courier, 
        Receiver
    }

    mapping(address => Role) public userRoles;
    mapping(address => bool) public isRegistered;

    event UserRegistered(address user, Role role, string message);

    function registerAsSender() public {
        require(!isRegistered[msg.sender], "User already registered!");

        userRoles[msg.sender] = Role.Sender;
        isRegistered[msg.sender] = true;

        emit UserRegistered(msg.sender, Role.Sender, "Registered as Sender.");
    }

    function registerAsCourier() public {
        require(!isRegistered[msg.sender], "User already registered!");

        userRoles[msg.sender] = Role.Courier;
        isRegistered[msg.sender] = true;

        emit UserRegistered(msg.sender, Role.Courier, "Registered as Courier");    
    }

    function registerAsReciever() public {
        require(!isRegistered[msg.sender], "User already registered!");

        userRoles[msg.sender] = Role.Receiver;
        isRegistered[msg.sender] = true;

        emit UserRegistered(msg.sender, Role.Receiver, "Registered as Receiver");    
    }
}