// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract CommitReveal {
    struct Commit {
        bytes32 commit;
        uint64 block;
        bool revealed;
    }

    mapping(address => Commit) public commits;

    event CommitHash(address indexed sender, bytes32 dataHash, uint64 block);
    event RevealHash(address indexed sender, uint choice);

    function commit(bytes32 dataHash) public {
        require(commits[msg.sender].block == 0, "Commit already made");
        
        commits[msg.sender] = Commit({
            commit: dataHash,
            block: uint64(block.number),
            revealed: false
        });

        emit CommitHash(msg.sender, dataHash, uint64(block.number));
    }

    function reveal(uint choice, string memory secret) public {
        require(commits[msg.sender].revealed == false, "Already revealed");
        require(commits[msg.sender].block != 0, "No commit found");

        bytes32 computedHash = getHash(choice, secret);
        require(computedHash == commits[msg.sender].commit, "Reveal does not match commit");

        commits[msg.sender].revealed = true;
        emit RevealHash(msg.sender, choice);
    }

    function getHash(uint choice, string memory secret) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(choice, secret));
    }
}
