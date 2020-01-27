pragma solidity >=0.6.0;

///@title Withdrawal Pattern
contract Withdrawal {
    /// @author Cyril Attie
    /// @notice allows secure withdrawal of funds

    mapping(address => uint256) pendingWithdrawals;

    function withdraw() public {
        ///@notice withdraw your funds
        uint256 amount = pendingWithdrawals[msg.sender];
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
}