pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract queue {
    struct Queue {
        uint256[200] data;
        uint256 front;
        uint256 back;
    }

    /// @dev the number of elements stored in the queue.
    function length(Queue storage q) internal view returns (uint256) {
        return q.back - q.front;
    }

    /// @dev the number of elements this queue can hold
    function capacity(Queue storage q) internal view returns (uint256) {
        return q.data.length - 1;
    }

    /// @dev push a new element to the back of the queue
    function push(Queue storage q, uint256 data) internal {
        if ((q.back + 1) % q.data.length == q.front) return; // throw;
        q.data[q.back] = data;
        q.back = (q.back + 1) % q.data.length;
    }

    /// @dev remove and return the element at the front of the queue
    function pop(Queue storage q) internal returns (uint256 r) {
        if (q.back == q.front) revert(); // throw;
        r = q.data[q.front];
        delete q.data[q.front];
        q.front = (q.front + 1) % q.data.length;
    }
}

contract PublicQueue is queue {
    Queue requests;

    constructor() public {
        // requests.data = uint[200];
    }

    function push(uint256 d) public {
        push(requests, d);
    }

    function pop() public returns (uint256) {
        return pop(requests);
    }

    function length() public returns (uint256) {
        return length(requests);
    }
}

contract Kubercoin {
    using SafeMath for uint256;

    PublicQueue garbageQueue;
    PublicQueue availableImages;
    PublicQueue priorityImages;

    uint256 private verifierTimeInterval = 300;
    uint256 private lastCheck;
    
    uint256 private defaultRating = 500;
    uint256 private maxRating = 1000;

    //Justin's code from pingVerify branch
    uint256 randNonce = 0;

    event MidContractTransfer(address payer, uint256 amount);
    event ContractEnded(address payer, uint256 amount);
    event MinerListUpdate(address UpdatedMiner);

    constructor() public payable {
        garbageQueue = new PublicQueue();
        availableImages = new PublicQueue();
        priorityImages = new PublicQueue();
        lastCheck = block.timestamp;
    }

    struct ImageSet {
        ImageData[] images;
        uint256[] emptySlots;
        bool locked;
    }

    struct ImageData {
        address owner;
        uint256 costPerMinute;
        uint256 maxTime;
        uint256 startTime;
        bool inUse;
        string ip;
        address currentClient;
    }

    ImageSet private imageList;
    ImageData[] images;
    uint256[] emptySlots;
    bool locked;

    address[] private clients;

    struct Verifiers {
        // 0 false
        // 1 true
        // 2 is undecided
        address[2] addressList;
        mapping(address => uint256) verifications;
        mapping(address => uint256) lastVerified;
    }

    mapping(address => uint256) minerRatings;
    mapping(address => string[]) currentPings;
    mapping(string => address) ipToClient;
    mapping(string => address) ipToOwner;

    mapping(address => string) publicKeys;

    mapping(address => Verifiers) pendingVerifies;
    mapping(address => uint256[]) imageOwnership;
    mapping(address => string[]) ipOwnership;
    mapping(string => uint256) private ipToBlock;
    mapping(string => bool) fails;
    mapping(string => string) private ipToEncryptedUsername;
    mapping(string => string) private ipToEncryptedPwd;

    // instead of addMiner
    function addImage(
        address owner,
        uint256 costPerMinute,
        uint256 maxTime,
        uint256 startTime,
        bool inUse,
        string memory ip,
        address currentClient
    ) public {
        ImageData memory newImage =
            ImageData(
                owner,
                costPerMinute,
                maxTime,
                startTime,
                inUse,
                ip,
                currentClient
            );
        if (minerRatings[owner] == 0) {
            minerRatings[owner] = defaultRating;
        }
        if (garbageQueue.length() == 0) {
            imageOwnership[owner].push(images.length);
            enqueueImage(owner, images.length);
            images.push(newImage);
        } else {
            uint256 emptySlot = garbageQueue.pop();
            images[emptySlot] = newImage;
            imageOwnership[owner].push(emptySlot);
            enqueueImage(owner, emptySlot);
            locked = false;
        }
    }

    function assignImage(address client) private returns (string memory) {
        if (availableImages.length() == 0 && priorityImages.length() == 0) {
            return "no available images at this time";
        }
        if (priorityImages.length() != 0) {
            uint256 slot = priorityImages.pop();
            images[slot].currentClient = client;
            images[slot].inUse = true;
            
            string memory ipAddress = images[slot].ip;
            ipToOwner[ipAddress] = images[slot].owner;
            ipToClient[ipAddress] = client;
            ipOwnership[client].push(ipAddress);
            assignPings(client, ipAddress);
            return ipAddress;
        }
        uint256 slot = availableImages.pop();
        images[slot].currentClient = client;
        images[slot].inUse = true;
        string memory ipAddress = images[slot].ip;
        ipToOwner[ipAddress] = images[slot].owner;
        ipToClient[ipAddress] = client;
        ipOwnership[client].push(ipAddress);
        assignPings(client, ipAddress);
        return ipAddress;
    }

    // adds image to available queue
    function removeImage(uint256 i) public {
        availableImages.push(i);
    }
    
    // adds image to garbage queue
    function deleteImage(uint256 i) public {
        garbageQueue.push(i);
    }

    // not secure but generates a semi random number,
    // issues with random numbers in solidity
    function random() internal returns (uint256) {
        // increase nonce
        randNonce++;
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, randNonce)
                )
            ) % 100;
    }

    //assign two random miners to ping image
    function assignPings(address client, string memory ipAddress) public {
        // select two miners at random
        uint256 minerOnePosition = random() % images.length;
        uint256 minerTwoPosition = random() % images.length;
        uint limit = 100;

        // check that positions are valid and unique
        while ((!images[minerOnePosition].inUse || !images[minerTwoPosition].inUse ||
                images[minerOnePosition].owner == client || images[minerTwoPosition].owner == client ||
                minerOnePosition == minerTwoPosition) && limit>0) {
            minerOnePosition = random() % images.length;
            minerTwoPosition = random() % images.length;
            limit--;
        }
        
        if (limit == 0) {
             uint c = 0;
             for (uint256 j = 0; j < images.length; j++) {
                 if (c == 2) {break;}
                 if (images[j].inUse) {
                     if (c==0) {
                         minerOnePosition = j;
                     } else {
                         minerTwoPosition = j;
                     }
                     c++;
                 }
             }
        
        minerOnePosition = 0;
        minerTwoPosition = 1;
        }

        // create new verifiers struct and add two miners
        // Verifiers storage pingers = Verifiers([minerOne, minerTwo]);
        address minerOne = images[minerOnePosition].owner;
        address minerTwo = images[minerTwoPosition].owner;
        pendingVerifies[client] = Verifiers([minerOne, minerTwo]);

        //add client to current pings mapping of both miners
        currentPings[minerOne].push(ipAddress);
        currentPings[minerTwo].push(ipAddress);
        clients.push(client);
    }
    
    function getPendingPings() public view returns (string[] memory) {
        return currentPings[msg.sender];
    }

    //check that the miner has written the ping results to the block chain
    function checkVerifies() public {
        //need to check every client's verifiers
        for (uint256 i = 0; i < clients.length; i++) {
            Verifiers storage verifiers = pendingVerifies[clients[i]];
            //check last ping
            for (uint256 j = 0; j < verifiers.addressList.length; j++) {
                address miner = verifiers.addressList[j];
                uint256 lastPing = verifiers.lastVerified[miner];
                if (lastCheck > lastPing) {
                    reportFailureToPing(miner);
                }
            }
        }
    }

    //check if any verifiers have reported unsuccessful ping
    function checkImageFailures() public {
        for (uint256 i = 0; i < clients.length; i++) {
            Verifiers storage verifiers = pendingVerifies[clients[i]];
            for (uint256 j = 0; j < verifiers.addressList.length; j++) {
                address miner = verifiers.addressList[j];
                if (verifiers.verifications[miner] == 0) {
                    reportImageOffline(clients[i]);
                }
            }
        }
    }

    // check if verifier has failed to ping or
    // an image has gone offline
    function checkForExpiriations() public {
        if (block.timestamp - lastCheck >= verifierTimeInterval) {
            checkVerifies();
            checkImageFailures();
            lastCheck = block.timestamp;
        }
    }

    // add mapping of miners to the number of failures to ping
    mapping(address => uint256) pingFailures;

    //increments failures and punush
    function reportFailureToPing(address minerAddress) public {
        pingFailures[minerAddress]++;

        if (pingFailures[minerAddress] >= 2) {
            punishPing(minerAddress);
        }
    }

    function reportImageOffline(address client) public {
        for (uint256 i = 0; i < images.length; i++) {
            ImageData memory image = images[i];
            if (image.currentClient == client) {
                fails["127.0.0.1"] = true;
                punishMiner(image.owner);
                removeImage(i);
            }
        }
    }

    function verify(string memory ipAddress, bool active) public {
        address addressToBeVerified = ipToClient[ipAddress];
        address[2] memory addressList =
            pendingVerifies[addressToBeVerified].addressList;
        for (uint256 i = 0; i < addressList.length; i++) {
            if (msg.sender == addressList[i]) {
                if (active) {
                    pendingVerifies[addressToBeVerified].verifications[
                        msg.sender
                    ] = 1;
                    pendingVerifies[addressToBeVerified].lastVerified[msg.sender] = block.timestamp;
                } else {
                    pendingVerifies[addressToBeVerified].verifications[
                        msg.sender
                    ] = 0;
                    pendingVerifies[addressToBeVerified].lastVerified[msg.sender] = block.timestamp;
                }
            }
        }
    }

    function closeConnection(uint256 position) public payable {
        ImageData storage data = images[position];
        require(
            msg.sender == data.currentClient || msg.sender == data.owner,
            "You do not have access"
        );
        uint256 elapsedTime = now - data.startTime;
        if (data.currentClient == msg.sender) {
            //client is done with task
            data.inUse = false;
            makeTransfer(
                data.currentClient,
                data.owner,
                (elapsedTime / 60) * data.costPerMinute
            );
            emit ContractEnded(
                data.currentClient,
                (elapsedTime / 60) * data.costPerMinute
            );
            updateRating(data.owner, true);
            enqueueImage(data.owner, position);
            emit MinerListUpdate(data.owner);
        } else if (data.owner == msg.sender) {
            //miner decides to end contract
            if (!data.inUse) {
                // task is complete
                emit MinerListUpdate(data.owner);
                makeTransfer(
                    data.currentClient,
                    data.owner,
                    (elapsedTime / 60) * data.costPerMinute
                );
                emit ContractEnded(
                    data.currentClient,
                    (elapsedTime / 60) * data.costPerMinute
                );
                updateRating(data.owner, true);
                enqueueImage(data.owner, position);
            } else {
                //penalize miner and move funds for work done.
                punishMiner(data.owner);
                emit MidContractTransfer(
                    data.currentClient,
                    (elapsedTime / 60) * data.costPerMinute
                );
                makeTransfer(
                    data.currentClient,
                    data.owner,
                    (elapsedTime / 60) * data.costPerMinute
                );

                //TODO: make sure removeImage and assignImage calls the MinterListUpdate event
                removeImage(position);
                assignImage(data.currentClient); //since miner ended, need to give client a new image to work with
            }
        }
    }

    function enqueueImage(address owner, uint256 position) private {
      uint256 rating = minerRatings[owner];
      if (rating > 700) {
        priorityImages.push(position);
      } else if (rating >= 300) {
        availableImages.push(position);
      }
    }

    function makeTransfer(
        address payer,
        address receiver,
        uint256 amount
    ) public payable {
        payable(receiver).transfer(amount);
    }

    //can probably remove the below 2 functions in the future, but might add additional functionality
    function punishMiner(address miner) public {
        updateRating(miner, false);
    }

    function punishPing(address pinger) public {
        updateRating(pinger, false);
    }

    function calculateNewScore(uint256 rating, bool success)
        public view
        returns (uint256)
    {
        uint multiplier = maxRating;
        if (!success) {
            multiplier = 0;
        }
        return (rating).mul(uint256(9)).div(10) + multiplier.mul(uint256(1)).div(10);
    }


    function updateRating(address owner, bool reward) public {
        uint256 rating = minerRatings[owner];
        uint256 newScore = calculateNewScore(rating, reward);
        minerRatings[owner] = newScore;
    }
    
    function getRating() public view returns (uint256) {
        return minerRatings[msg.sender];
    }

    // function addMiner() public {
    //     Rating memory rating = Rating(msg.sender, 500);
    //     ratingMap[msg.sender] = rating;
    //     Heap.Node memory node = heap.insert(rating.score);
    // }

    // Test Functions
    function respond() external view returns (int128) {
        return 145;
    }

    string testtmp;

    function assignNextAvailableImageToSender() public returns (string memory) {
        // Heap.Node memory node = heap.extractMax();
        // int128 id = node.id;

        // imageList.addMiner
        testtmp = assignImage(msg.sender);
        return testtmp;
    }

    function getTestTmp() public view returns (string memory) {
        return testtmp;
    }

    function getImage(uint256 i) public view returns (ImageData memory) {
        ImageData memory image = images[i];
        return image;
    }

    function getSendersImages() public view returns (uint256[] memory) {
        return imageOwnership[msg.sender];
    }

    
    
    function getEncryptedUsernamePwd(string memory ipAddress) public view returns (string memory, string memory) {
        if (ipToClient[ipAddress] == msg.sender || ipToOwner[ipAddress] == msg.sender) {
            string memory encryptedUsername = ipToEncryptedUsername[ipAddress];
            string memory encryptedPwd = ipToEncryptedPwd[ipAddress];
            return (encryptedUsername, encryptedPwd);
        }
        return ("access denied", "access denied");
    }
    
    function setEncryptedUsernamePwd(string memory ipAddress, string memory username, string memory pwd) external {
        if (ipToOwner[ipAddress] == msg.sender) {
            ipToEncryptedUsername[ipAddress] = username;
            ipToEncryptedPwd[ipAddress] = pwd;
        }
    }

    function updateImage(
        uint256 i,
        uint256 costPerMinute,
        uint256 maxTime
    ) public {
        if (msg.sender == images[i].owner) {
            images[i].costPerMinute = costPerMinute;
            images[i].maxTime = maxTime;
        }
    }

    function addCurrentMinerAsFreeImage() public {
        addImage(msg.sender, 2, 10000, block.timestamp, false, "i", msg.sender);
    }
    
       
    //justins test functions start
    function addCurrentMinerClient() public {
        addImage(msg.sender, 2, 10000, block.timestamp, false, "127.0.0.1", msg.sender);
    }
    
    function addImageWith(string memory ipAddress) external {
        addImage(msg.sender, 2, 10000, block.timestamp, false, ipAddress, msg.sender);
    }
    
    function closeConnectionWithIP(string memory ipAddress) external payable {
        if (msg.sender == ipToClient[ipAddress] || msg.sender == ipToOwner[ipAddress]) {
            uint256 blockNum = ipToBlock[ipAddress];
            closeConnection(blockNum);
        }
    }
    
    function clearIPs() external {
        delete ipOwnership[msg.sender];
    }
    
    function getIPs() external view returns (string[] memory) {
        return ipOwnership[msg.sender];
    }
    
    function testAssignPings() public {
        assignPings(msg.sender, "127.0.0.1");
    }
    
    function testGetPendingPings(address miner) public view returns (string[] memory) {
        return currentPings[miner];
    }
    
    function getClientFromIP(string memory ip) public view returns (address) {
        return ipToClient[ip];
    }
    
    function getVerifiersForClient(address client) public view returns (address[] memory) {
        address[] memory miners;
        miners[0] = pendingVerifies[client].addressList[0];
        miners[1] = pendingVerifies[client].addressList[1];
        return miners;
    }
    
    function getPingFailures() public view returns (uint256) {
        return pingFailures[msg.sender];
    }
    
    function didFail() public view returns (bool) {
        return fails["127.0.0.1"];
    }
    
    
    function sampleRun() public {
        addImage(msg.sender, 2, 10000, block.timestamp, false, "i", msg.sender);
        // ImageData memory data = assignImage(0);
        // randomPings(msg.sender)
    }
}
