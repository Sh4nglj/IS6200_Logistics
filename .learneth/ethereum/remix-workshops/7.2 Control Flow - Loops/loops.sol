// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract Loop {
    uint public count = 0;

    function loop() public {
        // for loop
        for (uint i = 0; i < 10; i++) {
            count++;
            
            if (i == 3) {
                // Skip to next iteration with continue
                continue;
            }
            if (i == 5) {
                // Exit loop with break
                break;
            }
        }

        // while loop
        uint j;
        while (j < 3) {
            j++;
            count++;
        }
    }
}
