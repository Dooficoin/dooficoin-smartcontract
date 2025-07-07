
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract DoofiCoin is ERC20, Ownable, Pausable {
    uint256 public constant MAX_SUPPLY = type(uint128).max;

    uint256 public maxTxPercent = 100; // 100% por transação
    uint256 public maxWalletPercent = 50; // 50% por carteira
    mapping(address => bool) public isExcludedFromAntiWhale;

    mapping(address => bool) public blacklist;

    event PvPKill(address indexed killer, address indexed victim, uint256 amount, uint256 timestamp);

    constructor(address initialOwner) ERC20("DOOFICOIN", "DOOFI") Ownable(initialOwner) {
        isExcludedFromAntiWhale[initialOwner] = true;
        _mint(initialOwner, MAX_SUPPLY);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Excede supply maximo");
        _mint(to, amount);
    }

    function setAntiWhaleLimits(uint256 txPercent, uint256 walletPercent) external onlyOwner {
        require(txPercent <= 100 && walletPercent <= 100, "Limites invalidos");
        maxTxPercent = txPercent;
        maxWalletPercent = walletPercent;
    }

    function setBlacklist(address account, bool blocked) external onlyOwner {
        blacklist[account] = blocked;
    }

    function setExcludedFromAntiWhale(address account, bool excluded) external onlyOwner {
        isExcludedFromAntiWhale[account] = excluded;
    }

    function _update(address from, address to, uint256 amount) internal override whenNotPaused {
        require(!blacklist[from] && !blacklist[to], "Endereco bloqueado");

        if (!isExcludedFromAntiWhale[from] && !isExcludedFromAntiWhale[to]) {
            uint256 supply = totalSupply();
            require(amount <= supply * maxTxPercent / 100, "Excede limite de transacao");
            if (to != address(0)) {
                require(balanceOf(to) + amount <= supply * maxWalletPercent / 100, "Excede limite por carteira");
            }
        }

        super._update(from, to, amount);
    }

    function pvpKill(address killer, address victim, uint256 amount) external onlyOwner {
        require(balanceOf(victim) >= amount, "Saldo insuficiente da vitima");
        _transfer(victim, killer, amount);
        emit PvPKill(killer, victim, amount, block.timestamp);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
