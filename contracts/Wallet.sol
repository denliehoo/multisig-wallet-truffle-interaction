/* A multisig wallet is a wallet where multiple “signatures” or approvals are needed for an outgoing transfer to take place.
 As an example, I could create a multisig wallet with me and my 2 friends.
 I configure the wallet such that it requires at least 2 of us to sign any transfer before it is valid.
 Anyone can deposit funds into this wallet. But as soon as we want to spend funds, it requires 2/3 approvals.
Requirements of the smart contract wallet you will be building:
1. Anyone should be able to deposit ether into the smart contract
2. The contract creator should be able to input:
    (a): the addresses of the owners and
    (b):  the numbers of approvals required for a transfer, in the constructor.
           For example, input 3 addresses and set the approval limit to 2. 
3. Anyone of the owners should be able to create a transfer request. The creator of the transfer request will
  specify what amount and to what address the transfer will be made.
4. Owners should be able to approve transfer requests.
5. When a transfer request has the required approvals, the transfer should be sent.
*/
pragma solidity 0.7.5;
pragma abicoder v2; //required to do this if we want to return structs

contract Wallet {
    struct PendingTransaction {
        address payable to;
        uint256 amount;
        uint256 numberOfApprovals;
        uint256 numberOfRejections;
        uint256 txId;
        bool sent;
        bool rejected;
    }
    PendingTransaction pendingTransaction;
    PendingTransaction[] pendingTransactions;
    address[] owners;
    // e.g. transacationApprovals[txId][0x....] = false; this double mapping keeps track
    // of whether an owner has approved a certain transaction of not
    mapping(uint256 => mapping(address => bool)) transactionApprovals;
    uint256 public approvalRequired;
    uint256 currentTxId;
    uint256 walletBalance;
    // events
    event TransferRequestCreated(
        uint256 _id,
        uint256 _amount,
        address _initiator,
        address _receiver
    );
    event TransactionApprovalReceived(uint256 _id, address _approver);
    event TransactionRejectionReceived(uint256 _id, address _rejector);
    event TransactionSent(uint256 _id);
    event TransactionRejected(uint256 _id);

    // initializing
    // _owners:
    /* e.g. 
["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2","0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"]
    
test pay to:
0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
    */
    constructor(address[] memory _owners, uint256 _approvalRequired) {
        owners = _owners;
        approvalRequired = _approvalRequired;
        currentTxId = 0;
        require(
            owners.length >= approvalRequired,
            "The amount of approvals required for a transaction is more than the amount of owners"
        );
    }

    // allows people to deposit
    function deposit() public payable {
        walletBalance += msg.value;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getWalletBalance() public view returns (uint256) {
        return walletBalance;
    }

    function viewOwners() public view returns (address[] memory) {
        return owners;
    }

    function viewLatestTransactionId() public view returns (uint256) {
        return currentTxId;
    }

    function requestTransfer(uint256 _amount, address payable _receiver)
        public
        onlyOwners
        returns (uint256)
    {
        // what if its a pending transaction? balance wouldn't have been deducted yet.
        // thats why need to keep a separate variable to keep track of walletBalance
        require(
            _amount <= walletBalance,
            "The wallet doesn't have enough balance"
        );
        pendingTransaction = PendingTransaction(
            _receiver,
            _amount,
            1,
            0,
            currentTxId,
            false,
            false
        );
        pendingTransactions.push(pendingTransaction); //pushes to the list of pendingTransactions
        emit TransferRequestCreated(
            currentTxId,
            _amount,
            msg.sender,
            _receiver
        );
        transactionApprovals[currentTxId][msg.sender] = true; // changes to transactionApproval for the user to be true
        currentTxId += 1; // increases currentTxId by 1 to prepare for the next transaction
        walletBalance -= _amount; // reduces the transferrable amount
        // note: currentTxId should + at the start if not first tx would give 1 for view latest tx Id
        return currentTxId - 1; //returns the txId of the requested transfer
    }

    function viewTransaction(uint256 _txId)
        public
        view
        returns (PendingTransaction memory)
    {
        return pendingTransactions[_txId];
    }

    function approvePendingTransaction(uint256 _txId)
        public
        onlyOwners
        ableToApproveOrReject(_txId)
    {
        // approves the transaction
        transactionApprovals[_txId][msg.sender] = true;
        pendingTransactions[_txId].numberOfApprovals += 1;
        emit TransactionApprovalReceived(_txId, msg.sender);
        // checks if numberOfApprovals == approvalRequired and initiates the transfer if it is
        if (pendingTransactions[_txId].numberOfApprovals == approvalRequired) {
            payTo(
                pendingTransactions[_txId].amount,
                pendingTransactions[_txId].to
            );
            pendingTransactions[_txId].sent = true;
            emit TransactionSent(_txId);
        }
    }

    // this private function will be called if number of approvals is reached
    function payTo(uint256 _amount, address payable _receiver) private {
        _receiver.transfer(_amount);
    }

    // rejects the transaction
    function rejectPendingTransaction(uint256 _txId)
        public
        onlyOwners
        ableToApproveOrReject(_txId)
    {
        transactionApprovals[_txId][msg.sender] = true;
        pendingTransactions[_txId].numberOfRejections += 1;
        emit TransactionRejectionReceived(_txId, msg.sender);
        // checks if numberOfApprovals == approvalRequired and initiates the transfer if it is
        // e.g. 4 owners , 2 approvalRequired
        // 1 rejected 1 approved: 4-1 | 2 => 3 > 2 => no reject
        // 2 rejected 1 approve: 4-2 | 2 => 2 > 2 => no reject
        // 3 rejected 1 approve: 4-3 | 2 => 1<2 => reject
        // e.g. 3 owners , 3 approval required
        // 1 rejected 1 approve: 3-1 | 3 => 2 <3 => reject
        if (
            owners.length - pendingTransactions[_txId].numberOfRejections <
            approvalRequired
        ) {
            pendingTransactions[_txId].rejected = true;
            walletBalance += pendingTransactions[_txId].amount; //increased the walletBalance back since tx rejected
            emit TransactionRejected(_txId);
        }
    }

    modifier onlyOwners() {
        bool isOwners = false;
        for (uint256 i = 0; i < owners.length; i++) {
            if (msg.sender == owners[i]) {
                isOwners = true;
            }
        }
        require(isOwners == true, "You are not an owner of the wallet");
        _;
    }
    modifier ableToApproveOrReject(uint256 _txId) {
        // checks if transaction has been rejected
        require(
            pendingTransactions[_txId].rejected == false,
            "The transaction has already been rejected"
        );
        // checks if transaction has already been sent
        require(
            pendingTransactions[_txId].sent == false,
            "The transaction has already been sent"
        );
        // do a check to see if owner has already approved/rejected
        require(
            transactionApprovals[_txId][msg.sender] == false,
            "You have already approved/rejected the transaction"
        );
        _;
    }
}
/* 
Flow:
1) Sender asks for permission to send requestTransfer
2) Other owners approve/reject approvePendingTransaction/rejectPendingTransaction
3)
    If at the correct amount of approval: transaction gets automatically sent
    If not possible to sent (due to rejects): transaction gets rejected
*/
