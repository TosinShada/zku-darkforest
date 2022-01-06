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
    // A struct of the player to hold the current location hash and an expiry timestamp of 5mins
    struct Player {
        uint256 location;
        uint256 expiry;
        bool exists;
    }
    uint256 index;
    Player[] players;

    // We will map the location hash to the player struct in order to validate whether a particular location already has a player in it
    mapping (uint256 => Player) locationTaken;

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

        emit PlayerInitialized(msg.sender, _location);
        // This assertion will confirm if the location is already taken by an existing player
        require(
            locationTaken[_location].location == 0,
            "A player exist in this location"
        );
        // This assertion will use the expiry timestamp to confirm if a player was in this location in the last five minutes however once the first assertion passes this one can't fail unless the players can move from their present location
        // require(
        //     locationTaken[_location].expiry <= block.timestamp,
        //     "A player is currently in this location"
        // );

        uint256 expiry = block.timestamp + 300;
        Player memory player = Player(_location, expiry, true);
        players.push(player);
        locationTaken[_location] = player;
    }

    function GetPlayerCount() view public returns (uint) {
        return players.length;
    }

    function GetPlayer(uint256 _location) view public returns (uint256 location, uint256 expiry) {
        Player storage player = locationTaken[_location];

        return (player.location, player.expiry);
    }
}
