# Hedera Voting System

A decentralized, secure, and transparent voting application built on the Hedera network with a Flutter frontend.


# Hackathon Track

Open Track: This project demonstrates a real-world application of blockchain technology by building a decentralized, secure, and transparent voting system on the Hedera network. It showcases how distributed ledger technology can solve critical challenges in electoral integrity and voter authentication.


# The Problem

Traditional voting systems often lack transparency and are vulnerable to tampering. Voters must place their trust in a central authority to count votes accurately and honestly, but this trust can be misplaced. Furthermore, ensuring that each person votes only once without compromising their privacy is a significant challenge. This centralization creates single points of failure and opportunities for corruption.


# Our Solution: A Decentralized & Verifiable Voting System

The Hedera Voting System provides a tamper-proof and publicly verifiable voting process. By leveraging a smart contract on the Hedera network, we create an immutable and transparent log of all votes.

To prevent duplicate voting, the system requires a hash of the user's National Identification Number (NIN). The smart contract tracks which NIN hashes have already been used to cast a vote, ensuring the "one person, one vote" principle is upheld in a privacy-preserving manner (as the actual NIN is never stored on-chain).


# Architecture and How it Uses Hedera

This project uses the Hedera network's EVM compatibility to run a Solidity smart contract, with a Flutter frontend for user interaction.

1.  Frontend (Flutter): A cross-platform application built with Flutter that allows users to view candidates, cast their vote, and see real-time results.
2.  Hedera JSON-RPC Relay: The Flutter application communicates with the Hedera network via the JSON-RPC relay.
3.  Backend (Hedera Smart Contract): A Solidity smart contract deployed to the Hedera Testnet. This contract is the core of the system and manages the entire voting process:
    *   Candidate Management: Stores the list of candidates.
    *   Vote Casting: Contains the `vote()` function, which increments a candidate's vote count and records the voter's NIN hash.
    *   Fraud Prevention: Maintains a mapping to track which NIN hashes have already voted.
    *   Transparency: Provides public functions to view candidate vote counts.


# Deployed Contract & Demo

*   Contract on HashScan: [View the deployed contract here] https://hashscan.io/testnet/address/0x754413bb34935080abd5762010CEc2F1e4201279
*   Demo Video: [Watch the 2-minute demo video here] https://youtu.be/sRn1Cg1dtJs


# Features

*   Securely cast a vote for a candidate.
*   Prevent double-voting using a NIN hash.
*   View real-time, transparent election results.
*   Built with a cross-platform Flutter UI for Android, iOS, Windows, and Linux.


# Tech Stack

*   Frontend: Flutter
*   DLT/Blockchain: Hedera Smart Contract Service (via EVM)
*   Languages: Dart, Solidity


# How to Test the Project

Judges can test the application by running it locally, an emulator or generating an apk file and running it on a mobile device.

# Option 1: Run Locally Using Git Bash(Recommended)

1.  Clone the repository:
    git clone https://github.com/TherealEltech/hedera-voting-system.git

3.  Get Flutter dependencies:
    flutter pub get

4.  Run the app:
    flutter run -d chrome
