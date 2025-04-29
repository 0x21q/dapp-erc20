import { useState } from 'react';
import { useAccount, useConnect, useDisconnect, useBalance, useWriteContract } from 'wagmi';
import { parseUnits, formatUnits } from 'viem';
import { CONTRACT_ADDRESS } from '../config';

export default function HomePage() {
    // wallet hook
    const account = useAccount();
    
    // connect and disconnect to available connectors
    const { connectors, connect, status, error } = useConnect();
    const { disconnect } = useDisconnect();
  
    // token balance hook
    const { data: tokenBalance } = useBalance({
        address: account.address,
        token: CONTRACT_ADDRESS as `0x${string}`,
    });

    // just to preformat the balance
    const formattedUnits  = tokenBalance ? formatUnits(tokenBalance.value, tokenBalance.decimals) : '';
    const formattedBalance = tokenBalance ? `${formattedUnits} ${tokenBalance.symbol}` : 'Not Available';

    // transfer hook
    const { writeContract, isPending, isError, isSuccess } = useWriteContract();

    // react states
    const [recipient, setRecipient] = useState('');
    const [amount, setAmount] = useState('');

    const handleTransfer = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!account.address || !recipient || !amount) return;

        try {
            // Convert amount to wei (using standard 18 decimal places)
            const value = parseUnits(amount, 18);
            writeContract({
                address: CONTRACT_ADDRESS as `0x${string}`,
                abi: erc20ABI,
                functionName: 'transfer',
                args: [recipient, value],
            });
        } catch (error) {
            console.error('Transfer error:', error);
        }
    };

    return (
        <div className="wallet-container">
            <h1>ERC20 - BDA</h1>

            {/* acc info subsection */}
            <div className="subsection">
                <h2>Account Information</h2>
                <p>Status: {account.status}</p>
                { account.status === 'connected' && (
                    <>
                        <p>Address: {account.address}</p>
                        <p>Chain ID: {account.chainId}</p>
                        <p>Token Balance: {formattedBalance}</p>
                        <button 
                            onClick={() => disconnect()}
                            className="button"
                        >
                            Disconnect
                        </button>
                    </>
                ) }
            </div>

            {/* connect wallet subsection */}
            <div className="subsection">
                <h2>Connect Wallet</h2>
                <div className="connect-buttons">
                    { connectors.map((connector) => (
                        <button
                            key={connector.uid}
                            onClick={() => connect({ connector })}
                            className="button"
                            disabled={account.status === 'connected'}
                        >
                            {connector.name}
                        </button>
                    )) }
                </div>
                { status && <p>Status: {status}</p>}
                { error && 
                    <p className="error-message">Error: {error.message}</p>
                }
            </div>

            {/* token transfer subsection */}
            { account.status === 'connected' && (
                <div className="subsection">
                    <h2>Token Transfer</h2>
                    <form onSubmit={handleTransfer} className="transfer-form">
                        <input
                            type="text"
                            value={recipient}
                            onChange={(e) => setRecipient(e.target.value)}
                            placeholder="Recipient Address"
                            className="input-field"
                        />
                        <input
                            type="number"
                            value={amount}
                            onChange={(e) => setAmount(e.target.value)}
                            placeholder="Amount"
                            className="input-field"
                        />
                        <button 
                            type="submit" 
                            disabled={isPending}
                            className="button"
                        >
                            {isPending ? 'Processing...' : 'Transfer Tokens'}
                        </button>
                        {isError && <p className="error-message">Error sending transaction</p>}
                        {isSuccess && <p className="success-message">Transaction successful!</p>}
                    </form>
                </div>
            ) }
        </div>
    );
}