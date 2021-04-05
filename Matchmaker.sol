pragma solidity >=0.4.22 <0.6.0;

contract Matchmaker {
    // matches potential machines/docker instances to clients

    uint256 private verifierTimeInterval = 300;
    uint256 private lastCheck;

    event MidContractTransfer(address payer, uint256 amount);
    event ContractEnded(address payer, uint256 amount);
    event MinerListUpdate(address UpdatedMiner);

    constructor() public {
        lastCheck = now;
    }

    struct ImageSet {
        ImageData[] images;
        uint256[] emptySlots;
    }

    struct ImageData {
        address owner;
        uint256 costPerMinute;
        uint256 maxTime;
        uint256 startTime;
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
        mapping(address => uint256) verifications;
    }

    mapping(address => uint256) minerRatings;
    mapping(address => address[]) currentPings;

    mapping(address => string) publicKeys;

    mapping(address => Verifiers) pendingVerifies;

    function checkVerifies() public {}

    function checkForExpiriations() public {
        if (now - lastCheck >= verifierTimeInterval) {
            checkVerifies();
        }
    }

    function reportFailure(address minerAddress) public {}

    function verify(address addressToBeVerified, bool active) public {
        address[] storage addressList =
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

    function getPings() public {
        return currentPings[msg.sender];
    }

    // function addClient() {
    //     clients.push(msg.sender);
    // }

    function removeMiner() public {}

    function addMiner() public {
        if (imageStruct.emptySlots.length == 0) {
            imageStruct.images.push(msg.sender);
        } else {
            // check for race condition mutex lock maybe
            //make into queue
            uint256 freeSlot = imageStruct.emptySlots[0];
            imageStruct.images[];
        }
    }

    function closeConnection(uint256 position, address owner) public {
        ImageData storage data = imageList.images[position];
        require(
            msg.sender == data.currentClient || msg.sender == data.owner,
            "You do not have access"
        );
        uint256 elapsedTime = now - data.startTime;
        if (data.currentClient == msg.sender) {
            //client is done with task
            data.inUse = false;
            makeTransfer(
                owner,
                msg.sender,
                (elapsedTime / 60) * data.costPerMinute
            );
            emit ContractEnded(owner, msg.sender);
            imageList.emptySlots.push(position);
            emit MinerListUpdate(data.owner);
        } else if (data.owner == msg.sender) {
            //miner decides to end contract
            if (!data.inUse) {
                // task is complete
                imageList.emptySlots.push(position);
                emit MinerListUpdate(data.owner);
                makeTransfer(
                    owner,
                    msg.sender,
                    (elapsedTime / 60) * data.costPerMinute
                );
                emit ContractEnded(owner, msg.sender);
            } else {
                //penalize miner and move funds for work done.
                punishMiner(data.currentClient, data.owner);
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
                assignImage(owner); //since miner ended, need to give client a new image to work with
            }
        }
    }

    function makeTransfer(
        address payer,
        address receiver,
        uint256 amount
    ) public {
        receiver.transfer(amount);
    }

    //can probably remove the below 2 functions in the future, but might add additional functionality
    function punishMiner(address miner) public {
        reduceRating(miner);
    }

    function punishPing(address pinger) public {
        reduceRating(pinger);
    }
}
