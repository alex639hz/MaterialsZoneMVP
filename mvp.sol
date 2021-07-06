pragma solidity ^0.4.24;

/** @title Sample Types is a wrapper granting certain custom types to the core contracts */
contract SampleTypes {
    enum accType {EOA,CA}

    /// @dev The transaction fees and gas are currently hardcoded
    uint256 __txFees = 0.0001 ether;
  	uint256 __txGas = 20317;

    /// @dev __debug is a simple flag for debugging
  	bool __debug;

    /**
    @notice The PassIfTrue modifier tests a condition before execution
      The ubiquitous need for this modifier inspired making it global
    */
  	modifier PassIfTrue(bool test){
  	    require(test == true);
  	    _;
  	}
}


/** @title The Entity Manager manages single-user accounts */
contract EntityManager is SampleTypes {
  /// @notice EntityType contains the different types of users on the system
  enum EntityType	{UNKNOWN, GUEST, USER, PROVIDER, ADMIN, OWNER}

  /**
  @notice Entity is a complex data type representing a single user
    A brief description of each data point:
      parent: the address of the creator of this Entity
      reputation: each entity has a reputation score stored here (not yet implemented)
      disputes: the amount of times this entity has opened a dispute
      authorized: signifies authorization
  */
  struct Entity {
    EntityType entityType;
    address parent;
    int256 reputation;
    uint256 disputes;
    bool authorized;
    // bool authenticated; This is intended as a KYC/AML flag, and is not yet implemented
  }

  /// @notice entityTable maps users from their address to their data structure
  mapping (address => Entity) public entityTable;

  event LogNewEMContract(address indexed contractOwner);
	event LogNewFoundationOwner(address indexed foundationOwner);
	event LogNewFoundationAdmin(address indexed foundationAdmin);
	event LogNewServiceProvider(address indexed ServiceProvider);
	event LogNewDataUser(address indexed user);
	event LogNewHashRegistered(address indexed entity, bytes32 indexed hash);
	event LogDeposit(address _src, uint256 _idx);

  /**
  @notice A number of modifiers have been created to control which calss of
    user can run which function. There are functions which can only be run
    by the Foundation, by Service Providers, or by Data Users, and these modifiers
    control that.
  */
  modifier OnlyRegisteredEntity(address _acc) {
    require(entityTable[_acc].entityType >= EntityType.USER);
    require(entityTable[_acc].parent != address(0));
    _;
  }

  modifier OnlyNonRegisteredEntity(address _acc) {
    require(entityTable[_acc].parent == address(0));
    _;
  }

  modifier OnlyAuthorizedEntity(address _acc) {
    require(entityTable[_acc].entityType >= EntityType.USER);
    require(entityTable[_acc].authorized == true);
    _;
  }

  /// @notice OnlyEntityContract restricts functions to the contract itself
  modifier OnlyEntityContract(address _acc) {
    require(_acc == address(this));
    _;
  }

  modifier OnlyFoundationOwner(address _acc) {
    require(entityTable[_acc].entityType == EntityType.OWNER);
    require(entityTable[_acc].authorized == true);
    _;
  }

  modifier OnlyFoundationAdmin(address _acc) {
    require(entityTable[_acc].entityType == EntityType.ADMIN);
    require(entityTable[_acc].authorized == true);
    _;
  }

  modifier OnlyFoundationOwnerOrAdmin(address _acc) {
    require(entityTable[_acc].entityType >= EntityType.ADMIN);
    require(entityTable[_acc].authorized == true);
    _;
  }

  modifier OnlyServiceProvider(address _acc) {
    require(entityTable[_acc].entityType == EntityType.PROVIDER);
    require(entityTable[_acc].authorized == true);
    _;
  }

  modifier OnlyFoundationOrProvider(address _acc) {
    require(entityTable[_acc].entityType >= EntityType.PROVIDER);
    require(entityTable[_acc].authorized == true);
    _;
  }

  modifier OnlyDataUser(address _acc) {
    require(entityTable[_acc].entityType == EntityType.USER);
    require(entityTable[_acc].authorized == true);
    _;
  }

  /**
  @notice The constructor sets the address that deployed the contract as the first Foundation Owner
  @dev By necessity, the parent of the first owner is the contract itself.
  */
  constructor()
    public
    payable
  {
    entityTable[msg.sender]=Entity({
      entityType: EntityType.OWNER,
      parent: address(this),
      reputation: 0,
      disputes: 0,
      // authenticated: true,
      authorized: true});

    emit LogNewFoundationOwner(msg.sender);
  }

  /**
  @notice The fallback function allows payable functions in the contract
  @dev The Entity contract does not currently have payable functions,
    but was left in due to the possible eventuality
  */
  function() public payable {
    if(msg.value > 0) {
      emit LogDeposit(msg.sender, msg.value);
    }
  }

  /**
  @notice Registers a new account as an additional Foundation owner - only accessible to Owners
  @dev Only a new, unregistered address may be used
  @param _newOwnerAddress address The address of the new Owner
  */
  function addFoundationOwner(address _newOwnerAddress)
    public
    payable
    OnlyFoundationOwner(msg.sender)
    PassIfTrue(_newOwnerAddress != 0)
    OnlyNonRegisteredEntity(_newOwnerAddress)
  {
      entityTable[_newOwnerAddress]=Entity({
  			entityType: EntityType.OWNER,
  			parent: msg.sender,
  			reputation: 0,
  			disputes: 0,
  			// authenticated: false,
  			authorized: true});

  		emit LogNewFoundationOwner( _newOwnerAddress);
  }

  /**
  @notice Registers a new account as an Admin - only accessible to Owners
  @dev Only a new, unregistered address may be used
  @param _newAdminAddress address The address of the new Admin
  */
  function addFoundationAdmin(address _newAdminAddress)
    public
    payable
    OnlyFoundationOwner(msg.sender)
    PassIfTrue(_newAdminAddress != 0)
    OnlyNonRegisteredEntity(_newAdminAddress)
  {
      entityTable[_newAdminAddress]=Entity({
  			entityType: EntityType.ADMIN,
  			parent: msg.sender,
  			reputation: 0,
  			disputes: 0,
  			// authenticated: false,
  			authorized: true});

  		emit LogNewFoundationAdmin(_newAdminAddress);
  }

  /**
  @notice Registers a new account as a Service Provider - accessible to Owners and admins
  @dev Only a new, unregistered address may be used
  @param _newProviderAddress address The address of the new Service Provider
  */
  function addServiceProvider(address _newProviderAddress)
    public
    payable
    OnlyFoundationOwnerOrAdmin(msg.sender)
    PassIfTrue(_newProviderAddress != 0)
    OnlyNonRegisteredEntity(_newProviderAddress)
  {
      entityTable[_newProviderAddress]=Entity({
  			entityType: EntityType.PROVIDER,
  			parent: msg.sender,
  			reputation: 0,
  			disputes: 0,
  			// authenticated: false,
  			authorized: true});

  		emit LogNewServiceProvider(_newProviderAddress);
  }

  /**
  @notice Registers a new account as a user - only accessible to Service Providers
  @dev Only a new, unregistered address may be used
  @param _newUserAddress address The address of the new user
  */
  function addDataUser(address _newUserAddress)
    public
    payable
    OnlyServiceProvider(msg.sender)
    PassIfTrue(_newUserAddress != 0)
    OnlyNonRegisteredEntity(_newUserAddress)
  {
      entityTable[_newUserAddress]=Entity({
  			entityType: EntityType.USER,
  			parent: msg.sender,
  			reputation: 0,
  			disputes: 0,
  			// authenticated: false,
  			authorized: true
  	   });

  		emit LogNewDataUser(_newUserAddress);
  }

  /**
  @notice isEntityAuthorized is a function that verifies if a particular address is authorized
  @param _address Address to be checked
  */
  function isEntityAuthorized(address _entityAddress)
    public
    constant
    returns(bool)
  {
      return entityTable[_entityAddress].authorized;
  }

  // Leaving out reputation and deploy contracts for now

}


/** @title The Datablock contract allows for the licenising of data to buyers */
contract Datablock is SampleTypes{

  /**
  @notice The Request struct represents a request to pay for access to the data
    represented by the Datablock contract. A brief description of the individual
    data points follows:
      account: the address of the potential buyer (data consumer)
      value: value transfered with the request
      logTime: the timestamp of the Request (lockup periods are calculated from this)
      confirmed: A confirmation from the Data Consumer releases the funds immidiately
      dispute: signals that there is a dispute over this Request
  */
  struct Request{
		address account;
		uint256 value;
		uint logTime;
		bool confirmed;
		bool dispute;
	}

  ///@notice contractBalance is a variable tied to the balance of the contract
  uint256 public contractBalance;
  ///@notice datablockOwner is the address of the Partnership which registered the Datablock
  address public datablockOwner;
  ///@notice claimHash is the hash address of the claim (what the recipe/proof can do)
  bytes32 public claimHash;
  ///@notice proofHash is the hash address of the proof (recipe) that can reproduce the Claim
  bytes32 public proofHash;
  /**
  @notice datablockPrice is a variable representing the base price
    IMPORTANT NOTE: This price is not intended as the final price, merely a base price.
    The intent is to have reputation and other factors contribute a coefficient that will
    be applied to this base price.
  */
  uint256 public datablockPrice;

  /**
  @notice Lockup periods serve as the maximum amount of time to start a dispute
    before the Data Producer can withdraw the funds, and are measured in days
  */
  uint256 public lockupPeriodInDays;

  /**
  @notice purchaseCounter measures how many times access has been purchased
    to this particular Datablock
  */
  uint256 public purchaseCounter;
  /**
  @notice disputeCounter measures how many disputes have been opened on this
    particular Datablock
  */
  uint256 public disputeCounter;

  /// @notice idx is an internal index number used for traversing the array of Requests
  uint256 private idx;
  /// @notice requests is the array of Requests
  Request[] public requests;
  /// @notice consumerAddressIndex allows an easy lookup of a Request using the address that created it
  mapping (address => uint256) private consumerAddressIndex;

  event LogDeposit(address _sender, uint256 _amount);
  event LogWithdraw(address _owner, uint256 _value);
	event LogDispute(address _sender);
	event LogConfirmation(address _sender, uint256 _idx);
	event LogNewDBK(address indexed _PTR, bytes32 indexed _claim, bytes32 indexed _proof);
	event LogNewPurchaseRequest(address indexed _sender,uint256 indexed _idx);
  event LogPaymentRefund(address thisDBK, address returnedTo, uint256 _value);

  modifier OnlyDatablockOwner(address _address) {
    require(datablockOwner == _address);
    _;
  }

  modifier OnlyRequestOwner(address _address) {
    require(requests[consumerAddressIndex[_address]].account == _address);
    _;
  }

  /**
  * @notice The constructor builds the Datablock
  * @param _owner Address of the Partnership registering the Datablock
  * @param _claimPointer 32-byte hash address of the claim
  * @param _proofPointer 32-byte hash address of the proof
  * @param _price Base price before coefficients
  * @param _periodInDays How long funds are locked up by default before being released to the owners
  */
  constructor(
    address _owner,
    bytes32 _claimPointer,
    bytes32 _proofPointer,
    uint256 _price,
    uint256 _periodInDays
    )
    public
    payable
  {
    datablockOwner = _owner;
    claimHash = _claimPointer;
    proofHash = _proofPointer;
    datablockPrice = _price;
    lockupPeriodInDays = _periodInDays;
    idx = 0;

    emit LogNewDBK(datablockOwner, claimHash, proofHash);
  }

  /// @notice The fallback function allows the contract to handle funds
  function()
    public
    payable
  {
    if(msg.value>0){
      emit LogDeposit(msg.sender, msg.value);
    }
  }

  /**
  @notice purchaseAccess is the function that registers a new request to purchase
    access. It does this by creating a new Request and pushing it to the requests
    array.
  */
  function purchaseAccess()
    public
    payable
  {
    require(msg.value >= datablockPrice);

    uint256 i=consumerAddressIndex[msg.sender];

    Request memory req = Request({
      account: msg.sender,
      value: msg.value,
      logTime: now,
      confirmed: false,
      dispute: false
      });

    if(requests[consumerAddressIndex[msg.sender]].account==msg.sender){
      i = consumerAddressIndex[msg.sender];
    }else{
      for(; idx<requests.length; idx++){
        if(requests[idx].account == 0){
          break;
        }
      }
    }

    if(idx<requests.length){
      requests[idx] = req;
    }else{
      requests.push(req);
    }

    consumerAddressIndex[msg.sender] = idx;
    purchaseCounter++;

    emit LogNewPurchaseRequest(msg.sender, i);

  }

  /// @notice withdrawFundsFromAllRequests calls withdrawFromSpecificRequest on all Requests
  function withdrawFundsFromAllRequests()
    public
    payable
    OnlyDatablockOwner(msg.sender)
  {
    require(datablockOwner == msg.sender);

    for(uint256 i = 0; i<requests.length; i++) {
      withdrawFromSpecificRequest(i);
    }
  }

  /**
  * @notice withdrawFromSpecificRequest allows the owners to withdraw funds from a
      Request which has either passed the lockup period or been manually confirmed
      by the buyer
  * @param _idx The index of the Request in the requests array
  */
  function withdrawFromSpecificRequest(uint256 _idx)
    public
    payable
    OnlyDatablockOwner(msg.sender)
  {
    if(requests[_idx].dispute == false){
      if((requests[_idx].confirmed==true) ||
  			((now - requests[_idx].logTime)>(lockupPeriodInDays*1 days)))
      {
      	uint256 tempValue = requests[_idx].value - __txFees;
        if(_idx<idx)idx=_idx;
      	consumerAddressIndex[msg.sender]=uint256(-1);
      	requests[_idx]=Request({
      		account:address(0),
      		value:0,
      		logTime:0,
      		confirmed:false,
      		dispute:false});

        datablockOwner.transfer(tempValue);

        emit LogWithdraw(datablockOwner, tempValue);
      }
    }
  }

  /**
  @notice openDispute allows a purchasing party to dispute that they received what
    they paid for
  */
  function openDispute()
    public
    payable
    OnlyRequestOwner(msg.sender)
  {
    require(requests[consumerAddressIndex[msg.sender]].dispute==false);
		requests[consumerAddressIndex[msg.sender]].dispute=true;
		disputeCounter++;
		emit LogDispute(msg.sender);
  }

  /**
  @notice closeDisputeAndConfirm confirms a purchase, closing a dispute if one is
    open, in the process
  */
  function closeDisputeAndConfirm()
    public
    payable
    OnlyRequestOwner(msg.sender)
  {
    uint256 i = consumerAddressIndex[msg.sender];
		requests[i].dispute=false;
		requests[i].confirmed=true;
		emit LogConfirmation(msg.sender,i);
  }

  /**
  @notice refundPayment allows the owners of the Datablock to refund a payment
  @param _refundTo The address to be refunded
  @dev Currently disabled
  */
  function refundPayment(address _refundTo)
    public
    OnlyRequestOwner(msg.sender)
  {
    uint256 _idx = consumerAddressIndex[_refundTo];

    if(requests[_idx].dispute == true){
      uint256 tempValue = requests[_idx].value - __txFees;
      if(int256(tempValue) > 0){
        address tempAccount = requests[_idx].account;
        consumerAddressIndex[msg.sender] = 0;
        requests[_idx]=Request({
          account: address(0),
          value: 0,
          logTime: 0,
          confirmed: false,
          dispute: false
          });

        // _refundTo.transfer(tempValue);

        emit LogPaymentRefund(this, tempAccount, requests[_idx].value);
      }
    }
  }

  /// @notice getBalance allows the balance of a Datablock to be queried
  function getBalance()
    public
    returns(uint256)
    {
      contractBalance = address(this).balance;
      return contractBalance;
    }
}

/** @title The Partnership contract manages a partnership between members on the network */
contract Partnership is SampleTypes{

  /**
  @notice The Invitation struct is used to invite members to a Partnership at its inception
    A brief description of the individual data points follows:
      account: the address to be invited
      units: a measure used to weight the user
      invited: a flag ensuring this user is invited
  */
  struct Invitation{
		address account;
		uint256 units;
		bool invited;
	}

  /// @notice pendingUnits measures how many weighting units have been alloted and not allocated
  uint256 public pendingUnits;
  /// @notice allocatedUnits measures how many weight units have been allocated
  uint256 public allocatedUnits;
  /// @notice totalUnits measures how many weight units are pending or allocated
  uint256 public totalUnits;
  /// @notice contractBalance is a variable reflecting the balance of the Partnership
  uint256 public contractBalance;
  /// @notice factor is a variable for conveniently converting between wei and ether
  uint256 private constant factor = 10**18;
  /// @notice flag is a debugging flag
  bool private flag;

  /// @notice unitsArray is an array of weight units which is synchronized with the array of members
  uint256[] public unitsArray;
  /// @notice unitBalances maps members to their weight (their units)
  mapping (address => uint256) public unitBalances;
  /// @notice members is an array of the addresses of the members of the Partnership
  address[] public members;
  /// @notice invitations maps Invitation structs to the addresses they were sent to
  mapping (address => Invitation) public invitations;

  event LogNewContract(address indexed contractOwner, address indexed contractAddress, string contractName);
	event LogNewInvitation(address indexed _guest, uint256 _units);
	event LogNewMember(address indexed _guest, uint256 _units);
	event LogDeposit(address indexed_src,uint256 _value);
	event LogAddNewMember(address _acc, uint256 _units);
	event LogPayout(address _acc, uint256 _value, uint256 _balance);
	event LogWithdrawAllCalled(address _caller);
	event LogWithdrawCalled(address _caller);
  event LogRemoteWithdrawCalled(address _caller, address remotePTR);

  modifier OnlyMember(address _address) {
    require(unitBalances[_address] > 0);
    _;
  }

  /**
  * @notice The constructor deploys a new Partnership
  * @param _accounts An array of addresses to invite to the Partnership
  * @param _units An array of the weight units each invited member is to receive
  * @param _totalUnits The total amounts of weight units
  * @param _debug Debugging flag
  */
  constructor(
    address[] _accounts,
    uint256[] _units,
    uint256 _totalUnits,
    bool _debug
    )
    public
    payable
  {
    __debug = _debug;
    require(_accounts.length == _units.length);
    totalUnits = _totalUnits;
    uint256 tempUnitCounter = 0;
    allocatedUnits = 0;
    for(uint256 i=0; i<_accounts.length; i++){
      require(_accounts[i] != 0);
      tempUnitCounter += _units[i];
      require(tempUnitCounter <= _totalUnits);
      invitations[_accounts[i]] = Invitation({
        account: _accounts[i],
        units: _units[i],
        invited: true
        });
      emit LogNewInvitation(_accounts[i], _units[i]);
    }

    pendingUnits = tempUnitCounter;

    flag = false;
  }

  /// @notice The fallback function allows the contract to handle funds
  function()
    public
    payable
  {
    if(msg.value>0){
      emit LogDeposit(msg.sender, msg.value);
    }
  }

  /// @notice acceptInvitation allows an invited user to accept the invitation
  function acceptInvitation()
    public
    payable
  {
    require(invitations[msg.sender].account == msg.sender);
		require(invitations[msg.sender].invited == true);
    require(invitations[msg.sender].units <= pendingUnits);

    uint256 tmpUnits = invitations[msg.sender].units;

    invitations[msg.sender].account=0;
		invitations[msg.sender].units=0;
		invitations[msg.sender].invited = false;

    pendingUnits -= tmpUnits;
    allocatedUnits += tmpUnits;
    members.push(msg.sender);
    unitBalances[msg.sender] += tmpUnits;

    emit LogNewMember(msg.sender, unitBalances[msg.sender]);
  }

  /// @notice distributeByHoldings distributes the balance of the partnership by the weight of its members
  function distributeByHoldings()
    public
    payable
    OnlyMember(msg.sender)
    PassIfTrue(!flag)
  {
      flag = true;

      require(unitsArray.length == members.length);
      uint256 amountToDistribute;

      uint256 tempBalance = address(this).balance - (__txFees * members.length);
      require(int256(tempBalance) > 0);
      for(uint256 i=0; i<unitsArray.length; i++){
        uint256 percentage = unitBalances[members[i]]/allocatedUnits;
        amountToDistribute = (tempBalance * percentage);
        if(amountToDistribute > 0){
          tempBalance -= amountToDistribute;

          members[i].transfer(amountToDistribute);

          emit LogPayout(members[i], amountToDistribute, tempBalance);
      }
      flag = false;
    }
  }

  /**
  @notice isMember is a function that queries if a certain address is a memebr of this Partnership
  @param _address The address checked
  */
  function isMember(address _address)
    public
    constant
    returns(bool)
  {
    return(unitBalances[_address] > 0);
  }

  /**
  @notice callWithdrawAll allows a Partnership to withdraw funds from all confirmed requests
    in a  particular Datablock that it owns
  @param _DBKaddress The address of the Datablock
  */
  function callWithdrawAll(address _DBKaddress)
    public
    payable
    OnlyMember(msg.sender)
  {
    require(_DBKaddress.call(bytes4(keccak256("withdrawAll()"))));

    emit LogWithdrawAllCalled(msg.sender);
  }

  /**
  @notice callWithdraw allows a Partnership to withdraw funds from a Datablock that it owns
  @param _DBKaddress The address of the Datablock
  @param _idx The index of the Request in the requests array in the Datablock
  */
  function callWithdraw(address _DBKaddress, uint256 _idx)
    public
    payable
    OnlyMember(msg.sender)
  {
    require(_DBKaddress.call(bytes4(keccak256("withdraw(uint256)")),_idx));

    emit LogWithdrawCalled(msg.sender);
  }

  /**
  @notice In the event that a Partnership is a member in another Partnership, callDistribute
    allows the sub-Partnership to call distributeByHoldings in the meta-Partnership
  @param _PTRtoCall Address of the Partnership contract being called
  */
  function callDistribute(address _PTRtoCall)
    public
    OnlyMember(msg.sender)
  {
    require(_PTRtoCall.call(bytes4(keccak256("distributeByHoldings()"))));

    emit LogRemoteWithdrawCalled(msg.sender, _PTRtoCall);
  }

  /// @notice getBalance allows the balance of the contract to be queried
  function getBalance()
    public
    constant
    returns(uint)
  {
    return(address(this).balance);
  }
}

