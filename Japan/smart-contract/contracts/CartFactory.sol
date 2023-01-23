pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./Ticket.sol";

contract CartFactory {
    // _addrs = [addr1, addr2]
    // _to = destination
    // amounts = [10, 20]
    // Result:

    function mintAll(address[] memory _addrs, address _to, uint256[] memory _amounts) public {
        Ticket temp;
        for(uint256 i = 0; i < _addrs.length; i++) {
            temp = Ticket(_addrs[i]);
            temp.adminMint(_to, _amounts[i]);
        }
    }
}