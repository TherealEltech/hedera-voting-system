import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'dart:typed_data';
import 'package:convert/convert.dart';

class HederaService {
  late Web3Client _web3client;
  late EthPrivateKey _credentials;
  late DeployedContract _contract;
  late EthereumAddress _contractAddress;

  // Updated ABI for new contract with NIN hash tracking
  final String _contractAbi = """
  [
    {
      "inputs": [],
      "stateMutability": "nonpayable",
      "type": "constructor"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": true,
          "internalType": "uint256",
          "name": "_candidateId",
          "type": "uint256"
        },
        {
          "indexed": true,
          "internalType": "bytes32",
          "name": "_ninHash",
          "type": "bytes32"
        }
      ],
      "name": "Voted",
      "type": "event"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "name": "candidates",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "id",
          "type": "uint256"
        },
        {
          "internalType": "string",
          "name": "name",
          "type": "string"
        },
        {
          "internalType": "uint256",
          "name": "voteCount",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "candidatesCount",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "bytes32",
          "name": "",
          "type": "bytes32"
        }
      ],
      "name": "hasVoted",
      "outputs": [
        {
          "internalType": "bool",
          "name": "",
          "type": "bool"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "_candidateId",
          "type": "uint256"
        },
        {
          "internalType": "bytes32",
          "name": "_ninHash",
          "type": "bytes32"
        }
      ],
      "name": "vote",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "bytes32",
          "name": "_ninHash",
          "type": "bytes32"
        }
      ],
      "name": "checkIfVoted",
      "outputs": [
        {
          "internalType": "bool",
          "name": "",
          "type": "bool"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    }
  ]
  """;

  HederaService({required String privateKey}) {
    final rpcUrl = dotenv.env['HEDERA_TESTNET_RPC_URL']!;
    _web3client = Web3Client(rpcUrl, Client());
    _credentials = EthPrivateKey.fromHex(privateKey);

    _contractAddress =
        EthereumAddress.fromHex(dotenv.env['VOTING_CONTRACT_ADDRESS']!);

    _contract = DeployedContract(
      ContractAbi.fromJson(_contractAbi, 'Voting'),
      _contractAddress,
    );
  }

  /// Calls the 'vote' function on the smart contract with NIN hash
  Future<String> vote(int candidateId, String ninHash) async {
    try {
      final voteFunction = _contract.function('vote');
      
      // Convert hex string to bytes32
      final hashBytes = hex.decode(ninHash.replaceFirst('0x', ''));
      
      final transaction = Transaction.callContract(
        contract: _contract,
        function: voteFunction,
        parameters: [
          BigInt.from(candidateId),
          Uint8List.fromList(hashBytes),
        ],
      );

      final txHash = await _web3client.sendTransaction(
        _credentials,
        transaction,
        chainId: 296, // Hedera Testnet Chain ID
      );

      print("Vote transaction hash: $txHash");
      return "SUCCESS"; // Simple success indicator
    } catch (e) {
      // Check for already voted error
      print("Vote error caught: $e");
      if (e.toString().contains("You have already voted")) {
        throw Exception("ALREADY_VOTED");
      }
      if (e.toString().contains("ALREADY_VOTED")) {
        rethrow;
      }
      throw Exception("UNKNOWN_ERROR");
    }
  }

  /// Get total number of candidates
Future<int> getCandidatesCount() async {
  try {
    final function = _contract.function('candidatesCount');
    final result = await _web3client.call(
      contract: _contract,
      function: function,
      params: [],
    );
    return (result[0] as BigInt).toInt();
  } catch (e) {
    print("Error getting candidates count: $e");
    return 0;
  }
}

/// Get candidate details by ID
Future<Map<String, dynamic>?> getCandidate(int candidateId) async {
  try {
    final function = _contract.function('candidates');
    final result = await _web3client.call(
      contract: _contract,
      function: function,
      params: [BigInt.from(candidateId)],
    );
    
    return {
      'id': (result[0] as BigInt).toInt(),
      'name': result[1] as String,
      'voteCount': (result[2] as BigInt).toInt(),
    };
  } catch (e) {
    print("Error getting candidate $candidateId: $e");
    return null;
  }
}

/// Get all candidates with their vote counts
Future<List<Map<String, dynamic>>> getAllCandidates() async {
  try {
    final count = await getCandidatesCount();
    List<Map<String, dynamic>> candidates = [];
    
    for (int i = 1; i <= count; i++) {
      final candidate = await getCandidate(i);
      if (candidate != null) {
        candidates.add(candidate);
      }
    }
    
    return candidates;
  } catch (e) {
    print("Error getting all candidates: $e");
    return [];
  }
}

  /// Check how many candidates are in the contract
Future<void> debugContractState() async {
  try {
    // Check candidates count
    final countFunction = _contract.function('candidatesCount');
    final countResult = await _web3client.call(
      contract: _contract,
      function: countFunction,
      params: [],
    );
    print('🔍 Candidates Count: ${countResult[0]}');

    // Try to get candidate 1 details
    final candidateFunction = _contract.function('candidates');
    for (int i = 1; i <= 4; i++) {
      try {
        final candidateResult = await _web3client.call(
          contract: _contract,
          function: candidateFunction,
          params: [BigInt.from(i)],
        );
        print('🔍 Candidate $i: ID=${candidateResult[0]}, Name=${candidateResult[1]}, Votes=${candidateResult[2]}');
      } catch (e) {
        print('❌ Candidate $i does not exist');
      }
    }
  } catch (e) {
    print('❌ Debug error: $e');
  }
}
}