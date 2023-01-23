pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./erc721a/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Ticket is ERC721AQueryable, AccessControl, ReentrancyGuard, Pausable {
    // ================== //
    //  Variable section  //
    // ================== //

    string public baseURI;

    uint256 public MAX_SUPPLY;

    uint256 public price = 30 ether;

    address public owner;

    bytes32 public constant SEC_ADMIN_ROLE = keccak256("ADMIN");

    // =============== //
    //  Event section  //
    // =============== //

    event MintTicket(
        address indexed _to,
        uint256 indexed quantity,
        uint256 indexed price
    );
    event AdminMint(address indexed _to, uint256 indexed quantity);
    event Burn(uint256 tokenId);

    // ================== //
    //  Modifier section  //
    // ================== //

    modifier checkMintCond(uint256 quantity) {
        require(_totalMinted() < MAX_SUPPLY, "Ticket already sold out!");
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Mint over supply");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        uint256 _maxSupply
    ) ERC721A(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SEC_ADMIN_ROLE, msg.sender);
        MAX_SUPPLY = _maxSupply;
        owner = msg.sender;
        baseURI = "";
    }

    function mint(
        uint256 quantity
    ) external payable checkMintCond(quantity) whenNotPaused nonReentrant {
        uint256 sumPrice = price * quantity;
        require(msg.value >= sumPrice, "Not enough value");
        _safeMint(msg.sender, quantity);
        emit MintTicket(msg.sender, quantity, sumPrice);
    }

    function adminMint(
        address to,
        uint256 quantity
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        checkMintCond(quantity)
        nonReentrant
    {
        _safeMint(to, quantity);
        emit AdminMint(to, quantity);
    }

    // ============= //
    //  Set section  //
    // ============= //

    function setBaseURI(
        string memory bURI
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = bURI;
    }

    function setMaxSupply(uint256 supply) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(supply > MAX_SUPPLY, "Not allow to lower Max supply");
        MAX_SUPPLY = supply;
    }

    function setTicketPrice(
        uint256 _ticketPrice
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        price = _ticketPrice;
    }

    // ================== //
    //  Utility section   //
    // ================== //

    function burn(uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _burn(tokenId);
        emit Burn(tokenId);
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(owner).transfer(address(this).balance);
    }

    function getBalance() external view returns (uint256 balance) {
        balance = address(this).balance;
    }

    // ================== //
    //  Override section  //
    // ================== //

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721A, AccessControl, IERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
