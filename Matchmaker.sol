pragma solidity >=0.4.22 <0.6.0;
pragma experimental ABIEncoderV2;

contract Matchmaker {

    // matches potential machines/docker instances to clients

    uint private verifierTimeInterval = 300;
    uint private lastCheck;
    uint randNonce = 0;
    
    event ContractEnded(address payer, uint amount);
    
    constructor() public {
        lastCheck = now;
    }

    struct ImageSet {
        ImageData[] images;
        uint[] emptySlots;
    }

    struct ImageData {
        address owner;
        uint costPerMinute;
        uint maxTime;
        uint startTime;
        bool inUse;
        address currentClient;
    }

    ImageSet private imageList;
    address[] private clients;

    struct Verifiers {
        // 0 false
        // 1 true
        // 2 is undecided
        address[2] addressList;
        mapping(address => uint) verifications;
        mapping(address => uint) lastVerified;
    }

    mapping(address => uint) minerRatings;
    mapping(address => address[]) currentPings;

    mapping(address => string) publicKeys;



    mapping(address => Verifiers) pendingVerifies;

// not secure but generates a semi random number,
// issues with random numbers in solidity
    function random() internal returns(uint) {
       // increase nonce
       randNonce++;  
       return uint(keccak256(abi.encodePacked(now, 
                                              msg.sender, 
                                              randNonce))) % 100;
     }

    //check if image list contains a miner in the randomly 
// generated position
    function minerExists(uint minerPosition) public returns (bool){
        for (uint i = 0; i < imageList.emptySlots.length; i++) {
            if (imageList.emptySlots[i] == minerPosition) {
                return false;
            }
        }
        return true;
    }

    //assign two random miners to ping image
    function assignPings (address client) public{
        // select two miners at random
        uint minerOnePosition = random() % imageList.images.length;
        uint minerTwoPosition = random() % imageList.images.length; 

        // check that positions are valid
        while (!minerExists(minerOnePosition) || !minerExists(minerTwoPosition)) {
            minerOnePosition = random() % imageList.images.length;
            minerTwoPosition = random() % imageList.images.length;
        }

        // create new verifiers struct and add two miners
        // Verifiers storage pingers = Verifiers([minerOne, minerTwo]);
        address minerOne = imageList.images[minerOnePosition].owner;
        address minerTwo = imageList.images[minerTwoPosition].owner;
        // pingers.addressList.push(minerOne);
        // pingers.addressList.push(minerTwo);
        // pingers = Verifiers([minerOne, minerTwo]);
        pendingVerifies[client] = Verifiers([minerOne, minerTwo]);

        //add client to current pings mapping of both miners
        currentPings[minerOne].push(client);
        currentPings[minerTwo].push(client);

    }
    //check that the miner has written the ping results to the block chain  
    function checkVerifies() public{
        //need to check every client's verifiers
        for (uint i=0; i < clients.length; i++) {
            Verifiers storage verifiers = pendingVerifies[clients[i]];
            //check last ping
            for (uint j=0; j<verifiers.addressList.length; j++) {
                address miner = verifiers.addressList[j];
                uint lastPing = verifiers.lastVerified[miner];
                if (lastCheck > lastPing) {
                    reportFailureToPing(miner);
                } 
            }
        }
    }
    //check if any verifiers have reported unsuccessful ping 
    function checkImageFailures() public{
        for (uint i=0; i < clients.length; i++) {
            Verifiers storage verifiers = pendingVerifies[clients[i]];
            for (uint j=0; j<verifiers.addressList.length; j++) {
                address miner = verifiers.addressList[j];
                if (verifiers.verifications[miner] == 0) {
                    reportImageOffline(clients[i]);
                } 
            }
        }
    }
// very inefficient 
// check if verifier has failed to ping or 
// an image has gone offline
    function checkForExpiriations() public {
        if (now - lastCheck >= verifierTimeInterval) {
            checkVerifies();
            checkImageFailures();
            lastCheck = now;
        }

    }


// add mapping of miners to the number of failures to ping
mapping (address => uint) pingFailures;

//increments failures and punush
function reportFailureToPing(address minerAddress) public{
    pingFailures[minerAddress]++;

    if (pingFailures[minerAddress] >= 2) {
        punishPing(minerAddress);
    }

}

// am i doing the right thing here?
//maybe maintain mapping of client to image to make easier?
    function reportImageOffline(address client) public{
        for (uint i = 0; i < imageList.images.length; i++) {
            ImageData memory image = imageList.images[i];
            if (image.currentClient == client) {
                punishMiner(image.owner) ;
                removeImage(image);
            } 
        }
    }

    function verify(address addressToBeVerified, bool active) public{
        address[2] memory addressList = pendingVerifies[addressToBeVerified].addressList;
        for (uint i = 0; i < addressList.length; i++) {
            if (msg.sender == addressList[i]) {
                if (active) {
                    pendingVerifies[addressToBeVerified].verifications[msg.sender] = 1;
                } else {
                    pendingVerifies[addressToBeVerified].verifications[msg.sender] = 0;
                }
            }
        }
    }
    
    function punishMiner(address minerAddress) public {}
    function removeImage(ImageData memory image) public {}
    function punishPing(address toPunish)  public {}

    // function getPings() returns address[] {
    //     return currentPings[msg.sender];
    // }

    // // function addClient() {
    // //     clients.push(msg.sender);
    // // }

    // function removeMiner() {

    // }

    // function addMiner() {
    //     if (imageStruct.emptySlots.length == 0) {
    //         imageStruct.images.push(msg.sender);
    //     } else {
    //         // check for race condition mutex lock maybe
    //         //make into queue
    //         uint freeSlot = imageStruct.emptySlots[0]
    //         imageStruct.images[]
    //     }
    // }



    // function closeConnection(uint position, address owner) {
    //     ImageData data = imageList.images[position];
    //     require(
    //         msg.sender == data.currentClient || msg.sender == data.owner,
    //         "You do not have access"
    //     );
    //     if (data.currentClient == msg.sender) {
    //         uint elapsedTime = now - data.startTime;
    //         data.inUse = false;
    //         makeTransfer(owner, msg.sender, (elapsedTime / 60) * data.costPerMinute);
    //     } else if (data.owner == msg.sender) {
    //         if (!data.inUse) {
    //             emptySlots.push(position);
    //         } else {
    //             // include penalty
    //         }
    //     }
    // }

    // function makeTransfer(payer, receiver, amount) {
    //     emit ContractEnded(payer, amount);
    //     receiver.transfer(amount);
    // }
}