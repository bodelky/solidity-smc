// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/*
    ░░░░░░░░░░░░░░░░░░░░░▄▀░░▌ 
    ░░░░░░░░░░░░░░░░░░░▄▀▐░░░▌ 
    ░░░░░░░░░░░░░░░░▄▀▀▒▐▒░░░▌ 
    ░░░░░▄▀▀▄░░░▄▄▀▀▒▒▒▒▌▒▒░░▌ 
    ░░░░▐▒░░░▀▄▀▒▒▒▒▒▒▒▒▒▒▒▒▒█ 
    ░░░░▌▒░░░░▒▀▄▒▒▒▒▒▒▒▒▒▒▒▒▒▀▄ 
    ░░░░▐▒░░░░░▒▒▒▒▒▒▒▒▒▌▒▐▒▒▒▒▒▀▄ 
    ░░░░▌▀▄░░▒▒▒▒▒▒▒▒▐▒▒▒▌▒▌▒▄▄▒▒▐ 
    ░░░▌▌▒▒▀▒▒▒▒▒▒▒▒▒▒▐▒▒▒▒▒█▄█▌▒▒▌ 
    ░▄▀▒▐▒▒▒▒▒▒▒▒▒▒▒▄▀█▌▒▒▒▒▒▀▀▒▒▐░░░▄ 
    ▀▒▒▒▒▌▒▒▒▒▒▒▒▄▒▐███▌▄▒▒▒▒▒▒▒▄▀▀▀▀ 
    ▒▒▒▒▒▐▒▒▒▒▒▄▀▒▒▒▀▀▀▒▒▒▒▄█▀░░▒▌▀▀▄▄ 
    ▒▒▒▒▒▒█▒▄▄▀▒▒▒▒▒▒▒▒▒▒▒░░▐▒▀▄▀▄░░░░▀ 
    ▒▒▒▒▒▒▒█▒▒▒▒▒▒▒▒▒▄▒▒▒▒▄▀▒▒▒▌░░▀▄ 
    ▒▒▒▒▒▒▒▒▀▄▒▒▒▒▒▒▒▒▀▀▀▀▒▒
*/

contract Ticket is ERC721A, Ownable, Pausable, ReentrancyGuard {
    // ================== //
    //  Variable section  //
    // ================== //

    // AggregatorV3Interface MATICUSDfeed = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0); // MATICUSD Mainnet
    AggregatorV3Interface private MATICUSDfeed =
        AggregatorV3Interface(0x7794ee502922e2b723432DDD852B3C30A911F021); // MATICUSD Rinkeby
    address public USDT_ADDRESS = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F; // Polygon - USDT Mainnet

    mapping(uint256 => bool) public isUse;

    string private baseURI;

    uint256 public MAX_SUPPLY = 1000;

    uint256 public ticketPrice = 1;

    uint256 public constant maticMockup = 832243950000000000;

    // =============== //
    //  Event section  //
    // =============== //

    event MintUSDT(
        address indexed _to,
        uint256 indexed quantity,
        uint256 indexed price
    );
    event MintMatic(
        address indexed _to,
        uint256 indexed quantity,
        uint256 indexed price
    );
    event AdminMint(address indexed _to, uint256 indexed quantity);

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

    constructor() ERC721A("Ticket", "TCK") {
        baseURI = "https://aws-s3.com/";
    }

    // ================= //
    //  Minting section  //
    // ================= //

    function usdMint(uint256 quantity)
        public
        checkMintCond(quantity)
        whenNotPaused
        nonReentrant
    {
        uint256 price = quantity * ticketPrice * (10**6); // amount * item price * wei => n * 20 * 1000000
        require(
            IERC20(USDT_ADDRESS).balanceOf(msg.sender) > price,
            "Not enough USDT"
        );
        IERC20(USDT_ADDRESS).transferFrom(msg.sender, address(this), price);
        IERC20(USDT_ADDRESS).transfer(
            owner(),
            IERC20(USDT_ADDRESS).balanceOf(address(this))
        );
        _safeMint(msg.sender, quantity);

        emit MintUSDT(msg.sender, quantity, price);
    }

    function nativeMint(uint256 quantity)
        public
        payable
        checkMintCond(quantity)
        whenNotPaused
        nonReentrant
    {
        uint256 price = (quantity * ticketPrice * 10**36) / maticMockup; // mock up matic price
        require(msg.value >= price, "Insufficient MATIC");
        _safeMint(msg.sender, quantity);
        payable(owner()).transfer(address(this).balance);

        emit MintMatic(msg.sender, quantity, price);
    }

    function adminMint(address _to, uint256 quantity)
        public
        onlyOwner
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

    function changeState(uint256 ticketId) public {
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

    // Don't forget to remove
    function setUSDTAddress(address _addr) public onlyOwner {
        USDT_ADDRESS = _addr;
    }

    function setBaseURI(string memory bURI) public onlyOwner {
        baseURI = bURI;
    }

    function setMaxSupply(uint256 supply) public onlyOwner {
        MAX_SUPPLY = supply;
    }

    function setTicketPrice(uint256 _ticketPrice) public onlyOwner {
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
        price = (quantity * ticketPrice * 10**36) / maticMockup; // mock up matic price
        // price = (quantity * ticketPrice * 10**36) / getMATICPrice(); // Real price
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
    //  Override section  //
    // ================== //

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
