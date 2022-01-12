contract MultiSigWallet {
    struct TransactionData {
        address to;
        bytes data;
        uint256 value;
    }

    struct Transaction {
        TransactionData data;
        uint256 numApprovedOwners;
        bool executed;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;
    Transaction[] transactions;
    mapping(uint256 => mapping(address => bool)) isApproved;
    uint256 public immutable minOwnersRequiredForApproval;

    modifier txExists(uint256 _tnxIndex) {
        require(_tnxIndex < transactions.length, "Invalid transaction index");
        _;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not owner");
        _;
    }

    modifier notExecuted(uint256 _tnxIndex) {
        require(!transactions[_tnxIndex].executed, "tx already executed");
        _;
    }

    modifier notApproved(uint256 _tnxIndex) {
        require(!isApproved[_tnxIndex][msg.sender], "Owner already approved");
        _;
    }

    event TransactionSubmission(
        address indexed owner,
        uint256 indexed tnx,
        address indexed _to,
        bytes _data,
        uint256 _value
    );

    constructor() {
        minOwnersRequiredForApproval = 3;
    }

    function submitTransaction(
        address _to,
        bytes memory _data,
        uint256 _value
    ) public onlyOwner {
        uint256 inx = transactions.length;
        TransactionData memory data = TransactionData(_to, _data, _value);
        Transaction memory transaction = Transaction(data, 0, false);
        transactions.push(transaction);
        emit TransactionSubmission(msg.sender, inx, _to, _data, _value);
    }

    function approveTransaction(uint256 _tnxIndex)
        public
        onlyOwner
        txExists(_tnxIndex)
        notExecuted(_tnxIndex)
        notApproved(_tnxIndex)
    {
        Transaction storage transaction = transactions[_tnxIndex];
        transaction.numApprovedOwners += 1; // Use safemath?
        isApproved[_tnxIndex][msg.sender] = true;
    }

    function revokeTransactionApproval(uint256 _tnxIndex)
        public
        onlyOwner
        txExists(_tnxIndex)
        notExecuted(_tnxIndex)
    {
        require(
            isApproved[_tnxIndex][msg.sender],
            "Owner didn't approve transaction to revoke it."
        );
        Transaction storage transaction = transactions[_tnxIndex];
        transaction.numApprovedOwners -= 1; // Use safemath?
        isApproved[_tnxIndex][msg.sender] = false;
    }

    function executeTransaction(uint256 _tnxIndex)
        public
        onlyOwner
        txExists(_tnxIndex)
        notExecuted(_tnxIndex)
    {
        Transaction storage transaction = transactions[_tnxIndex];
        require(
            transaction.numApprovedOwners >= minOwnersRequiredForApproval,
            "Not enough owners approved this transaction"
        );
        // ... execute the transaction
        transaction.executed = true;
    }
}
