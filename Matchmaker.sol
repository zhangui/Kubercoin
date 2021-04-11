pragma solidity >=0.4.22 <0.6.0;
pragma experimental ABIEncoderV2;

contract Matchmaker {

    // matches potential machines/docker instances to clients

    uint private verifierTimeInterval = 300;
    uint private lastCheck;

    event ContractEnded(address payer, uint amount);

    constructor () public {
        lastCheck = now;
    }

    struct ImageSet {
        ImageData[] images;
        uint[] emptySlots;
        bool locked;
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
        address[] addressList;
        mapping(address => uint) verifications;
    }

    mapping(address => uint) minerRatings;
    mapping(address => address[]) currentPings;

    mapping(address => string) publicKeys;



    mapping(address => Verifiers) pendingVerifies;

    function checkVerifies() public {

    }

    function checkForExpiriations() public {
        if (now - lastCheck >= verifierTimeInterval) {
            checkVerifies();
        }
    }

    function reportFailure(address minerAddress) public {

    }

    function verify(address addressToBeVerified, bool active) public {
        address[] memory addressList = pendingVerifies[addressToBeVerified].addressList;
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

    // instead of addMiner
    function addImage(address owner, uint costPerMinute, uint maxTime, uint startTime, bool inUse, address currentClient) public {
        ImageData memory newImage = ImageData(owner, costPerMinute, maxTime, startTime, inUse, currentClient);
        if (imageList.emptySlots.length == 0) {
            imageList.images.push(newImage);
        } else {
            // need to test whether this works as a mutex lock
            while(imageList.locked)
                imageList.locked = true;
            uint emptySlot = imageList.emptySlots[imageList.emptySlots.length - 1];
            imageList.emptySlots.pop();
            imageList.images[emptySlot] = newImage;
            imageList.locked = false;
        }
    }

    // instead of removeMiner, just take in index and remove it
    function removeImage(uint i) public {
        imageList.emptySlots.push(i);
    }

    function getImage(uint i) public returns(ImageData memory) {
        ImageData memory image = imageList.images[i];
        return image;
    }

    function updateImage(uint i, uint costPerMinute, uint maxTime, uint startTime, bool inUse, address currentClient) public {
        if (msg.sender == imageList.images[i].owner) {
            imageList.images[i].costPerMinute = costPerMinute;
            imageList.images[i].maxTime = maxTime;
            imageList.images[i].startTime = startTime;
            imageList.images[i].inUse = inUse;
            imageList.images[i].currentClient = currentClient;
        }
    }

}
