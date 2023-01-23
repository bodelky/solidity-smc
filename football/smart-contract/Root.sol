pragma solidity ^0.8.12;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "github.com/thundercore/RandomLibrary/RandomLibrary.sol";
import "./FootballChild.sol";

contract Root is AccessControl {
    // ====== Event ======

    event Minted(address to, uint256 team, uint256 amount);
    event PickedWinner(uint256 winnerTeam, address winner, uint256 tokenId);
    event WinnerClaimed(address winnerTeam, uint256 value);
    event DroppedOutTeam(uint256[] teams);
    event RoundUp(uint256 newTicketPrice);
    event Receive(address from, uint256 amount);

    // ====== Variable function ======

    enum COUNTRY {
        Qatar,
        Ecuador,
        Senegal,
        Netherlands, // 0 - 3
        England,
        Iran,
        USA,
        Wales, // 4 - 7
        Argentina,
        SaudiArabia,
        Mexico,
        Poland, // 8 - 11
        France,
        Australia,
        Denmark,
        Tunisia, // 12 - 15
        Spain,
        CostaRica,
        Germany,
        Japan, // 16 - 19
        Belgium,
        Canada,
        Morocco,
        Croatia, // 20 - 23
        Portugal,
        Ghana,
        Uruguay,
        Korea, // 24 - 27
        Brazil,
        Serbia,
        Switzerland,
        Cameroon,
        Last // 28 - 31
    }

    mapping(uint256 => FootballChild) public teamAddresses;
    mapping(uint256 => bool) public dropOutTeam;
    uint256 public teamCount = 0;

    uint256 public ticketPrice = 2700 ether;

    uint256 public level;

    // bool public isSpawned;
    bool public isPicked;
    bool public isClaimed;

    address public winnerAddress;
    string public baseURI;

    struct Cart {
        uint8 team;
        uint256 amount;
    }

    constructor() {
        level = 0;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // ====== Mint function ======

    function mint(
        address to,
        uint256 country,
        uint256 quantity
    ) internal {
        FootballChild(teamAddresses[country]).mint(to, quantity);
        emit Minted(to, country, quantity);
    }

    // Admin mint
    function mintTo(address _to, Cart[] memory _cart)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 cartLength = _cart.length;
        for (uint16 i = 0; i < cartLength; i++) {
            mint(_to, _cart[i].team, _cart[i].amount);
        }
    }

    // Public sale
    function mintCart(Cart[] memory _cart) public payable {
        require(msg.value == ticketPrice * calculateAmount(_cart));
        uint256 cartLength = _cart.length;
        for (uint16 i = 0; i < cartLength; i++) {
            mint(msg.sender, _cart[i].team, _cart[i].amount);
        }
    }

    // ====== Uitlity function ======

    function calculateAmount(Cart[] memory _cart)
        public
        pure
        returns (uint256 sum)
    {
        uint256 cartLength = _cart.length;
        sum = 0;
        for (uint256 i = 0; i < cartLength; i++) {
            sum += _cart[i].amount;
        }
    }

    function spawnTeam(uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // spawn 32 teams and collect in contract
        require(teamCount + amount <= 32, "Cannot over 32 teams");
        for (uint256 i = 0; i < amount; i++) {
            // for (uint256 i = 0; i < uint256(5); i++) {
            string memory name = string(
                abi.encodePacked("Football Fantasy Team ", Strings.toString(i))
            );
            string memory sym = string(
                abi.encodePacked("FFT-", Strings.toString(i))
            );
            teamAddresses[teamCount] = new FootballChild(
                this,
                teamCount,
                name,
                sym
            );
            teamCount += 1;
        }
    }

    // ====== Winner function ======

    function pickWinner(uint256 team) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!isPicked, "Already picked");
        require(!dropOutTeam[team], "This team already lost");
        uint256 randVal = LibThunderRNG.rand();
        uint256 _totalSupply = teamAddresses[team].totalSupply();
        uint256 randomTokenId = randVal % _totalSupply; // RNG Lib
        address winner = FootballChild(teamAddresses[team]).ownerOf(
            randomTokenId
        );
        winnerAddress = winner;
        isPicked = true;

        emit PickedWinner(team, winner, randomTokenId);
    }

    function winnerClaim() public {
        require(!isClaimed, "Already claimed");
        require(msg.sender == winnerAddress, "You are not winner");
        payable(winnerAddress).transfer(address(this).balance);
        isClaimed = true;
    }

    // ====== Setter function ======

    function setPrice(uint256 newPrice) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ticketPrice = newPrice;
    }

    function setBaseURI(string memory newBaseURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseURI = newBaseURI;
    }

    function setLevel(uint256 _level) public onlyRole(DEFAULT_ADMIN_ROLE) {
        level = _level;
    }

    function setTeamAddress(uint256 team, address addr)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        teamAddresses[team] = FootballChild(addr);
    }

    function roundUp() internal {
        ticketPrice += 0.5 ether;
        setLevel(level += 1);
        emit RoundUp(ticketPrice);
    }

    function setDropOut(uint256[] memory _teams)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 teamsLength = _teams.length;
        for (uint256 i = 0; i < teamsLength; i++) {
            dropOutTeam[_teams[i]] = true;
            teamAddresses[_teams[i]].pause();
        }
        roundUp();

        emit DroppedOutTeam(_teams);
    }

    // ====== Getter function ======

    function getBaseURI() public view returns (string memory) {
        return baseURI;
    }

    function getLevel() public view returns (uint256) {
        return level;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // ====== Built-in function ======

    receive() external payable {
        emit Receive(msg.sender, msg.value);
    }
}
