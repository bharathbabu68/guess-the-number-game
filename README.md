# Number Guessing Game - Single Number Bingo

## Overview
This game is a smart contract deployed on the Inco network. It offers a fun and secure platform for players to test their luck and intuition in guessing a hidden number. Leveraging the strengths of the Inco network and Fully Homomorphic Encryption (FHE), this game stands out for its fair play and innovative use of blockchain technology in gaming.

## Game Concept
Players participate in a game by guessing a randomly generated number, encrypted for security. The game is divided into three difficulty levels - Easy, Medium, and Hard - each varying in the range of numbers to guess and the participation fee. The unique challenge of the game is to guess the correct number with as few attempts as possible.

## Features
- Three Levels of Difficulty: Easy, Medium, and Hard, to cater to different skill levels.
- Encrypted Guessing Mechanism: Ensures fairness and integrity of the game using the TFHE library.
- Reward System: The winner receives a reward, accumulated from the participation fees of all players in that round.
- Transparent Record of Attempts: Tracks the number of tries taken by the winning player to guess the correct number.
- Built on Inco Network: Leverages the efficiency and security features of the Inco network for decentralized gaming.

## Participation
- Players can join a game by paying a fee, the amount of which depends on the chosen difficulty level. The contract owner sets these fees.

## Guessing the Number
Players submit their guesses in an encrypted format to maintain game integrity. Each guess is counted, and the game continues until the correct number is guessed.

## Winning Criteria
The first player to correctly guess the number wins the round. The winner is awarded the cumulative fees from that game's participants, and the contract records their winning attempt count.

## Game Rounds
Each game round is independent, and new rounds can be created and joined by players. The game continues to cycle through rounds, offering continuous play.