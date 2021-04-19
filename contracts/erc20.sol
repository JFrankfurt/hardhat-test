//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
      if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Token {
  string public constant name = "Token";

  string public constant symbol = "TOK";

  uint8 public constant decimals = 18;

  uint public totalSupply = 1_000_000_000e18; // 1 billion TOK

  address public minter;

  uint32 public constant minimumTimeBetweenMints = 1 days * 365;

  uint8 public constant mintCap = 2;

  mapping (address => mapping (address => uint96)) internal allowances;

  mapping (address => uint96) internal balances;

  struct Checkpoint {
      uint32 fromBlock;
      uint96 votes;
  }

  mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

  bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

  bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

  bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

  mapping (address => uint) public nonces;

  event MinterChanged(address minter, address newMinter);

  event Transfer(address indexed from, address indexed to, uint256 amount);

  event Approval(address indexed owner, address indexed spender, uint256 amount);

  constructor(address account, address minter_) {
    balances[account] = uint96(totalSupply);
    emit Transfer(address(0), account, totalSupply);
    minter = minter_;
    emit MinterChanged(address(0), minter);
  }

  function setMinter(address minter_) external {
    require(msg.sender == minter, "Token::setMinter: only the minter can change the minter address");
    emit MinterChanged(minter, minter_);
    minter = minter_;
  }

  function mint(address dst, uint rawAmount) external {
    require(msg.sender == minter, "Token::mint: only the minter can mint");
    require(dst != address(0), "Token::mint: cannot transfer to the zero address");

    // mint the amount
    uint96 amount = safe96(rawAmount, "Token::mint: amount exceeds 96 bits");
    require(amount <= SafeMath.div(SafeMath.mul(totalSupply, mintCap), 100), "Token::mint: exceeded mint cap");
    totalSupply = safe96(SafeMath.add(totalSupply, amount), "Token::mint: totalSupply exceeds 96 bits");

    // transfer the amount to the recipient
    balances[dst] = add96(balances[dst], amount, "Token::mint: transfer amount overflows");
    emit Transfer(address(0), dst, amount);
  }

  function allowance(address account, address spender) external view returns (uint) {
    return allowances[account][spender];
  }

  function approve(address spender, uint rawAmount) external returns (bool) {
    uint96 amount;
    if (rawAmount == type(uint).max) {
      amount = type(uint96).max;
    } else {
      amount = safe96(rawAmount, "Token::approve: amount exceeds 96 bits");
    }

    allowances[msg.sender][spender] = amount;

    emit Approval(msg.sender, spender, amount);
    return true;
  }

  function permit(address owner, address spender, uint rawAmount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
    uint96 amount;
    if (rawAmount == type(uint).max) {
      amount = type(uint96).max;
    } else {
      amount = safe96(rawAmount, "Token::permit: amount exceeds 96 bits");
    }

    bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
    bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, rawAmount, nonces[owner]++, deadline));
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    address signatory = ecrecover(digest, v, r, s);
    require(signatory != address(0), "Token::permit: invalid signature");
    require(signatory == owner, "Token::permit: unauthorized");
    require(block.timestamp <= deadline, "Token::permit: signature expired");

    allowances[owner][spender] = amount;

    emit Approval(owner, spender, amount);
  }

  function balanceOf(address account) external view returns (uint) {
    return balances[account];
  }

  function transfer(address dst, uint rawAmount) external returns (bool) {
    uint96 amount = safe96(rawAmount, "Token::transfer: amount exceeds 96 bits");
    _transferTokens(msg.sender, dst, amount);
    return true;
  }

  function transferFrom(address src, address dst, uint rawAmount) external returns (bool) {
    address spender = msg.sender;
    uint96 spenderAllowance = allowances[src][spender];
    uint96 amount = safe96(rawAmount, "Token::approve: amount exceeds 96 bits");

    if (spender != src && spenderAllowance != type(uint96).max) {
      uint96 newAllowance = sub96(spenderAllowance, amount, "Token::transferFrom: transfer amount exceeds spender allowance");
      allowances[src][spender] = newAllowance;

      emit Approval(src, spender, newAllowance);
    }

    _transferTokens(src, dst, amount);
    return true;
  }

  function _transferTokens(address src, address dst, uint96 amount) internal {
      require(src != address(0), "Token::_transferTokens: cannot transfer from the zero address");
      require(dst != address(0), "Token::_transferTokens: cannot transfer to the zero address");

      balances[src] = sub96(balances[src], amount, "Token::_transferTokens: transfer amount exceeds balance");
      balances[dst] = add96(balances[dst], amount, "Token::_transferTokens: transfer amount overflows");
      emit Transfer(src, dst, amount);
  }

  function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }

  function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
    require(n < 2**96, errorMessage);
    return uint96(n);
  }

  function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
    uint96 c = a + b;
    require(c >= a, errorMessage);
    return c;
  }

  function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
    require(b <= a, errorMessage);
    return a - b;
  }

  function getChainId() internal view returns (uint) {
    uint256 chainId;
    assembly { chainId := chainid() }
    return chainId;
  }
}