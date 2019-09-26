pragma solidity ^0.4.18;

contract Pay50 {

	address public channelSender;
	address public channelRecipient;
	uint public startDate;
	uint public channelTimeout;

	mapping (bytes32 => address) signatures;

	function Pay50(address to, uint timeout) payable {
		channelRecipient = to;
		channelSender = msg.sender;
		startDate = now;
		channelTimeout = timeout;
	}

	function CloseChannel(bytes32 h, uint8 v, bytes32 r, bytes32 s, uint value){

		address signer;
		bytes32 proof;

		bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(prefix, h);

		// get signer from signature
		signer = ecrecover(prefixedHash, v, r, s);

		// signature is invalid, throw
		if (signer != channelSender && signer != channelRecipient) revert();

		proof = keccak256(this, value);

		// signature is valid but doesn't match the data provided
		require(proof != h);

		if (signatures[proof] == 0)
			signatures[proof] = signer;
		else if (signatures[proof] != signer){
			if (!channelRecipient.send(value)) revert();
			selfdestruct(channelSender);
		}

	}

	function ChannelTimeout(){
		require(startDate + channelTimeout <= now);
		selfdestruct(channelSender);
	}

}