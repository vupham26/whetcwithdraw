// This contract just saves in the blockchain the intention to withdraw dth
// A Bot will execute this operation in the ETC blockchain and will save
// the result back
contract Owned {
    /// Prevents methods from perfoming any value transfer
    modifier noEther() {if (msg.value > 0) throw; _}
    /// Allows only the owner to call a function
    modifier onlyOwner { if (msg.sender == owner) _ }

    function Owned() { owner = msg.sender;}
    address owner;


    function changeOwner(address _newOwner) onlyOwner {
        owner = _newOwner;
    }

    function execute(address _dst, uint _value, bytes _data) onlyOwner {
        _dst.call.value(_value)(_data);
    }

    function getOwner() noEther constant returns (address) {
        return owner;
    }
}

contract CrossWhitehatWithdraw is Owned {
    address bot;
    uint price;

    Operation[] public operations;

    modifier onlyBot { if ((msg.sender == owner)||(msg.sender == bot)) _ }

    struct Operation {
        address dth;
        address etcBeneficiary;
        uint percentageWHG;
        uint queryTime;

        uint answerTime;
        uint result;
        bytes32 etcTxHash;
    }

    function CrossWhitehatWithdraw(uint _price, address _bot) Owned() {
        price = _price;
        bot = _bot;
    }

    function withdraw(address _etcBeneficiary, uint _percentageWHG) returns (uint) {
        if (_percentageWHG > 100) throw;
        if (msg.value < price) throw;
        Operation op = operations[operations.length ++];
        op.dth = msg.sender;
        op.etcBeneficiary = _etcBeneficiary;
        op.percentageWHG = _percentageWHG;
        op.queryTime = now;
        Withdraw(op.dth, op.etcBeneficiary, op.percentageWHG, operations.length -1);

        return operations.length -1;
    }

    function setResult(uint _idOperation, uint _result, bytes32 _etcTxHash) onlyBot noEther {
        Operation op = operations[_idOperation];
        if (op.dth == 0) throw;
        op.answerTime = now;
        op.result = _result;
        op.etcTxHash = _etcTxHash;
        WithdrawResult(_idOperation, _etcTxHash, _result);
    }

    function setBot(address _bot) onlyOwner noEther  {
        bot = _bot;
    }

    function getBot() noEther constant returns (address) {
        return bot;
    }

    function setPrice(uint _price) onlyOwner noEther  {
        price = _price;
    }

    function getPrice() noEther constant returns (uint) {
        return price;
    }

    function getOperation(uint _idOperation) noEther constant returns (address dth,
        address etcBeneficiary,
        uint percentageWHG,
        uint queryTime,
        uint answerTime,
        uint result,
        bytes32 dthTxHash)
    {
        Operation op = operations[_idOperation];
        return (op.dth,
                op.etcBeneficiary,
                op.percentageWHG,
                op.queryTime,
                op.answerTime,
                op.result,
                op.etcTxHash);
    }

    function getOperationsNumber() noEther constant returns (uint) {
        return operations.length;
    }

    function() {
        throw;
    }

    function kill() onlyOwner {
        selfdestruct(owner);
    }

    event Withdraw(address indexed dth, address indexed beneficiary, uint percentageWHG, uint proposal);
    event WithdrawResult(uint indexed proposal, bytes32 indexed etcTxHash, uint result);


}
