// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity >=0.8.13 <0.9.0;

import "fhevm/lib/TFHE.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NumberGuessing is Ownable {
    constructor(address initialOwner) Ownable(initialOwner) {}

    uint256 public gameIdCounter = 0;

    // The game ends as soon as someone guesses the actual number stored in the contract
    // There will be 3 modes of difficuly - easy, medium, and hard

    struct scoreValue {
        uint256 easyGamesWon;
        uint256 mediumGamesWon;
        uint256 hardGamesWon;
    }

    struct Game {
        address[] players;
        address gameWinner;
        uint256 numberOfTriesForWinner;
        uint256 gameStatus; // 0 when game is created (in this phase players are allowed to join the game ), 1 when game is started ( in this phase , the random number is set), and 2 when game is finished
        uint256 numberofPlayers;
        uint256 gameId;
        uint256 difficultyLevel; // This will either be 0 (easy), 1 (Medium), or 2 (hard)
        euint8 encryptedValuetoGuess;
        uint8 decryptedResult; // This will be revealed only after someone finds the result
    }

    Game[] public games;

    mapping(address => scoreValue) public addressScores;
    mapping(uint256 => uint256) public gameFee;
    mapping(uint256 => mapping(address => uint256)) private guessCount;

    function setGameFees(uint256 difficultyLevel, uint256 feeValue)
        public
        onlyOwner
    {
        gameFee[difficultyLevel] = feeValue;
    }

    function getGameFeeValue(uint256 difficultyLevel)
        public
        view
        returns (uint256)
    {
        require(
            difficultyLevel >= 0 && difficultyLevel <= 2,
            "Invalid difficulty level passed"
        );
        return gameFee[difficultyLevel];
    }

    function createNewGame(uint256 difficultyLevel) public payable {
        require(
            difficultyLevel >= 0 && difficultyLevel <= 2,
            "Invalid difficulty level passed"
        );
        require(
            msg.value == gameFee[difficultyLevel],
            "Game fee not sent to create game!"
        );

        Game memory newGame;
        newGame.gameStatus = 0; // Game is created but not started
        newGame.numberofPlayers = 1;
        newGame.gameId = gameIdCounter;
        newGame.difficultyLevel = difficultyLevel;
        newGame.encryptedValuetoGuess = TFHE.randEuint8();
        newGame.decryptedResult = 0;

        games.push(newGame); // Add new game to games array
        games[gameIdCounter].players.push(msg.sender); // Initialize with the creator as the first player

        gameIdCounter++; // Increment game ID counter
    }

    function startGame(uint256 gameId) public {
        // Game can be started by any of the joined players as soon as there atleast two people who join the game
        // Once game is started, based on the difficulty level of the game - the encrypted number will vary
        require(gameId < gameIdCounter, "Invalid game ID passed");
        Game storage currentGame = games[gameId];
        require(
            currentGame.gameStatus == 0,
            "Invalid game status. Game is already active / complete !"
        );
        euint8 actualEncryptedNumber = currentGame.encryptedValuetoGuess;
        euint8 updatedRandomEncryptedNumber;
        if (currentGame.difficultyLevel == 0) {
            // If game is easy then the encrypted number will be within 0-10
            updatedRandomEncryptedNumber = TFHE.rem(actualEncryptedNumber, 10);
        } else if (currentGame.difficultyLevel == 1) {
            updatedRandomEncryptedNumber = TFHE.rem(actualEncryptedNumber, 20);
            // If game is medium, then encrypted number will be within 0-20
        } else {
            updatedRandomEncryptedNumber = TFHE.rem(actualEncryptedNumber, 30);
            // If game is hard, then encrypted number will be within 0-30
        }
        currentGame.encryptedValuetoGuess = updatedRandomEncryptedNumber;
        currentGame.gameStatus = 1;
    }

    function makeGuess(uint256 gameId, bytes calldata encryptedGuessinBytes)
        public
        returns (uint256)
    {
        // Check if game ID passed is valid
        require(gameId < gameIdCounter, "Invalid game ID passed");

        Game storage currentGame = games[gameId];

        // Check if game is started and active, i.e game status is 1
        require(
            currentGame.gameStatus == 1,
            "Game is not started / is already complete !"
        );

        address userAddress = msg.sender;
        // Check if user is already part of the game and allowed to make a guess
        address[] memory players = currentGame.players;
        bool flag;
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == userAddress) {
                flag = true;
            }
        }
        require(flag == true, "User is not a part of the game !");

        // Increment guess count
        guessCount[gameId][msg.sender]++;

        euint8 userEncryptedGuess = TFHE.asEuint8(encryptedGuessinBytes);
        euint8 actualEncryptedNumber = currentGame.encryptedValuetoGuess;

        // Check if guess is correct
        ebool guessResult = TFHE.eq(userEncryptedGuess, actualEncryptedNumber);
        bool guessResultDecrypted = TFHE.decrypt(guessResult);
        if (guessResultDecrypted == true) {
            // User guessed correctly, wins game !
            currentGame.gameStatus = 2;
            uint8 actualNumber = TFHE.decrypt(actualEncryptedNumber);
            currentGame.gameWinner = msg.sender;
            currentGame.decryptedResult = TFHE.decrypt(actualEncryptedNumber);
            currentGame.numberOfTriesForWinner = guessCount[gameId][msg.sender];
            uint256 rewardAmount = currentGame.numberofPlayers *
                gameFee[currentGame.difficultyLevel];
            payable(msg.sender).transfer(rewardAmount);
            return actualNumber;
        } else {
            return 0;
        }
    }

    function joinActiveGame(uint256 gameId) public payable {
        require(gameId < gameIdCounter, "Invalid game ID passed");
        Game storage gameToJoin = games[gameId];

        // Check game status and required fee
        require(
            gameToJoin.gameStatus == 0,
            "Game already started or completed"
        );
        require(
            msg.value == gameFee[gameToJoin.difficultyLevel],
            "Incorrect game fee"
        );

        // Check if the user has already joined the game
        for (uint256 i = 0; i < gameToJoin.players.length; i++) {
            require(
                gameToJoin.players[i] != msg.sender,
                "User has already joined this game"
            );
        }

        // Add the user to the game's players array
        gameToJoin.players.push(msg.sender);
        gameToJoin.numberofPlayers++;
    }
}
