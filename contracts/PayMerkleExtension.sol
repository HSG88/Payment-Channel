pragma solidity ^0.4.18;

contract PayMerkleExtended {
    address public channelSender;
    address public channelRecipient;
    uint public startDate;
    uint public channelTimeout;
    bytes32 public root;

    function PayMerkleExtended(address to, uint _timeout, bytes32 _root) public payable {
        require(msg.value>0);
        channelRecipient = to;
        channelSender = msg.sender;
        startDate = now;
        channelTimeout = _timeout;
        root = _root;
    }
    function AddBalance(bytes32 _newRoot) public payable {
      if (root < _newRoot)
          root = keccak256(root, _newRoot);
      else
          root = keccak256(_newRoot, root);
    }
  function CloseChannel(uint256 _amount, bytes32[] proof) public {
        bytes32 computedHash = keccak256(_amount);
        require(verifyMerkle(root, computedHash, proof));
        channelRecipient.transfer(_amount);
        selfdestruct(channelSender);
    }
    function verifyMerkle (bytes32 root, bytes32 leaf, bytes32[] proof) public pure returns (bool) {
      bytes32 computedHash = leaf;
      for (uint256 i = 0; i < proof.length; i++) {
          if (computedHash < proof[i])
            computedHash = keccak256(computedHash, proof[i]);
          else
            computedHash = keccak256(proof[i], computedHash);
          }
        return computedHash==root;
    }
    function ChannelTimeout() public {
        require(now >= startDate + channelTimeout);
        selfdestruct(channelSender);
    }
}