pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "../erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "hardhat/console.sol";

contract MysteryBox is ERC721A, Ownable, ReentrancyGuard {
    // AggregatorV3Interface MATICUSDfeed = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0); // MATICUSD Mainnet
    AggregatorV3Interface MATICUSDfeed =
        AggregatorV3Interface(0x7794ee502922e2b723432DDD852B3C30A911F021); // MATICUSD Rinkeby

    event MintUSD(
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

    // address constant USDT_ADDRESS = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F; // Polygon - USDT Mainnet
    address constant USDT_ADDRESS = 0xd9145CCE52D386f254917e481eB44e9943F39138; // Fake USD

    string public baseURI;

    mapping(uint256 => bool) private isUse;
    uint256 mysteryBoxPrice = 20; // 20 USDT
    uint256 maticMockup = 832243950000000000;
    uint256 public constant MB_AMOUNT = 99;

    modifier checkSoldOut() {
        require(_totalMinted() <= MB_AMOUNT, "mysteryBox already sold out!");
        _;
    }

    constructor(string memory _buri)
        ERC721A("Japan Iconic Mystery Box", "JIMB")
    {
        baseURI = _buri;
    }

    function getMATICPrice() public view returns (uint256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/
            ,
            ,

        ) = /*uint timeStamp*/
            /*uint80 answeredInRound*/
            MATICUSDfeed.latestRoundData();
        return uint256(price * (10**10));
    }

    function setMysteryBoxPrice(uint256 _price) public onlyOwner {
        mysteryBoxPrice = _price;
    }

    // require USDC to mint
    function mintUSDT(uint256 quantity) public checkSoldOut {
        uint256 price = quantity * mysteryBoxPrice * (10**6); // amount * Box price * wei => n * 20 * 1000000
        console.log("price: ", price);
        require(
            IERC20(USDT_ADDRESS).balanceOf(msg.sender) >= price,
            "Not enough USDT"
        );
        console.log("here");
        IERC20(USDT_ADDRESS).transferFrom(msg.sender, address(this), price);
        IERC20(USDT_ADDRESS).transfer(
            owner(),
            IERC20(USDT_ADDRESS).balanceOf(address(this))
        );
        _safeMint(msg.sender, quantity);

        emit MintUSD(msg.sender, quantity, price);
    }

    function checkPrice(uint256 quantity) public view returns (uint256) {
        uint256 price = (quantity * mysteryBoxPrice * 10**36) / maticMockup; // mock up matic price
        return price;
    }

    // require Matic to mint
    function mintMatic(uint256 quantity) public payable checkSoldOut {
        // uint256 price = (quantity * mysteryBoxPrice * 10 ** 36) / getMATICPrice() ;
        uint256 price = (quantity * mysteryBoxPrice * 10**36) / maticMockup; // mock up matic price

        require(msg.value >= price, "Insufficient MATIC");
        _safeMint(msg.sender, quantity);
        payable(owner()).transfer(address(this).balance);

        emit MintMatic(msg.sender, quantity, price);
    }

    function adminMint(address _to, uint256 quantity)
        public
        onlyOwner
        checkSoldOut
    {
        _safeMint(_to, quantity);

        emit AdminMint(_to, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory bURI) public onlyOwner {
        baseURI = bURI;
    }

    function checkBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function checkBalanceUSDT() public view onlyOwner returns (uint256) {
        return IERC20(USDT_ADDRESS).balanceOf(address(this));
    }

    function withdrawUSDT(address payable _to, uint256 amount)
        public
        onlyOwner
    {
        IERC20(USDT_ADDRESS).transfer(_to, amount);
    }

    function withdraw(address _to, uint256 amount) public onlyOwner {
        payable(_to).transfer(amount);
    }

    function withdrawAll(address _to) public onlyOwner {
        payable(_to).transfer(address(this).balance);
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory sbaseURI = _baseURI();
        return
            bytes(sbaseURI).length != 0
                ? string(abi.encodePacked(sbaseURI, Strings.toString(tokenId)))
                : "";
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
