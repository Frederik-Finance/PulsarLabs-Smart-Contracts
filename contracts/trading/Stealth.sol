// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract Stealth {
    function forward(address target) external returns (address payable result) {
        // convert address to 20 bytes
        bytes20 targetBytes = bytes20(target);

        assembly {
            let clone := mload(0x40)
            // store 32 bytes to memory starting at "clone"
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )

            mstore(add(clone, 0x14), targetBytes)
            // store 32 bytes to memory starting at "clone" + 40 bytes
            // 0x28 = 40
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            // create the new contract
            // zero means zero eth is send
            result := create(0, clone, 0x37)
        }
    }
}
