// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract Ticket is ERC1155, Ownable, Pausable, ERC1155Burnable, ERC1155Supply {
    constructor() ERC1155("") {
        _mint(msg.sender, 0, 25000, "");
    }

    uint256 public price = 1 ether;

    // Mint

    function mint(uint256 id, uint256 amount) external payable whenNotPaused {
        require(msg.value >= price * amount, "Insufficient fund");
        _mint(msg.sender, id, amount, "");
    }

    function adminMint(
        address to,
        uint256 id,
        uint256 amount
    ) external onlyOwner whenNotPaused {
        _mint(to, id, amount, "");
    }

    // Configuration

    function setURI(string memory newuri) public onlyOwner whenNotPaused {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // Utility

    function setPrice(uint256 _price) external onlyOwner whenNotPaused {
        price = _price;
    }

    function withdraw() external onlyOwner whenNotPaused {
        payable(owner()).transfer(address(this).balance);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Override

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
