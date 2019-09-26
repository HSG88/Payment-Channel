pragma solidity ^0.4.18;

contract EthWord {

    address public channelSender;
    address public channelRecipient;
    uint public startDate;
    uint public channelTimeout;
    uint public channelMargin;
    bytes32 public channelTip;

    function EthWord(address to, uint timeout, uint margin, bytes32 tip) public payable {
        channelRecipient = to;
        channelSender = msg.sender;
        startDate = now;
        channelTimeout = timeout;
        channelMargin = margin;
        channelTip = tip;
    }

    function CloseChannel(bytes32 _word, uint _wordCount) public {
        require(msg.sender==channelRecipient);
        bytes32 wordScratch = _word;
        for (uint i = 1; i <= _wordCount; i++) {
            wordScratch = keccak256(wordScratch);
        }

        require(wordScratch == channelTip);
        require(channelRecipient.send(_wordCount * channelMargin));
        selfdestruct(channelSender);
    }

    function ChannelTimeout() public {
        require(now >= startDate + channelTimeout);
        selfdestruct(channelSender);
    }

}
