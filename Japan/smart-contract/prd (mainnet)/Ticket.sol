// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./erc721a/ERC721A.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Ticket is ERC721A, AccessControl, Pausable, ReentrancyGuard {
    // ================== //
    //  Variable section  //
    // ================== //

    AggregatorV3Interface MATICUSDfeed =
        AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada); // MATICUSD Mainnet

    mapping(uint256 => bool) public isUse;

    string private baseURI;

    uint256 public MAX_SUPPLY;

    uint256 public ticketPrice = 1; // 100 = 1 USD

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
        require(_totalMinted() < MAX_SUPPLY, "Ticket already sold out!");
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Mint over supply");
        _;
    }

    // ===================== //
    //  Constructor section  //
    // ===================== //

    constructor(
        string memory name,
        string memory symbol,
        uint256 _maxSupply,
        uint256 price
    ) ERC721A(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SEC_ADMIN_ROLE, msg.sender);
        MAX_SUPPLY = _maxSupply;
        ticketPrice = price;
        owner = msg.sender;
        baseURI = "";
    }

    // ================= //
    //  Minting section  //
    // ================= //

    function nativeMint(uint256 quantity)
        public
        payable
        checkMintCond(quantity)
        whenNotPaused
        nonReentrant
    {
        uint256 price = getTicketNativePrice(quantity); // mock up matic price
        require(msg.value >= price, "Insufficient MATIC");
        _safeMint(msg.sender, quantity);
        payable(owner).transfer(address(this).balance);

        emit MintMatic(msg.sender, quantity, price);
    }

    function adminMint(address _to, uint256 quantity)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        checkMintCond(quantity)
        whenNotPaused
        nonReentrant
    {
        _safeMint(_to, quantity);
        emit AdminMint(_to, quantity);
    }

    // ============= //
    //  Use section  //
    // ============= //

    function changeState(uint256 ticketId) public onlyRole(SEC_ADMIN_ROLE) {
        require(_exists(ticketId), "This ticket has not beed minted yet!!");
        require(!isUse[ticketId], "This ticket already used!!");
        isUse[ticketId] = true;
    }

    function checkState(uint256 ticketId) public view returns (bool) {
        require(_exists(ticketId), "This ticket has not beed minted yet!!");
        return isUse[ticketId];
    }

    // ============= //
    //  Set section  //
    // ============= //

    function setAggr(address _addr) public onlyRole(DEFAULT_ADMIN_ROLE) {
        MATICUSDfeed = AggregatorV3Interface(_addr);
    }

    function setBaseURI(string memory bURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseURI = bURI;
    }

    function setMaxSupply(uint256 supply) public onlyRole(DEFAULT_ADMIN_ROLE) {
        MAX_SUPPLY = supply;
    }

    function setTicketPrice(uint256 _ticketPrice)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        ticketPrice = _ticketPrice;
    }

    // ============== //
    //  Price section //
    // ============== //

    function getTicketNativePrice(uint256 quantity)
        public
        view
        returns (uint256 price)
    {
        price = (quantity * ticketPrice * 10**34) / getMATICPrice(); // Real price
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
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
