# An Efficient Unidirectional Micropayment Channel on Ethereum
This is the accompanying code for the article "An Efficient Unidirectional Micropayment Channel on Ethereum". It consists of:

 -   Four Solidity contracts: `EthWord`, `Pay50`, `PayMerkle`, `PayMerkleExtension`.
-   Helper scripts in order to test `PayMerkle` contract.
## Test Case
### Senario
Assume that Alice runs an online service for which she accepts (`Ether`) payments on a micro-level (i.e., a very low fraction of
`Ether` that costs less than one dollar). Bob is interested in that service and he wants to utilize it.
### requirements
The following programs are required to test this senario:
 1. [Nodejs](https://nodejs.org/en/)
 2. [Web3](https://www.npmjs.com/package/web3)
 3. [ethereumjs-util](https://www.npmjs.com/package/ethereumjs-util)
#### Channel Setup (Running by Bob)
Suppose that Bob estimates the number of maximum payments he is willing to make is `4096` with a minimum unit of payments of `1 Wei`. He create a Merkle Tree with number of leaves equal to `channelCapacity = 4096` by executing  the following code on his Nodejs console.

   ```js
const { MerkleTree } = require('../helpers/merkletree.js');
const Web3 = require('web3');
const { keccak256, bufferToHex } = require('ethereumjs-util');
const crypto = require('crypto');   
const web3 = new Web3(new Web3.providers.HttpProvider('http://127.0.0.1:8545'));
//Create MerkleTree
const channelCapacity = 4096; 
const leaves =[];
const seed = crypto.randomBytes(256);
let rn = keccak256(seed);
for(i = channelCapacity; i > 0; i--){
        let a = web3.eth.abi.encodeParameter('uint256',web3.utils.toWei(`${i}`, "wei"));
        let b = bufferToHex(rn);
        let ab = a + b.slice(2);
        leaves.unshift(ab);//push at the beginning of the array 
        rn = keccak256(rn);
}
const merkleTree = new MerkleTree(leaves);
const treeRoot = merkleTree.getHexRoot();
console.log("seed : " + bufferToHex(seed));
console.log("Tree Root : " + treeRoot);
```
### Channel Deployment (Running by Bob)
Bob deploys `PayMerkle` smart contract on Ethereum to act as a trusted third party.  The mart contract constructor parameters  are:
1.  Alice's address on Ethereum.
2. A timeout value before the channel is closed.
3. The root of the Merkle tree `treeRoot`.

Also, Bob has to send the  amount of  `4096 Wei` to the smart contract to be held in escrow and pay Alice when she submits a valid Merkle proof.

### Off-chain Payments (Running by Bob and Alice)
Alice and Bob are performing transactions off-chain. Every time Bob wants to utilize Alice's service, he sends her a new Merkle proof `proof` for an amount of `i` of `Wei`. To obtain the Merkle proof,   he executes the following code on his previously opened Nodejs console:
```js
const claimedLeaf = leaves[i - 1];
const claimedValue = claimedLeaf.slice(0,66);
const randomValue = '0x'+claimedLeaf.slice(66);
const proof = merkleTree.getHexProof(claimedLeaf);
```
Then, Bob sends the values of `claimedValue, randomValue, proof` to Alice.  From her side, she verifies that `claimedValue||randomValue` is a part of the Merkle tree depolyed in the smart contract by calls `VerifyMerkleProof` function on her Nodejs console, and based on the output she decides to accept or reject.
```js
const { keccak256, bufferToHex } = require('ethereumjs-util');
function VerifyMerkleProof(_claimedValue, _randomValue, _proof, _treeRoot) {
	let node = bufferToHex(keccak256(_claimedValue + _randomValue.slice(2)));
        for (i = 0; i < _proof.length; i++) {
          let proofElement = _proof[i];
          if (node < proofElement)
            node = bufferToHex(keccak256(node + proofElement.slice(2)));
          else
            node = bufferToHex(keccak256(proofElement + node.slice(2)));
          }
         if (node == treeRoot)
	    return true;
	 else
	    return false;
     }  

console.log(VerifyMerkleProof(claimedValue, randomValue, proof, treeRoot))  
``` 
### Channel Close (Runing by Alice)
Once, Alice and Bob agree that there is no more transactions going between them, Alice invokes the `CloseChannel` function on `PayMerkle` smart contract by sending the latest values of `claimedValue, randomValue, proof`  (the proof for largest amount) to the smart contract which will verify it and release the payment to Alice.
