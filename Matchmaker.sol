pragma solidity >=0.4.22 <0.6.0;

contract Matchmaker {

    // matches potential machines/docker instances to clients

    uint private verifierTimeInterval = 300;
    uint private lastCheck;

    event MidContractTransfer(address payer, uint amount);
    event ContractEnded(address payer, uint amount);
    event MinerListUpdate(address UpdatedMiner);
    
    constructor () {
        lastCheck = now
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
        address[] addressList;
        mapping(address => uint) verifications;
    }

    mapping(address => uint) minerRatings;
    mapping(address => address[]) currentPings;

    mapping(address => string) publicKeys;



    mapping(address => Verifiers) pendingVerifies;

    function checkVerifies() {

    }

    function checkForExpiriations() {
        if (now - lastCheck >= verifierTimeInterval) {
            checkVerifies()
        }
    }

    function reportFailure(address minerAddress) {

    }

    function verify(address addressToBeVerified, bool active) {
        address[] addressList = pendingVerifies[addressToBeVerified].addressList
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

    function getPings() returns address[] {
        return currentPings[msg.sender];
    }

    // function addClient() {
    //     clients.push(msg.sender);
    // }

    function removeMiner() {

    }

    function addMiner() {
        if (imageStruct.emptySlots.length == 0) {
            imageStruct.images.push(msg.sender);
        } else {
            // check for race condition mutex lock maybe
            //make into queue
            uint freeSlot = imageStruct.emptySlots[0]
            imageStruct.images[]
        }
    }



    function closeConnection(uint position, address owner) {
        ImageData data = imageList.images[position];
        require(
            msg.sender == data.currentClient || msg.sender == data.owner,
            "You do not have access"
        );
        if (data.currentClient == msg.sender) { //client is done with task
            uint elapsedTime = now - data.startTime;
            data.inUse = false;
            makeTransfer(owner, msg.sender, (elapsedTime / 60) * data.costPerMinute);
            emit ContractEnded(owner, msg.sender);
            imageList.emptySlots.push(position);
            emit MinerListUpdate(data.owner);
        } else if (data.owner == msg.sender) { //miner decides to end contract
            if (!data.inUse) { // task is complete
                imageList.emptySlots.push(position);
                emit MinerListUpdate(data.owner);
                makeTransfer(owner, msg.sender, (elapsedTime / 60) * data.costPerMinute);
                emit ContractEnded(owner, msg.sender);
            } else {
                //penalize miner and move funds for work done.
                punishMiner(data.currentClient, data.owner);
                emit MidContractTransfer(data.currentClient, (elapsedTime / 60) * data.costPerMinute);
                makeTransfer(data.currentClient, data.owner, (elapsedTime / 60) * data.costPerMinute);

                //TODO: make sure removeImage and assignImage calls the MinterListUpdate event
                removeImage(position);
                assignImage(owner); //since miner ended, need to give client a new image to work with
            }
        }
    }

    function makeTransfer(address payer, address receiver, uint amount) {
        payable(receiver).transfer(amount);
    }

    //can probably remove the below 2 functions in the future, but might add additional functionality
    function punishMiner(address miner) {
      reduceRating(miner);
    }

    function punishPing(address pinger) {
        reduceRating(pinger);
    }
}