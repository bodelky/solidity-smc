pragma solidity ^0.8.4;
// SPDX-License-Identifier: MIT

import "./erc721a/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Root.sol";

contract FootballChild is ERC721AQueryable, Pausable, AccessControl {
    Root root;
    string public bURI;

    uint256 public teamIndex;

    constructor(
        Root _root,
        uint256 _teamIndex,
        string memory _name,
        string memory _sym
    ) ERC721A(_name, _sym) {
        root = _root;
        teamIndex = _teamIndex;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(address _to, uint256 quantity)
        public
        whenNotPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _safeMint(_to, quantity);
    }

    // ====== Admin function ======

    function getBaseURI() public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    _toString(teamIndex),
                    "/",
                    _toString(root.getLevel()),
                    "/"
                )
            );
    }

    function setRoot(Root _root) public onlyRole(DEFAULT_ADMIN_ROLE) {
        root = _root;
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    // ====== Override function ======

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        // string memory baseURI = _baseURI();
        return string(abi.encodePacked(getBaseURI(), _toString(tokenId)));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return root.getBaseURI();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, AccessControl, IERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
//
