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

library Heap {
    // default max-heap

    uint256 constant ROOT_INDEX = 1;

    struct Data {
        int128 idCount;
        Node[] nodes; // root is index 1; index 0 not used
        mapping(int128 => uint256) indices; // unique id => node index
    }
    struct Node {
        int128 id; //use with another mapping to store arbitrary object types
        int128 priority;
    }

    //call init before anything else
    function init(Data storage self) internal {
        if (self.nodes.length == 0) self.nodes.push(Node(0, 0));
    }

    function insert(Data storage self, int128 priority)
        internal
        returns (Node memory)
    {
        //√
        if (self.nodes.length == 0) {
            init(self);
        } // test on-the-fly-init
        self.idCount++;
        //self.nodes.length++;
        Node memory n = Node(self.idCount, priority);
        _bubbleUp(self, n, self.nodes.length - 1);
        return n;
    }

    function extractMax(Data storage self) internal returns (Node memory) {
        //√
        return _extract(self, ROOT_INDEX);
    }

    function extractById(Data storage self, int128 id)
        internal
        returns (Node memory)
    {
        //√
        return _extract(self, self.indices[id]);
    }

    //view
    function dump(Data storage self) internal view returns (Node[] memory) {
        //note: Empty set will return `[Node(0,0)]`. uninitialized will return `[]`.
        return self.nodes;
    }

    function getById(Data storage self, int128 id)
        internal
        view
        returns (Node memory)
    {
        return getByIndex(self, self.indices[id]); //test that all these return the emptyNode
    }

    function getByIndex(Data storage self, uint256 i)
        internal
        view
        returns (Node memory)
    {
        return self.nodes.length > i ? self.nodes[i] : Node(0, 0);
    }

    function getMax(Data storage self) internal view returns (Node memory) {
        return getByIndex(self, ROOT_INDEX);
    }

    function size(Data storage self) internal view returns (uint256) {
        return self.nodes.length > 0 ? self.nodes.length - 1 : 0;
    }

    function isNode(Node memory n) internal pure returns (bool) {
        return n.id > 0;
    }

    //private
    function _extract(Data storage self, uint256 i)
        private
        returns (Node memory)
    {
        //√
        if (self.nodes.length <= i || i <= 0) {
            return Node(0, 0);
        }

        Node memory extractedNode = self.nodes[i];
        delete self.indices[extractedNode.id];

        Node memory tailNode = self.nodes[self.nodes.length - 1];
        //self.nodes.length--;

        if (i < self.nodes.length) {
            // if extracted node was not tail
            _bubbleUp(self, tailNode, i);
            _bubbleDown(self, self.nodes[i], i); // then try bubbling down
        }
        return extractedNode;
    }

    function _bubbleUp(
        Data storage self,
        Node memory n,
        uint256 i
    ) private {
        //√
        if (i == ROOT_INDEX || n.priority <= self.nodes[i / 2].priority) {
            _insert(self, n, i);
        } else {
            _insert(self, self.nodes[i / 2], i);
            _bubbleUp(self, n, i / 2);
        }
    }

    function _bubbleDown(
        Data storage self,
        Node memory n,
        uint256 i
    ) private {
        //
        uint256 length = self.nodes.length;
        uint256 cIndex = i * 2; // left child index

        if (length <= cIndex) {
            _insert(self, n, i);
        } else {
            Node memory largestChild = self.nodes[cIndex];

            if (
                length > cIndex + 1 &&
                self.nodes[cIndex + 1].priority > largestChild.priority
            ) {
                largestChild = self.nodes[++cIndex]; // TEST ++ gets executed first here
            }

            if (largestChild.priority <= n.priority) {
                //TEST: priority 0 is valid! negative ints work
                _insert(self, n, i);
            } else {
                _insert(self, largestChild, i);
                _bubbleDown(self, n, cIndex);
            }
        }
    }

    function _insert(
        Data storage self,
        Node memory n,
        uint256 i
    ) private {
        //√
        self.nodes[i] = n;
        self.indices[n.id] = i;
    }
}

contract PublicHeap {
    using Heap for Heap.Data;
    Heap.Data public data;

    constructor() public {
        data.init();
    }

    function heapify(int128[] memory priorities) public {
        for (uint256 i; i < priorities.length; i++) {
            data.insert(priorities[i]);
        }
    }

    function insert(int128 priority) public returns (Heap.Node memory) {
        return data.insert(priority);
    }

    function extractMax() public returns (Heap.Node memory) {
        return data.extractMax();
    }

    function extractById(int128 id) public returns (Heap.Node memory) {
        return data.extractById(id);
    }

    //view
    function dump() public view returns (Heap.Node[] memory) {
        return data.dump();
    }

    function getMax() public view returns (Heap.Node memory) {
        return data.getMax();
    }

    function getById(int128 id) public view returns (Heap.Node memory) {
        return data.getById(id);
    }

    function getByIndex(uint256 i) public view returns (Heap.Node memory) {
        return data.getByIndex(i);
    }

    function size() public view returns (uint256) {
        return data.size();
    }

    function idCount() public view returns (int128) {
        return data.idCount;
    }

    function indices(int128 id) public view returns (uint256) {
        return data.indices[id];
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
    PublicHeap heap;
    PublicQueue freeHeap;
    PublicQueue freeImages;

    uint256 private verifierTimeInterval = 300;
    uint256 private lastCheck;

    //Justin's code from pingVerify branch
    uint256 randNonce = 0;

    event MidContractTransfer(address payer, uint256 amount);
    event ContractEnded(address payer, uint256 amount);
    event MinerListUpdate(address UpdatedMiner);

    constructor() public payable {
        heap = new PublicHeap();
        freeHeap = new PublicQueue();
        freeImages = new PublicQueue();
        lastCheck = block.timestamp;
        // imageList = new ImageSet();
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
    mapping(address => address[]) currentPings;

    mapping(address => string) publicKeys;

    mapping(address => Verifiers) pendingVerifies;
    mapping(address => uint256[]) imageOwnership;

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
            minerRatings[owner] = 700;
        }
        if (freeHeap.length() == 0) {
            imageOwnership[owner].push(images.length);
            freeImages.push(images.length);
            images.push(newImage);
        } else {
            // need to test whether this works as a mutex lock
            while (locked) locked = true;
            // uint emptySlot = imageList.emptySlots[imageList.emptySlots.length - 1];

            uint256 emptySlot = freeHeap.pop();
            images[emptySlot] = newImage;
            imageOwnership[owner].push(emptySlot);
            freeImages.push(emptySlot);
            locked = false;
        }
    }

    function assignImage(address client) private returns (string memory) {
        // uint unvetted = 0;
        // Heap.Node memory emptySlot = freeImages.extractMax();
        if (freeImages.length() == 0) {
            return "no available images at this time";
        }
        uint256 slot = freeImages.pop();
        // for (uint i = 0; i < emptySlots.length; i++) {
        //  = emptySlots[i];
        //ImageData memory imageData = images[slot];
        //address owner = imageData.owner;
        images[slot].currentClient = client;
        images[slot].inUse = true;
        return images[slot].ip;
        // if (minerRatings[owner] > 600) {

        // }
        // }
        // uint slot = emptySlots[unvetted];
        // ImageData memory imageData = images[slot];
        // if (imageData.inUse) {
        //     return "";
        // }
        // imageData.currentClient = client;
        // imageData.inUse = true;
        // return imageData.ip;
    }

    // instead of removeMiner, just take in index and remove it
    function removeImage(uint256 i) public {
        freeImages.push(i);
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
    function assignPings(address client) public {
        // select two miners at random
        uint256 minerOnePosition = random() % images.length;
        uint256 minerTwoPosition = random() % images.length;

        // check that positions are valid and unique
        while (!images[minerOnePosition].inUse) {
            minerOnePosition = random() % images.length;
        }

        while (
            !images[minerTwoPosition].inUse ||
            minerTwoPosition == minerOnePosition
        ) {
            minerTwoPosition = random() % images.length;
        }

        // create new verifiers struct and add two miners
        // Verifiers storage pingers = Verifiers([minerOne, minerTwo]);
        address minerOne = images[minerOnePosition].owner;
        address minerTwo = images[minerTwoPosition].owner;
        pendingVerifies[client] = Verifiers([minerOne, minerTwo]);

        //add client to current pings mapping of both miners
        currentPings[minerOne].push(client);
        currentPings[minerTwo].push(client);
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
    mapping(address => uint256) pingFailures;

    //increments failures and punush
    function reportFailureToPing(address minerAddress) public {
        pingFailures[minerAddress]++;

        if (pingFailures[minerAddress] >= 2) {
            punishPing(minerAddress);
        }
    }

    // am i doing the right thing here?
    //maybe maintain mapping of client to image to make easier?
    function reportImageOffline(address client) public {
        for (uint256 i = 0; i < images.length; i++) {
            ImageData memory image = images[i];
            if (image.currentClient == client) {
                punishMiner(image.owner);
                removeImage(i);
            }
        }
    }

    function verify(address addressToBeVerified, bool active) public {
        address[2] memory addressList =
            pendingVerifies[addressToBeVerified].addressList;
        for (uint256 i = 0; i < addressList.length; i++) {
            if (msg.sender == addressList[i]) {
                if (active) {
                    pendingVerifies[addressToBeVerified].verifications[
                        msg.sender
                    ] = 1;
                } else {
                    pendingVerifies[addressToBeVerified].verifications[
                        msg.sender
                    ] = 0;
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
            freeImages.push(position);
            updateRating(data.owner, true);
            emit MinerListUpdate(data.owner);
        } else if (data.owner == msg.sender) {
            //miner decides to end contract
            if (!data.inUse) {
                // task is complete
                freeImages.push(position);
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

    struct Rating {
        address owner;
        int128 score;
    }

    function calculateNewScore(Rating memory rating, bool success)
        public
        returns (int128)
    {
        // 1000 + (400 * (successes - losses)) / (successes + losses)
        return rating.score * int128(9);
    }

    mapping(address => Rating) ratingMap;
    mapping(int128 => uint128) heapToImage;

    function updateRating(address owner, bool reward) public {
        Rating memory rating = ratingMap[owner];
        // require(
        //     rating != null,
        //     "Rating doesn't exist"
        // );
        int128 newScore = calculateNewScore(rating, false);
        rating.score = newScore;
        rating.owner = owner;
        ratingMap[owner] = rating;
    }

    function addMiner() public {
        Rating memory rating = Rating(msg.sender, 500);
        ratingMap[msg.sender] = rating;
        Heap.Node memory node = heap.insert(rating.score);
    }

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

    function updateImage(
        uint256 i,
        uint256 costPerMinute,
        uint256 maxTime,
        uint256 startTime,
        bool inUse,
        address currentClient
    ) public {
        if (msg.sender == images[i].owner) {
            images[i].costPerMinute = costPerMinute;
            images[i].maxTime = maxTime;
            images[i].startTime = startTime;
            images[i].inUse = inUse;
            images[i].currentClient = currentClient;
        }
    }

    function addCurrentMinerAsFreeImage() public {
        addImage(msg.sender, 2, 10000, block.timestamp, false, "i", msg.sender);
    }
}
