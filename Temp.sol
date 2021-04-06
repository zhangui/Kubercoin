pragma solidity 0.4.24;
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


library Heap{ // default max-heap

  uint constant ROOT_INDEX = 1;

  struct Data{
    int128 idCount;
    Node[] nodes; // root is index 1; index 0 not used
    mapping (int128 => uint) indices; // unique id => node index
  }
  struct Node{
    int128 id; //use with another mapping to store arbitrary object types
    int128 priority;
  }

  //call init before anything else
  function init(Data storage self) internal{
    if(self.nodes.length == 0) self.nodes.push(Node(0,0));
  }

  function insert(Data storage self, int128 priority) internal returns(Node){//√
    if(self.nodes.length == 0){ init(self); }// test on-the-fly-init
    self.idCount++;
    self.nodes.length++;
    Node memory n = Node(self.idCount, priority);
    _bubbleUp(self, n, self.nodes.length-1);
    return n;
  }
  function extractMax(Data storage self) internal returns(Node){//√
    return _extract(self, ROOT_INDEX);
  }
  function extractById(Data storage self, int128 id) internal returns(Node){//√
    return _extract(self, self.indices[id]);
  }

  //view
  function dump(Data storage self) internal view returns(Node[]){
  //note: Empty set will return `[Node(0,0)]`. uninitialized will return `[]`.
    return self.nodes;
  }
  function getById(Data storage self, int128 id) internal view returns(Node){
    return getByIndex(self, self.indices[id]);//test that all these return the emptyNode
  }
  function getByIndex(Data storage self, uint i) internal view returns(Node){
    return self.nodes.length > i ? self.nodes[i] : Node(0,0);
  }
  function getMax(Data storage self) internal view returns(Node){
    return getByIndex(self, ROOT_INDEX);
  }
  function size(Data storage self) internal view returns(uint){
    return self.nodes.length > 0 ? self.nodes.length-1 : 0;
  }
  function isNode(Node n) internal pure returns(bool){ return n.id > 0; }

  //private
  function _extract(Data storage self, uint i) private returns(Node){//√
    if(self.nodes.length <= i || i <= 0){ return Node(0,0); }

    Node memory extractedNode = self.nodes[i];
    delete self.indices[extractedNode.id];

    Node memory tailNode = self.nodes[self.nodes.length-1];
    self.nodes.length--;

    if(i < self.nodes.length){ // if extracted node was not tail
      _bubbleUp(self, tailNode, i);
      _bubbleDown(self, self.nodes[i], i); // then try bubbling down
    }
    return extractedNode;
  }
  function _bubbleUp(Data storage self, Node memory n, uint i) private{//√
    if(i==ROOT_INDEX || n.priority <= self.nodes[i/2].priority){
      _insert(self, n, i);
    }else{
      _insert(self, self.nodes[i/2], i);
      _bubbleUp(self, n, i/2);
    }
  }
  function _bubbleDown(Data storage self, Node memory n, uint i) private{//
    uint length = self.nodes.length;
    uint cIndex = i*2; // left child index

    if(length <= cIndex){
      _insert(self, n, i);
    }else{
      Node memory largestChild = self.nodes[cIndex];

      if(length > cIndex+1 && self.nodes[cIndex+1].priority > largestChild.priority ){
        largestChild = self.nodes[++cIndex];// TEST ++ gets executed first here
      }

      if(largestChild.priority <= n.priority){ //TEST: priority 0 is valid! negative ints work
        _insert(self, n, i);
      }else{
        _insert(self, largestChild, i);
        _bubbleDown(self, n, cIndex);
      }
    }
  }

  function _insert(Data storage self, Node memory n, uint i) private{//√
    self.nodes[i] = n;
    self.indices[n.id] = i;
  }
}

contract PublicHeap{
  using Heap for Heap.Data;
  Heap.Data public data;

  constructor() public { data.init(); }

  function heapify(int128[] priorities) public {
    for(uint i ; i < priorities.length ; i++){
      data.insert(priorities[i]);
    }
  }
  function insert(int128 priority) public returns(Heap.Node){
    return data.insert(priority);
  }
  function extractMax() public returns(Heap.Node){
    return data.extractMax();
  }
  function extractById(int128 id) public returns(Heap.Node){
    return data.extractById(id);
  }
  //view
  function dump() public view returns(Heap.Node[]){
    return data.dump();
  }
  function getMax() public view returns(Heap.Node){
    return data.getMax();
  }
  function getById(int128 id) public view returns(Heap.Node){
    return data.getById(id);
  }
  function getByIndex(uint i) public view returns(Heap.Node){
    return data.getByIndex(i);
  }
  function size() public view returns(uint){
    return data.size();
  }
  function idCount() public view returns(int128){
    return data.idCount;
  }
  function indices(int128 id) public view returns(uint){
    return data.indices[id];
  }
}



contract Matchmaker {

    using SafeMath for uint256;
    PublicHeap heap;
    
    constructor() public {
        heap = new PublicHeap();
    }


    // struct Rating {
    //     uint256 successes
    //     uint256 losses
    //     uint256 elo
    // }

    struct Rating {
        address owner;
        int128 score;
    }
    
    // struct Node{
    //     int128 id; //use with another mapping to store arbitrary object types
    //     int128 priority;
    // }
    
    // function whynot() public returns (uint128) {
        
    //     return 3;
    // }

    function calculateNewScore(Rating rating, bool success) returns (int128) {
        // 1000 + (400 * (successes - losses)) / (successes + losses)
        return rating.score * int128(9);
    }

    // address[] private trustworthy;
    // address[] private trustUnknown;
    // address[] private untrustworthy;

    mapping(address => Rating) ratingMap;
    

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
        // ratingMap[owner] = 
        // uint score = rating.score;
        // rating.losses -= 1;
        // uint newElo = calculateElo(rating);
        // if (newElo <= 800 && oldElo > 800) {

        // }
        // if (newElo > 800 && oldElo <= 800) {

        // }

        // if (newElo >= 1200 && oldElo < 1200) {
            
        // }
        // if (newElo < 1200 && oldElo >= 1200) {
            
        // }
        // newElo = ;
    }
    
    function addMiner() public {
        Rating memory rating = Rating(msg.sender, 500);
        ratingMap[msg.sender] = rating;
        Heap.Node memory node = heap.insert(rating.score);
    }
    
    function getRating() public view returns (int128) {
        Heap.Node memory node = heap.extractMax();
        // Rating memory rating = ratingMap[node.sender];
        return node.priority;
    }
    
    function respond() external view returns (int128) {
        return 145;
    }


}

contract WrapperContract {
    function calculateNewScoreFrom(address toAddress) public view returns (int128) {
        Matchmaker maker = Matchmaker(toAddress);
        int128 val = maker.respond();
        if (val == 145) {
            return 1;
        }
        return 0;
        // address(this);
        
    }
}