// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

interface IVerifier {
    function verifyInitProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[3] memory input
    ) external returns (bool);

    function verifyMoveProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[4] memory input
    ) external returns (bool);
}

contract DarkForestCore {
    IVerifier public immutable verifier;
    // A struct of the player to hold the current location hash and an expiry timestamp of 5mins
    struct Player {
        address user;
        uint256 location;
        uint256 initExpiry;
        uint256 moveExpiry;
        bool exists;
        uint256 pendingResources;
        uint256 resources;
    }
    struct Planet {
        uint256 index;
        uint256 resources;
    }
    
    address public owner;
    uint256 index;
    Player[] players;
    Player defaultPlayer;

    // We will map the location hash to the player struct in order to validate whether a particular location already has a player in it
    mapping (uint256 => Player) locationTaken;
    mapping (uint256 => uint256) locationIndex;
    mapping (uint256 => Planet) isPlanet;
    // mapping the player's address to his index in the player's array
    mapping (address => uint256) playerPosition;

    event PlayerInitialized(address player, uint256 loc);
    event PlanetInitialized(uint256 loc, uint256 resources);

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
        uint256[3] memory _input
    ) public {
        require(
            verifier.verifyInitProof(_a, _b, _c, _input),
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
        Player memory player = Player(msg.sender, _location, expiry, 0, true, 0, 0);
        players.push(player);
        locationTaken[_location] = player;
        locationIndex[_location] = players.length - 1;
        playerPosition[msg.sender] = players.length - 1;
    }

    function initializePlanet(
        uint256[4] memory _input
    ) public {
        for (uint256 i = 1; i < _input.length; i++) {
            uint256 planetIndex = _input[i];
            uint256 planetResources = 10*(i);

            Planet memory planet = Planet(planetIndex, planetResources);
            isPlanet[planetIndex] = planet;

            emit PlanetInitialized(planetIndex, planetResources);
        }
    }

    function move(
        uint256[2] memory _a,
        uint256[2][2] memory _b,
        uint256[2] memory _c,
        uint256[4] memory _input
    ) public {
        require(
            verifier.verifyMoveProof(_a, _b, _c, _input),
            "Failed init proof check"
        );
        uint256 presentLocation = _input[0];
        uint256 newLocation = _input[1];
        uint256 playerIndex = playerPosition[msg.sender];
        uint256 existingLocation = players[playerIndex].location;
        uint256 activePlayerIndex = locationIndex[newLocation];

        require(
            existingLocation == presentLocation,
            "Player does not exist at current location"
        );
        require(
            players[playerIndex].moveExpiry <= block.timestamp,
            "Player has to wait 30 seconds before moving to a new location"
        );
        players[playerIndex].moveExpiry = block.timestamp + 30;
        if (presentLocation != newLocation) {
            players[playerIndex].resources += players[playerIndex].pendingResources;
            players[playerIndex].pendingResources = 0;
            players[playerIndex].pendingResources = players[activePlayerIndex].pendingResources;
            players[activePlayerIndex].pendingResources = 0;
        }
        locationIndex[presentLocation] = 9999999999999999999999999999;
        locationIndex[newLocation] = playerIndex;
        locationTaken[presentLocation] = defaultPlayer;
        locationTaken[newLocation] = players[playerIndex];
        players[playerIndex].location = newLocation;
    }

    function mineResources(uint256 amount) public {
        uint256 playerIndex = playerPosition[msg.sender];
        uint256 existingLocation = players[playerIndex].location;
        uint256 isPlanetIndex = existingLocation % 4;

        Planet memory currentPlanet = isPlanet[isPlanetIndex];

        require(
            currentPlanet.index > 0,
            "This location is not a planet"
        );
        require(
            amount <= currentPlanet.resources,
            "This planet does not have up to the requested resources"
        );
        isPlanet[isPlanetIndex].resources -= amount;
        players[playerIndex].pendingResources += amount;
    }

    function GetPlayerCount() view public returns (uint) {
        return players.length;
    }

    function GetAllPlayers() view public returns (uint256[] memory) {
        uint256[] memory location = new uint256[](players.length);

        for (uint i = 0; i < players.length; i++) {
            Player storage player = players[i];

            location[i] = player.location;
        }

        return (location);
    }

    function GetPlayer() view public returns (
        uint256 location, 
        uint256 initExpiry, 
        uint256 pendingResources, 
        uint256 resources) {
        uint256 playerIndex = playerPosition[msg.sender];
        Player storage player = players[playerIndex];

        return (player.location, player.initExpiry, player.pendingResources, player.resources);
    }

    function GetPlanet(uint256 _index) view public returns (uint256 resources) {
        Planet storage planet = isPlanet[_index];

        return (planet.resources);
    }
}
