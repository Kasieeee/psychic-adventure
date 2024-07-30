// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RockPaperScissors{
    //Enum to create the Choices
    enum Choice {None, Rock, Paper, Scissors}

    struct Player {
        address payable playerAddress;
        bytes32 commitment;
        Choice choice;
        uint256 wager;
    }

    // State variables
    Player public player1;
    Player public player2;
    
    bool public isPlayer1Committed = false;
    bool public isPlayer2Committed = false;
    bool public isPlayer1Revealed = false;
    bool public isPlayer2Revealed = false;

    // Ensure the players are set
    modifier playersSet() {
        require(player1.playerAddress != address(0) && player2.playerAddress != address(0), "Players not set");
        _;
    }
    
    // Ensure player has not committed
    modifier hasNotCommitted() {
        require(
            !(msg.sender == player1.playerAddress && isPlayer1Committed) &&
            !(msg.sender == player2.playerAddress && isPlayer2Committed),
            "Player already committed"
        );
        _;
    }

    // Ensure both players committed
    modifier bothPlayersCommitted() {
        require(isPlayer1Committed && isPlayer2Committed, "Both players must commit first");
        _;
    }

    // Ensure both players revealed
    modifier bothPlayersRevealed() {
        require(isPlayer1Committed && isPlayer2Committed && isPlayer1Revealed && isPlayer2Revealed, "Players must commit and reveal before determining the winner");
        _;
    }

    // Set player addresses (call once)
    function setPlayers(address payable _player1, address payable _player2) external {
        require(player1.playerAddress == address(0) && player2.playerAddress == address(0), "Players already set");
        player1.playerAddress = _player1;
        player2.playerAddress = _player2;
    }

    // Player commits to their choice
    function commit(Choice _choice, string memory _secret) external payable playersSet hasNotCommitted {
        // Ensure that the player sends some ether as their wager
        require(msg.value > 0, "Wager must be greater than zero");
        require(_choice == Choice.Rock || _choice == Choice.Paper || _choice == Choice.Scissors, "Invalid choice");

        // Determine which player is calling the function
        Player storage currentPlayer = (msg.sender == player1.playerAddress) ? player1 : player2;

        // Compute a hash of the choice and secret
        bytes32 _commitment = keccak256(abi.encodePacked(_choice, _secret));

        // Store the hash and the player's wager
        currentPlayer.commitment = _commitment;
        currentPlayer.wager = msg.value;

        // Update the boolean state variable that tracks if the player has committed
        if (msg.sender == player1.playerAddress) {
            isPlayer1Committed = true;
        } else {
            isPlayer2Committed = true;
        }
    }

    // Player reveals their choice
    function reveal(Choice _choice, string memory _secret) external playersSet bothPlayersCommitted {
        // Determine which player is calling the function
        Player storage currentPlayer = (msg.sender == player1.playerAddress) ? player1 : player2;

        // Verify that the hash of the revealed choice and secret matches the player's commitment
        require(keccak256(abi.encodePacked(_choice, _secret)) == currentPlayer.commitment, "Invalid reveal!");

        // Update the game state with the player's revealed choice
        currentPlayer.choice = _choice;

        // Update the boolean state variable that tracks if the player has revealed
        if (msg.sender == player1.playerAddress) {
            isPlayer1Revealed = true;
        } else {
            isPlayer2Revealed = true;
        }
    }

    // Determine the winner
    function determineWinner() external playersSet bothPlayersRevealed {
        // Compare the choices of player1 and player2
        if (player1.choice == player2.choice) {
            // Draw: Return the wagers to the respective players
            player1.playerAddress.transfer(player1.wager);
            player2.playerAddress.transfer(player2.wager);
        } else if (
            (player1.choice == Choice.Rock && player2.choice == Choice.Scissors) ||
            (player1.choice == Choice.Paper && player2.choice == Choice.Rock) ||
            (player1.choice == Choice.Scissors && player2.choice == Choice.Paper)
        ) {
            // Player 1 Wins: Transfer the combined pot to player1
            player1.playerAddress.transfer(player1.wager + player2.wager);
        } else {
            // Player 2 Wins: Transfer the combined pot to player2
            player2.playerAddress.transfer(player1.wager + player2.wager);
        }

        // Reset the game state for the next round
        resetGame();
    }

    // Function to reset the game state
    function resetGame() internal {
        player1.commitment = 0;
        player2.commitment = 0;
        player1.choice = Choice.None;
        player2.choice = Choice.None;
        player1.wager = 0;
        player2.wager = 0;
        isPlayer1Committed = false;
        isPlayer2Committed = false;
        isPlayer1Revealed = false;
        isPlayer2Revealed = false;
    }
}
