pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./erc721r/ERC721rV2.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract MysteryBox is ERC721r, AccessControl, Pausable, ReentrancyGuard {
    // ================== //
    //  Variable section  //
    // ================== //

    AggregatorV3Interface MATICUSDfeed =
        AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada); // MATICUSD Mainnet

    string private baseURI;

    uint256 public mysteryBoxPrice; // 100 = 1 USD

    address public owner;
    bytes32 public constant SEC_ADMIN_ROLE = keccak256("ADMIN");

    // =============== //
    //  Event section  //
    // =============== //

    event MintMatic(
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
        require(_totalMinted() < maxSupply(), "MysteryBox already sold out!");
        require(_totalMinted() + quantity <= maxSupply(), "Mint over supply");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        uint256 MAX_SUPPLY,
        uint256 price,
        uint32 subscriptionId,
        address _vrfCoordinator,
        bytes32 _keyHash
    )
        ERC721r(
            name,
            symbol,
            MAX_SUPPLY,
            subscriptionId,
            _vrfCoordinator,
            _keyHash
        )
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SEC_ADMIN_ROLE, msg.sender);
        owner = msg.sender;
        mysteryBoxPrice = price;
        baseURI = "";
    }

    // ============= //
    //  Use section  //
    // ============= //

    function nativeMint(uint32 quantity)
        external
        payable
        checkMintCond(quantity)
        whenNotPaused
    {
        uint256 price = getMBNativePrice(quantity);
        require(msg.value >= price, "Insufficient MATIC");
        _mintRandom(msg.sender, quantity);
        payable(owner).transfer(address(this).balance);

        emit MintMatic(msg.sender, quantity, price);
    }

    function adminMint(address _to, uint32 quantity)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        checkMintCond(quantity)
        whenNotPaused
        nonReentrant
    {
        _mintRandom(_to, quantity);
        emit AdminMint(_to, quantity);
    }

    // ============= //
    //  Set section  //
    // ============= //

    function setAggr(address _addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        MATICUSDfeed = AggregatorV3Interface(_addr);
    }

    function setBaseURI(string memory bURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseURI = bURI;
    }

    function setPrice(uint256 _mysteryBoxPrice)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        mysteryBoxPrice = _mysteryBoxPrice;
    }

    // ============== //
    //  Price section //
    // ============== //

    function getMBNativePrice(uint256 quantity)
        public
        view
        returns (uint256 price)
    {
        // price = (quantity * ticketPrice * 10**36) / getMATICPrice(); // Real price
        price = (quantity * mysteryBoxPrice * 10**34) / getMATICPrice(); // Real price
    }

    function getMATICPrice() public view returns (uint256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = MATICUSDfeed.latestRoundData();
        return uint256(price * (10**10));
    }

    // ================== //
    //  Utility section   //
    // ================== //

    function burn(uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _burn(tokenId);
        emit Burn(tokenId);
    }

    // ================== //
    //  Override section  //
    // ================== //

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721r, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
