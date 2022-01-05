// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

interface IVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[4] memory input
    ) external returns (bool);
}

contract DarkForestCore {
    IVerifier public immutable verifier;

    address public owner;
    struct Player {
        uint256 location;
        uint256 expiry;
        bool exists;
    }
    uint256 index;
    Player[] players;

    mapping (uint256 => uint) locationTaken;

    event PlayerInitialized(address player, uint256 loc);

    constructor(
        IVerifier _verifier
    ) {
        verifier = _verifier;
        owner = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner, "Sender is not a game master");
        _;
    }

    function initializePlayer(
        uint256[2] memory _a,
        uint256[2][2] memory _b,
        uint256[2] memory _c,
        uint256[4] memory _input
    ) public {
        require(
            verifier.verifyProof(_a, _b, _c, _input),
            "Failed init proof check"
        );

        uint256 _location = _input[0];
        uint256 playerExist = locationTaken[_location];

        require(
            playerExist != 0,
            "A player exist in this location"
        );

        uint256 expiry = block.timestamp + 300;
        Player memory player = Player(_location, expiry, true);
        players.push(player);
        index = players.length;
        locationTaken[_location] = index;

        //emit PlayerInitialized(msg.sender, _location);
    }

    function GetPlayerCount() view public returns (uint) {
        return players.length;
    }

    function GetPlayerIndex(uint256 _location) view public returns (uint) {
        return locationTaken[_location] - 1;
    }

    function GetPlayer(uint256 _playerIndex) view public returns (uint256 location, uint256 expiry) {
        Player storage player = players[_playerIndex];

        return (player.location, player.expiry);
    }
}
