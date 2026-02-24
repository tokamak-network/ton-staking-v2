(globalThis.TURBOPACK || (globalThis.TURBOPACK = [])).push([typeof document === "object" ? document.currentScript : undefined,
"[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "Block",
    ()=>Block,
    "FeeData",
    ()=>FeeData,
    "Log",
    ()=>Log,
    "TransactionReceipt",
    ()=>TransactionReceipt,
    "TransactionResponse",
    ()=>TransactionResponse,
    "copyRequest",
    ()=>copyRequest
]);
//import { resolveAddress } from "@ethersproject/address";
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/properties.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/maths.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/data.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/errors.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$transaction$2f$accesslist$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/transaction/accesslist.js [client] (ecmascript)");
;
;
const BN_0 = BigInt(0);
// -----------------------
function getValue(value) {
    if (value == null) {
        return null;
    }
    return value;
}
function toJson(value) {
    if (value == null) {
        return null;
    }
    return value.toString();
}
class FeeData {
    /**
     *  The gas price for legacy networks.
     */ gasPrice;
    /**
     *  The maximum fee to pay per gas.
     *
     *  The base fee per gas is defined by the network and based on
     *  congestion, increasing the cost during times of heavy load
     *  and lowering when less busy.
     *
     *  The actual fee per gas will be the base fee for the block
     *  and the priority fee, up to the max fee per gas.
     *
     *  This will be ``null`` on legacy networks (i.e. [pre-EIP-1559](link-eip-1559))
     */ maxFeePerGas;
    /**
     *  The additional amout to pay per gas to encourage a validator
     *  to include the transaction.
     *
     *  The purpose of this is to compensate the validator for the
     *  adjusted risk for including a given transaction.
     *
     *  This will be ``null`` on legacy networks (i.e. [pre-EIP-1559](link-eip-1559))
     */ maxPriorityFeePerGas;
    /**
     *  Creates a new FeeData for %%gasPrice%%, %%maxFeePerGas%% and
     *  %%maxPriorityFeePerGas%%.
     */ constructor(gasPrice, maxFeePerGas, maxPriorityFeePerGas){
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            gasPrice: getValue(gasPrice),
            maxFeePerGas: getValue(maxFeePerGas),
            maxPriorityFeePerGas: getValue(maxPriorityFeePerGas)
        });
    }
    /**
     *  Returns a JSON-friendly value.
     */ toJSON() {
        const { gasPrice, maxFeePerGas, maxPriorityFeePerGas } = this;
        return {
            _type: "FeeData",
            gasPrice: toJson(gasPrice),
            maxFeePerGas: toJson(maxFeePerGas),
            maxPriorityFeePerGas: toJson(maxPriorityFeePerGas)
        };
    }
}
;
function copyRequest(req) {
    const result = {};
    // These could be addresses, ENS names or Addressables
    if (req.to) {
        result.to = req.to;
    }
    if (req.from) {
        result.from = req.from;
    }
    if (req.data) {
        result.data = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["hexlify"])(req.data);
    }
    const bigIntKeys = "chainId,gasLimit,gasPrice,maxFeePerBlobGas,maxFeePerGas,maxPriorityFeePerGas,value".split(/,/);
    for (const key of bigIntKeys){
        if (!(key in req) || req[key] == null) {
            continue;
        }
        result[key] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"])(req[key], `request.${key}`);
    }
    const numberKeys = "type,nonce".split(/,/);
    for (const key of numberKeys){
        if (!(key in req) || req[key] == null) {
            continue;
        }
        result[key] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"])(req[key], `request.${key}`);
    }
    if (req.accessList) {
        result.accessList = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$transaction$2f$accesslist$2e$js__$5b$client$5d$__$28$ecmascript$29$__["accessListify"])(req.accessList);
    }
    if (req.authorizationList) {
        result.authorizationList = req.authorizationList.slice();
    }
    if ("blockTag" in req) {
        result.blockTag = req.blockTag;
    }
    if ("enableCcipRead" in req) {
        result.enableCcipRead = !!req.enableCcipRead;
    }
    if ("customData" in req) {
        result.customData = req.customData;
    }
    if ("blobVersionedHashes" in req && req.blobVersionedHashes) {
        result.blobVersionedHashes = req.blobVersionedHashes.slice();
    }
    if ("kzg" in req) {
        result.kzg = req.kzg;
    }
    if ("blobWrapperVersion" in req) {
        result.blobWrapperVersion = req.blobWrapperVersion;
    }
    if ("blobs" in req && req.blobs) {
        result.blobs = req.blobs.map((b)=>{
            if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isBytesLike"])(b)) {
                return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["hexlify"])(b);
            }
            return Object.assign({}, b);
        });
    }
    return result;
}
class Block {
    /**
     *  The provider connected to the block used to fetch additional details
     *  if necessary.
     */ provider;
    /**
     *  The block number, sometimes called the block height. This is a
     *  sequential number that is one higher than the parent block.
     */ number;
    /**
     *  The block hash.
     *
     *  This hash includes all properties, so can be safely used to identify
     *  an exact set of block properties.
     */ hash;
    /**
     *  The timestamp for this block, which is the number of seconds since
     *  epoch that this block was included.
     */ timestamp;
    /**
     *  The block hash of the parent block.
     */ parentHash;
    /**
     *  The hash tree root of the parent beacon block for the given
     *  execution block. See [[link-eip-4788]].
     */ parentBeaconBlockRoot;
    /**
     *  The nonce.
     *
     *  On legacy networks, this is the random number inserted which
     *  permitted the difficulty target to be reached.
     */ nonce;
    /**
     *  The difficulty target.
     *
     *  On legacy networks, this is the proof-of-work target required
     *  for a block to meet the protocol rules to be included.
     *
     *  On modern networks, this is a random number arrived at using
     *  randao.  @TODO: Find links?
     */ difficulty;
    /**
     *  The total gas limit for this block.
     */ gasLimit;
    /**
     *  The total gas used in this block.
     */ gasUsed;
    /**
     *  The root hash for the global state after applying changes
     *  in this block.
     */ stateRoot;
    /**
     *  The hash of the transaction receipts trie.
     */ receiptsRoot;
    /**
     *  The total amount of blob gas consumed by the transactions
     *  within the block. See [[link-eip-4844]].
     */ blobGasUsed;
    /**
     *  The running total of blob gas consumed in excess of the
     *  target, prior to the block. See [[link-eip-4844]].
     */ excessBlobGas;
    /**
     *  The miner coinbase address, wihch receives any subsidies for
     *  including this block.
     */ miner;
    /**
     *  The latest RANDAO mix of the post beacon state of
     *  the previous block.
     */ prevRandao;
    /**
     *  Any extra data the validator wished to include.
     */ extraData;
    /**
     *  The base fee per gas that all transactions in this block were
     *  charged.
     *
     *  This adjusts after each block, depending on how congested the network
     *  is.
     */ baseFeePerGas;
    #transactions;
    /**
     *  Create a new **Block** object.
     *
     *  This should generally not be necessary as the unless implementing a
     *  low-level library.
     */ constructor(block, provider){
        this.#transactions = block.transactions.map((tx)=>{
            if (typeof tx !== "string") {
                return new TransactionResponse(tx, provider);
            }
            return tx;
        });
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            provider,
            hash: getValue(block.hash),
            number: block.number,
            timestamp: block.timestamp,
            parentHash: block.parentHash,
            parentBeaconBlockRoot: block.parentBeaconBlockRoot,
            nonce: block.nonce,
            difficulty: block.difficulty,
            gasLimit: block.gasLimit,
            gasUsed: block.gasUsed,
            blobGasUsed: block.blobGasUsed,
            excessBlobGas: block.excessBlobGas,
            miner: block.miner,
            prevRandao: getValue(block.prevRandao),
            extraData: block.extraData,
            baseFeePerGas: getValue(block.baseFeePerGas),
            stateRoot: block.stateRoot,
            receiptsRoot: block.receiptsRoot
        });
    }
    /**
     *  Returns the list of transaction hashes, in the order
     *  they were executed within the block.
     */ get transactions() {
        return this.#transactions.map((tx)=>{
            if (typeof tx === "string") {
                return tx;
            }
            return tx.hash;
        });
    }
    /**
     *  Returns the complete transactions, in the order they
     *  were executed within the block.
     *
     *  This is only available for blocks which prefetched
     *  transactions, by passing ``true`` to %%prefetchTxs%%
     *  into [[Provider-getBlock]].
     */ get prefetchedTransactions() {
        const txs = this.#transactions.slice();
        // Doesn't matter...
        if (txs.length === 0) {
            return [];
        }
        // Make sure we prefetched the transactions
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(typeof txs[0] === "object", "transactions were not prefetched with block request", "UNSUPPORTED_OPERATION", {
            operation: "transactionResponses()"
        });
        return txs;
    }
    /**
     *  Returns a JSON-friendly value.
     */ toJSON() {
        const { baseFeePerGas, difficulty, extraData, gasLimit, gasUsed, hash, miner, prevRandao, nonce, number, parentHash, parentBeaconBlockRoot, stateRoot, receiptsRoot, timestamp, transactions } = this;
        return {
            _type: "Block",
            baseFeePerGas: toJson(baseFeePerGas),
            difficulty: toJson(difficulty),
            extraData,
            gasLimit: toJson(gasLimit),
            gasUsed: toJson(gasUsed),
            blobGasUsed: toJson(this.blobGasUsed),
            excessBlobGas: toJson(this.excessBlobGas),
            hash,
            miner,
            prevRandao,
            nonce,
            number,
            parentHash,
            timestamp,
            parentBeaconBlockRoot,
            stateRoot,
            receiptsRoot,
            transactions
        };
    }
    [Symbol.iterator]() {
        let index = 0;
        const txs = this.transactions;
        return {
            next: ()=>{
                if (index < this.length) {
                    return {
                        value: txs[index++],
                        done: false
                    };
                }
                return {
                    value: undefined,
                    done: true
                };
            }
        };
    }
    /**
     *  The number of transactions in this block.
     */ get length() {
        return this.#transactions.length;
    }
    /**
     *  The [[link-js-date]] this block was included at.
     */ get date() {
        if (this.timestamp == null) {
            return null;
        }
        return new Date(this.timestamp * 1000);
    }
    /**
     *  Get the transaction at %%indexe%% within this block.
     */ async getTransaction(indexOrHash) {
        // Find the internal value by its index or hash
        let tx = undefined;
        if (typeof indexOrHash === "number") {
            tx = this.#transactions[indexOrHash];
        } else {
            const hash = indexOrHash.toLowerCase();
            for (const v of this.#transactions){
                if (typeof v === "string") {
                    if (v !== hash) {
                        continue;
                    }
                    tx = v;
                    break;
                } else {
                    if (v.hash !== hash) {
                        continue;
                    }
                    tx = v;
                    break;
                }
            }
        }
        if (tx == null) {
            throw new Error("no such tx");
        }
        if (typeof tx === "string") {
            return await this.provider.getTransaction(tx);
        } else {
            return tx;
        }
    }
    /**
     *  If a **Block** was fetched with a request to include the transactions
     *  this will allow synchronous access to those transactions.
     *
     *  If the transactions were not prefetched, this will throw.
     */ getPrefetchedTransaction(indexOrHash) {
        const txs = this.prefetchedTransactions;
        if (typeof indexOrHash === "number") {
            return txs[indexOrHash];
        }
        indexOrHash = indexOrHash.toLowerCase();
        for (const tx of txs){
            if (tx.hash === indexOrHash) {
                return tx;
            }
        }
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, "no matching transaction", "indexOrHash", indexOrHash);
    }
    /**
     *  Returns true if this block been mined. This provides a type guard
     *  for all properties on a [[MinedBlock]].
     */ isMined() {
        return !!this.hash;
    }
    /**
     *  Returns true if this block is an [[link-eip-2930]] block.
     */ isLondon() {
        return !!this.baseFeePerGas;
    }
    /**
     *  @_ignore:
     */ orphanedEvent() {
        if (!this.isMined()) {
            throw new Error("");
        }
        return createOrphanedBlockFilter(this);
    }
}
class Log {
    /**
     *  The provider connected to the log used to fetch additional details
     *  if necessary.
     */ provider;
    /**
     *  The transaction hash of the transaction this log occurred in. Use the
     *  [[Log-getTransaction]] to get the [[TransactionResponse]].
     */ transactionHash;
    /**
     *  The block hash of the block this log occurred in. Use the
     *  [[Log-getBlock]] to get the [[Block]].
     */ blockHash;
    /**
     *  The block number of the block this log occurred in. It is preferred
     *  to use the [[Block-hash]] when fetching the related [[Block]],
     *  since in the case of an orphaned block, the block at that height may
     *  have changed.
     */ blockNumber;
    /**
     *  If the **Log** represents a block that was removed due to an orphaned
     *  block, this will be true.
     *
     *  This can only happen within an orphan event listener.
     */ removed;
    /**
     *  The address of the contract that emitted this log.
     */ address;
    /**
     *  The data included in this log when it was emitted.
     */ data;
    /**
     *  The indexed topics included in this log when it was emitted.
     *
     *  All topics are included in the bloom filters, so they can be
     *  efficiently filtered using the [[Provider-getLogs]] method.
     */ topics;
    /**
     *  The index within the block this log occurred at. This is generally
     *  not useful to developers, but can be used with the various roots
     *  to proof inclusion within a block.
     */ index;
    /**
     *  The index within the transaction of this log.
     */ transactionIndex;
    /**
     *  @_ignore:
     */ constructor(log, provider){
        this.provider = provider;
        const topics = Object.freeze(log.topics.slice());
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            transactionHash: log.transactionHash,
            blockHash: log.blockHash,
            blockNumber: log.blockNumber,
            removed: log.removed,
            address: log.address,
            data: log.data,
            topics,
            index: log.index,
            transactionIndex: log.transactionIndex
        });
    }
    /**
     *  Returns a JSON-compatible object.
     */ toJSON() {
        const { address, blockHash, blockNumber, data, index, removed, topics, transactionHash, transactionIndex } = this;
        return {
            _type: "log",
            address,
            blockHash,
            blockNumber,
            data,
            index,
            removed,
            topics,
            transactionHash,
            transactionIndex
        };
    }
    /**
     *  Returns the block that this log occurred in.
     */ async getBlock() {
        const block = await this.provider.getBlock(this.blockHash);
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(!!block, "failed to find transaction", "UNKNOWN_ERROR", {});
        return block;
    }
    /**
     *  Returns the transaction that this log occurred in.
     */ async getTransaction() {
        const tx = await this.provider.getTransaction(this.transactionHash);
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(!!tx, "failed to find transaction", "UNKNOWN_ERROR", {});
        return tx;
    }
    /**
     *  Returns the transaction receipt fot the transaction that this
     *  log occurred in.
     */ async getTransactionReceipt() {
        const receipt = await this.provider.getTransactionReceipt(this.transactionHash);
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(!!receipt, "failed to find transaction receipt", "UNKNOWN_ERROR", {});
        return receipt;
    }
    /**
     *  @_ignore:
     */ removedEvent() {
        return createRemovedLogFilter(this);
    }
}
class TransactionReceipt {
    /**
     *  The provider connected to the log used to fetch additional details
     *  if necessary.
     */ provider;
    /**
     *  The address the transaction was sent to.
     */ to;
    /**
     *  The sender of the transaction.
     */ from;
    /**
     *  The address of the contract if the transaction was directly
     *  responsible for deploying one.
     *
     *  This is non-null **only** if the ``to`` is empty and the ``data``
     *  was successfully executed as initcode.
     */ contractAddress;
    /**
     *  The transaction hash.
     */ hash;
    /**
     *  The index of this transaction within the block transactions.
     */ index;
    /**
     *  The block hash of the [[Block]] this transaction was included in.
     */ blockHash;
    /**
     *  The block number of the [[Block]] this transaction was included in.
     */ blockNumber;
    /**
     *  The bloom filter bytes that represent all logs that occurred within
     *  this transaction. This is generally not useful for most developers,
     *  but can be used to validate the included logs.
     */ logsBloom;
    /**
     *  The actual amount of gas used by this transaction.
     *
     *  When creating a transaction, the amount of gas that will be used can
     *  only be approximated, but the sender must pay the gas fee for the
     *  entire gas limit. After the transaction, the difference is refunded.
     */ gasUsed;
    /**
     *  The gas used for BLObs. See [[link-eip-4844]].
     */ blobGasUsed;
    /**
     *  The amount of gas used by all transactions within the block for this
     *  and all transactions with a lower ``index``.
     *
     *  This is generally not useful for developers but can be used to
     *  validate certain aspects of execution.
     */ cumulativeGasUsed;
    /**
     *  The actual gas price used during execution.
     *
     *  Due to the complexity of [[link-eip-1559]] this value can only
     *  be caluclated after the transaction has been mined, snce the base
     *  fee is protocol-enforced.
     */ gasPrice;
    /**
     *  The price paid per BLOB in gas. See [[link-eip-4844]].
     */ blobGasPrice;
    /**
     *  The [[link-eip-2718]] transaction type.
     */ type;
    //readonly byzantium!: boolean;
    /**
     *  The status of this transaction, indicating success (i.e. ``1``) or
     *  a revert (i.e. ``0``).
     *
     *  This is available in post-byzantium blocks, but some backends may
     *  backfill this value.
     */ status;
    /**
     *  The root hash of this transaction.
     *
     *  This is no present and was only included in pre-byzantium blocks, but
     *  could be used to validate certain parts of the receipt.
     */ root;
    #logs;
    /**
     *  @_ignore:
     */ constructor(tx, provider){
        this.#logs = Object.freeze(tx.logs.map((log)=>{
            return new Log(log, provider);
        }));
        let gasPrice = BN_0;
        if (tx.effectiveGasPrice != null) {
            gasPrice = tx.effectiveGasPrice;
        } else if (tx.gasPrice != null) {
            gasPrice = tx.gasPrice;
        }
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            provider,
            to: tx.to,
            from: tx.from,
            contractAddress: tx.contractAddress,
            hash: tx.hash,
            index: tx.index,
            blockHash: tx.blockHash,
            blockNumber: tx.blockNumber,
            logsBloom: tx.logsBloom,
            gasUsed: tx.gasUsed,
            cumulativeGasUsed: tx.cumulativeGasUsed,
            blobGasUsed: tx.blobGasUsed,
            gasPrice,
            blobGasPrice: tx.blobGasPrice,
            type: tx.type,
            //byzantium: tx.byzantium,
            status: tx.status,
            root: tx.root
        });
    }
    /**
     *  The logs for this transaction.
     */ get logs() {
        return this.#logs;
    }
    /**
     *  Returns a JSON-compatible representation.
     */ toJSON() {
        const { to, from, contractAddress, hash, index, blockHash, blockNumber, logsBloom, logs, status, root } = this;
        return {
            _type: "TransactionReceipt",
            blockHash,
            blockNumber,
            //byzantium, 
            contractAddress,
            cumulativeGasUsed: toJson(this.cumulativeGasUsed),
            from,
            gasPrice: toJson(this.gasPrice),
            blobGasUsed: toJson(this.blobGasUsed),
            blobGasPrice: toJson(this.blobGasPrice),
            gasUsed: toJson(this.gasUsed),
            hash,
            index,
            logs,
            logsBloom,
            root,
            status,
            to
        };
    }
    /**
     *  @_ignore:
     */ get length() {
        return this.logs.length;
    }
    [Symbol.iterator]() {
        let index = 0;
        return {
            next: ()=>{
                if (index < this.length) {
                    return {
                        value: this.logs[index++],
                        done: false
                    };
                }
                return {
                    value: undefined,
                    done: true
                };
            }
        };
    }
    /**
     *  The total fee for this transaction, in wei.
     */ get fee() {
        return this.gasUsed * this.gasPrice;
    }
    /**
     *  Resolves to the block this transaction occurred in.
     */ async getBlock() {
        const block = await this.provider.getBlock(this.blockHash);
        if (block == null) {
            throw new Error("TODO");
        }
        return block;
    }
    /**
     *  Resolves to the transaction this transaction occurred in.
     */ async getTransaction() {
        const tx = await this.provider.getTransaction(this.hash);
        if (tx == null) {
            throw new Error("TODO");
        }
        return tx;
    }
    /**
     *  Resolves to the return value of the execution of this transaction.
     *
     *  Support for this feature is limited, as it requires an archive node
     *  with the ``debug_`` or ``trace_`` API enabled.
     */ async getResult() {
        return await this.provider.getTransactionResult(this.hash);
    }
    /**
     *  Resolves to the number of confirmations this transaction has.
     */ async confirmations() {
        return await this.provider.getBlockNumber() - this.blockNumber + 1;
    }
    /**
     *  @_ignore:
     */ removedEvent() {
        return createRemovedTransactionFilter(this);
    }
    /**
     *  @_ignore:
     */ reorderedEvent(other) {
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(!other || other.isMined(), "unmined 'other' transction cannot be orphaned", "UNSUPPORTED_OPERATION", {
            operation: "reorderedEvent(other)"
        });
        return createReorderedTransactionFilter(this, other);
    }
}
class TransactionResponse {
    /**
     *  The provider this is connected to, which will influence how its
     *  methods will resolve its async inspection methods.
     */ provider;
    /**
     *  The block number of the block that this transaction was included in.
     *
     *  This is ``null`` for pending transactions.
     */ blockNumber;
    /**
     *  The blockHash of the block that this transaction was included in.
     *
     *  This is ``null`` for pending transactions.
     */ blockHash;
    /**
     *  The index within the block that this transaction resides at.
     */ index;
    /**
     *  The transaction hash.
     */ hash;
    /**
     *  The [[link-eip-2718]] transaction envelope type. This is
     *  ``0`` for legacy transactions types.
     */ type;
    /**
     *  The receiver of this transaction.
     *
     *  If ``null``, then the transaction is an initcode transaction.
     *  This means the result of executing the [[data]] will be deployed
     *  as a new contract on chain (assuming it does not revert) and the
     *  address may be computed using [[getCreateAddress]].
     */ to;
    /**
     *  The sender of this transaction. It is implicitly computed
     *  from the transaction pre-image hash (as the digest) and the
     *  [[signature]] using ecrecover.
     */ from;
    /**
     *  The nonce, which is used to prevent replay attacks and offer
     *  a method to ensure transactions from a given sender are explicitly
     *  ordered.
     *
     *  When sending a transaction, this must be equal to the number of
     *  transactions ever sent by [[from]].
     */ nonce;
    /**
     *  The maximum units of gas this transaction can consume. If execution
     *  exceeds this, the entries transaction is reverted and the sender
     *  is charged for the full amount, despite not state changes being made.
     */ gasLimit;
    /**
     *  The gas price can have various values, depending on the network.
     *
     *  In modern networks, for transactions that are included this is
     *  the //effective gas price// (the fee per gas that was actually
     *  charged), while for transactions that have not been included yet
     *  is the [[maxFeePerGas]].
     *
     *  For legacy transactions, or transactions on legacy networks, this
     *  is the fee that will be charged per unit of gas the transaction
     *  consumes.
     */ gasPrice;
    /**
     *  The maximum priority fee (per unit of gas) to allow a
     *  validator to charge the sender. This is inclusive of the
     *  [[maxFeeFeePerGas]].
     */ maxPriorityFeePerGas;
    /**
     *  The maximum fee (per unit of gas) to allow this transaction
     *  to charge the sender.
     */ maxFeePerGas;
    /**
     *  The [[link-eip-4844]] max fee per BLOb gas.
     */ maxFeePerBlobGas;
    /**
     *  The data.
     */ data;
    /**
     *  The value, in wei. Use [[formatEther]] to format this value
     *  as ether.
     */ value;
    /**
     *  The chain ID.
     */ chainId;
    /**
     *  The signature.
     */ signature;
    /**
     *  The [[link-eip-2930]] access list for transaction types that
     *  support it, otherwise ``null``.
     */ accessList;
    /**
     *  The [[link-eip-4844]] BLOb versioned hashes.
     */ blobVersionedHashes;
    /**
     *  The [[link-eip-7702]] authorizations (if any).
     */ authorizationList;
    #startBlock;
    /**
     *  @_ignore:
     */ constructor(tx, provider){
        this.provider = provider;
        this.blockNumber = tx.blockNumber != null ? tx.blockNumber : null;
        this.blockHash = tx.blockHash != null ? tx.blockHash : null;
        this.hash = tx.hash;
        this.index = tx.index;
        this.type = tx.type;
        this.from = tx.from;
        this.to = tx.to || null;
        this.gasLimit = tx.gasLimit;
        this.nonce = tx.nonce;
        this.data = tx.data;
        this.value = tx.value;
        this.gasPrice = tx.gasPrice;
        this.maxPriorityFeePerGas = tx.maxPriorityFeePerGas != null ? tx.maxPriorityFeePerGas : null;
        this.maxFeePerGas = tx.maxFeePerGas != null ? tx.maxFeePerGas : null;
        this.maxFeePerBlobGas = tx.maxFeePerBlobGas != null ? tx.maxFeePerBlobGas : null;
        this.chainId = tx.chainId;
        this.signature = tx.signature;
        this.accessList = tx.accessList != null ? tx.accessList : null;
        this.blobVersionedHashes = tx.blobVersionedHashes != null ? tx.blobVersionedHashes : null;
        this.authorizationList = tx.authorizationList != null ? tx.authorizationList : null;
        this.#startBlock = -1;
    }
    /**
     *  Returns a JSON-compatible representation of this transaction.
     */ toJSON() {
        const { blockNumber, blockHash, index, hash, type, to, from, nonce, data, signature, accessList, blobVersionedHashes } = this;
        return {
            _type: "TransactionResponse",
            accessList,
            blockNumber,
            blockHash,
            blobVersionedHashes,
            chainId: toJson(this.chainId),
            data,
            from,
            gasLimit: toJson(this.gasLimit),
            gasPrice: toJson(this.gasPrice),
            hash,
            maxFeePerGas: toJson(this.maxFeePerGas),
            maxPriorityFeePerGas: toJson(this.maxPriorityFeePerGas),
            maxFeePerBlobGas: toJson(this.maxFeePerBlobGas),
            nonce,
            signature,
            to,
            index,
            type,
            value: toJson(this.value)
        };
    }
    /**
     *  Resolves to the Block that this transaction was included in.
     *
     *  This will return null if the transaction has not been included yet.
     */ async getBlock() {
        let blockNumber = this.blockNumber;
        if (blockNumber == null) {
            const tx = await this.getTransaction();
            if (tx) {
                blockNumber = tx.blockNumber;
            }
        }
        if (blockNumber == null) {
            return null;
        }
        const block = this.provider.getBlock(blockNumber);
        if (block == null) {
            throw new Error("TODO");
        }
        return block;
    }
    /**
     *  Resolves to this transaction being re-requested from the
     *  provider. This can be used if you have an unmined transaction
     *  and wish to get an up-to-date populated instance.
     */ async getTransaction() {
        return this.provider.getTransaction(this.hash);
    }
    /**
     *  Resolve to the number of confirmations this transaction has.
     */ async confirmations() {
        if (this.blockNumber == null) {
            const { tx, blockNumber } = await (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["resolveProperties"])({
                tx: this.getTransaction(),
                blockNumber: this.provider.getBlockNumber()
            });
            // Not mined yet...
            if (tx == null || tx.blockNumber == null) {
                return 0;
            }
            return blockNumber - tx.blockNumber + 1;
        }
        const blockNumber = await this.provider.getBlockNumber();
        return blockNumber - this.blockNumber + 1;
    }
    /**
     *  Resolves once this transaction has been mined and has
     *  %%confirms%% blocks including it (default: ``1``) with an
     *  optional %%timeout%%.
     *
     *  This can resolve to ``null`` only if %%confirms%% is ``0``
     *  and the transaction has not been mined, otherwise this will
     *  wait until enough confirmations have completed.
     */ async wait(_confirms, _timeout) {
        const confirms = _confirms == null ? 1 : _confirms;
        const timeout = _timeout == null ? 0 : _timeout;
        let startBlock = this.#startBlock;
        let nextScan = -1;
        let stopScanning = startBlock === -1 ? true : false;
        const checkReplacement = async ()=>{
            // Get the current transaction count for this sender
            if (stopScanning) {
                return null;
            }
            const { blockNumber, nonce } = await (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["resolveProperties"])({
                blockNumber: this.provider.getBlockNumber(),
                nonce: this.provider.getTransactionCount(this.from)
            });
            // No transaction or our nonce has not been mined yet; but we
            // can start scanning later when we do start
            if (nonce < this.nonce) {
                startBlock = blockNumber;
                return;
            }
            // We were mined; no replacement
            if (stopScanning) {
                return null;
            }
            const mined = await this.getTransaction();
            if (mined && mined.blockNumber != null) {
                return;
            }
            // We were replaced; start scanning for that transaction
            // Starting to scan; look back a few extra blocks for safety
            if (nextScan === -1) {
                nextScan = startBlock - 3;
                if (nextScan < this.#startBlock) {
                    nextScan = this.#startBlock;
                }
            }
            while(nextScan <= blockNumber){
                // Get the next block to scan
                if (stopScanning) {
                    return null;
                }
                const block = await this.provider.getBlock(nextScan, true);
                // This should not happen; but we'll try again shortly
                if (block == null) {
                    return;
                }
                // We were mined; no replacement
                for (const hash of block){
                    if (hash === this.hash) {
                        return;
                    }
                }
                // Search for the transaction that replaced us
                for(let i = 0; i < block.length; i++){
                    const tx = await block.getTransaction(i);
                    if (tx.from === this.from && tx.nonce === this.nonce) {
                        // Get the receipt
                        if (stopScanning) {
                            return null;
                        }
                        const receipt = await this.provider.getTransactionReceipt(tx.hash);
                        // This should not happen; but we'll try again shortly
                        if (receipt == null) {
                            return;
                        }
                        // We will retry this on the next block (this case could be optimized)
                        if (blockNumber - receipt.blockNumber + 1 < confirms) {
                            return;
                        }
                        // The reason we were replaced
                        let reason = "replaced";
                        if (tx.data === this.data && tx.to === this.to && tx.value === this.value) {
                            reason = "repriced";
                        } else if (tx.data === "0x" && tx.from === tx.to && tx.value === BN_0) {
                            reason = "cancelled";
                        }
                        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, "transaction was replaced", "TRANSACTION_REPLACED", {
                            cancelled: reason === "replaced" || reason === "cancelled",
                            reason,
                            replacement: tx.replaceableTransaction(startBlock),
                            hash: tx.hash,
                            receipt
                        });
                    }
                }
                nextScan++;
            }
            return;
        };
        const checkReceipt = (receipt)=>{
            if (receipt == null || receipt.status !== 0) {
                return receipt;
            }
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, "transaction execution reverted", "CALL_EXCEPTION", {
                action: "sendTransaction",
                data: null,
                reason: null,
                invocation: null,
                revert: null,
                transaction: {
                    to: receipt.to,
                    from: receipt.from,
                    data: "" // @TODO: in v7, split out sendTransaction properties
                },
                receipt
            });
        };
        const receipt = await this.provider.getTransactionReceipt(this.hash);
        if (confirms === 0) {
            return checkReceipt(receipt);
        }
        if (receipt) {
            if (confirms === 1 || await receipt.confirmations() >= confirms) {
                return checkReceipt(receipt);
            }
        } else {
            // Check for a replacement; throws if a replacement was found
            await checkReplacement();
            // Allow null only when the confirms is 0
            if (confirms === 0) {
                return null;
            }
        }
        const waiter = new Promise((resolve, reject)=>{
            // List of things to cancel when we have a result (one way or the other)
            const cancellers = [];
            const cancel = ()=>{
                cancellers.forEach((c)=>c());
            };
            // On cancel, stop scanning for replacements
            cancellers.push(()=>{
                stopScanning = true;
            });
            // Set up any timeout requested
            if (timeout > 0) {
                const timer = setTimeout(()=>{
                    cancel();
                    reject((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["makeError"])("wait for transaction timeout", "TIMEOUT"));
                }, timeout);
                cancellers.push(()=>{
                    clearTimeout(timer);
                });
            }
            const txListener = async (receipt)=>{
                // Done; return it!
                if (await receipt.confirmations() >= confirms) {
                    cancel();
                    try {
                        resolve(checkReceipt(receipt));
                    } catch (error) {
                        reject(error);
                    }
                }
            };
            cancellers.push(()=>{
                this.provider.off(this.hash, txListener);
            });
            this.provider.on(this.hash, txListener);
            // We support replacement detection; start checking
            if (startBlock >= 0) {
                const replaceListener = async ()=>{
                    try {
                        // Check for a replacement; this throws only if one is found
                        await checkReplacement();
                    } catch (error) {
                        // We were replaced (with enough confirms); re-throw the error
                        if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isError"])(error, "TRANSACTION_REPLACED")) {
                            cancel();
                            reject(error);
                            return;
                        }
                    }
                    // Rescheudle a check on the next block
                    if (!stopScanning) {
                        this.provider.once("block", replaceListener);
                    }
                };
                cancellers.push(()=>{
                    this.provider.off("block", replaceListener);
                });
                this.provider.once("block", replaceListener);
            }
        });
        return await waiter;
    }
    /**
     *  Returns ``true`` if this transaction has been included.
     *
     *  This is effective only as of the time the TransactionResponse
     *  was instantiated. To get up-to-date information, use
     *  [[getTransaction]].
     *
     *  This provides a Type Guard that this transaction will have
     *  non-null property values for properties that are null for
     *  unmined transactions.
     */ isMined() {
        return this.blockHash != null;
    }
    /**
     *  Returns true if the transaction is a legacy (i.e. ``type == 0``)
     *  transaction.
     *
     *  This provides a Type Guard that this transaction will have
     *  the ``null``-ness for hardfork-specific properties set correctly.
     */ isLegacy() {
        return this.type === 0;
    }
    /**
     *  Returns true if the transaction is a Berlin (i.e. ``type == 1``)
     *  transaction. See [[link-eip-2070]].
     *
     *  This provides a Type Guard that this transaction will have
     *  the ``null``-ness for hardfork-specific properties set correctly.
     */ isBerlin() {
        return this.type === 1;
    }
    /**
     *  Returns true if the transaction is a London (i.e. ``type == 2``)
     *  transaction. See [[link-eip-1559]].
     *
     *  This provides a Type Guard that this transaction will have
     *  the ``null``-ness for hardfork-specific properties set correctly.
     */ isLondon() {
        return this.type === 2;
    }
    /**
     *  Returns true if hte transaction is a Cancun (i.e. ``type == 3``)
     *  transaction. See [[link-eip-4844]].
     */ isCancun() {
        return this.type === 3;
    }
    /**
     *  Returns a filter which can be used to listen for orphan events
     *  that evict this transaction.
     */ removedEvent() {
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(this.isMined(), "unmined transaction canot be orphaned", "UNSUPPORTED_OPERATION", {
            operation: "removeEvent()"
        });
        return createRemovedTransactionFilter(this);
    }
    /**
     *  Returns a filter which can be used to listen for orphan events
     *  that re-order this event against %%other%%.
     */ reorderedEvent(other) {
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(this.isMined(), "unmined transaction canot be orphaned", "UNSUPPORTED_OPERATION", {
            operation: "removeEvent()"
        });
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(!other || other.isMined(), "unmined 'other' transaction canot be orphaned", "UNSUPPORTED_OPERATION", {
            operation: "removeEvent()"
        });
        return createReorderedTransactionFilter(this, other);
    }
    /**
     *  Returns a new TransactionResponse instance which has the ability to
     *  detect (and throw an error) if the transaction is replaced, which
     *  will begin scanning at %%startBlock%%.
     *
     *  This should generally not be used by developers and is intended
     *  primarily for internal use. Setting an incorrect %%startBlock%% can
     *  have devastating performance consequences if used incorrectly.
     */ replaceableTransaction(startBlock) {
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(Number.isInteger(startBlock) && startBlock >= 0, "invalid startBlock", "startBlock", startBlock);
        const tx = new TransactionResponse(this, this.provider);
        tx.#startBlock = startBlock;
        return tx;
    }
}
function createOrphanedBlockFilter(block) {
    return {
        orphan: "drop-block",
        hash: block.hash,
        number: block.number
    };
}
function createReorderedTransactionFilter(tx, other) {
    return {
        orphan: "reorder-transaction",
        tx,
        other
    };
}
function createRemovedTransactionFilter(tx) {
    return {
        orphan: "drop-transaction",
        tx
    };
}
function createRemovedLogFilter(log) {
    return {
        orphan: "drop-log",
        log: {
            transactionHash: log.transactionHash,
            blockHash: log.blockHash,
            blockNumber: log.blockNumber,
            address: log.address,
            data: log.data,
            topics: Object.freeze(log.topics.slice()),
            index: log.index
        }
    };
} //# sourceMappingURL=provider.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/community.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "showThrottleMessage",
    ()=>showThrottleMessage
]);
/**
 *  There are many awesome community services that provide Ethereum
 *  nodes both for developers just starting out and for large-scale
 *  communities.
 *
 *  @_section: api/providers/thirdparty: Community Providers  [thirdparty]
 */ // Show the throttle message only once per service
const shown = new Set();
function showThrottleMessage(service) {
    if (shown.has(service)) {
        return;
    }
    shown.add(service);
    console.log("========= NOTICE =========");
    console.log(`Request-Rate Exceeded for ${service} (this message will not be repeated)`);
    console.log("");
    console.log("The default API keys for each service are provided as a highly-throttled,");
    console.log("community resource for low-traffic projects and early prototyping.");
    console.log("");
    console.log("While your application will continue to function, we highly recommended");
    console.log("signing up for your own API keys to improve performance, increase your");
    console.log("request rate/limit and enable other perks, such as metrics and advanced APIs.");
    console.log("");
    console.log("For more details: https:/\/docs.ethers.org/api-keys/");
    console.log("==========================");
} //# sourceMappingURL=community.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/plugins-network.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "EnsPlugin",
    ()=>EnsPlugin,
    "FeeDataNetworkPlugin",
    ()=>FeeDataNetworkPlugin,
    "FetchUrlFeeDataNetworkPlugin",
    ()=>FetchUrlFeeDataNetworkPlugin,
    "GasCostPlugin",
    ()=>GasCostPlugin,
    "NetworkPlugin",
    ()=>NetworkPlugin
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/properties.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/errors.js [client] (ecmascript)");
;
;
const EnsAddress = "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e";
class NetworkPlugin {
    /**
     *  The name of the plugin.
     *
     *  It is recommended to use reverse-domain-notation, which permits
     *  unique names with a known authority as well as hierarchal entries.
     */ name;
    /**
     *  Creates a new **NetworkPlugin**.
     */ constructor(name){
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            name
        });
    }
    /**
     *  Creates a copy of this plugin.
     */ clone() {
        return new NetworkPlugin(this.name);
    }
}
class GasCostPlugin extends NetworkPlugin {
    /**
     *  The block number to treat these values as valid from.
     *
     *  This allows a hardfork to have updated values included as well as
     *  mulutiple hardforks to be supported.
     */ effectiveBlock;
    /**
     *  The transactions base fee.
     */ txBase;
    /**
     *  The fee for creating a new account.
     */ txCreate;
    /**
     *  The fee per zero-byte in the data.
     */ txDataZero;
    /**
     *  The fee per non-zero-byte in the data.
     */ txDataNonzero;
    /**
     *  The fee per storage key in the [[link-eip-2930]] access list.
     */ txAccessListStorageKey;
    /**
     *  The fee per address in the [[link-eip-2930]] access list.
     */ txAccessListAddress;
    /**
     *  Creates a new GasCostPlugin from %%effectiveBlock%% until the
     *  latest block or another GasCostPlugin supercedes that block number,
     *  with the associated %%costs%%.
     */ constructor(effectiveBlock, costs){
        if (effectiveBlock == null) {
            effectiveBlock = 0;
        }
        super(`org.ethers.network.plugins.GasCost#${effectiveBlock || 0}`);
        const props = {
            effectiveBlock
        };
        function set(name, nullish) {
            let value = (costs || {})[name];
            if (value == null) {
                value = nullish;
            }
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(typeof value === "number", `invalud value for ${name}`, "costs", costs);
            props[name] = value;
        }
        set("txBase", 21000);
        set("txCreate", 32000);
        set("txDataZero", 4);
        set("txDataNonzero", 16);
        set("txAccessListStorageKey", 1900);
        set("txAccessListAddress", 2400);
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, props);
    }
    clone() {
        return new GasCostPlugin(this.effectiveBlock, this);
    }
}
class EnsPlugin extends NetworkPlugin {
    /**
     *  The ENS Registrty Contract address.
     */ address;
    /**
     *  The chain ID that the ENS contract lives on.
     */ targetNetwork;
    /**
     *  Creates a new **EnsPlugin** connected to %%address%% on the
     *  %%targetNetwork%%. The default ENS address and mainnet is used
     *  if unspecified.
     */ constructor(address, targetNetwork){
        super("org.ethers.plugins.network.Ens");
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            address: address || EnsAddress,
            targetNetwork: targetNetwork == null ? 1 : targetNetwork
        });
    }
    clone() {
        return new EnsPlugin(this.address, this.targetNetwork);
    }
}
class FeeDataNetworkPlugin extends NetworkPlugin {
    #feeDataFunc;
    /**
     *  The fee data function provided to the constructor.
     */ get feeDataFunc() {
        return this.#feeDataFunc;
    }
    /**
     *  Creates a new **FeeDataNetworkPlugin**.
     */ constructor(feeDataFunc){
        super("org.ethers.plugins.network.FeeData");
        this.#feeDataFunc = feeDataFunc;
    }
    /**
     *  Resolves to the fee data.
     */ async getFeeData(provider) {
        return await this.#feeDataFunc(provider);
    }
    clone() {
        return new FeeDataNetworkPlugin(this.#feeDataFunc);
    }
}
class FetchUrlFeeDataNetworkPlugin extends NetworkPlugin {
    #url;
    #processFunc;
    /**
     *  The URL to initialize the FetchRequest with in %%processFunc%%.
     */ get url() {
        return this.#url;
    }
    /**
     *  The callback to use when computing the FeeData.
     */ get processFunc() {
        return this.#processFunc;
    }
    /**
     *  Creates a new **FetchUrlFeeDataNetworkPlugin** which will
     *  be used when computing the fee data for the network.
     */ constructor(url, processFunc){
        super("org.ethers.plugins.network.FetchUrlFeeDataPlugin");
        this.#url = url;
        this.#processFunc = processFunc;
    }
    // We are immutable, so we can serve as our own clone
    clone() {
        return this;
    }
} /*
export class CustomBlockNetworkPlugin extends NetworkPlugin {
    readonly #blockFunc: (provider: Provider, block: BlockParams<string>) => Block<string>;
    readonly #blockWithTxsFunc: (provider: Provider, block: BlockParams<TransactionResponseParams>) => Block<TransactionResponse>;

    constructor(blockFunc: (provider: Provider, block: BlockParams<string>) => Block<string>, blockWithTxsFunc: (provider: Provider, block: BlockParams<TransactionResponseParams>) => Block<TransactionResponse>) {
        super("org.ethers.network-plugins.custom-block");
        this.#blockFunc = blockFunc;
        this.#blockWithTxsFunc = blockWithTxsFunc;
    }

    async getBlock(provider: Provider, block: BlockParams<string>): Promise<Block<string>> {
        return await this.#blockFunc(provider, block);
    }

    async getBlockions(provider: Provider, block: BlockParams<TransactionResponseParams>): Promise<Block<TransactionResponse>> {
        return await this.#blockWithTxsFunc(provider, block);
    }

    clone(): CustomBlockNetworkPlugin {
        return new CustomBlockNetworkPlugin(this.#blockFunc, this.#blockWithTxsFunc);
    }
}
*/  //# sourceMappingURL=plugins-network.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/network.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "Network",
    ()=>Network
]);
/**
 *  A **Network** encapsulates the various properties required to
 *  interact with a specific chain.
 *
 *  @_subsection: api/providers:Networks  [networks]
 */ var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$transaction$2f$accesslist$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/transaction/accesslist.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/maths.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/errors.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$plugins$2d$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/plugins-network.js [client] (ecmascript)");
;
;
;
/* * * *
// Networks which operation against an L2 can use this plugin to
// specify how to access L1, for the purpose of resolving ENS,
// for example.
export class LayerOneConnectionPlugin extends NetworkPlugin {
    readonly provider!: Provider;
// @TODO: Rename to ChainAccess and allow for connecting to any chain
    constructor(provider: Provider) {
        super("org.ethers.plugins.layer-one-connection");
        defineProperties<LayerOneConnectionPlugin>(this, { provider });
    }

    clone(): LayerOneConnectionPlugin {
        return new LayerOneConnectionPlugin(this.provider);
    }
}
*/ const Networks = new Map();
class Network {
    #name;
    #chainId;
    #plugins;
    /**
     *  Creates a new **Network** for %%name%% and %%chainId%%.
     */ constructor(name, chainId){
        this.#name = name;
        this.#chainId = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"])(chainId);
        this.#plugins = new Map();
    }
    /**
     *  Returns a JSON-compatible representation of a Network.
     */ toJSON() {
        return {
            name: this.name,
            chainId: String(this.chainId)
        };
    }
    /**
     *  The network common name.
     *
     *  This is the canonical name, as networks migh have multiple
     *  names.
     */ get name() {
        return this.#name;
    }
    set name(value) {
        this.#name = value;
    }
    /**
     *  The network chain ID.
     */ get chainId() {
        return this.#chainId;
    }
    set chainId(value) {
        this.#chainId = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"])(value, "chainId");
    }
    /**
     *  Returns true if %%other%% matches this network. Any chain ID
     *  must match, and if no chain ID is present, the name must match.
     *
     *  This method does not currently check for additional properties,
     *  such as ENS address or plug-in compatibility.
     */ matches(other) {
        if (other == null) {
            return false;
        }
        if (typeof other === "string") {
            try {
                return this.chainId === (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"])(other);
            } catch (error) {}
            return this.name === other;
        }
        if (typeof other === "number" || typeof other === "bigint") {
            try {
                return this.chainId === (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"])(other);
            } catch (error) {}
            return false;
        }
        if (typeof other === "object") {
            if (other.chainId != null) {
                try {
                    return this.chainId === (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"])(other.chainId);
                } catch (error) {}
                return false;
            }
            if (other.name != null) {
                return this.name === other.name;
            }
            return false;
        }
        return false;
    }
    /**
     *  Returns the list of plugins currently attached to this Network.
     */ get plugins() {
        return Array.from(this.#plugins.values());
    }
    /**
     *  Attach a new %%plugin%% to this Network. The network name
     *  must be unique, excluding any fragment.
     */ attachPlugin(plugin) {
        if (this.#plugins.get(plugin.name)) {
            throw new Error(`cannot replace existing plugin: ${plugin.name} `);
        }
        this.#plugins.set(plugin.name, plugin.clone());
        return this;
    }
    /**
     *  Return the plugin, if any, matching %%name%% exactly. Plugins
     *  with fragments will not be returned unless %%name%% includes
     *  a fragment.
     */ getPlugin(name) {
        return this.#plugins.get(name) || null;
    }
    /**
     *  Gets a list of all plugins that match %%name%%, with otr without
     *  a fragment.
     */ getPlugins(basename) {
        return this.plugins.filter((p)=>p.name.split("#")[0] === basename);
    }
    /**
     *  Create a copy of this Network.
     */ clone() {
        const clone = new Network(this.name, this.chainId);
        this.plugins.forEach((plugin)=>{
            clone.attachPlugin(plugin.clone());
        });
        return clone;
    }
    /**
     *  Compute the intrinsic gas required for a transaction.
     *
     *  A GasCostPlugin can be attached to override the default
     *  values.
     */ computeIntrinsicGas(tx) {
        const costs = this.getPlugin("org.ethers.plugins.network.GasCost") || new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$plugins$2d$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__["GasCostPlugin"]();
        let gas = costs.txBase;
        if (tx.to == null) {
            gas += costs.txCreate;
        }
        if (tx.data) {
            for(let i = 2; i < tx.data.length; i += 2){
                if (tx.data.substring(i, i + 2) === "00") {
                    gas += costs.txDataZero;
                } else {
                    gas += costs.txDataNonzero;
                }
            }
        }
        if (tx.accessList) {
            const accessList = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$transaction$2f$accesslist$2e$js__$5b$client$5d$__$28$ecmascript$29$__["accessListify"])(tx.accessList);
            for(const addr in accessList){
                gas += costs.txAccessListAddress + costs.txAccessListStorageKey * accessList[addr].storageKeys.length;
            }
        }
        return gas;
    }
    /**
     *  Returns a new Network for the %%network%% name or chainId.
     */ static from(network) {
        injectCommonNetworks();
        // Default network
        if (network == null) {
            return Network.from("mainnet");
        }
        // Canonical name or chain ID
        if (typeof network === "number") {
            network = BigInt(network);
        }
        if (typeof network === "string" || typeof network === "bigint") {
            const networkFunc = Networks.get(network);
            if (networkFunc) {
                return networkFunc();
            }
            if (typeof network === "bigint") {
                return new Network("unknown", network);
            }
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, "unknown network", "network", network);
        }
        // Clonable with network-like abilities
        if (typeof network.clone === "function") {
            const clone = network.clone();
            //if (typeof(network.name) !== "string" || typeof(network.chainId) !== "number") {
            //}
            return clone;
        }
        // Networkish
        if (typeof network === "object") {
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(typeof network.name === "string" && typeof network.chainId === "number", "invalid network object name or chainId", "network", network);
            const custom = new Network(network.name, network.chainId);
            if (network.ensAddress || network.ensNetwork != null) {
                custom.attachPlugin(new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$plugins$2d$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__["EnsPlugin"](network.ensAddress, network.ensNetwork));
            }
            //if ((<any>network).layerOneConnection) {
            //    custom.attachPlugin(new LayerOneConnectionPlugin((<any>network).layerOneConnection));
            //}
            return custom;
        }
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, "invalid network", "network", network);
    }
    /**
     *  Register %%nameOrChainId%% with a function which returns
     *  an instance of a Network representing that chain.
     */ static register(nameOrChainId, networkFunc) {
        if (typeof nameOrChainId === "number") {
            nameOrChainId = BigInt(nameOrChainId);
        }
        const existing = Networks.get(nameOrChainId);
        if (existing) {
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, `conflicting network for ${JSON.stringify(existing.name)}`, "nameOrChainId", nameOrChainId);
        }
        Networks.set(nameOrChainId, networkFunc);
    }
}
// We don't want to bring in formatUnits because it is backed by
// FixedNumber and we want to keep Networks tiny. The values
// included by the Gas Stations are also IEEE 754 with lots of
// rounding issues and exceed the strict checks formatUnits has.
function parseUnits(_value, decimals) {
    const value = String(_value);
    if (!value.match(/^[0-9.]+$/)) {
        throw new Error(`invalid gwei value: ${_value}`);
    }
    // Break into [ whole, fraction ]
    const comps = value.split(".");
    if (comps.length === 1) {
        comps.push("");
    }
    // More than 1 decimal point or too many fractional positions
    if (comps.length !== 2) {
        throw new Error(`invalid gwei value: ${_value}`);
    }
    // Pad the fraction to 9 decimalplaces
    while(comps[1].length < decimals){
        comps[1] += "0";
    }
    // Too many decimals and some non-zero ending, take the ceiling
    if (comps[1].length > 9) {
        let frac = BigInt(comps[1].substring(0, 9));
        if (!comps[1].substring(9).match(/^0+$/)) {
            frac++;
        }
        comps[1] = frac.toString();
    }
    return BigInt(comps[0] + comps[1]);
}
// Used by Polygon to use a gas station for fee data
function getGasStationPlugin(url) {
    return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$plugins$2d$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__["FetchUrlFeeDataNetworkPlugin"](url, async (fetchFeeData, provider, request)=>{
        // Prevent Cloudflare from blocking our request in node.js
        request.setHeader("User-Agent", "ethers");
        let response;
        try {
            const [_response, _feeData] = await Promise.all([
                request.send(),
                fetchFeeData()
            ]);
            response = _response;
            const payload = response.bodyJson.standard;
            const feeData = {
                gasPrice: _feeData.gasPrice,
                maxFeePerGas: parseUnits(payload.maxFee, 9),
                maxPriorityFeePerGas: parseUnits(payload.maxPriorityFee, 9)
            };
            return feeData;
        } catch (error) {
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, `error encountered with polygon gas station (${JSON.stringify(request.url)})`, "SERVER_ERROR", {
                request,
                response,
                error
            });
        }
    });
}
// See: https://chainlist.org
let injected = false;
function injectCommonNetworks() {
    if (injected) {
        return;
    }
    injected = true;
    /// Register popular Ethereum networks
    function registerEth(name, chainId, options) {
        const func = function() {
            const network = new Network(name, chainId);
            // We use 0 to disable ENS
            if (options.ensNetwork != null) {
                network.attachPlugin(new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$plugins$2d$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__["EnsPlugin"](null, options.ensNetwork));
            }
            network.attachPlugin(new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$plugins$2d$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__["GasCostPlugin"]());
            (options.plugins || []).forEach((plugin)=>{
                network.attachPlugin(plugin);
            });
            return network;
        };
        // Register the network by name and chain ID
        Network.register(name, func);
        Network.register(chainId, func);
        if (options.altNames) {
            options.altNames.forEach((name)=>{
                Network.register(name, func);
            });
        }
    }
    registerEth("mainnet", 1, {
        ensNetwork: 1,
        altNames: [
            "homestead"
        ]
    });
    registerEth("ropsten", 3, {
        ensNetwork: 3
    });
    registerEth("rinkeby", 4, {
        ensNetwork: 4
    });
    registerEth("goerli", 5, {
        ensNetwork: 5
    });
    registerEth("kovan", 42, {
        ensNetwork: 42
    });
    registerEth("sepolia", 11155111, {
        ensNetwork: 11155111
    });
    registerEth("holesky", 17000, {
        ensNetwork: 17000
    });
    registerEth("classic", 61, {});
    registerEth("classicKotti", 6, {});
    registerEth("arbitrum", 42161, {
        ensNetwork: 1
    });
    registerEth("arbitrum-goerli", 421613, {});
    registerEth("arbitrum-sepolia", 421614, {});
    registerEth("base", 8453, {
        ensNetwork: 1
    });
    registerEth("base-goerli", 84531, {});
    registerEth("base-sepolia", 84532, {});
    registerEth("bnb", 56, {
        ensNetwork: 1
    });
    registerEth("bnbt", 97, {});
    registerEth("filecoin", 314, {});
    registerEth("filecoin-calibration", 314159, {});
    registerEth("linea", 59144, {
        ensNetwork: 1
    });
    registerEth("linea-goerli", 59140, {});
    registerEth("linea-sepolia", 59141, {});
    registerEth("matic", 137, {
        ensNetwork: 1,
        plugins: [
            getGasStationPlugin("https:/\/gasstation.polygon.technology/v2")
        ]
    });
    registerEth("matic-amoy", 80002, {});
    registerEth("matic-mumbai", 80001, {
        altNames: [
            "maticMumbai",
            "maticmum"
        ],
        plugins: [
            getGasStationPlugin("https:/\/gasstation-testnet.polygon.technology/v2")
        ]
    });
    registerEth("optimism", 10, {
        ensNetwork: 1,
        plugins: []
    });
    registerEth("optimism-goerli", 420, {});
    registerEth("optimism-sepolia", 11155420, {});
    registerEth("xdai", 100, {
        ensNetwork: 1
    });
} //# sourceMappingURL=network.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/ens-resolver.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "BasicMulticoinProviderPlugin",
    ()=>BasicMulticoinProviderPlugin,
    "EnsResolver",
    ()=>EnsResolver,
    "MulticoinProviderPlugin",
    ()=>MulticoinProviderPlugin
]);
/**
 *  ENS is a service which allows easy-to-remember names to map to
 *  network addresses.
 *
 *  @_section: api/providers/ens-resolver:ENS Resolver  [about-ens-rsolver]
 */ var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$address$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/address/address.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$constants$2f$addresses$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/constants/addresses.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$contract$2f$contract$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/contract/contract.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$hash$2f$namehash$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/hash/namehash.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/data.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/maths.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/properties.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$base58$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/base58.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/errors.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$fetch$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/fetch.js [client] (ecmascript)");
;
;
;
;
;
// @TODO: This should use the fetch-data:ipfs gateway
// Trim off the ipfs:// prefix and return the default gateway URL
function getIpfsLink(link) {
    if (link.match(/^ipfs:\/\/ipfs\//i)) {
        link = link.substring(12);
    } else if (link.match(/^ipfs:\/\//i)) {
        link = link.substring(7);
    } else {
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, "unsupported IPFS format", "link", link);
    }
    return `https:/\/gateway.ipfs.io/ipfs/${link}`;
}
;
;
class MulticoinProviderPlugin {
    /**
     *  The name.
     */ name;
    /**
     *  Creates a new **MulticoinProviderPluing** for %%name%%.
     */ constructor(name){
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            name
        });
    }
    connect(proivder) {
        return this;
    }
    /**
     *  Returns ``true`` if %%coinType%% is supported by this plugin.
     */ supportsCoinType(coinType) {
        return false;
    }
    /**
     *  Resolves to the encoded %%address%% for %%coinType%%.
     */ async encodeAddress(coinType, address) {
        throw new Error("unsupported coin");
    }
    /**
     *  Resolves to the decoded %%data%% for %%coinType%%.
     */ async decodeAddress(coinType, data) {
        throw new Error("unsupported coin");
    }
}
const BasicMulticoinPluginId = "org.ethers.plugins.provider.BasicMulticoin";
class BasicMulticoinProviderPlugin extends MulticoinProviderPlugin {
    /**
     *  Creates a new **BasicMulticoinProviderPlugin**.
     */ constructor(){
        super(BasicMulticoinPluginId);
    }
}
const matcherIpfs = new RegExp("^(ipfs):/\/(.*)$", "i");
const matchers = [
    new RegExp("^(https):/\/(.*)$", "i"),
    new RegExp("^(data):(.*)$", "i"),
    matcherIpfs,
    new RegExp("^eip155:[0-9]+/(erc[0-9]+):(.*)$", "i")
];
class EnsResolver {
    /**
     *  The connected provider.
     */ provider;
    /**
     *  The address of the resolver.
     */ address;
    /**
     *  The name this resolver was resolved against.
     */ name;
    // For EIP-2544 names, the ancestor that provided the resolver
    #supports2544;
    #resolver;
    constructor(provider, address, name){
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            provider,
            address,
            name
        });
        this.#supports2544 = null;
        this.#resolver = new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$contract$2f$contract$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Contract"](address, [
            "function supportsInterface(bytes4) view returns (bool)",
            "function resolve(bytes, bytes) view returns (bytes)",
            "function addr(bytes32) view returns (address)",
            "function addr(bytes32, uint) view returns (bytes)",
            "function text(bytes32, string) view returns (string)",
            "function contenthash(bytes32) view returns (bytes)"
        ], provider);
    }
    /**
     *  Resolves to true if the resolver supports wildcard resolution.
     */ async supportsWildcard() {
        if (this.#supports2544 == null) {
            this.#supports2544 = (async ()=>{
                try {
                    return await this.#resolver.supportsInterface("0x9061b923");
                } catch (error) {
                    // Wildcard resolvers must understand supportsInterface
                    // and return true.
                    if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isError"])(error, "CALL_EXCEPTION")) {
                        return false;
                    }
                    // Let future attempts try again...
                    this.#supports2544 = null;
                    throw error;
                }
            })();
        }
        return await this.#supports2544;
    }
    async #fetch(funcName, params) {
        params = (params || []).slice();
        const iface = this.#resolver.interface;
        // The first parameters is always the nodehash
        params.unshift((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$hash$2f$namehash$2e$js__$5b$client$5d$__$28$ecmascript$29$__["namehash"])(this.name));
        let fragment = null;
        if (await this.supportsWildcard()) {
            fragment = iface.getFunction(funcName);
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(fragment, "missing fragment", "UNKNOWN_ERROR", {
                info: {
                    funcName
                }
            });
            params = [
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$hash$2f$namehash$2e$js__$5b$client$5d$__$28$ecmascript$29$__["dnsEncode"])(this.name, 255),
                iface.encodeFunctionData(fragment, params)
            ];
            funcName = "resolve(bytes,bytes)";
        }
        params.push({
            enableCcipRead: true
        });
        try {
            const result = await this.#resolver[funcName](...params);
            if (fragment) {
                return iface.decodeFunctionResult(fragment, result)[0];
            }
            return result;
        } catch (error) {
            if (!(0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isError"])(error, "CALL_EXCEPTION")) {
                throw error;
            }
        }
        return null;
    }
    /**
     *  Resolves to the address for %%coinType%% or null if the
     *  provided %%coinType%% has not been configured.
     */ async getAddress(coinType) {
        if (coinType == null) {
            coinType = 60;
        }
        if (coinType === 60) {
            try {
                const result = await this.#fetch("addr(bytes32)");
                // No address
                if (result == null || result === __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$constants$2f$addresses$2e$js__$5b$client$5d$__$28$ecmascript$29$__["ZeroAddress"]) {
                    return null;
                }
                return result;
            } catch (error) {
                if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isError"])(error, "CALL_EXCEPTION")) {
                    return null;
                }
                throw error;
            }
        }
        // Try decoding its EVM canonical chain as an EVM chain address first
        if (coinType >= 0 && coinType < 0x80000000) {
            let ethCoinType = coinType + 0x80000000;
            const data = await this.#fetch("addr(bytes32,uint)", [
                ethCoinType
            ]);
            if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isHexString"])(data, 20)) {
                return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$address$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getAddress"])(data);
            }
        }
        let coinPlugin = null;
        for (const plugin of this.provider.plugins){
            if (!(plugin instanceof MulticoinProviderPlugin)) {
                continue;
            }
            if (plugin.supportsCoinType(coinType)) {
                coinPlugin = plugin;
                break;
            }
        }
        if (coinPlugin == null) {
            return null;
        }
        // keccak256("addr(bytes32,uint256")
        const data = await this.#fetch("addr(bytes32,uint)", [
            coinType
        ]);
        // No address
        if (data == null || data === "0x") {
            return null;
        }
        // Compute the address
        const address = await coinPlugin.decodeAddress(coinType, data);
        if (address != null) {
            return address;
        }
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, `invalid coin data`, "UNSUPPORTED_OPERATION", {
            operation: `getAddress(${coinType})`,
            info: {
                coinType,
                data
            }
        });
    }
    /**
     *  Resolves to the EIP-634 text record for %%key%%, or ``null``
     *  if unconfigured.
     */ async getText(key) {
        const data = await this.#fetch("text(bytes32,string)", [
            key
        ]);
        if (data == null || data === "0x") {
            return null;
        }
        return data;
    }
    /**
     *  Rsolves to the content-hash or ``null`` if unconfigured.
     */ async getContentHash() {
        // keccak256("contenthash()")
        const data = await this.#fetch("contenthash(bytes32)");
        // No contenthash
        if (data == null || data === "0x") {
            return null;
        }
        // IPFS (CID: 1, Type: 70=DAG-PB, 72=libp2p-key)
        const ipfs = data.match(/^0x(e3010170|e5010172)(([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f]*))$/);
        if (ipfs) {
            const scheme = ipfs[1] === "e3010170" ? "ipfs" : "ipns";
            const length = parseInt(ipfs[4], 16);
            if (ipfs[5].length === length * 2) {
                return `${scheme}:/\/${(0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$base58$2e$js__$5b$client$5d$__$28$ecmascript$29$__["encodeBase58"])("0x" + ipfs[2])}`;
            }
        }
        // Swarm (CID: 1, Type: swarm-manifest; hash/length hard-coded to keccak256/32)
        const swarm = data.match(/^0xe40101fa011b20([0-9a-f]*)$/);
        if (swarm && swarm[1].length === 64) {
            return `bzz:/\/${swarm[1]}`;
        }
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, `invalid or unsupported content hash data`, "UNSUPPORTED_OPERATION", {
            operation: "getContentHash()",
            info: {
                data
            }
        });
    }
    /**
     *  Resolves to the avatar url or ``null`` if the avatar is either
     *  unconfigured or incorrectly configured (e.g. references an NFT
     *  not owned by the address).
     *
     *  If diagnosing issues with configurations, the [[_getAvatar]]
     *  method may be useful.
     */ async getAvatar() {
        const avatar = await this._getAvatar();
        return avatar.url;
    }
    /**
     *  When resolving an avatar, there are many steps involved, such
     *  fetching metadata and possibly validating ownership of an
     *  NFT.
     *
     *  This method can be used to examine each step and the value it
     *  was working from.
     */ async _getAvatar() {
        const linkage = [
            {
                type: "name",
                value: this.name
            }
        ];
        try {
            // test data for ricmoo.eth
            //const avatar = "eip155:1/erc721:0x265385c7f4132228A0d54EB1A9e7460b91c0cC68/29233";
            const avatar = await this.getText("avatar");
            if (avatar == null) {
                linkage.push({
                    type: "!avatar",
                    value: ""
                });
                return {
                    url: null,
                    linkage
                };
            }
            linkage.push({
                type: "avatar",
                value: avatar
            });
            for(let i = 0; i < matchers.length; i++){
                const match = avatar.match(matchers[i]);
                if (match == null) {
                    continue;
                }
                const scheme = match[1].toLowerCase();
                switch(scheme){
                    case "https":
                    case "data":
                        linkage.push({
                            type: "url",
                            value: avatar
                        });
                        return {
                            linkage,
                            url: avatar
                        };
                    case "ipfs":
                        {
                            const url = getIpfsLink(avatar);
                            linkage.push({
                                type: "ipfs",
                                value: avatar
                            });
                            linkage.push({
                                type: "url",
                                value: url
                            });
                            return {
                                linkage,
                                url
                            };
                        }
                    case "erc721":
                    case "erc1155":
                        {
                            // Depending on the ERC type, use tokenURI(uint256) or url(uint256)
                            const selector = scheme === "erc721" ? "tokenURI(uint256)" : "uri(uint256)";
                            linkage.push({
                                type: scheme,
                                value: avatar
                            });
                            // The owner of this name
                            const owner = await this.getAddress();
                            if (owner == null) {
                                linkage.push({
                                    type: "!owner",
                                    value: ""
                                });
                                return {
                                    url: null,
                                    linkage
                                };
                            }
                            const comps = (match[2] || "").split("/");
                            if (comps.length !== 2) {
                                linkage.push({
                                    type: `!${scheme}caip`,
                                    value: match[2] || ""
                                });
                                return {
                                    url: null,
                                    linkage
                                };
                            }
                            const tokenId = comps[1];
                            const contract = new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$contract$2f$contract$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Contract"](comps[0], [
                                // ERC-721
                                "function tokenURI(uint) view returns (string)",
                                "function ownerOf(uint) view returns (address)",
                                // ERC-1155
                                "function uri(uint) view returns (string)",
                                "function balanceOf(address, uint256) view returns (uint)"
                            ], this.provider);
                            // Check that this account owns the token
                            if (scheme === "erc721") {
                                const tokenOwner = await contract.ownerOf(tokenId);
                                if (owner !== tokenOwner) {
                                    linkage.push({
                                        type: "!owner",
                                        value: tokenOwner
                                    });
                                    return {
                                        url: null,
                                        linkage
                                    };
                                }
                                linkage.push({
                                    type: "owner",
                                    value: tokenOwner
                                });
                            } else if (scheme === "erc1155") {
                                const balance = await contract.balanceOf(owner, tokenId);
                                if (!balance) {
                                    linkage.push({
                                        type: "!balance",
                                        value: "0"
                                    });
                                    return {
                                        url: null,
                                        linkage
                                    };
                                }
                                linkage.push({
                                    type: "balance",
                                    value: balance.toString()
                                });
                            }
                            // Call the token contract for the metadata URL
                            let metadataUrl = await contract[selector](tokenId);
                            if (metadataUrl == null || metadataUrl === "0x") {
                                linkage.push({
                                    type: "!metadata-url",
                                    value: ""
                                });
                                return {
                                    url: null,
                                    linkage
                                };
                            }
                            linkage.push({
                                type: "metadata-url-base",
                                value: metadataUrl
                            });
                            // ERC-1155 allows a generic {id} in the URL
                            if (scheme === "erc1155") {
                                metadataUrl = metadataUrl.replace("{id}", (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["toBeHex"])(tokenId, 32).substring(2));
                                linkage.push({
                                    type: "metadata-url-expanded",
                                    value: metadataUrl
                                });
                            }
                            // Transform IPFS metadata links
                            if (metadataUrl.match(/^ipfs:/i)) {
                                metadataUrl = getIpfsLink(metadataUrl);
                            }
                            linkage.push({
                                type: "metadata-url",
                                value: metadataUrl
                            });
                            // Get the token metadata
                            let metadata = {};
                            const response = await new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$fetch$2e$js__$5b$client$5d$__$28$ecmascript$29$__["FetchRequest"](metadataUrl).send();
                            response.assertOk();
                            try {
                                metadata = response.bodyJson;
                            } catch (error) {
                                try {
                                    linkage.push({
                                        type: "!metadata",
                                        value: response.bodyText
                                    });
                                } catch (error) {
                                    const bytes = response.body;
                                    if (bytes) {
                                        linkage.push({
                                            type: "!metadata",
                                            value: (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["hexlify"])(bytes)
                                        });
                                    }
                                    return {
                                        url: null,
                                        linkage
                                    };
                                }
                                return {
                                    url: null,
                                    linkage
                                };
                            }
                            if (!metadata) {
                                linkage.push({
                                    type: "!metadata",
                                    value: ""
                                });
                                return {
                                    url: null,
                                    linkage
                                };
                            }
                            linkage.push({
                                type: "metadata",
                                value: JSON.stringify(metadata)
                            });
                            // Pull the image URL out
                            let imageUrl = metadata.image;
                            if (typeof imageUrl !== "string") {
                                linkage.push({
                                    type: "!imageUrl",
                                    value: ""
                                });
                                return {
                                    url: null,
                                    linkage
                                };
                            }
                            if (imageUrl.match(/^(https:\/\/|data:)/i)) {
                            // Allow
                            } else {
                                // Transform IPFS link to gateway
                                const ipfs = imageUrl.match(matcherIpfs);
                                if (ipfs == null) {
                                    linkage.push({
                                        type: "!imageUrl-ipfs",
                                        value: imageUrl
                                    });
                                    return {
                                        url: null,
                                        linkage
                                    };
                                }
                                linkage.push({
                                    type: "imageUrl-ipfs",
                                    value: imageUrl
                                });
                                imageUrl = getIpfsLink(imageUrl);
                            }
                            linkage.push({
                                type: "url",
                                value: imageUrl
                            });
                            return {
                                linkage,
                                url: imageUrl
                            };
                        }
                }
            }
        } catch (error) {}
        return {
            linkage,
            url: null
        };
    }
    static async getEnsAddress(provider) {
        const network = await provider.getNetwork();
        const ensPlugin = network.getPlugin("org.ethers.plugins.network.Ens");
        // No ENS...
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(ensPlugin, "network does not support ENS", "UNSUPPORTED_OPERATION", {
            operation: "getEnsAddress",
            info: {
                network
            }
        });
        return ensPlugin.address;
    }
    static async #getResolver(provider, name) {
        const ensAddr = await EnsResolver.getEnsAddress(provider);
        try {
            const contract = new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$contract$2f$contract$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Contract"](ensAddr, [
                "function resolver(bytes32) view returns (address)"
            ], provider);
            const addr = await contract.resolver((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$hash$2f$namehash$2e$js__$5b$client$5d$__$28$ecmascript$29$__["namehash"])(name), {
                enableCcipRead: true
            });
            if (addr === __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$constants$2f$addresses$2e$js__$5b$client$5d$__$28$ecmascript$29$__["ZeroAddress"]) {
                return null;
            }
            return addr;
        } catch (error) {
            // ENS registry cannot throw errors on resolver(bytes32),
            // so probably a link error
            throw error;
        }
        return null;
    }
    /**
     *  Resolve to the ENS resolver for %%name%% using %%provider%% or
     *  ``null`` if unconfigured.
     */ static async fromName(provider, name) {
        let currentName = name;
        while(true){
            if (currentName === "" || currentName === ".") {
                return null;
            }
            // Optimization since the eth node cannot change and does
            // not have a wildcard resolver
            if (name !== "eth" && currentName === "eth") {
                return null;
            }
            // Check the current node for a resolver
            const addr = await EnsResolver.#getResolver(provider, currentName);
            // Found a resolver!
            if (addr != null) {
                const resolver = new EnsResolver(provider, addr, name);
                // Legacy resolver found, using EIP-2544 so it isn't safe to use
                if (currentName !== name && !await resolver.supportsWildcard()) {
                    return null;
                }
                return resolver;
            }
            // Get the parent node
            currentName = currentName.split(".").slice(1).join(".");
        }
    }
} //# sourceMappingURL=ens-resolver.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/format.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "allowNull",
    ()=>allowNull,
    "arrayOf",
    ()=>arrayOf,
    "formatBlock",
    ()=>formatBlock,
    "formatBoolean",
    ()=>formatBoolean,
    "formatData",
    ()=>formatData,
    "formatHash",
    ()=>formatHash,
    "formatLog",
    ()=>formatLog,
    "formatReceiptLog",
    ()=>formatReceiptLog,
    "formatTransactionReceipt",
    ()=>formatTransactionReceipt,
    "formatTransactionResponse",
    ()=>formatTransactionResponse,
    "formatUint256",
    ()=>formatUint256,
    "object",
    ()=>object
]);
/**
 *  @_ignore
 */ var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$address$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/address/address.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$contract$2d$address$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/address/contract-address.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$crypto$2f$signature$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/crypto/signature.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$transaction$2f$accesslist$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/transaction/accesslist.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/maths.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/data.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/errors.js [client] (ecmascript)");
;
;
;
;
const BN_0 = BigInt(0);
function allowNull(format, nullValue) {
    return function(value) {
        if (value == null) {
            return nullValue;
        }
        return format(value);
    };
}
function arrayOf(format, allowNull) {
    return (array)=>{
        if (allowNull && array == null) {
            return null;
        }
        if (!Array.isArray(array)) {
            throw new Error("not an array");
        }
        return array.map((i)=>format(i));
    };
}
function object(format, altNames) {
    return (value)=>{
        const result = {};
        for(const key in format){
            let srcKey = key;
            if (altNames && key in altNames && !(srcKey in value)) {
                for (const altKey of altNames[key]){
                    if (altKey in value) {
                        srcKey = altKey;
                        break;
                    }
                }
            }
            try {
                const nv = format[key](value[srcKey]);
                if (nv !== undefined) {
                    result[key] = nv;
                }
            } catch (error) {
                const message = error instanceof Error ? error.message : "not-an-error";
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, `invalid value for value.${key} (${message})`, "BAD_DATA", {
                    value
                });
            }
        }
        return result;
    };
}
function formatBoolean(value) {
    switch(value){
        case true:
        case "true":
            return true;
        case false:
        case "false":
            return false;
    }
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, `invalid boolean; ${JSON.stringify(value)}`, "value", value);
}
function formatData(value) {
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isHexString"])(value, true), "invalid data", "value", value);
    return value;
}
function formatHash(value) {
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isHexString"])(value, 32), "invalid hash", "value", value);
    return value;
}
function formatUint256(value) {
    if (!(0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isHexString"])(value)) {
        throw new Error("invalid uint256");
    }
    return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["zeroPadValue"])(value, 32);
}
const _formatLog = object({
    address: __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$address$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getAddress"],
    blockHash: formatHash,
    blockNumber: __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"],
    data: formatData,
    index: __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"],
    removed: allowNull(formatBoolean, false),
    topics: arrayOf(formatHash),
    transactionHash: formatHash,
    transactionIndex: __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"]
}, {
    index: [
        "logIndex"
    ]
});
function formatLog(value) {
    return _formatLog(value);
}
const _formatBlock = object({
    hash: allowNull(formatHash),
    parentHash: formatHash,
    parentBeaconBlockRoot: allowNull(formatHash, null),
    number: __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"],
    timestamp: __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"],
    nonce: allowNull(formatData),
    difficulty: __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"],
    gasLimit: __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"],
    gasUsed: __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"],
    stateRoot: allowNull(formatHash, null),
    receiptsRoot: allowNull(formatHash, null),
    blobGasUsed: allowNull(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"], null),
    excessBlobGas: allowNull(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"], null),
    miner: allowNull(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$address$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getAddress"]),
    prevRandao: allowNull(formatHash, null),
    extraData: formatData,
    baseFeePerGas: allowNull(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"])
}, {
    prevRandao: [
        "mixHash"
    ]
});
function formatBlock(value) {
    const result = _formatBlock(value);
    result.transactions = value.transactions.map((tx)=>{
        if (typeof tx === "string") {
            return tx;
        }
        return formatTransactionResponse(tx);
    });
    return result;
}
const _formatReceiptLog = object({
    transactionIndex: __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"],
    blockNumber: __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"],
    transactionHash: formatHash,
    address: __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$address$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getAddress"],
    topics: arrayOf(formatHash),
    data: formatData,
    index: __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"],
    blockHash: formatHash
}, {
    index: [
        "logIndex"
    ]
});
function formatReceiptLog(value) {
    return _formatReceiptLog(value);
}
const _formatTransactionReceipt = object({
    to: allowNull(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$address$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getAddress"], null),
    from: allowNull(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$address$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getAddress"], null),
    contractAddress: allowNull(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$address$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getAddress"], null),
    // should be allowNull(hash), but broken-EIP-658 support is handled in receipt
    index: __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"],
    root: allowNull(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["hexlify"]),
    gasUsed: __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"],
    blobGasUsed: allowNull(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"], null),
    logsBloom: allowNull(formatData),
    blockHash: formatHash,
    hash: formatHash,
    logs: arrayOf(formatReceiptLog),
    blockNumber: __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"],
    //confirmations: allowNull(getNumber, null),
    cumulativeGasUsed: __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"],
    effectiveGasPrice: allowNull(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"]),
    blobGasPrice: allowNull(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"], null),
    status: allowNull(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"]),
    type: allowNull(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"], 0)
}, {
    effectiveGasPrice: [
        "gasPrice"
    ],
    hash: [
        "transactionHash"
    ],
    index: [
        "transactionIndex"
    ]
});
function formatTransactionReceipt(value) {
    return _formatTransactionReceipt(value);
}
function formatTransactionResponse(value) {
    // Some clients (TestRPC) do strange things like return 0x0 for the
    // 0 address; correct this to be a real address
    if (value.to && (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"])(value.to) === BN_0) {
        value.to = "0x0000000000000000000000000000000000000000";
    }
    const result = object({
        hash: formatHash,
        // Some nodes do not return this, usually test nodes (like Ganache)
        index: allowNull(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"], undefined),
        type: (value)=>{
            if (value === "0x" || value == null) {
                return 0;
            }
            return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"])(value);
        },
        accessList: allowNull(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$transaction$2f$accesslist$2e$js__$5b$client$5d$__$28$ecmascript$29$__["accessListify"], null),
        blobVersionedHashes: allowNull(arrayOf(formatHash, true), null),
        authorizationList: allowNull(arrayOf((v)=>{
            let sig;
            if (v.signature) {
                sig = v.signature;
            } else {
                let yParity = v.yParity;
                if (yParity === "0x1b") {
                    yParity = 0;
                } else if (yParity === "0x1c") {
                    yParity = 1;
                }
                sig = Object.assign({}, v, {
                    yParity
                });
            }
            return {
                address: (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$address$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getAddress"])(v.address),
                chainId: (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"])(v.chainId),
                nonce: (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"])(v.nonce),
                signature: __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$crypto$2f$signature$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Signature"].from(sig)
            };
        }, false), null),
        blockHash: allowNull(formatHash, null),
        blockNumber: allowNull(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"], null),
        transactionIndex: allowNull(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"], null),
        from: __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$address$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getAddress"],
        // either (gasPrice) or (maxPriorityFeePerGas + maxFeePerGas) must be set
        gasPrice: allowNull(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"]),
        maxPriorityFeePerGas: allowNull(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"]),
        maxFeePerGas: allowNull(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"]),
        maxFeePerBlobGas: allowNull(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"], null),
        gasLimit: __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"],
        to: allowNull(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$address$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getAddress"], null),
        value: __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"],
        nonce: __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"],
        data: formatData,
        creates: allowNull(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$address$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getAddress"], null),
        chainId: allowNull(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"], null)
    }, {
        data: [
            "input"
        ],
        gasLimit: [
            "gas"
        ],
        index: [
            "transactionIndex"
        ]
    })(value);
    // If to and creates are empty, populate the creates from the value
    if (result.to == null && result.creates == null) {
        result.creates = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$contract$2d$address$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getCreateAddress"])(result);
    }
    // @TODO: Check fee data
    // Add an access list to supported transaction types
    if ((value.type === 1 || value.type === 2) && value.accessList == null) {
        result.accessList = [];
    }
    // Compute the signature
    if (value.signature) {
        result.signature = __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$crypto$2f$signature$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Signature"].from(value.signature);
    } else {
        result.signature = __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$crypto$2f$signature$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Signature"].from(value);
    }
    // Some backends omit ChainId on legacy transactions, but we can compute it
    if (result.chainId == null) {
        const chainId = result.signature.legacyChainId;
        if (chainId != null) {
            result.chainId = chainId;
        }
    }
    // @TODO: check chainID
    /*
    if (value.chainId != null) {
        let chainId = value.chainId;

        if (isHexString(chainId)) {
            chainId = BigNumber.from(chainId).toNumber();
        }

        result.chainId = chainId;

    } else {
        let chainId = value.networkId;

        // geth-etc returns chainId
        if (chainId == null && result.v == null) {
            chainId = value.chainId;
        }

        if (isHexString(chainId)) {
            chainId = BigNumber.from(chainId).toNumber();
        }

        if (typeof(chainId) !== "number" && result.v != null) {
            chainId = (result.v - 35) / 2;
            if (chainId < 0) { chainId = 0; }
            chainId = parseInt(chainId);
        }

        if (typeof(chainId) !== "number") { chainId = 0; }

        result.chainId = chainId;
    }
    */ // 0x0000... should actually be null
    if (result.blockHash && (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"])(result.blockHash) === BN_0) {
        result.blockHash = null;
    }
    return result;
} //# sourceMappingURL=format.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/subscriber-polling.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "OnBlockSubscriber",
    ()=>OnBlockSubscriber,
    "PollingBlockSubscriber",
    ()=>PollingBlockSubscriber,
    "PollingBlockTagSubscriber",
    ()=>PollingBlockTagSubscriber,
    "PollingEventSubscriber",
    ()=>PollingEventSubscriber,
    "PollingOrphanSubscriber",
    ()=>PollingOrphanSubscriber,
    "PollingTransactionSubscriber",
    ()=>PollingTransactionSubscriber,
    "getPollingSubscriber",
    ()=>getPollingSubscriber
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/errors.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/data.js [client] (ecmascript)");
;
function copy(obj) {
    return JSON.parse(JSON.stringify(obj));
}
function getPollingSubscriber(provider, event) {
    if (event === "block") {
        return new PollingBlockSubscriber(provider);
    }
    if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isHexString"])(event, 32)) {
        return new PollingTransactionSubscriber(provider, event);
    }
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, "unsupported polling event", "UNSUPPORTED_OPERATION", {
        operation: "getPollingSubscriber",
        info: {
            event
        }
    });
}
class PollingBlockSubscriber {
    #provider;
    #poller;
    #interval;
    // The most recent block we have scanned for events. The value -2
    // indicates we still need to fetch an initial block number
    #blockNumber;
    /**
     *  Create a new **PollingBlockSubscriber** attached to %%provider%%.
     */ constructor(provider){
        this.#provider = provider;
        this.#poller = null;
        this.#interval = 4000;
        this.#blockNumber = -2;
    }
    /**
     *  The polling interval.
     */ get pollingInterval() {
        return this.#interval;
    }
    set pollingInterval(value) {
        this.#interval = value;
    }
    async #poll() {
        try {
            const blockNumber = await this.#provider.getBlockNumber();
            // Bootstrap poll to setup our initial block number
            if (this.#blockNumber === -2) {
                this.#blockNumber = blockNumber;
                return;
            }
            // @TODO: Put a cap on the maximum number of events per loop?
            if (blockNumber !== this.#blockNumber) {
                for(let b = this.#blockNumber + 1; b <= blockNumber; b++){
                    // We have been stopped
                    if (this.#poller == null) {
                        return;
                    }
                    await this.#provider.emit("block", b);
                }
                this.#blockNumber = blockNumber;
            }
        } catch (error) {
        // @TODO: Minor bump, add an "error" event to let subscribers
        //        know things went awry.
        //console.log(error);
        }
        // We have been stopped
        if (this.#poller == null) {
            return;
        }
        this.#poller = this.#provider._setTimeout(this.#poll.bind(this), this.#interval);
    }
    start() {
        if (this.#poller) {
            return;
        }
        this.#poller = this.#provider._setTimeout(this.#poll.bind(this), this.#interval);
        this.#poll();
    }
    stop() {
        if (!this.#poller) {
            return;
        }
        this.#provider._clearTimeout(this.#poller);
        this.#poller = null;
    }
    pause(dropWhilePaused) {
        this.stop();
        if (dropWhilePaused) {
            this.#blockNumber = -2;
        }
    }
    resume() {
        this.start();
    }
}
class OnBlockSubscriber {
    #provider;
    #poll;
    #running;
    /**
     *  Create a new **OnBlockSubscriber** attached to %%provider%%.
     */ constructor(provider){
        this.#provider = provider;
        this.#running = false;
        this.#poll = (blockNumber)=>{
            this._poll(blockNumber, this.#provider);
        };
    }
    /**
     *  Called on every new block.
     */ async _poll(blockNumber, provider) {
        throw new Error("sub-classes must override this");
    }
    start() {
        if (this.#running) {
            return;
        }
        this.#running = true;
        this.#poll(-2);
        this.#provider.on("block", this.#poll);
    }
    stop() {
        if (!this.#running) {
            return;
        }
        this.#running = false;
        this.#provider.off("block", this.#poll);
    }
    pause(dropWhilePaused) {
        this.stop();
    }
    resume() {
        this.start();
    }
}
class PollingBlockTagSubscriber extends OnBlockSubscriber {
    #tag;
    #lastBlock;
    constructor(provider, tag){
        super(provider);
        this.#tag = tag;
        this.#lastBlock = -2;
    }
    pause(dropWhilePaused) {
        if (dropWhilePaused) {
            this.#lastBlock = -2;
        }
        super.pause(dropWhilePaused);
    }
    async _poll(blockNumber, provider) {
        const block = await provider.getBlock(this.#tag);
        if (block == null) {
            return;
        }
        if (this.#lastBlock === -2) {
            this.#lastBlock = block.number;
        } else if (block.number > this.#lastBlock) {
            provider.emit(this.#tag, block.number);
            this.#lastBlock = block.number;
        }
    }
}
class PollingOrphanSubscriber extends OnBlockSubscriber {
    #filter;
    constructor(provider, filter){
        super(provider);
        this.#filter = copy(filter);
    }
    async _poll(blockNumber, provider) {
        throw new Error("@TODO");
        console.log(this.#filter);
    }
}
class PollingTransactionSubscriber extends OnBlockSubscriber {
    #hash;
    /**
     *  Create a new **PollingTransactionSubscriber** attached to
     *  %%provider%%, listening for %%hash%%.
     */ constructor(provider, hash){
        super(provider);
        this.#hash = hash;
    }
    async _poll(blockNumber, provider) {
        const tx = await provider.getTransactionReceipt(this.#hash);
        if (tx) {
            provider.emit(this.#hash, tx);
        }
    }
}
class PollingEventSubscriber {
    #provider;
    #filter;
    #poller;
    #running;
    // The most recent block we have scanned for events. The value -2
    // indicates we still need to fetch an initial block number
    #blockNumber;
    /**
     *  Create a new **PollingTransactionSubscriber** attached to
     *  %%provider%%, listening for %%filter%%.
     */ constructor(provider, filter){
        this.#provider = provider;
        this.#filter = copy(filter);
        this.#poller = this.#poll.bind(this);
        this.#running = false;
        this.#blockNumber = -2;
    }
    async #poll(blockNumber) {
        // The initial block hasn't been determined yet
        if (this.#blockNumber === -2) {
            return;
        }
        const filter = copy(this.#filter);
        filter.fromBlock = this.#blockNumber + 1;
        filter.toBlock = blockNumber;
        const logs = await this.#provider.getLogs(filter);
        // No logs could just mean the node has not indexed them yet,
        // so we keep a sliding window of 60 blocks to keep scanning
        if (logs.length === 0) {
            if (this.#blockNumber < blockNumber - 60) {
                this.#blockNumber = blockNumber - 60;
            }
            return;
        }
        for (const log of logs){
            this.#provider.emit(this.#filter, log);
            // Only advance the block number when logs were found to
            // account for networks (like BNB and Polygon) which may
            // sacrifice event consistency for block event speed
            this.#blockNumber = log.blockNumber;
        }
    }
    start() {
        if (this.#running) {
            return;
        }
        this.#running = true;
        if (this.#blockNumber === -2) {
            this.#provider.getBlockNumber().then((blockNumber)=>{
                this.#blockNumber = blockNumber;
            });
        }
        this.#provider.on("block", this.#poller);
    }
    stop() {
        if (!this.#running) {
            return;
        }
        this.#running = false;
        this.#provider.off("block", this.#poller);
    }
    pause(dropWhilePaused) {
        this.stop();
        if (dropWhilePaused) {
            this.#blockNumber = -2;
        }
    }
    resume() {
        this.start();
    }
} //# sourceMappingURL=subscriber-polling.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/abstract-provider.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "AbstractProvider",
    ()=>AbstractProvider,
    "UnmanagedSubscriber",
    ()=>UnmanagedSubscriber
]);
/**
 *  The available providers should suffice for most developers purposes,
 *  but the [[AbstractProvider]] class has many features which enable
 *  sub-classing it for specific purposes.
 *
 *  @_section: api/providers/abstract-provider: Subclassing Provider  [abstract-provider]
 */ // @TODO
// Event coalescence
//   When we register an event with an async value (e.g. address is a Signer
//   or ENS name), we need to add it immeidately for the Event API, but also
//   need time to resolve the address. Upon resolving the address, we need to
//   migrate the listener to the static event. We also need to maintain a map
//   of Signer/ENS name to address so we can sync respond to listenerCount.
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$address$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/address/address.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$checks$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/address/checks.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$constants$2f$addresses$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/constants/addresses.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$contract$2f$contract$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/contract/contract.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$hash$2f$namehash$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/hash/namehash.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$transaction$2f$transaction$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/transaction/transaction.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/data.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/maths.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/errors.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$fetch$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/fetch.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/properties.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$events$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/events.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$utf8$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/utf8.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$ens$2d$resolver$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/ens-resolver.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$format$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/format.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/network.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$subscriber$2d$polling$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/subscriber-polling.js [client] (ecmascript)");
;
;
;
;
;
;
;
;
;
;
;
// Constants
const BN_2 = BigInt(2);
const MAX_CCIP_REDIRECTS = 10;
function isPromise(value) {
    return value && typeof value.then === "function";
}
function getTag(prefix, value) {
    return prefix + ":" + JSON.stringify(value, (k, v)=>{
        if (v == null) {
            return "null";
        }
        if (typeof v === "bigint") {
            return `bigint:${v.toString()}`;
        }
        if (typeof v === "string") {
            return v.toLowerCase();
        }
        // Sort object keys
        if (typeof v === "object" && !Array.isArray(v)) {
            const keys = Object.keys(v);
            keys.sort();
            return keys.reduce((accum, key)=>{
                accum[key] = v[key];
                return accum;
            }, {});
        }
        return v;
    });
}
class UnmanagedSubscriber {
    /**
     *  The name fof the event.
     */ name;
    /**
     *  Create a new UnmanagedSubscriber with %%name%%.
     */ constructor(name){
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            name
        });
    }
    start() {}
    stop() {}
    pause(dropWhilePaused) {}
    resume() {}
}
function copy(value) {
    return JSON.parse(JSON.stringify(value));
}
function concisify(items) {
    items = Array.from(new Set(items).values());
    items.sort();
    return items;
}
async function getSubscription(_event, provider) {
    if (_event == null) {
        throw new Error("invalid event");
    }
    // Normalize topic array info an EventFilter
    if (Array.isArray(_event)) {
        _event = {
            topics: _event
        };
    }
    if (typeof _event === "string") {
        switch(_event){
            case "block":
            case "debug":
            case "error":
            case "finalized":
            case "network":
            case "pending":
            case "safe":
                {
                    return {
                        type: _event,
                        tag: _event
                    };
                }
        }
    }
    if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isHexString"])(_event, 32)) {
        const hash = _event.toLowerCase();
        return {
            type: "transaction",
            tag: getTag("tx", {
                hash
            }),
            hash
        };
    }
    if (_event.orphan) {
        const event = _event;
        // @TODO: Should lowercase and whatnot things here instead of copy...
        return {
            type: "orphan",
            tag: getTag("orphan", event),
            filter: copy(event)
        };
    }
    if (_event.address || _event.topics) {
        const event = _event;
        const filter = {
            topics: (event.topics || []).map((t)=>{
                if (t == null) {
                    return null;
                }
                if (Array.isArray(t)) {
                    return concisify(t.map((t)=>t.toLowerCase()));
                }
                return t.toLowerCase();
            })
        };
        if (event.address) {
            const addresses = [];
            const promises = [];
            const addAddress = (addr)=>{
                if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isHexString"])(addr)) {
                    addresses.push(addr);
                } else {
                    promises.push((async ()=>{
                        addresses.push(await (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$checks$2e$js__$5b$client$5d$__$28$ecmascript$29$__["resolveAddress"])(addr, provider));
                    })());
                }
            };
            if (Array.isArray(event.address)) {
                event.address.forEach(addAddress);
            } else {
                addAddress(event.address);
            }
            if (promises.length) {
                await Promise.all(promises);
            }
            filter.address = concisify(addresses.map((a)=>a.toLowerCase()));
        }
        return {
            filter,
            tag: getTag("event", filter),
            type: "event"
        };
    }
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, "unknown ProviderEvent", "event", _event);
}
function getTime() {
    return new Date().getTime();
}
const defaultOptions = {
    cacheTimeout: 250,
    pollingInterval: 4000
};
class AbstractProvider {
    #subs;
    #plugins;
    // null=unpaused, true=paused+dropWhilePaused, false=paused
    #pausedState;
    #destroyed;
    #networkPromise;
    #anyNetwork;
    #performCache;
    // The most recent block number if running an event or -1 if no "block" event
    #lastBlockNumber;
    #nextTimer;
    #timers;
    #disableCcipRead;
    #options;
    /**
     *  Create a new **AbstractProvider** connected to %%network%%, or
     *  use the various network detection capabilities to discover the
     *  [[Network]] if necessary.
     */ constructor(_network, options){
        this.#options = Object.assign({}, defaultOptions, options || {});
        if (_network === "any") {
            this.#anyNetwork = true;
            this.#networkPromise = null;
        } else if (_network) {
            const network = __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Network"].from(_network);
            this.#anyNetwork = false;
            this.#networkPromise = Promise.resolve(network);
            setTimeout(()=>{
                this.emit("network", network, null);
            }, 0);
        } else {
            this.#anyNetwork = false;
            this.#networkPromise = null;
        }
        this.#lastBlockNumber = -1;
        this.#performCache = new Map();
        this.#subs = new Map();
        this.#plugins = new Map();
        this.#pausedState = null;
        this.#destroyed = false;
        this.#nextTimer = 1;
        this.#timers = new Map();
        this.#disableCcipRead = false;
    }
    get pollingInterval() {
        return this.#options.pollingInterval;
    }
    /**
     *  Returns ``this``, to allow an **AbstractProvider** to implement
     *  the [[ContractRunner]] interface.
     */ get provider() {
        return this;
    }
    /**
     *  Returns all the registered plug-ins.
     */ get plugins() {
        return Array.from(this.#plugins.values());
    }
    /**
     *  Attach a new plug-in.
     */ attachPlugin(plugin) {
        if (this.#plugins.get(plugin.name)) {
            throw new Error(`cannot replace existing plugin: ${plugin.name} `);
        }
        this.#plugins.set(plugin.name, plugin.connect(this));
        return this;
    }
    /**
     *  Get a plugin by name.
     */ getPlugin(name) {
        return this.#plugins.get(name) || null;
    }
    /**
     *  Prevent any CCIP-read operation, regardless of whether requested
     *  in a [[call]] using ``enableCcipRead``.
     */ get disableCcipRead() {
        return this.#disableCcipRead;
    }
    set disableCcipRead(value) {
        this.#disableCcipRead = !!value;
    }
    // Shares multiple identical requests made during the same 250ms
    async #perform(req) {
        const timeout = this.#options.cacheTimeout;
        // Caching disabled
        if (timeout < 0) {
            return await this._perform(req);
        }
        // Create a tag
        const tag = getTag(req.method, req);
        let perform = this.#performCache.get(tag);
        if (!perform) {
            perform = this._perform(req);
            this.#performCache.set(tag, perform);
            setTimeout(()=>{
                if (this.#performCache.get(tag) === perform) {
                    this.#performCache.delete(tag);
                }
            }, timeout);
        }
        return await perform;
    }
    /**
     *  Resolves to the data for executing the CCIP-read operations.
     */ async ccipReadFetch(tx, calldata, urls) {
        if (this.disableCcipRead || urls.length === 0 || tx.to == null) {
            return null;
        }
        const sender = tx.to.toLowerCase();
        const data = calldata.toLowerCase();
        const errorMessages = [];
        for(let i = 0; i < urls.length; i++){
            const url = urls[i];
            // URL expansion
            const href = url.replace("{sender}", sender).replace("{data}", data);
            // If no {data} is present, use POST; otherwise GET
            //const json: string | null = (url.indexOf("{data}") >= 0) ? null: JSON.stringify({ data, sender });
            //const result = await fetchJson({ url: href, errorPassThrough: true }, json, (value, response) => {
            //    value.status = response.statusCode;
            //    return value;
            //});
            const request = new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$fetch$2e$js__$5b$client$5d$__$28$ecmascript$29$__["FetchRequest"](href);
            if (url.indexOf("{data}") === -1) {
                request.body = {
                    data,
                    sender
                };
            }
            this.emit("debug", {
                action: "sendCcipReadFetchRequest",
                request,
                index: i,
                urls
            });
            let errorMessage = "unknown error";
            // Fetch the resource...
            let resp;
            try {
                resp = await request.send();
            } catch (error) {
                // ...low-level fetch error (missing host, bad SSL, etc.),
                // so try next URL
                errorMessages.push(error.message);
                this.emit("debug", {
                    action: "receiveCcipReadFetchError",
                    request,
                    result: {
                        error
                    }
                });
                continue;
            }
            try {
                const result = resp.bodyJson;
                if (result.data) {
                    this.emit("debug", {
                        action: "receiveCcipReadFetchResult",
                        request,
                        result
                    });
                    return result.data;
                }
                if (result.message) {
                    errorMessage = result.message;
                }
                this.emit("debug", {
                    action: "receiveCcipReadFetchError",
                    request,
                    result
                });
            } catch (error) {}
            // 4xx indicates the result is not present; stop
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(resp.statusCode < 400 || resp.statusCode >= 500, `response not found during CCIP fetch: ${errorMessage}`, "OFFCHAIN_FAULT", {
                reason: "404_MISSING_RESOURCE",
                transaction: tx,
                info: {
                    url,
                    errorMessage
                }
            });
            // 5xx indicates server issue; try the next url
            errorMessages.push(errorMessage);
        }
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, `error encountered during CCIP fetch: ${errorMessages.map((m)=>JSON.stringify(m)).join(", ")}`, "OFFCHAIN_FAULT", {
            reason: "500_SERVER_ERROR",
            transaction: tx,
            info: {
                urls,
                errorMessages
            }
        });
    }
    /**
     *  Provides the opportunity for a sub-class to wrap a block before
     *  returning it, to add additional properties or an alternate
     *  sub-class of [[Block]].
     */ _wrapBlock(value, network) {
        return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Block"]((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$format$2e$js__$5b$client$5d$__$28$ecmascript$29$__["formatBlock"])(value), this);
    }
    /**
     *  Provides the opportunity for a sub-class to wrap a log before
     *  returning it, to add additional properties or an alternate
     *  sub-class of [[Log]].
     */ _wrapLog(value, network) {
        return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Log"]((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$format$2e$js__$5b$client$5d$__$28$ecmascript$29$__["formatLog"])(value), this);
    }
    /**
     *  Provides the opportunity for a sub-class to wrap a transaction
     *  receipt before returning it, to add additional properties or an
     *  alternate sub-class of [[TransactionReceipt]].
     */ _wrapTransactionReceipt(value, network) {
        return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2e$js__$5b$client$5d$__$28$ecmascript$29$__["TransactionReceipt"]((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$format$2e$js__$5b$client$5d$__$28$ecmascript$29$__["formatTransactionReceipt"])(value), this);
    }
    /**
     *  Provides the opportunity for a sub-class to wrap a transaction
     *  response before returning it, to add additional properties or an
     *  alternate sub-class of [[TransactionResponse]].
     */ _wrapTransactionResponse(tx, network) {
        return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2e$js__$5b$client$5d$__$28$ecmascript$29$__["TransactionResponse"]((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$format$2e$js__$5b$client$5d$__$28$ecmascript$29$__["formatTransactionResponse"])(tx), this);
    }
    /**
     *  Resolves to the Network, forcing a network detection using whatever
     *  technique the sub-class requires.
     *
     *  Sub-classes **must** override this.
     */ _detectNetwork() {
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, "sub-classes must implement this", "UNSUPPORTED_OPERATION", {
            operation: "_detectNetwork"
        });
    }
    /**
     *  Sub-classes should use this to perform all built-in operations. All
     *  methods sanitizes and normalizes the values passed into this.
     *
     *  Sub-classes **must** override this.
     */ async _perform(req) {
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, `unsupported method: ${req.method}`, "UNSUPPORTED_OPERATION", {
            operation: req.method,
            info: req
        });
    }
    // State
    async getBlockNumber() {
        const blockNumber = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"])(await this.#perform({
            method: "getBlockNumber"
        }), "%response");
        if (this.#lastBlockNumber >= 0) {
            this.#lastBlockNumber = blockNumber;
        }
        return blockNumber;
    }
    /**
     *  Returns or resolves to the address for %%address%%, resolving ENS
     *  names and [[Addressable]] objects and returning if already an
     *  address.
     */ _getAddress(address) {
        return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$checks$2e$js__$5b$client$5d$__$28$ecmascript$29$__["resolveAddress"])(address, this);
    }
    /**
     *  Returns or resolves to a valid block tag for %%blockTag%%, resolving
     *  negative values and returning if already a valid block tag.
     */ _getBlockTag(blockTag) {
        if (blockTag == null) {
            return "latest";
        }
        switch(blockTag){
            case "earliest":
                return "0x0";
            case "finalized":
            case "latest":
            case "pending":
            case "safe":
                return blockTag;
        }
        if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isHexString"])(blockTag)) {
            if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isHexString"])(blockTag, 32)) {
                return blockTag;
            }
            return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["toQuantity"])(blockTag);
        }
        if (typeof blockTag === "bigint") {
            blockTag = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"])(blockTag, "blockTag");
        }
        if (typeof blockTag === "number") {
            if (blockTag >= 0) {
                return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["toQuantity"])(blockTag);
            }
            if (this.#lastBlockNumber >= 0) {
                return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["toQuantity"])(this.#lastBlockNumber + blockTag);
            }
            return this.getBlockNumber().then((b)=>(0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["toQuantity"])(b + blockTag));
        }
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, "invalid blockTag", "blockTag", blockTag);
    }
    /**
     *  Returns or resolves to a filter for %%filter%%, resolving any ENS
     *  names or [[Addressable]] object and returning if already a valid
     *  filter.
     */ _getFilter(filter) {
        // Create a canonical representation of the topics
        const topics = (filter.topics || []).map((t)=>{
            if (t == null) {
                return null;
            }
            if (Array.isArray(t)) {
                return concisify(t.map((t)=>t.toLowerCase()));
            }
            return t.toLowerCase();
        });
        const blockHash = "blockHash" in filter ? filter.blockHash : undefined;
        const resolve = (_address, fromBlock, toBlock)=>{
            let address = undefined;
            switch(_address.length){
                case 0:
                    break;
                case 1:
                    address = _address[0];
                    break;
                default:
                    _address.sort();
                    address = _address;
            }
            if (blockHash) {
                if (fromBlock != null || toBlock != null) {
                    throw new Error("invalid filter");
                }
            }
            const filter = {};
            if (address) {
                filter.address = address;
            }
            if (topics.length) {
                filter.topics = topics;
            }
            if (fromBlock) {
                filter.fromBlock = fromBlock;
            }
            if (toBlock) {
                filter.toBlock = toBlock;
            }
            if (blockHash) {
                filter.blockHash = blockHash;
            }
            return filter;
        };
        // Addresses could be async (ENS names or Addressables)
        let address = [];
        if (filter.address) {
            if (Array.isArray(filter.address)) {
                for (const addr of filter.address){
                    address.push(this._getAddress(addr));
                }
            } else {
                address.push(this._getAddress(filter.address));
            }
        }
        let fromBlock = undefined;
        if ("fromBlock" in filter) {
            fromBlock = this._getBlockTag(filter.fromBlock);
        }
        let toBlock = undefined;
        if ("toBlock" in filter) {
            toBlock = this._getBlockTag(filter.toBlock);
        }
        if (address.filter((a)=>typeof a !== "string").length || fromBlock != null && typeof fromBlock !== "string" || toBlock != null && typeof toBlock !== "string") {
            return Promise.all([
                Promise.all(address),
                fromBlock,
                toBlock
            ]).then((result)=>{
                return resolve(result[0], result[1], result[2]);
            });
        }
        return resolve(address, fromBlock, toBlock);
    }
    /**
     *  Returns or resolves to a transaction for %%request%%, resolving
     *  any ENS names or [[Addressable]] and returning if already a valid
     *  transaction.
     */ _getTransactionRequest(_request) {
        const request = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2e$js__$5b$client$5d$__$28$ecmascript$29$__["copyRequest"])(_request);
        const promises = [];
        [
            "to",
            "from"
        ].forEach((key)=>{
            if (request[key] == null) {
                return;
            }
            const addr = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$checks$2e$js__$5b$client$5d$__$28$ecmascript$29$__["resolveAddress"])(request[key], this);
            if (isPromise(addr)) {
                promises.push(async function() {
                    request[key] = await addr;
                }());
            } else {
                request[key] = addr;
            }
        });
        if (request.blockTag != null) {
            const blockTag = this._getBlockTag(request.blockTag);
            if (isPromise(blockTag)) {
                promises.push(async function() {
                    request.blockTag = await blockTag;
                }());
            } else {
                request.blockTag = blockTag;
            }
        }
        if (promises.length) {
            return async function() {
                await Promise.all(promises);
                return request;
            }();
        }
        return request;
    }
    async getNetwork() {
        // No explicit network was set and this is our first time
        if (this.#networkPromise == null) {
            // Detect the current network (shared with all calls)
            const detectNetwork = (async ()=>{
                try {
                    const network = await this._detectNetwork();
                    this.emit("network", network, null);
                    return network;
                } catch (error) {
                    if (this.#networkPromise === detectNetwork) {
                        this.#networkPromise = null;
                    }
                    throw error;
                }
            })();
            this.#networkPromise = detectNetwork;
            return (await detectNetwork).clone();
        }
        const networkPromise = this.#networkPromise;
        const [expected, actual] = await Promise.all([
            networkPromise,
            this._detectNetwork() // The actual connected network
        ]);
        if (expected.chainId !== actual.chainId) {
            if (this.#anyNetwork) {
                // The "any" network can change, so notify listeners
                this.emit("network", actual, expected);
                // Update the network if something else hasn't already changed it
                if (this.#networkPromise === networkPromise) {
                    this.#networkPromise = Promise.resolve(actual);
                }
            } else {
                // Otherwise, we do not allow changes to the underlying network
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, `network changed: ${expected.chainId} => ${actual.chainId} `, "NETWORK_ERROR", {
                    event: "changed"
                });
            }
        }
        return expected.clone();
    }
    async getFeeData() {
        const network = await this.getNetwork();
        const getFeeDataFunc = async ()=>{
            const { _block, gasPrice, priorityFee } = await (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["resolveProperties"])({
                _block: this.#getBlock("latest", false),
                gasPrice: (async ()=>{
                    try {
                        const value = await this.#perform({
                            method: "getGasPrice"
                        });
                        return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"])(value, "%response");
                    } catch (error) {}
                    return null;
                })(),
                priorityFee: (async ()=>{
                    try {
                        const value = await this.#perform({
                            method: "getPriorityFee"
                        });
                        return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"])(value, "%response");
                    } catch (error) {}
                    return null;
                })()
            });
            let maxFeePerGas = null;
            let maxPriorityFeePerGas = null;
            // These are the recommended EIP-1559 heuristics for fee data
            const block = this._wrapBlock(_block, network);
            if (block && block.baseFeePerGas) {
                maxPriorityFeePerGas = priorityFee != null ? priorityFee : BigInt("1000000000");
                maxFeePerGas = block.baseFeePerGas * BN_2 + maxPriorityFeePerGas;
            }
            return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2e$js__$5b$client$5d$__$28$ecmascript$29$__["FeeData"](gasPrice, maxFeePerGas, maxPriorityFeePerGas);
        };
        // Check for a FeeDataNetWorkPlugin
        const plugin = network.getPlugin("org.ethers.plugins.network.FetchUrlFeeDataPlugin");
        if (plugin) {
            const req = new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$fetch$2e$js__$5b$client$5d$__$28$ecmascript$29$__["FetchRequest"](plugin.url);
            const feeData = await plugin.processFunc(getFeeDataFunc, this, req);
            return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2e$js__$5b$client$5d$__$28$ecmascript$29$__["FeeData"](feeData.gasPrice, feeData.maxFeePerGas, feeData.maxPriorityFeePerGas);
        }
        return await getFeeDataFunc();
    }
    async estimateGas(_tx) {
        let tx = this._getTransactionRequest(_tx);
        if (isPromise(tx)) {
            tx = await tx;
        }
        return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"])(await this.#perform({
            method: "estimateGas",
            transaction: tx
        }), "%response");
    }
    async #call(tx, blockTag, attempt) {
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(attempt < MAX_CCIP_REDIRECTS, "CCIP read exceeded maximum redirections", "OFFCHAIN_FAULT", {
            reason: "TOO_MANY_REDIRECTS",
            transaction: Object.assign({}, tx, {
                blockTag,
                enableCcipRead: true
            })
        });
        // This came in as a PerformActionTransaction, so to/from are safe; we can cast
        const transaction = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2e$js__$5b$client$5d$__$28$ecmascript$29$__["copyRequest"])(tx);
        try {
            return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["hexlify"])(await this._perform({
                method: "call",
                transaction,
                blockTag
            }));
        } catch (error) {
            // CCIP Read OffchainLookup
            if (!this.disableCcipRead && (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isCallException"])(error) && error.data && attempt >= 0 && blockTag === "latest" && transaction.to != null && (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["dataSlice"])(error.data, 0, 4) === "0x556f1830") {
                const data = error.data;
                const txSender = await (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$checks$2e$js__$5b$client$5d$__$28$ecmascript$29$__["resolveAddress"])(transaction.to, this);
                // Parse the CCIP Read Arguments
                let ccipArgs;
                try {
                    ccipArgs = parseOffchainLookup((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["dataSlice"])(error.data, 4));
                } catch (error) {
                    (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, error.message, "OFFCHAIN_FAULT", {
                        reason: "BAD_DATA",
                        transaction,
                        info: {
                            data
                        }
                    });
                }
                // Check the sender of the OffchainLookup matches the transaction
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(ccipArgs.sender.toLowerCase() === txSender.toLowerCase(), "CCIP Read sender mismatch", "CALL_EXCEPTION", {
                    action: "call",
                    data,
                    reason: "OffchainLookup",
                    transaction: transaction,
                    invocation: null,
                    revert: {
                        signature: "OffchainLookup(address,string[],bytes,bytes4,bytes)",
                        name: "OffchainLookup",
                        args: ccipArgs.errorArgs
                    }
                });
                const ccipResult = await this.ccipReadFetch(transaction, ccipArgs.calldata, ccipArgs.urls);
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(ccipResult != null, "CCIP Read failed to fetch data", "OFFCHAIN_FAULT", {
                    reason: "FETCH_FAILED",
                    transaction,
                    info: {
                        data: error.data,
                        errorArgs: ccipArgs.errorArgs
                    }
                });
                const tx = {
                    to: txSender,
                    data: (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["concat"])([
                        ccipArgs.selector,
                        encodeBytes([
                            ccipResult,
                            ccipArgs.extraData
                        ])
                    ])
                };
                this.emit("debug", {
                    action: "sendCcipReadCall",
                    transaction: tx
                });
                try {
                    const result = await this.#call(tx, blockTag, attempt + 1);
                    this.emit("debug", {
                        action: "receiveCcipReadCallResult",
                        transaction: Object.assign({}, tx),
                        result
                    });
                    return result;
                } catch (error) {
                    this.emit("debug", {
                        action: "receiveCcipReadCallError",
                        transaction: Object.assign({}, tx),
                        error
                    });
                    throw error;
                }
            }
            throw error;
        }
    }
    async #checkNetwork(promise) {
        const { value } = await (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["resolveProperties"])({
            network: this.getNetwork(),
            value: promise
        });
        return value;
    }
    async call(_tx) {
        const { tx, blockTag } = await (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["resolveProperties"])({
            tx: this._getTransactionRequest(_tx),
            blockTag: this._getBlockTag(_tx.blockTag)
        });
        return await this.#checkNetwork(this.#call(tx, blockTag, _tx.enableCcipRead ? 0 : -1));
    }
    // Account
    async #getAccountValue(request, _address, _blockTag) {
        let address = this._getAddress(_address);
        let blockTag = this._getBlockTag(_blockTag);
        if (typeof address !== "string" || typeof blockTag !== "string") {
            [address, blockTag] = await Promise.all([
                address,
                blockTag
            ]);
        }
        return await this.#checkNetwork(this.#perform(Object.assign(request, {
            address,
            blockTag
        })));
    }
    async getBalance(address, blockTag) {
        return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"])(await this.#getAccountValue({
            method: "getBalance"
        }, address, blockTag), "%response");
    }
    async getTransactionCount(address, blockTag) {
        return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"])(await this.#getAccountValue({
            method: "getTransactionCount"
        }, address, blockTag), "%response");
    }
    async getCode(address, blockTag) {
        return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["hexlify"])(await this.#getAccountValue({
            method: "getCode"
        }, address, blockTag));
    }
    async getStorage(address, _position, blockTag) {
        const position = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"])(_position, "position");
        return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["hexlify"])(await this.#getAccountValue({
            method: "getStorage",
            position
        }, address, blockTag));
    }
    // Write
    async broadcastTransaction(signedTx) {
        const { blockNumber, hash, network } = await (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["resolveProperties"])({
            blockNumber: this.getBlockNumber(),
            hash: this._perform({
                method: "broadcastTransaction",
                signedTransaction: signedTx
            }),
            network: this.getNetwork()
        });
        const tx = __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$transaction$2f$transaction$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Transaction"].from(signedTx);
        if (tx.hash !== hash) {
            throw new Error("@TODO: the returned hash did not match");
        }
        return this._wrapTransactionResponse(tx, network).replaceableTransaction(blockNumber);
    }
    async #getBlock(block, includeTransactions) {
        // @TODO: Add CustomBlockPlugin check
        if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isHexString"])(block, 32)) {
            return await this.#perform({
                method: "getBlock",
                blockHash: block,
                includeTransactions
            });
        }
        let blockTag = this._getBlockTag(block);
        if (typeof blockTag !== "string") {
            blockTag = await blockTag;
        }
        return await this.#perform({
            method: "getBlock",
            blockTag,
            includeTransactions
        });
    }
    // Queries
    async getBlock(block, prefetchTxs) {
        const { network, params } = await (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["resolveProperties"])({
            network: this.getNetwork(),
            params: this.#getBlock(block, !!prefetchTxs)
        });
        if (params == null) {
            return null;
        }
        return this._wrapBlock(params, network);
    }
    async getTransaction(hash) {
        const { network, params } = await (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["resolveProperties"])({
            network: this.getNetwork(),
            params: this.#perform({
                method: "getTransaction",
                hash
            })
        });
        if (params == null) {
            return null;
        }
        return this._wrapTransactionResponse(params, network);
    }
    async getTransactionReceipt(hash) {
        const { network, params } = await (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["resolveProperties"])({
            network: this.getNetwork(),
            params: this.#perform({
                method: "getTransactionReceipt",
                hash
            })
        });
        if (params == null) {
            return null;
        }
        // Some backends did not backfill the effectiveGasPrice into old transactions
        // in the receipt, so we look it up manually and inject it.
        if (params.gasPrice == null && params.effectiveGasPrice == null) {
            const tx = await this.#perform({
                method: "getTransaction",
                hash
            });
            if (tx == null) {
                throw new Error("report this; could not find tx or effectiveGasPrice");
            }
            params.effectiveGasPrice = tx.gasPrice;
        }
        return this._wrapTransactionReceipt(params, network);
    }
    async getTransactionResult(hash) {
        const { result } = await (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["resolveProperties"])({
            network: this.getNetwork(),
            result: this.#perform({
                method: "getTransactionResult",
                hash
            })
        });
        if (result == null) {
            return null;
        }
        return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["hexlify"])(result);
    }
    // Bloom-filter Queries
    async getLogs(_filter) {
        let filter = this._getFilter(_filter);
        if (isPromise(filter)) {
            filter = await filter;
        }
        const { network, params } = await (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["resolveProperties"])({
            network: this.getNetwork(),
            params: this.#perform({
                method: "getLogs",
                filter
            })
        });
        return params.map((p)=>this._wrapLog(p, network));
    }
    // ENS
    _getProvider(chainId) {
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, "provider cannot connect to target network", "UNSUPPORTED_OPERATION", {
            operation: "_getProvider()"
        });
    }
    async getResolver(name) {
        return await __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$ens$2d$resolver$2e$js__$5b$client$5d$__$28$ecmascript$29$__["EnsResolver"].fromName(this, name);
    }
    async getAvatar(name) {
        const resolver = await this.getResolver(name);
        if (resolver) {
            return await resolver.getAvatar();
        }
        return null;
    }
    async resolveName(name) {
        const resolver = await this.getResolver(name);
        if (resolver) {
            return await resolver.getAddress();
        }
        return null;
    }
    async lookupAddress(address) {
        address = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$address$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getAddress"])(address);
        const node = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$hash$2f$namehash$2e$js__$5b$client$5d$__$28$ecmascript$29$__["namehash"])(address.substring(2).toLowerCase() + ".addr.reverse");
        try {
            const ensAddr = await __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$ens$2d$resolver$2e$js__$5b$client$5d$__$28$ecmascript$29$__["EnsResolver"].getEnsAddress(this);
            const ensContract = new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$contract$2f$contract$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Contract"](ensAddr, [
                "function resolver(bytes32) view returns (address)"
            ], this);
            const resolver = await ensContract.resolver(node);
            if (resolver == null || resolver === __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$constants$2f$addresses$2e$js__$5b$client$5d$__$28$ecmascript$29$__["ZeroAddress"]) {
                return null;
            }
            const resolverContract = new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$contract$2f$contract$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Contract"](resolver, [
                "function name(bytes32) view returns (string)"
            ], this);
            const name = await resolverContract.name(node);
            // Failed forward resolution
            const check = await this.resolveName(name);
            if (check !== address) {
                return null;
            }
            return name;
        } catch (error) {
            // No data was returned from the resolver
            if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isError"])(error, "BAD_DATA") && error.value === "0x") {
                return null;
            }
            // Something reerted
            if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isError"])(error, "CALL_EXCEPTION")) {
                return null;
            }
            throw error;
        }
        return null;
    }
    async waitForTransaction(hash, _confirms, timeout) {
        const confirms = _confirms != null ? _confirms : 1;
        if (confirms === 0) {
            return this.getTransactionReceipt(hash);
        }
        return new Promise(async (resolve, reject)=>{
            let timer = null;
            const listener = async (blockNumber)=>{
                try {
                    const receipt = await this.getTransactionReceipt(hash);
                    if (receipt != null) {
                        if (blockNumber - receipt.blockNumber + 1 >= confirms) {
                            resolve(receipt);
                            //this.off("block", listener);
                            if (timer) {
                                clearTimeout(timer);
                                timer = null;
                            }
                            return;
                        }
                    }
                } catch (error) {
                    console.log("EEE", error);
                }
                this.once("block", listener);
            };
            if (timeout != null) {
                timer = setTimeout(()=>{
                    if (timer == null) {
                        return;
                    }
                    timer = null;
                    this.off("block", listener);
                    reject((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["makeError"])("timeout", "TIMEOUT", {
                        reason: "timeout"
                    }));
                }, timeout);
            }
            listener(await this.getBlockNumber());
        });
    }
    async waitForBlock(blockTag) {
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, "not implemented yet", "NOT_IMPLEMENTED", {
            operation: "waitForBlock"
        });
    }
    /**
     *  Clear a timer created using the [[_setTimeout]] method.
     */ _clearTimeout(timerId) {
        const timer = this.#timers.get(timerId);
        if (!timer) {
            return;
        }
        if (timer.timer) {
            clearTimeout(timer.timer);
        }
        this.#timers.delete(timerId);
    }
    /**
     *  Create a timer that will execute %%func%% after at least %%timeout%%
     *  (in ms). If %%timeout%% is unspecified, then %%func%% will execute
     *  in the next event loop.
     *
     *  [Pausing](AbstractProvider-paused) the provider will pause any
     *  associated timers.
     */ _setTimeout(_func, timeout) {
        if (timeout == null) {
            timeout = 0;
        }
        const timerId = this.#nextTimer++;
        const func = ()=>{
            this.#timers.delete(timerId);
            _func();
        };
        if (this.paused) {
            this.#timers.set(timerId, {
                timer: null,
                func,
                time: timeout
            });
        } else {
            const timer = setTimeout(func, timeout);
            this.#timers.set(timerId, {
                timer,
                func,
                time: getTime()
            });
        }
        return timerId;
    }
    /**
     *  Perform %%func%% on each subscriber.
     */ _forEachSubscriber(func) {
        for (const sub of this.#subs.values()){
            func(sub.subscriber);
        }
    }
    /**
     *  Sub-classes may override this to customize subscription
     *  implementations.
     */ _getSubscriber(sub) {
        switch(sub.type){
            case "debug":
            case "error":
            case "network":
                return new UnmanagedSubscriber(sub.type);
            case "block":
                {
                    const subscriber = new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$subscriber$2d$polling$2e$js__$5b$client$5d$__$28$ecmascript$29$__["PollingBlockSubscriber"](this);
                    subscriber.pollingInterval = this.pollingInterval;
                    return subscriber;
                }
            case "safe":
            case "finalized":
                return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$subscriber$2d$polling$2e$js__$5b$client$5d$__$28$ecmascript$29$__["PollingBlockTagSubscriber"](this, sub.type);
            case "event":
                return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$subscriber$2d$polling$2e$js__$5b$client$5d$__$28$ecmascript$29$__["PollingEventSubscriber"](this, sub.filter);
            case "transaction":
                return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$subscriber$2d$polling$2e$js__$5b$client$5d$__$28$ecmascript$29$__["PollingTransactionSubscriber"](this, sub.hash);
            case "orphan":
                return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$subscriber$2d$polling$2e$js__$5b$client$5d$__$28$ecmascript$29$__["PollingOrphanSubscriber"](this, sub.filter);
        }
        throw new Error(`unsupported event: ${sub.type}`);
    }
    /**
     *  If a [[Subscriber]] fails and needs to replace itself, this
     *  method may be used.
     *
     *  For example, this is used for providers when using the
     *  ``eth_getFilterChanges`` method, which can return null if state
     *  filters are not supported by the backend, allowing the Subscriber
     *  to swap in a [[PollingEventSubscriber]].
     */ _recoverSubscriber(oldSub, newSub) {
        for (const sub of this.#subs.values()){
            if (sub.subscriber === oldSub) {
                if (sub.started) {
                    sub.subscriber.stop();
                }
                sub.subscriber = newSub;
                if (sub.started) {
                    newSub.start();
                }
                if (this.#pausedState != null) {
                    newSub.pause(this.#pausedState);
                }
                break;
            }
        }
    }
    async #hasSub(event, emitArgs) {
        let sub = await getSubscription(event, this);
        // This is a log that is removing an existing log; we actually want
        // to emit an orphan event for the removed log
        if (sub.type === "event" && emitArgs && emitArgs.length > 0 && emitArgs[0].removed === true) {
            sub = await getSubscription({
                orphan: "drop-log",
                log: emitArgs[0]
            }, this);
        }
        return this.#subs.get(sub.tag) || null;
    }
    async #getSub(event) {
        const subscription = await getSubscription(event, this);
        // Prevent tampering with our tag in any subclass' _getSubscriber
        const tag = subscription.tag;
        let sub = this.#subs.get(tag);
        if (!sub) {
            const subscriber = this._getSubscriber(subscription);
            const addressableMap = new WeakMap();
            const nameMap = new Map();
            sub = {
                subscriber,
                tag,
                addressableMap,
                nameMap,
                started: false,
                listeners: []
            };
            this.#subs.set(tag, sub);
        }
        return sub;
    }
    async on(event, listener) {
        const sub = await this.#getSub(event);
        sub.listeners.push({
            listener,
            once: false
        });
        if (!sub.started) {
            sub.subscriber.start();
            sub.started = true;
            if (this.#pausedState != null) {
                sub.subscriber.pause(this.#pausedState);
            }
        }
        return this;
    }
    async once(event, listener) {
        const sub = await this.#getSub(event);
        sub.listeners.push({
            listener,
            once: true
        });
        if (!sub.started) {
            sub.subscriber.start();
            sub.started = true;
            if (this.#pausedState != null) {
                sub.subscriber.pause(this.#pausedState);
            }
        }
        return this;
    }
    async emit(event, ...args) {
        const sub = await this.#hasSub(event, args);
        // If there is not subscription or if a recent emit removed
        // the last of them (which also deleted the sub) do nothing
        if (!sub || sub.listeners.length === 0) {
            return false;
        }
        ;
        const count = sub.listeners.length;
        sub.listeners = sub.listeners.filter(({ listener, once })=>{
            const payload = new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$events$2e$js__$5b$client$5d$__$28$ecmascript$29$__["EventPayload"](this, once ? null : listener, event);
            try {
                listener.call(this, ...args, payload);
            } catch (error) {}
            return !once;
        });
        if (sub.listeners.length === 0) {
            if (sub.started) {
                sub.subscriber.stop();
            }
            this.#subs.delete(sub.tag);
        }
        return count > 0;
    }
    async listenerCount(event) {
        if (event) {
            const sub = await this.#hasSub(event);
            if (!sub) {
                return 0;
            }
            return sub.listeners.length;
        }
        let total = 0;
        for (const { listeners } of this.#subs.values()){
            total += listeners.length;
        }
        return total;
    }
    async listeners(event) {
        if (event) {
            const sub = await this.#hasSub(event);
            if (!sub) {
                return [];
            }
            return sub.listeners.map(({ listener })=>listener);
        }
        let result = [];
        for (const { listeners } of this.#subs.values()){
            result = result.concat(listeners.map(({ listener })=>listener));
        }
        return result;
    }
    async off(event, listener) {
        const sub = await this.#hasSub(event);
        if (!sub) {
            return this;
        }
        if (listener) {
            const index = sub.listeners.map(({ listener })=>listener).indexOf(listener);
            if (index >= 0) {
                sub.listeners.splice(index, 1);
            }
        }
        if (!listener || sub.listeners.length === 0) {
            if (sub.started) {
                sub.subscriber.stop();
            }
            this.#subs.delete(sub.tag);
        }
        return this;
    }
    async removeAllListeners(event) {
        if (event) {
            const { tag, started, subscriber } = await this.#getSub(event);
            if (started) {
                subscriber.stop();
            }
            this.#subs.delete(tag);
        } else {
            for (const [tag, { started, subscriber }] of this.#subs){
                if (started) {
                    subscriber.stop();
                }
                this.#subs.delete(tag);
            }
        }
        return this;
    }
    // Alias for "on"
    async addListener(event, listener) {
        return await this.on(event, listener);
    }
    // Alias for "off"
    async removeListener(event, listener) {
        return this.off(event, listener);
    }
    /**
     *  If this provider has been destroyed using the [[destroy]] method.
     *
     *  Once destroyed, all resources are reclaimed, internal event loops
     *  and timers are cleaned up and no further requests may be sent to
     *  the provider.
     */ get destroyed() {
        return this.#destroyed;
    }
    /**
     *  Sub-classes may use this to shutdown any sockets or release their
     *  resources and reject any pending requests.
     *
     *  Sub-classes **must** call ``super.destroy()``.
     */ destroy() {
        // Stop all listeners
        this.removeAllListeners();
        // Shut down all tiemrs
        for (const timerId of this.#timers.keys()){
            this._clearTimeout(timerId);
        }
        this.#destroyed = true;
    }
    /**
     *  Whether the provider is currently paused.
     *
     *  A paused provider will not emit any events, and generally should
     *  not make any requests to the network, but that is up to sub-classes
     *  to manage.
     *
     *  Setting ``paused = true`` is identical to calling ``.pause(false)``,
     *  which will buffer any events that occur while paused until the
     *  provider is unpaused.
     */ get paused() {
        return this.#pausedState != null;
    }
    set paused(pause) {
        if (!!pause === this.paused) {
            return;
        }
        if (this.paused) {
            this.resume();
        } else {
            this.pause(false);
        }
    }
    /**
     *  Pause the provider. If %%dropWhilePaused%%, any events that occur
     *  while paused are dropped, otherwise all events will be emitted once
     *  the provider is unpaused.
     */ pause(dropWhilePaused) {
        this.#lastBlockNumber = -1;
        if (this.#pausedState != null) {
            if (this.#pausedState == !!dropWhilePaused) {
                return;
            }
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, "cannot change pause type; resume first", "UNSUPPORTED_OPERATION", {
                operation: "pause"
            });
        }
        this._forEachSubscriber((s)=>s.pause(dropWhilePaused));
        this.#pausedState = !!dropWhilePaused;
        for (const timer of this.#timers.values()){
            // Clear the timer
            if (timer.timer) {
                clearTimeout(timer.timer);
            }
            // Remaining time needed for when we become unpaused
            timer.time = getTime() - timer.time;
        }
    }
    /**
     *  Resume the provider.
     */ resume() {
        if (this.#pausedState == null) {
            return;
        }
        this._forEachSubscriber((s)=>s.resume());
        this.#pausedState = null;
        for (const timer of this.#timers.values()){
            // Remaining time when we were paused
            let timeout = timer.time;
            if (timeout < 0) {
                timeout = 0;
            }
            // Start time (in cause paused, so we con compute remaininf time)
            timer.time = getTime();
            // Start the timer
            setTimeout(timer.func, timeout);
        }
    }
}
function _parseString(result, start) {
    try {
        const bytes = _parseBytes(result, start);
        if (bytes) {
            return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$utf8$2e$js__$5b$client$5d$__$28$ecmascript$29$__["toUtf8String"])(bytes);
        }
    } catch (error) {}
    return null;
}
function _parseBytes(result, start) {
    if (result === "0x") {
        return null;
    }
    try {
        const offset = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"])((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["dataSlice"])(result, start, start + 32));
        const length = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"])((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["dataSlice"])(result, offset, offset + 32));
        return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["dataSlice"])(result, offset + 32, offset + 32 + length);
    } catch (error) {}
    return null;
}
function numPad(value) {
    const result = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["toBeArray"])(value);
    if (result.length > 32) {
        throw new Error("internal; should not happen");
    }
    const padded = new Uint8Array(32);
    padded.set(result, 32 - result.length);
    return padded;
}
function bytesPad(value) {
    if (value.length % 32 === 0) {
        return value;
    }
    const result = new Uint8Array(Math.ceil(value.length / 32) * 32);
    result.set(value);
    return result;
}
const empty = new Uint8Array([]);
// ABI Encodes a series of (bytes, bytes, ...)
function encodeBytes(datas) {
    const result = [];
    let byteCount = 0;
    // Add place-holders for pointers as we add items
    for(let i = 0; i < datas.length; i++){
        result.push(empty);
        byteCount += 32;
    }
    for(let i = 0; i < datas.length; i++){
        const data = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBytes"])(datas[i]);
        // Update the bytes offset
        result[i] = numPad(byteCount);
        // The length and padded value of data
        result.push(numPad(data.length));
        result.push(bytesPad(data));
        byteCount += 32 + Math.ceil(data.length / 32) * 32;
    }
    return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["concat"])(result);
}
const zeros = "0x0000000000000000000000000000000000000000000000000000000000000000";
function parseOffchainLookup(data) {
    const result = {
        sender: "",
        urls: [],
        calldata: "",
        selector: "",
        extraData: "",
        errorArgs: []
    };
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["dataLength"])(data) >= 5 * 32, "insufficient OffchainLookup data", "OFFCHAIN_FAULT", {
        reason: "insufficient OffchainLookup data"
    });
    const sender = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["dataSlice"])(data, 0, 32);
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["dataSlice"])(sender, 0, 12) === (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["dataSlice"])(zeros, 0, 12), "corrupt OffchainLookup sender", "OFFCHAIN_FAULT", {
        reason: "corrupt OffchainLookup sender"
    });
    result.sender = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["dataSlice"])(sender, 12);
    // Read the URLs from the response
    try {
        const urls = [];
        const urlsOffset = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"])((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["dataSlice"])(data, 32, 64));
        const urlsLength = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"])((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["dataSlice"])(data, urlsOffset, urlsOffset + 32));
        const urlsData = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["dataSlice"])(data, urlsOffset + 32);
        for(let u = 0; u < urlsLength; u++){
            const url = _parseString(urlsData, u * 32);
            if (url == null) {
                throw new Error("abort");
            }
            urls.push(url);
        }
        result.urls = urls;
    } catch (error) {
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, "corrupt OffchainLookup urls", "OFFCHAIN_FAULT", {
            reason: "corrupt OffchainLookup urls"
        });
    }
    // Get the CCIP calldata to forward
    try {
        const calldata = _parseBytes(data, 64);
        if (calldata == null) {
            throw new Error("abort");
        }
        result.calldata = calldata;
    } catch (error) {
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, "corrupt OffchainLookup calldata", "OFFCHAIN_FAULT", {
            reason: "corrupt OffchainLookup calldata"
        });
    }
    // Get the callbackSelector (bytes4)
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["dataSlice"])(data, 100, 128) === (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["dataSlice"])(zeros, 0, 28), "corrupt OffchainLookup callbaackSelector", "OFFCHAIN_FAULT", {
        reason: "corrupt OffchainLookup callbaackSelector"
    });
    result.selector = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["dataSlice"])(data, 96, 100);
    // Get the extra data to send back to the contract as context
    try {
        const extraData = _parseBytes(data, 128);
        if (extraData == null) {
            throw new Error("abort");
        }
        result.extraData = extraData;
    } catch (error) {
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, "corrupt OffchainLookup extraData", "OFFCHAIN_FAULT", {
            reason: "corrupt OffchainLookup extraData"
        });
    }
    result.errorArgs = "sender,urls,calldata,selector,extraData".split(/,/).map((k)=>result[k]);
    return result;
} //# sourceMappingURL=abstract-provider.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/abstract-signer.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "AbstractSigner",
    ()=>AbstractSigner,
    "VoidSigner",
    ()=>VoidSigner
]);
/**
 *  Generally the [[Wallet]] and [[JsonRpcSigner]] and their sub-classes
 *  are sufficient for most developers, but this is provided to
 *  fascilitate more complex Signers.
 *
 *  @_section: api/providers/abstract-signer: Subclassing Signer [abstract-signer]
 */ var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$checks$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/address/checks.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$transaction$2f$transaction$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/transaction/transaction.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/properties.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/maths.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/errors.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider.js [client] (ecmascript)");
;
;
;
;
function checkProvider(signer, operation) {
    if (signer.provider) {
        return signer.provider;
    }
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, "missing provider", "UNSUPPORTED_OPERATION", {
        operation
    });
}
async function populate(signer, tx) {
    let pop = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2e$js__$5b$client$5d$__$28$ecmascript$29$__["copyRequest"])(tx);
    if (pop.to != null) {
        pop.to = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$checks$2e$js__$5b$client$5d$__$28$ecmascript$29$__["resolveAddress"])(pop.to, signer);
    }
    if (pop.from != null) {
        const from = pop.from;
        pop.from = Promise.all([
            signer.getAddress(),
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$checks$2e$js__$5b$client$5d$__$28$ecmascript$29$__["resolveAddress"])(from, signer)
        ]).then(([address, from])=>{
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(address.toLowerCase() === from.toLowerCase(), "transaction from mismatch", "tx.from", from);
            return address;
        });
    } else {
        pop.from = signer.getAddress();
    }
    return await (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["resolveProperties"])(pop);
}
class AbstractSigner {
    /**
     *  The provider this signer is connected to.
     */ provider;
    /**
     *  Creates a new Signer connected to %%provider%%.
     */ constructor(provider){
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            provider: provider || null
        });
    }
    async getNonce(blockTag) {
        return checkProvider(this, "getTransactionCount").getTransactionCount(await this.getAddress(), blockTag);
    }
    async populateCall(tx) {
        const pop = await populate(this, tx);
        return pop;
    }
    async populateTransaction(tx) {
        const provider = checkProvider(this, "populateTransaction");
        const pop = await populate(this, tx);
        if (pop.nonce == null) {
            pop.nonce = await this.getNonce("pending");
        }
        if (pop.gasLimit == null) {
            pop.gasLimit = await this.estimateGas(pop);
        }
        // Populate the chain ID
        const network = await this.provider.getNetwork();
        if (pop.chainId != null) {
            const chainId = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"])(pop.chainId);
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(chainId === network.chainId, "transaction chainId mismatch", "tx.chainId", tx.chainId);
        } else {
            pop.chainId = network.chainId;
        }
        // Do not allow mixing pre-eip-1559 and eip-1559 properties
        const hasEip1559 = pop.maxFeePerGas != null || pop.maxPriorityFeePerGas != null;
        if (pop.gasPrice != null && (pop.type === 2 || hasEip1559)) {
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, "eip-1559 transaction do not support gasPrice", "tx", tx);
        } else if ((pop.type === 0 || pop.type === 1) && hasEip1559) {
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, "pre-eip-1559 transaction do not support maxFeePerGas/maxPriorityFeePerGas", "tx", tx);
        }
        if ((pop.type === 2 || pop.type == null) && pop.maxFeePerGas != null && pop.maxPriorityFeePerGas != null) {
            // Fully-formed EIP-1559 transaction (skip getFeeData)
            pop.type = 2;
        } else if (pop.type === 0 || pop.type === 1) {
            // Explicit Legacy or EIP-2930 transaction
            // We need to get fee data to determine things
            const feeData = await provider.getFeeData();
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(feeData.gasPrice != null, "network does not support gasPrice", "UNSUPPORTED_OPERATION", {
                operation: "getGasPrice"
            });
            // Populate missing gasPrice
            if (pop.gasPrice == null) {
                pop.gasPrice = feeData.gasPrice;
            }
        } else {
            // We need to get fee data to determine things
            const feeData = await provider.getFeeData();
            if (pop.type == null) {
                // We need to auto-detect the intended type of this transaction...
                if (feeData.maxFeePerGas != null && feeData.maxPriorityFeePerGas != null) {
                    // The network supports EIP-1559!
                    // Upgrade transaction from null to eip-1559
                    if (pop.authorizationList && pop.authorizationList.length) {
                        pop.type = 4;
                    } else {
                        pop.type = 2;
                    }
                    if (pop.gasPrice != null) {
                        // Using legacy gasPrice property on an eip-1559 network,
                        // so use gasPrice as both fee properties
                        const gasPrice = pop.gasPrice;
                        delete pop.gasPrice;
                        pop.maxFeePerGas = gasPrice;
                        pop.maxPriorityFeePerGas = gasPrice;
                    } else {
                        // Populate missing fee data
                        if (pop.maxFeePerGas == null) {
                            pop.maxFeePerGas = feeData.maxFeePerGas;
                        }
                        if (pop.maxPriorityFeePerGas == null) {
                            pop.maxPriorityFeePerGas = feeData.maxPriorityFeePerGas;
                        }
                    }
                } else if (feeData.gasPrice != null) {
                    // Network doesn't support EIP-1559...
                    // ...but they are trying to use EIP-1559 properties
                    (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(!hasEip1559, "network does not support EIP-1559", "UNSUPPORTED_OPERATION", {
                        operation: "populateTransaction"
                    });
                    // Populate missing fee data
                    if (pop.gasPrice == null) {
                        pop.gasPrice = feeData.gasPrice;
                    }
                    // Explicitly set untyped transaction to legacy
                    // @TODO: Maybe this shold allow type 1?
                    pop.type = 0;
                } else {
                    // getFeeData has failed us.
                    (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, "failed to get consistent fee data", "UNSUPPORTED_OPERATION", {
                        operation: "signer.getFeeData"
                    });
                }
            } else if (pop.type === 2 || pop.type === 3 || pop.type === 4) {
                // Explicitly using EIP-1559 or EIP-4844
                // Populate missing fee data
                if (pop.maxFeePerGas == null) {
                    pop.maxFeePerGas = feeData.maxFeePerGas;
                }
                if (pop.maxPriorityFeePerGas == null) {
                    pop.maxPriorityFeePerGas = feeData.maxPriorityFeePerGas;
                }
            }
        }
        //@TOOD: Don't await all over the place; save them up for
        // the end for better batching
        return await (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["resolveProperties"])(pop);
    }
    async populateAuthorization(_auth) {
        const auth = Object.assign({}, _auth);
        // Add a chain ID if not explicitly set to 0
        if (auth.chainId == null) {
            auth.chainId = (await checkProvider(this, "getNetwork").getNetwork()).chainId;
        }
        // @TODO: Take chain ID into account when populating noce?
        if (auth.nonce == null) {
            auth.nonce = await this.getNonce();
        }
        return auth;
    }
    async estimateGas(tx) {
        return checkProvider(this, "estimateGas").estimateGas(await this.populateCall(tx));
    }
    async call(tx) {
        return checkProvider(this, "call").call(await this.populateCall(tx));
    }
    async resolveName(name) {
        const provider = checkProvider(this, "resolveName");
        return await provider.resolveName(name);
    }
    async sendTransaction(tx) {
        const provider = checkProvider(this, "sendTransaction");
        const pop = await this.populateTransaction(tx);
        delete pop.from;
        const txObj = __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$transaction$2f$transaction$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Transaction"].from(pop);
        return await provider.broadcastTransaction(await this.signTransaction(txObj));
    }
    // @TODO: in v7 move this to be abstract
    authorize(authorization) {
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, "authorization not implemented for this signer", "UNSUPPORTED_OPERATION", {
            operation: "authorize"
        });
    }
}
class VoidSigner extends AbstractSigner {
    /**
     *  The signer address.
     */ address;
    /**
     *  Creates a new **VoidSigner** with %%address%% attached to
     *  %%provider%%.
     */ constructor(address, provider){
        super(provider);
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            address
        });
    }
    async getAddress() {
        return this.address;
    }
    connect(provider) {
        return new VoidSigner(this.address, provider);
    }
    #throwUnsupported(suffix, operation) {
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, `VoidSigner cannot sign ${suffix}`, "UNSUPPORTED_OPERATION", {
            operation
        });
    }
    async signTransaction(tx) {
        this.#throwUnsupported("transactions", "signTransaction");
    }
    async signMessage(message) {
        this.#throwUnsupported("messages", "signMessage");
    }
    async signTypedData(domain, types, value) {
        this.#throwUnsupported("typed-data", "signTypedData");
    }
} //# sourceMappingURL=abstract-signer.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/subscriber-filterid.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "FilterIdEventSubscriber",
    ()=>FilterIdEventSubscriber,
    "FilterIdPendingSubscriber",
    ()=>FilterIdPendingSubscriber,
    "FilterIdSubscriber",
    ()=>FilterIdSubscriber
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/errors.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$subscriber$2d$polling$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/subscriber-polling.js [client] (ecmascript)");
;
;
function copy(obj) {
    return JSON.parse(JSON.stringify(obj));
}
class FilterIdSubscriber {
    #provider;
    #filterIdPromise;
    #poller;
    #running;
    #network;
    #hault;
    /**
     *  Creates a new **FilterIdSubscriber** which will used [[_subscribe]]
     *  and [[_emitResults]] to setup the subscription and provide the event
     *  to the %%provider%%.
     */ constructor(provider){
        this.#provider = provider;
        this.#filterIdPromise = null;
        this.#poller = this.#poll.bind(this);
        this.#running = false;
        this.#network = null;
        this.#hault = false;
    }
    /**
     *  Sub-classes **must** override this to begin the subscription.
     */ _subscribe(provider) {
        throw new Error("subclasses must override this");
    }
    /**
     *  Sub-classes **must** override this handle the events.
     */ _emitResults(provider, result) {
        throw new Error("subclasses must override this");
    }
    /**
     *  Sub-classes **must** override this handle recovery on errors.
     */ _recover(provider) {
        throw new Error("subclasses must override this");
    }
    async #poll(blockNumber) {
        try {
            // Subscribe if necessary
            if (this.#filterIdPromise == null) {
                this.#filterIdPromise = this._subscribe(this.#provider);
            }
            // Get the Filter ID
            let filterId = null;
            try {
                filterId = await this.#filterIdPromise;
            } catch (error) {
                if (!(0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isError"])(error, "UNSUPPORTED_OPERATION") || error.operation !== "eth_newFilter") {
                    throw error;
                }
            }
            // The backend does not support Filter ID; downgrade to
            // polling
            if (filterId == null) {
                this.#filterIdPromise = null;
                this.#provider._recoverSubscriber(this, this._recover(this.#provider));
                return;
            }
            const network = await this.#provider.getNetwork();
            if (!this.#network) {
                this.#network = network;
            }
            if (this.#network.chainId !== network.chainId) {
                throw new Error("chaid changed");
            }
            if (this.#hault) {
                return;
            }
            const result = await this.#provider.send("eth_getFilterChanges", [
                filterId
            ]);
            await this._emitResults(this.#provider, result);
        } catch (error) {
            console.log("@TODO", error);
        }
        this.#provider.once("block", this.#poller);
    }
    #teardown() {
        const filterIdPromise = this.#filterIdPromise;
        if (filterIdPromise) {
            this.#filterIdPromise = null;
            filterIdPromise.then((filterId)=>{
                if (this.#provider.destroyed) {
                    return;
                }
                this.#provider.send("eth_uninstallFilter", [
                    filterId
                ]);
            });
        }
    }
    start() {
        if (this.#running) {
            return;
        }
        this.#running = true;
        this.#poll(-2);
    }
    stop() {
        if (!this.#running) {
            return;
        }
        this.#running = false;
        this.#hault = true;
        this.#teardown();
        this.#provider.off("block", this.#poller);
    }
    pause(dropWhilePaused) {
        if (dropWhilePaused) {
            this.#teardown();
        }
        this.#provider.off("block", this.#poller);
    }
    resume() {
        this.start();
    }
}
class FilterIdEventSubscriber extends FilterIdSubscriber {
    #event;
    /**
     *  Creates a new **FilterIdEventSubscriber** attached to %%provider%%
     *  listening for %%filter%%.
     */ constructor(provider, filter){
        super(provider);
        this.#event = copy(filter);
    }
    _recover(provider) {
        return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$subscriber$2d$polling$2e$js__$5b$client$5d$__$28$ecmascript$29$__["PollingEventSubscriber"](provider, this.#event);
    }
    async _subscribe(provider) {
        const filterId = await provider.send("eth_newFilter", [
            this.#event
        ]);
        return filterId;
    }
    async _emitResults(provider, results) {
        for (const result of results){
            provider.emit(this.#event, provider._wrapLog(result, provider._network));
        }
    }
}
class FilterIdPendingSubscriber extends FilterIdSubscriber {
    async _subscribe(provider) {
        return await provider.send("eth_newPendingTransactionFilter", []);
    }
    async _emitResults(provider, results) {
        for (const result of results){
            provider.emit("pending", result);
        }
    }
} //# sourceMappingURL=subscriber-filterid.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-jsonrpc.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "JsonRpcApiPollingProvider",
    ()=>JsonRpcApiPollingProvider,
    "JsonRpcApiProvider",
    ()=>JsonRpcApiProvider,
    "JsonRpcProvider",
    ()=>JsonRpcProvider,
    "JsonRpcSigner",
    ()=>JsonRpcSigner
]);
/**
 *  One of the most common ways to interact with the blockchain is
 *  by a node running a JSON-RPC interface which can be connected to,
 *  based on the transport, using:
 *
 *  - HTTP or HTTPS - [[JsonRpcProvider]]
 *  - WebSocket - [[WebSocketProvider]]
 *  - IPC - [[IpcSocketProvider]]
 *
 * @_section: api/providers/jsonrpc:JSON-RPC Provider  [about-jsonrpcProvider]
 */ // @TODO:
// - Add the batching API
// https://playground.open-rpc.org/?schemaUrl=https://raw.githubusercontent.com/ethereum/eth1.0-apis/assembled-spec/openrpc.json&uiSchema%5BappBar%5D%5Bui:splitView%5D=true&uiSchema%5BappBar%5D%5Bui:input%5D=false&uiSchema%5BappBar%5D%5Bui:examplesDropdown%5D=false
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$abi$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/abi-coder.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$address$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/address/address.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$checks$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/address/checks.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$hash$2f$typed$2d$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/hash/typed-data.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$transaction$2f$accesslist$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/transaction/accesslist.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$transaction$2f$authorization$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/transaction/authorization.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/properties.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/maths.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/data.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$utf8$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/utf8.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/errors.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$fetch$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/fetch.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$abstract$2d$provider$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/abstract-provider.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$abstract$2d$signer$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/abstract-signer.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/network.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$subscriber$2d$filterid$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/subscriber-filterid.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$subscriber$2d$polling$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/subscriber-polling.js [client] (ecmascript)");
;
;
;
;
;
;
;
;
;
;
const Primitive = "bigint,boolean,function,number,string,symbol".split(/,/g);
//const Methods = "getAddress,then".split(/,/g);
function deepCopy(value) {
    if (value == null || Primitive.indexOf(typeof value) >= 0) {
        return value;
    }
    // Keep any Addressable
    if (typeof value.getAddress === "function") {
        return value;
    }
    if (Array.isArray(value)) {
        return value.map(deepCopy);
    }
    if (typeof value === "object") {
        return Object.keys(value).reduce((accum, key)=>{
            accum[key] = value[key];
            return accum;
        }, {});
    }
    throw new Error(`should not happen: ${value} (${typeof value})`);
}
function stall(duration) {
    return new Promise((resolve)=>{
        setTimeout(resolve, duration);
    });
}
function getLowerCase(value) {
    if (value) {
        return value.toLowerCase();
    }
    return value;
}
function isPollable(value) {
    return value && typeof value.pollingInterval === "number";
}
const defaultOptions = {
    polling: false,
    staticNetwork: null,
    batchStallTime: 10,
    batchMaxSize: 1 << 20,
    batchMaxCount: 100,
    cacheTimeout: 250,
    pollingInterval: 4000
};
class JsonRpcSigner extends __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$abstract$2d$signer$2e$js__$5b$client$5d$__$28$ecmascript$29$__["AbstractSigner"] {
    address;
    constructor(provider, address){
        super(provider);
        address = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$address$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getAddress"])(address);
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            address
        });
    }
    connect(provider) {
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, "cannot reconnect JsonRpcSigner", "UNSUPPORTED_OPERATION", {
            operation: "signer.connect"
        });
    }
    async getAddress() {
        return this.address;
    }
    // JSON-RPC will automatially fill in nonce, etc. so we just check from
    async populateTransaction(tx) {
        return await this.populateCall(tx);
    }
    // Returns just the hash of the transaction after sent, which is what
    // the bare JSON-RPC API does;
    async sendUncheckedTransaction(_tx) {
        const tx = deepCopy(_tx);
        const promises = [];
        // Make sure the from matches the sender
        if (tx.from) {
            const _from = tx.from;
            promises.push((async ()=>{
                const from = await (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$checks$2e$js__$5b$client$5d$__$28$ecmascript$29$__["resolveAddress"])(_from, this.provider);
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(from != null && from.toLowerCase() === this.address.toLowerCase(), "from address mismatch", "transaction", _tx);
                tx.from = from;
            })());
        } else {
            tx.from = this.address;
        }
        // The JSON-RPC for eth_sendTransaction uses 90000 gas; if the user
        // wishes to use this, it is easy to specify explicitly, otherwise
        // we look it up for them.
        if (tx.gasLimit == null) {
            promises.push((async ()=>{
                tx.gasLimit = await this.provider.estimateGas({
                    ...tx,
                    from: this.address
                });
            })());
        }
        // The address may be an ENS name or Addressable
        if (tx.to != null) {
            const _to = tx.to;
            promises.push((async ()=>{
                tx.to = await (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$checks$2e$js__$5b$client$5d$__$28$ecmascript$29$__["resolveAddress"])(_to, this.provider);
            })());
        }
        // Wait until all of our properties are filled in
        if (promises.length) {
            await Promise.all(promises);
        }
        const hexTx = this.provider.getRpcTransaction(tx);
        return this.provider.send("eth_sendTransaction", [
            hexTx
        ]);
    }
    async sendTransaction(tx) {
        // This cannot be mined any earlier than any recent block
        const blockNumber = await this.provider.getBlockNumber();
        // Send the transaction
        const hash = await this.sendUncheckedTransaction(tx);
        // Unfortunately, JSON-RPC only provides and opaque transaction hash
        // for a response, and we need the actual transaction, so we poll
        // for it; it should show up very quickly
        return await new Promise((resolve, reject)=>{
            const timeouts = [
                1000,
                100
            ];
            let invalids = 0;
            const checkTx = async ()=>{
                try {
                    // Try getting the transaction
                    const tx = await this.provider.getTransaction(hash);
                    if (tx != null) {
                        resolve(tx.replaceableTransaction(blockNumber));
                        return;
                    }
                } catch (error) {
                    // If we were cancelled: stop polling.
                    // If the data is bad: the node returns bad transactions
                    // If the network changed: calling again will also fail
                    // If unsupported: likely destroyed
                    if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isError"])(error, "CANCELLED") || (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isError"])(error, "BAD_DATA") || (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isError"])(error, "NETWORK_ERROR") || (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isError"])(error, "UNSUPPORTED_OPERATION")) {
                        if (error.info == null) {
                            error.info = {};
                        }
                        error.info.sendTransactionHash = hash;
                        reject(error);
                        return;
                    }
                    // Stop-gap for misbehaving backends; see #4513
                    if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isError"])(error, "INVALID_ARGUMENT")) {
                        invalids++;
                        if (error.info == null) {
                            error.info = {};
                        }
                        error.info.sendTransactionHash = hash;
                        if (invalids > 10) {
                            reject(error);
                            return;
                        }
                    }
                    // Notify anyone that cares; but we will try again, since
                    // it is likely an intermittent service error
                    this.provider.emit("error", (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["makeError"])("failed to fetch transation after sending (will try again)", "UNKNOWN_ERROR", {
                        error
                    }));
                }
                // Wait another 4 seconds
                this.provider._setTimeout(()=>{
                    checkTx();
                }, timeouts.pop() || 4000);
            };
            checkTx();
        });
    }
    async signTransaction(_tx) {
        const tx = deepCopy(_tx);
        // Make sure the from matches the sender
        if (tx.from) {
            const from = await (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$checks$2e$js__$5b$client$5d$__$28$ecmascript$29$__["resolveAddress"])(tx.from, this.provider);
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(from != null && from.toLowerCase() === this.address.toLowerCase(), "from address mismatch", "transaction", _tx);
            tx.from = from;
        } else {
            tx.from = this.address;
        }
        const hexTx = this.provider.getRpcTransaction(tx);
        return await this.provider.send("eth_signTransaction", [
            hexTx
        ]);
    }
    async signMessage(_message) {
        const message = typeof _message === "string" ? (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$utf8$2e$js__$5b$client$5d$__$28$ecmascript$29$__["toUtf8Bytes"])(_message) : _message;
        return await this.provider.send("personal_sign", [
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["hexlify"])(message),
            this.address.toLowerCase()
        ]);
    }
    async signTypedData(domain, types, _value) {
        const value = deepCopy(_value);
        // Populate any ENS names (in-place)
        const populated = await __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$hash$2f$typed$2d$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["TypedDataEncoder"].resolveNames(domain, types, value, async (value)=>{
            const address = await (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$checks$2e$js__$5b$client$5d$__$28$ecmascript$29$__["resolveAddress"])(value);
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(address != null, "TypedData does not support null address", "value", value);
            return address;
        });
        return await this.provider.send("eth_signTypedData_v4", [
            this.address.toLowerCase(),
            JSON.stringify(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$hash$2f$typed$2d$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["TypedDataEncoder"].getPayload(populated.domain, types, populated.value))
        ]);
    }
    async unlock(password) {
        return this.provider.send("personal_unlockAccount", [
            this.address.toLowerCase(),
            password,
            null
        ]);
    }
    // https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign
    async _legacySignMessage(_message) {
        const message = typeof _message === "string" ? (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$utf8$2e$js__$5b$client$5d$__$28$ecmascript$29$__["toUtf8Bytes"])(_message) : _message;
        return await this.provider.send("eth_sign", [
            this.address.toLowerCase(),
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["hexlify"])(message)
        ]);
    }
}
class JsonRpcApiProvider extends __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$abstract$2d$provider$2e$js__$5b$client$5d$__$28$ecmascript$29$__["AbstractProvider"] {
    #options;
    // The next ID to use for the JSON-RPC ID field
    #nextId;
    // Payloads are queued and triggered in batches using the drainTimer
    #payloads;
    #drainTimer;
    #notReady;
    #network;
    #pendingDetectNetwork;
    #scheduleDrain() {
        if (this.#drainTimer) {
            return;
        }
        // If we aren't using batching, no harm in sending it immediately
        const stallTime = this._getOption("batchMaxCount") === 1 ? 0 : this._getOption("batchStallTime");
        this.#drainTimer = setTimeout(()=>{
            this.#drainTimer = null;
            const payloads = this.#payloads;
            this.#payloads = [];
            while(payloads.length){
                // Create payload batches that satisfy our batch constraints
                const batch = [
                    payloads.shift()
                ];
                while(payloads.length){
                    if (batch.length === this.#options.batchMaxCount) {
                        break;
                    }
                    batch.push(payloads.shift());
                    const bytes = JSON.stringify(batch.map((p)=>p.payload));
                    if (bytes.length > this.#options.batchMaxSize) {
                        payloads.unshift(batch.pop());
                        break;
                    }
                }
                // Process the result to each payload
                (async ()=>{
                    const payload = batch.length === 1 ? batch[0].payload : batch.map((p)=>p.payload);
                    this.emit("debug", {
                        action: "sendRpcPayload",
                        payload
                    });
                    try {
                        const result = await this._send(payload);
                        this.emit("debug", {
                            action: "receiveRpcResult",
                            result
                        });
                        // Process results in batch order
                        for (const { resolve, reject, payload } of batch){
                            if (this.destroyed) {
                                reject((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["makeError"])("provider destroyed; cancelled request", "UNSUPPORTED_OPERATION", {
                                    operation: payload.method
                                }));
                                continue;
                            }
                            // Find the matching result
                            const resp = result.filter((r)=>r.id === payload.id)[0];
                            // No result; the node failed us in unexpected ways
                            if (resp == null) {
                                const error = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["makeError"])("missing response for request", "BAD_DATA", {
                                    value: result,
                                    info: {
                                        payload
                                    }
                                });
                                this.emit("error", error);
                                reject(error);
                                continue;
                            }
                            // The response is an error
                            if ("error" in resp) {
                                reject(this.getRpcError(payload, resp));
                                continue;
                            }
                            // All good; send the result
                            resolve(resp.result);
                        }
                    } catch (error) {
                        this.emit("debug", {
                            action: "receiveRpcError",
                            error
                        });
                        for (const { reject } of batch){
                            // @TODO: augment the error with the payload
                            reject(error);
                        }
                    }
                })();
            }
        }, stallTime);
    }
    constructor(network, options){
        super(network, options);
        this.#nextId = 1;
        this.#options = Object.assign({}, defaultOptions, options || {});
        this.#payloads = [];
        this.#drainTimer = null;
        this.#network = null;
        this.#pendingDetectNetwork = null;
        {
            let resolve = null;
            const promise = new Promise((_resolve)=>{
                resolve = _resolve;
            });
            this.#notReady = {
                promise,
                resolve
            };
        }
        const staticNetwork = this._getOption("staticNetwork");
        if (typeof staticNetwork === "boolean") {
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(!staticNetwork || network !== "any", "staticNetwork cannot be used on special network 'any'", "options", options);
            if (staticNetwork && network != null) {
                this.#network = __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Network"].from(network);
            }
        } else if (staticNetwork) {
            // Make sure any static network is compatbile with the provided netwrok
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(network == null || staticNetwork.matches(network), "staticNetwork MUST match network object", "options", options);
            this.#network = staticNetwork;
        }
    }
    /**
     *  Returns the value associated with the option %%key%%.
     *
     *  Sub-classes can use this to inquire about configuration options.
     */ _getOption(key) {
        return this.#options[key];
    }
    /**
     *  Gets the [[Network]] this provider has committed to. On each call, the network
     *  is detected, and if it has changed, the call will reject.
     */ get _network() {
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(this.#network, "network is not available yet", "NETWORK_ERROR");
        return this.#network;
    }
    /**
     *  Resolves to the non-normalized value by performing %%req%%.
     *
     *  Sub-classes may override this to modify behavior of actions,
     *  and should generally call ``super._perform`` as a fallback.
     */ async _perform(req) {
        // Legacy networks do not like the type field being passed along (which
        // is fair), so we delete type if it is 0 and a non-EIP-1559 network
        if (req.method === "call" || req.method === "estimateGas") {
            let tx = req.transaction;
            if (tx && tx.type != null && (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"])(tx.type)) {
                // If there are no EIP-1559 or newer properties, it might be pre-EIP-1559
                if (tx.maxFeePerGas == null && tx.maxPriorityFeePerGas == null) {
                    const feeData = await this.getFeeData();
                    if (feeData.maxFeePerGas == null && feeData.maxPriorityFeePerGas == null) {
                        // Network doesn't know about EIP-1559 (and hence type)
                        req = Object.assign({}, req, {
                            transaction: Object.assign({}, tx, {
                                type: undefined
                            })
                        });
                    }
                }
            }
        }
        const request = this.getRpcRequest(req);
        if (request != null) {
            return await this.send(request.method, request.args);
        }
        return super._perform(req);
    }
    /**
     *  Sub-classes may override this; it detects the *actual* network that
     *  we are **currently** connected to.
     *
     *  Keep in mind that [[send]] may only be used once [[ready]], otherwise the
     *  _send primitive must be used instead.
     */ async _detectNetwork() {
        const network = this._getOption("staticNetwork");
        if (network) {
            if (network === true) {
                if (this.#network) {
                    return this.#network;
                }
            } else {
                return network;
            }
        }
        if (this.#pendingDetectNetwork) {
            return await this.#pendingDetectNetwork;
        }
        // If we are ready, use ``send``, which enabled requests to be batched
        if (this.ready) {
            this.#pendingDetectNetwork = (async ()=>{
                try {
                    const result = __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Network"].from((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"])(await this.send("eth_chainId", [])));
                    this.#pendingDetectNetwork = null;
                    return result;
                } catch (error) {
                    this.#pendingDetectNetwork = null;
                    throw error;
                }
            })();
            return await this.#pendingDetectNetwork;
        }
        // We are not ready yet; use the primitive _send
        this.#pendingDetectNetwork = (async ()=>{
            const payload = {
                id: this.#nextId++,
                method: "eth_chainId",
                params: [],
                jsonrpc: "2.0"
            };
            this.emit("debug", {
                action: "sendRpcPayload",
                payload
            });
            let result;
            try {
                result = (await this._send(payload))[0];
                this.#pendingDetectNetwork = null;
            } catch (error) {
                this.#pendingDetectNetwork = null;
                this.emit("debug", {
                    action: "receiveRpcError",
                    error
                });
                throw error;
            }
            this.emit("debug", {
                action: "receiveRpcResult",
                result
            });
            if ("result" in result) {
                return __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Network"].from((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"])(result.result));
            }
            throw this.getRpcError(payload, result);
        })();
        return await this.#pendingDetectNetwork;
    }
    /**
     *  Sub-classes **MUST** call this. Until [[_start]] has been called, no calls
     *  will be passed to [[_send]] from [[send]]. If it is overridden, then
     *  ``super._start()`` **MUST** be called.
     *
     *  Calling it multiple times is safe and has no effect.
     */ _start() {
        if (this.#notReady == null || this.#notReady.resolve == null) {
            return;
        }
        this.#notReady.resolve();
        this.#notReady = null;
        (async ()=>{
            // Bootstrap the network
            while(this.#network == null && !this.destroyed){
                try {
                    this.#network = await this._detectNetwork();
                } catch (error) {
                    if (this.destroyed) {
                        break;
                    }
                    console.log("JsonRpcProvider failed to detect network and cannot start up; retry in 1s (perhaps the URL is wrong or the node is not started)");
                    this.emit("error", (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["makeError"])("failed to bootstrap network detection", "NETWORK_ERROR", {
                        event: "initial-network-discovery",
                        info: {
                            error
                        }
                    }));
                    await stall(1000);
                }
            }
            // Start dispatching requests
            this.#scheduleDrain();
        })();
    }
    /**
     *  Resolves once the [[_start]] has been called. This can be used in
     *  sub-classes to defer sending data until the connection has been
     *  established.
     */ async _waitUntilReady() {
        if (this.#notReady == null) {
            return;
        }
        return await this.#notReady.promise;
    }
    /**
     *  Return a Subscriber that will manage the %%sub%%.
     *
     *  Sub-classes may override this to modify the behavior of
     *  subscription management.
     */ _getSubscriber(sub) {
        // Pending Filters aren't availble via polling
        if (sub.type === "pending") {
            return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$subscriber$2d$filterid$2e$js__$5b$client$5d$__$28$ecmascript$29$__["FilterIdPendingSubscriber"](this);
        }
        if (sub.type === "event") {
            if (this._getOption("polling")) {
                return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$subscriber$2d$polling$2e$js__$5b$client$5d$__$28$ecmascript$29$__["PollingEventSubscriber"](this, sub.filter);
            }
            return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$subscriber$2d$filterid$2e$js__$5b$client$5d$__$28$ecmascript$29$__["FilterIdEventSubscriber"](this, sub.filter);
        }
        // Orphaned Logs are handled automatically, by the filter, since
        // logs with removed are emitted by it
        if (sub.type === "orphan" && sub.filter.orphan === "drop-log") {
            return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$abstract$2d$provider$2e$js__$5b$client$5d$__$28$ecmascript$29$__["UnmanagedSubscriber"]("orphan");
        }
        return super._getSubscriber(sub);
    }
    /**
     *  Returns true only if the [[_start]] has been called.
     */ get ready() {
        return this.#notReady == null;
    }
    /**
     *  Returns %%tx%% as a normalized JSON-RPC transaction request,
     *  which has all values hexlified and any numeric values converted
     *  to Quantity values.
     */ getRpcTransaction(tx) {
        const result = {};
        // JSON-RPC now requires numeric values to be "quantity" values
        [
            "chainId",
            "gasLimit",
            "gasPrice",
            "type",
            "maxFeePerGas",
            "maxPriorityFeePerGas",
            "nonce",
            "value"
        ].forEach((key)=>{
            if (tx[key] == null) {
                return;
            }
            let dstKey = key;
            if (key === "gasLimit") {
                dstKey = "gas";
            }
            result[dstKey] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["toQuantity"])((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"])(tx[key], `tx.${key}`));
        });
        // Make sure addresses and data are lowercase
        [
            "from",
            "to",
            "data"
        ].forEach((key)=>{
            if (tx[key] == null) {
                return;
            }
            result[key] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["hexlify"])(tx[key]);
        });
        // Normalize the access list object
        if (tx.accessList) {
            result["accessList"] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$transaction$2f$accesslist$2e$js__$5b$client$5d$__$28$ecmascript$29$__["accessListify"])(tx.accessList);
        }
        if (tx.blobVersionedHashes) {
            // @TODO: Remove this <any> case once EIP-4844 added to prepared tx
            result["blobVersionedHashes"] = tx.blobVersionedHashes.map((h)=>h.toLowerCase());
        }
        if (tx.authorizationList) {
            result["authorizationList"] = tx.authorizationList.map((_a)=>{
                const a = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$transaction$2f$authorization$2e$js__$5b$client$5d$__$28$ecmascript$29$__["authorizationify"])(_a);
                return {
                    address: a.address,
                    nonce: (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["toQuantity"])(a.nonce),
                    chainId: (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["toQuantity"])(a.chainId),
                    yParity: (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["toQuantity"])(a.signature.yParity),
                    r: (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["toQuantity"])(a.signature.r),
                    s: (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["toQuantity"])(a.signature.s)
                };
            });
        }
        // @TODO: blobs should probably also be copied over, optionally
        // accounting for the kzg property to backfill blobVersionedHashes
        // using the commitment. Or should that be left as an exercise to
        // the caller?
        return result;
    }
    /**
     *  Returns the request method and arguments required to perform
     *  %%req%%.
     */ getRpcRequest(req) {
        switch(req.method){
            case "chainId":
                return {
                    method: "eth_chainId",
                    args: []
                };
            case "getBlockNumber":
                return {
                    method: "eth_blockNumber",
                    args: []
                };
            case "getGasPrice":
                return {
                    method: "eth_gasPrice",
                    args: []
                };
            case "getPriorityFee":
                return {
                    method: "eth_maxPriorityFeePerGas",
                    args: []
                };
            case "getBalance":
                return {
                    method: "eth_getBalance",
                    args: [
                        getLowerCase(req.address),
                        req.blockTag
                    ]
                };
            case "getTransactionCount":
                return {
                    method: "eth_getTransactionCount",
                    args: [
                        getLowerCase(req.address),
                        req.blockTag
                    ]
                };
            case "getCode":
                return {
                    method: "eth_getCode",
                    args: [
                        getLowerCase(req.address),
                        req.blockTag
                    ]
                };
            case "getStorage":
                return {
                    method: "eth_getStorageAt",
                    args: [
                        getLowerCase(req.address),
                        "0x" + req.position.toString(16),
                        req.blockTag
                    ]
                };
            case "broadcastTransaction":
                return {
                    method: "eth_sendRawTransaction",
                    args: [
                        req.signedTransaction
                    ]
                };
            case "getBlock":
                if ("blockTag" in req) {
                    return {
                        method: "eth_getBlockByNumber",
                        args: [
                            req.blockTag,
                            !!req.includeTransactions
                        ]
                    };
                } else if ("blockHash" in req) {
                    return {
                        method: "eth_getBlockByHash",
                        args: [
                            req.blockHash,
                            !!req.includeTransactions
                        ]
                    };
                }
                break;
            case "getTransaction":
                return {
                    method: "eth_getTransactionByHash",
                    args: [
                        req.hash
                    ]
                };
            case "getTransactionReceipt":
                return {
                    method: "eth_getTransactionReceipt",
                    args: [
                        req.hash
                    ]
                };
            case "call":
                return {
                    method: "eth_call",
                    args: [
                        this.getRpcTransaction(req.transaction),
                        req.blockTag
                    ]
                };
            case "estimateGas":
                {
                    return {
                        method: "eth_estimateGas",
                        args: [
                            this.getRpcTransaction(req.transaction)
                        ]
                    };
                }
            case "getLogs":
                if (req.filter && req.filter.address != null) {
                    if (Array.isArray(req.filter.address)) {
                        req.filter.address = req.filter.address.map(getLowerCase);
                    } else {
                        req.filter.address = getLowerCase(req.filter.address);
                    }
                }
                return {
                    method: "eth_getLogs",
                    args: [
                        req.filter
                    ]
                };
        }
        return null;
    }
    /**
     *  Returns an ethers-style Error for the given JSON-RPC error
     *  %%payload%%, coalescing the various strings and error shapes
     *  that different nodes return, coercing them into a machine-readable
     *  standardized error.
     */ getRpcError(payload, _error) {
        const { method } = payload;
        const { error } = _error;
        if (method === "eth_estimateGas" && error.message) {
            const msg = error.message;
            if (!msg.match(/revert/i) && msg.match(/insufficient funds/i)) {
                return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["makeError"])("insufficient funds", "INSUFFICIENT_FUNDS", {
                    transaction: payload.params[0],
                    info: {
                        payload,
                        error
                    }
                });
            } else if (msg.match(/nonce/i) && msg.match(/too low/i)) {
                return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["makeError"])("nonce has already been used", "NONCE_EXPIRED", {
                    transaction: payload.params[0],
                    info: {
                        payload,
                        error
                    }
                });
            }
        }
        if (method === "eth_call" || method === "eth_estimateGas") {
            const result = spelunkData(error);
            const e = __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$abi$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__["AbiCoder"].getBuiltinCallException(method === "eth_call" ? "call" : "estimateGas", payload.params[0], result ? result.data : null);
            e.info = {
                error,
                payload
            };
            return e;
        }
        // Only estimateGas and call can return arbitrary contract-defined text, so now we
        // we can process text safely.
        const message = JSON.stringify(spelunkMessage(error));
        if (typeof error.message === "string" && error.message.match(/user denied|ethers-user-denied/i)) {
            const actionMap = {
                eth_sign: "signMessage",
                personal_sign: "signMessage",
                eth_signTypedData_v4: "signTypedData",
                eth_signTransaction: "signTransaction",
                eth_sendTransaction: "sendTransaction",
                eth_requestAccounts: "requestAccess",
                wallet_requestAccounts: "requestAccess"
            };
            return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["makeError"])(`user rejected action`, "ACTION_REJECTED", {
                action: actionMap[method] || "unknown",
                reason: "rejected",
                info: {
                    payload,
                    error
                }
            });
        }
        if (method === "eth_sendRawTransaction" || method === "eth_sendTransaction") {
            const transaction = payload.params[0];
            if (message.match(/insufficient funds|base fee exceeds gas limit/i)) {
                return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["makeError"])("insufficient funds for intrinsic transaction cost", "INSUFFICIENT_FUNDS", {
                    transaction,
                    info: {
                        error
                    }
                });
            }
            if (message.match(/nonce/i) && message.match(/too low/i)) {
                return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["makeError"])("nonce has already been used", "NONCE_EXPIRED", {
                    transaction,
                    info: {
                        error
                    }
                });
            }
            // "replacement transaction underpriced"
            if (message.match(/replacement transaction/i) && message.match(/underpriced/i)) {
                return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["makeError"])("replacement fee too low", "REPLACEMENT_UNDERPRICED", {
                    transaction,
                    info: {
                        error
                    }
                });
            }
            if (message.match(/only replay-protected/i)) {
                return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["makeError"])("legacy pre-eip-155 transactions not supported", "UNSUPPORTED_OPERATION", {
                    operation: method,
                    info: {
                        transaction,
                        info: {
                            error
                        }
                    }
                });
            }
        }
        let unsupported = !!message.match(/the method .* does not exist/i);
        if (!unsupported) {
            if (error && error.details && error.details.startsWith("Unauthorized method:")) {
                unsupported = true;
            }
        }
        if (unsupported) {
            return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["makeError"])("unsupported operation", "UNSUPPORTED_OPERATION", {
                operation: payload.method,
                info: {
                    error,
                    payload
                }
            });
        }
        return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["makeError"])("could not coalesce error", "UNKNOWN_ERROR", {
            error,
            payload
        });
    }
    /**
     *  Requests the %%method%% with %%params%% via the JSON-RPC protocol
     *  over the underlying channel. This can be used to call methods
     *  on the backend that do not have a high-level API within the Provider
     *  API.
     *
     *  This method queues requests according to the batch constraints
     *  in the options, assigns the request a unique ID.
     *
     *  **Do NOT override** this method in sub-classes; instead
     *  override [[_send]] or force the options values in the
     *  call to the constructor to modify this method's behavior.
     */ send(method, params) {
        // @TODO: cache chainId?? purge on switch_networks
        // We have been destroyed; no operations are supported anymore
        if (this.destroyed) {
            return Promise.reject((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["makeError"])("provider destroyed; cancelled request", "UNSUPPORTED_OPERATION", {
                operation: method
            }));
        }
        const id = this.#nextId++;
        const promise = new Promise((resolve, reject)=>{
            this.#payloads.push({
                resolve,
                reject,
                payload: {
                    method,
                    params,
                    id,
                    jsonrpc: "2.0"
                }
            });
        });
        // If there is not a pending drainTimer, set one
        this.#scheduleDrain();
        return promise;
    }
    /**
     *  Resolves to the [[Signer]] account for  %%address%% managed by
     *  the client.
     *
     *  If the %%address%% is a number, it is used as an index in the
     *  the accounts from [[listAccounts]].
     *
     *  This can only be used on clients which manage accounts (such as
     *  Geth with imported account or MetaMask).
     *
     *  Throws if the account doesn't exist.
     */ async getSigner(address) {
        if (address == null) {
            address = 0;
        }
        const accountsPromise = this.send("eth_accounts", []);
        // Account index
        if (typeof address === "number") {
            const accounts = await accountsPromise;
            if (address >= accounts.length) {
                throw new Error("no such account");
            }
            return new JsonRpcSigner(this, accounts[address]);
        }
        const { accounts } = await (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["resolveProperties"])({
            network: this.getNetwork(),
            accounts: accountsPromise
        });
        // Account address
        address = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$address$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getAddress"])(address);
        for (const account of accounts){
            if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$address$2f$address$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getAddress"])(account) === address) {
                return new JsonRpcSigner(this, address);
            }
        }
        throw new Error("invalid account");
    }
    async listAccounts() {
        const accounts = await this.send("eth_accounts", []);
        return accounts.map((a)=>new JsonRpcSigner(this, a));
    }
    destroy() {
        // Stop processing requests
        if (this.#drainTimer) {
            clearTimeout(this.#drainTimer);
            this.#drainTimer = null;
        }
        // Cancel all pending requests
        for (const { payload, reject } of this.#payloads){
            reject((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["makeError"])("provider destroyed; cancelled request", "UNSUPPORTED_OPERATION", {
                operation: payload.method
            }));
        }
        this.#payloads = [];
        // Parent clean-up
        super.destroy();
    }
}
class JsonRpcApiPollingProvider extends JsonRpcApiProvider {
    #pollingInterval;
    constructor(network, options){
        super(network, options);
        let pollingInterval = this._getOption("pollingInterval");
        if (pollingInterval == null) {
            pollingInterval = defaultOptions.pollingInterval;
        }
        this.#pollingInterval = pollingInterval;
    }
    _getSubscriber(sub) {
        const subscriber = super._getSubscriber(sub);
        if (isPollable(subscriber)) {
            subscriber.pollingInterval = this.#pollingInterval;
        }
        return subscriber;
    }
    /**
     *  The polling interval (default: 4000 ms)
     */ get pollingInterval() {
        return this.#pollingInterval;
    }
    set pollingInterval(value) {
        if (!Number.isInteger(value) || value < 0) {
            throw new Error("invalid interval");
        }
        this.#pollingInterval = value;
        this._forEachSubscriber((sub)=>{
            if (isPollable(sub)) {
                sub.pollingInterval = this.#pollingInterval;
            }
        });
    }
}
class JsonRpcProvider extends JsonRpcApiPollingProvider {
    #connect;
    constructor(url, network, options){
        if (url == null) {
            url = "http:/\/localhost:8545";
        }
        super(network, options);
        if (typeof url === "string") {
            this.#connect = new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$fetch$2e$js__$5b$client$5d$__$28$ecmascript$29$__["FetchRequest"](url);
        } else {
            this.#connect = url.clone();
        }
    }
    _getConnection() {
        return this.#connect.clone();
    }
    async send(method, params) {
        // All requests are over HTTP, so we can just start handling requests
        // We do this here rather than the constructor so that we don't send any
        // requests to the network (i.e. eth_chainId) until we absolutely have to.
        await this._start();
        return await super.send(method, params);
    }
    async _send(payload) {
        // Configure a POST connection for the requested method
        const request = this._getConnection();
        request.body = JSON.stringify(payload);
        request.setHeader("content-type", "application/json");
        const response = await request.send();
        response.assertOk();
        let resp = response.bodyJson;
        if (!Array.isArray(resp)) {
            resp = [
                resp
            ];
        }
        return resp;
    }
}
function spelunkData(value) {
    if (value == null) {
        return null;
    }
    // These *are* the droids we're looking for.
    if (typeof value.message === "string" && value.message.match(/revert/i) && (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isHexString"])(value.data)) {
        return {
            message: value.message,
            data: value.data
        };
    }
    // Spelunk further...
    if (typeof value === "object") {
        for(const key in value){
            const result = spelunkData(value[key]);
            if (result) {
                return result;
            }
        }
        return null;
    }
    // Might be a JSON string we can further descend...
    if (typeof value === "string") {
        try {
            return spelunkData(JSON.parse(value));
        } catch (error) {}
    }
    return null;
}
function _spelunkMessage(value, result) {
    if (value == null) {
        return;
    }
    // These *are* the droids we're looking for.
    if (typeof value.message === "string") {
        result.push(value.message);
    }
    // Spelunk further...
    if (typeof value === "object") {
        for(const key in value){
            _spelunkMessage(value[key], result);
        }
    }
    // Might be a JSON string we can further descend...
    if (typeof value === "string") {
        try {
            return _spelunkMessage(JSON.parse(value), result);
        } catch (error) {}
    }
}
function spelunkMessage(value) {
    const result = [];
    _spelunkMessage(value, result);
    return result;
} //# sourceMappingURL=provider-jsonrpc.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-ankr.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "AnkrProvider",
    ()=>AnkrProvider
]);
/**
 *  [[link-ankr]] provides a third-party service for connecting to
 *  various blockchains over JSON-RPC.
 *
 *  **Supported Networks**
 *
 *  - Ethereum Mainnet (``mainnet``)
 *  - Goerli Testnet (``goerli``)
 *  - Sepolia Testnet (``sepolia``)
 *  - Arbitrum (``arbitrum``)
 *  - Base (``base``)
 *  - Base Goerlia Testnet (``base-goerli``)
 *  - Base Sepolia Testnet (``base-sepolia``)
 *  - BNB (``bnb``)
 *  - BNB Testnet (``bnbt``)
 *  - Filecoin (``filecoin``)
 *  - Filecoin Calibration Testnet (``filecoin-calibration``)
 *  - Optimism (``optimism``)
 *  - Optimism Goerli Testnet (``optimism-goerli``)
 *  - Optimism Sepolia Testnet (``optimism-sepolia``)
 *  - Polygon (``matic``)
 *  - Polygon Mumbai Testnet (``matic-mumbai``)
 *
 *  @_subsection: api/providers/thirdparty:Ankr  [providers-ankr]
 */ var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/properties.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$fetch$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/fetch.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/errors.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$community$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/community.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/network.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$jsonrpc$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-jsonrpc.js [client] (ecmascript)");
;
;
;
;
const defaultApiKey = "9f7d929b018cdffb338517efa06f58359e86ff1ffd350bc889738523659e7972";
function getHost(name) {
    switch(name){
        case "mainnet":
            return "rpc.ankr.com/eth";
        case "goerli":
            return "rpc.ankr.com/eth_goerli";
        case "sepolia":
            return "rpc.ankr.com/eth_sepolia";
        case "arbitrum":
            return "rpc.ankr.com/arbitrum";
        case "base":
            return "rpc.ankr.com/base";
        case "base-goerli":
            return "rpc.ankr.com/base_goerli";
        case "base-sepolia":
            return "rpc.ankr.com/base_sepolia";
        case "bnb":
            return "rpc.ankr.com/bsc";
        case "bnbt":
            return "rpc.ankr.com/bsc_testnet_chapel";
        case "filecoin":
            return "rpc.ankr.com/filecoin";
        case "filecoin-calibration":
            return "rpc.ankr.com/filecoin_testnet";
        case "matic":
            return "rpc.ankr.com/polygon";
        case "matic-mumbai":
            return "rpc.ankr.com/polygon_mumbai";
        case "optimism":
            return "rpc.ankr.com/optimism";
        case "optimism-goerli":
            return "rpc.ankr.com/optimism_testnet";
        case "optimism-sepolia":
            return "rpc.ankr.com/optimism_sepolia";
    }
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, "unsupported network", "network", name);
}
class AnkrProvider extends __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$jsonrpc$2e$js__$5b$client$5d$__$28$ecmascript$29$__["JsonRpcProvider"] {
    /**
     *  The API key for the Ankr connection.
     */ apiKey;
    /**
     *  Create a new **AnkrProvider**.
     *
     *  By default connecting to ``mainnet`` with a highly throttled
     *  API key.
     */ constructor(_network, apiKey){
        if (_network == null) {
            _network = "mainnet";
        }
        const network = __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Network"].from(_network);
        if (apiKey == null) {
            apiKey = defaultApiKey;
        }
        // Ankr does not support filterId, so we force polling
        const options = {
            polling: true,
            staticNetwork: network
        };
        const request = AnkrProvider.getRequest(network, apiKey);
        super(request, network, options);
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            apiKey
        });
    }
    _getProvider(chainId) {
        try {
            return new AnkrProvider(chainId, this.apiKey);
        } catch (error) {}
        return super._getProvider(chainId);
    }
    /**
     *  Returns a prepared request for connecting to %%network%% with
     *  %%apiKey%%.
     */ static getRequest(network, apiKey) {
        if (apiKey == null) {
            apiKey = defaultApiKey;
        }
        const request = new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$fetch$2e$js__$5b$client$5d$__$28$ecmascript$29$__["FetchRequest"](`https:/\/${getHost(network.name)}/${apiKey}`);
        request.allowGzip = true;
        if (apiKey === defaultApiKey) {
            request.retryFunc = async (request, response, attempt)=>{
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$community$2e$js__$5b$client$5d$__$28$ecmascript$29$__["showThrottleMessage"])("AnkrProvider");
                return true;
            };
        }
        return request;
    }
    getRpcError(payload, error) {
        if (payload.method === "eth_sendRawTransaction") {
            if (error && error.error && error.error.message === "INTERNAL_ERROR: could not replace existing tx") {
                error.error.message = "replacement transaction underpriced";
            }
        }
        return super.getRpcError(payload, error);
    }
    isCommunityResource() {
        return this.apiKey === defaultApiKey;
    }
} //# sourceMappingURL=provider-ankr.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-alchemy.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "AlchemyProvider",
    ()=>AlchemyProvider
]);
/**
 *  [[link-alchemy]] provides a third-party service for connecting to
 *  various blockchains over JSON-RPC.
 *
 *  **Supported Networks**
 *
 *  - Ethereum Mainnet (``mainnet``)
 *  - Goerli Testnet (``goerli``)
 *  - Sepolia Testnet (``sepolia``)
 *  - Arbitrum (``arbitrum``)
 *  - Arbitrum Goerli Testnet (``arbitrum-goerli``)
 *  - Arbitrum Sepolia Testnet (``arbitrum-sepolia``)
 *  - Base (``base``)
 *  - Base Goerlia Testnet (``base-goerli``)
 *  - Base Sepolia Testnet (``base-sepolia``)
 *  - Optimism (``optimism``)
 *  - Optimism Goerli Testnet (``optimism-goerli``)
 *  - Optimism Sepolia Testnet (``optimism-sepolia``)
 *  - Polygon (``matic``)
 *  - Polygon Amoy Testnet (``matic-amoy``)
 *  - Polygon Mumbai Testnet (``matic-mumbai``)
 *
 *  @_subsection: api/providers/thirdparty:Alchemy  [providers-alchemy]
 */ var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/properties.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/errors.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$fetch$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/fetch.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$community$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/community.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/network.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$jsonrpc$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-jsonrpc.js [client] (ecmascript)");
;
;
;
;
const defaultApiKey = "_gg7wSSi0KMBsdKnGVfHDueq6xMB9EkC";
function getHost(name) {
    switch(name){
        case "mainnet":
            return "eth-mainnet.g.alchemy.com";
        case "goerli":
            return "eth-goerli.g.alchemy.com";
        case "sepolia":
            return "eth-sepolia.g.alchemy.com";
        case "arbitrum":
            return "arb-mainnet.g.alchemy.com";
        case "arbitrum-goerli":
            return "arb-goerli.g.alchemy.com";
        case "arbitrum-sepolia":
            return "arb-sepolia.g.alchemy.com";
        case "base":
            return "base-mainnet.g.alchemy.com";
        case "base-goerli":
            return "base-goerli.g.alchemy.com";
        case "base-sepolia":
            return "base-sepolia.g.alchemy.com";
        case "matic":
            return "polygon-mainnet.g.alchemy.com";
        case "matic-amoy":
            return "polygon-amoy.g.alchemy.com";
        case "matic-mumbai":
            return "polygon-mumbai.g.alchemy.com";
        case "optimism":
            return "opt-mainnet.g.alchemy.com";
        case "optimism-goerli":
            return "opt-goerli.g.alchemy.com";
        case "optimism-sepolia":
            return "opt-sepolia.g.alchemy.com";
    }
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, "unsupported network", "network", name);
}
class AlchemyProvider extends __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$jsonrpc$2e$js__$5b$client$5d$__$28$ecmascript$29$__["JsonRpcProvider"] {
    apiKey;
    constructor(_network, apiKey){
        if (_network == null) {
            _network = "mainnet";
        }
        const network = __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Network"].from(_network);
        if (apiKey == null) {
            apiKey = defaultApiKey;
        }
        const request = AlchemyProvider.getRequest(network, apiKey);
        super(request, network, {
            staticNetwork: network
        });
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            apiKey
        });
    }
    _getProvider(chainId) {
        try {
            return new AlchemyProvider(chainId, this.apiKey);
        } catch (error) {}
        return super._getProvider(chainId);
    }
    async _perform(req) {
        // https://docs.alchemy.com/reference/trace-transaction
        if (req.method === "getTransactionResult") {
            const { trace, tx } = await (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["resolveProperties"])({
                trace: this.send("trace_transaction", [
                    req.hash
                ]),
                tx: this.getTransaction(req.hash)
            });
            if (trace == null || tx == null) {
                return null;
            }
            let data;
            let error = false;
            try {
                data = trace[0].result.output;
                error = trace[0].error === "Reverted";
            } catch (error) {}
            if (data) {
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(!error, "an error occurred during transaction executions", "CALL_EXCEPTION", {
                    action: "getTransactionResult",
                    data,
                    reason: null,
                    transaction: tx,
                    invocation: null,
                    revert: null // @TODO
                });
                return data;
            }
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, "could not parse trace result", "BAD_DATA", {
                value: trace
            });
        }
        return await super._perform(req);
    }
    isCommunityResource() {
        return this.apiKey === defaultApiKey;
    }
    static getRequest(network, apiKey) {
        if (apiKey == null) {
            apiKey = defaultApiKey;
        }
        const request = new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$fetch$2e$js__$5b$client$5d$__$28$ecmascript$29$__["FetchRequest"](`https:/\/${getHost(network.name)}/v2/${apiKey}`);
        request.allowGzip = true;
        if (apiKey === defaultApiKey) {
            request.retryFunc = async (request, response, attempt)=>{
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$community$2e$js__$5b$client$5d$__$28$ecmascript$29$__["showThrottleMessage"])("alchemy");
                return true;
            };
        }
        return request;
    }
} //# sourceMappingURL=provider-alchemy.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-chainstack.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "ChainstackProvider",
    ()=>ChainstackProvider
]);
/**
 *  [[link-chainstack]] provides a third-party service for connecting to
 *  various blockchains over JSON-RPC.
 *
 *  **Supported Networks**
 *
 *  - Ethereum Mainnet (``mainnet``)
 *  - Arbitrum (``arbitrum``)
 *  - BNB Smart Chain Mainnet (``bnb``)
 *  - Polygon (``matic``)
 *
 *  @_subsection: api/providers/thirdparty:Chainstack  [providers-chainstack]
 */ var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/properties.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$fetch$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/fetch.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/errors.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$community$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/community.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/network.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$jsonrpc$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-jsonrpc.js [client] (ecmascript)");
;
;
;
;
function getApiKey(name) {
    switch(name){
        case "mainnet":
            return "39f1d67cedf8b7831010a665328c9197";
        case "arbitrum":
            return "0550c209db33c3abf4cc927e1e18cea1";
        case "bnb":
            return "98b5a77e531614387366f6fc5da097f8";
        case "matic":
            return "cd9d4d70377471aa7c142ec4a4205249";
    }
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, "unsupported network", "network", name);
}
function getHost(name) {
    switch(name){
        case "mainnet":
            return "ethereum-mainnet.core.chainstack.com";
        case "arbitrum":
            return "arbitrum-mainnet.core.chainstack.com";
        case "bnb":
            return "bsc-mainnet.core.chainstack.com";
        case "matic":
            return "polygon-mainnet.core.chainstack.com";
    }
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, "unsupported network", "network", name);
}
class ChainstackProvider extends __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$jsonrpc$2e$js__$5b$client$5d$__$28$ecmascript$29$__["JsonRpcProvider"] {
    /**
     *  The API key for the Chainstack connection.
     */ apiKey;
    /**
     *  Creates a new **ChainstackProvider**.
     */ constructor(_network, apiKey){
        if (_network == null) {
            _network = "mainnet";
        }
        const network = __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Network"].from(_network);
        if (apiKey == null) {
            apiKey = getApiKey(network.name);
        }
        const request = ChainstackProvider.getRequest(network, apiKey);
        super(request, network, {
            staticNetwork: network
        });
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            apiKey
        });
    }
    _getProvider(chainId) {
        try {
            return new ChainstackProvider(chainId, this.apiKey);
        } catch (error) {}
        return super._getProvider(chainId);
    }
    isCommunityResource() {
        return this.apiKey === getApiKey(this._network.name);
    }
    /**
     *  Returns a prepared request for connecting to %%network%%
     *  with %%apiKey%% and %%projectSecret%%.
     */ static getRequest(network, apiKey) {
        if (apiKey == null) {
            apiKey = getApiKey(network.name);
        }
        const request = new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$fetch$2e$js__$5b$client$5d$__$28$ecmascript$29$__["FetchRequest"](`https:/\/${getHost(network.name)}/${apiKey}`);
        request.allowGzip = true;
        if (apiKey === getApiKey(network.name)) {
            request.retryFunc = async (request, response, attempt)=>{
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$community$2e$js__$5b$client$5d$__$28$ecmascript$29$__["showThrottleMessage"])("ChainstackProvider");
                return true;
            };
        }
        return request;
    }
} //# sourceMappingURL=provider-chainstack.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-cloudflare.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "CloudflareProvider",
    ()=>CloudflareProvider
]);
/**
 *  About Cloudflare
 *
 *  @_subsection: api/providers/thirdparty:Cloudflare  [providers-cloudflare]
 */ var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/errors.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/network.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$jsonrpc$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-jsonrpc.js [client] (ecmascript)");
;
;
;
class CloudflareProvider extends __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$jsonrpc$2e$js__$5b$client$5d$__$28$ecmascript$29$__["JsonRpcProvider"] {
    constructor(_network){
        if (_network == null) {
            _network = "mainnet";
        }
        const network = __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Network"].from(_network);
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(network.name === "mainnet", "unsupported network", "network", _network);
        super("https:/\/cloudflare-eth.com/", network, {
            staticNetwork: network
        });
    }
} //# sourceMappingURL=provider-cloudflare.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-etherscan.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "EtherscanPlugin",
    ()=>EtherscanPlugin,
    "EtherscanProvider",
    ()=>EtherscanProvider
]);
/**
 *  [[link-etherscan]] provides a third-party service for connecting to
 *  various blockchains over a combination of JSON-RPC and custom API
 *  endpoints.
 *
 *  **Supported Networks**
 *
 *  - Ethereum Mainnet (``mainnet``)
 *  - Goerli Testnet (``goerli``)
 *  - Sepolia Testnet (``sepolia``)
 *  - Holesky Testnet (``holesky``)
 *  - Arbitrum (``arbitrum``)
 *  - Arbitrum Goerli Testnet (``arbitrum-goerli``)
 *  - Base (``base``)
 *  - Base Sepolia Testnet (``base-sepolia``)
 *  - BNB Smart Chain Mainnet (``bnb``)
 *  - BNB Smart Chain Testnet (``bnbt``)
 *  - Optimism (``optimism``)
 *  - Optimism Goerli Testnet (``optimism-goerli``)
 *  - Polygon (``matic``)
 *  - Polygon Mumbai Testnet (``matic-mumbai``)
 *  - Polygon Amoy Testnet (``matic-amoy``)
 *
 *  @_subsection api/providers/thirdparty:Etherscan  [providers-etherscan]
 */ var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$abi$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/abi/abi-coder.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$contract$2f$contract$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/contract/contract.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$transaction$2f$accesslist$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/transaction/accesslist.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$transaction$2f$transaction$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/transaction/transaction.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/properties.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/data.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/maths.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$fetch$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/fetch.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/errors.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$utf8$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/utf8.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$abstract$2d$provider$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/abstract-provider.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/network.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$plugins$2d$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/plugins-network.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$community$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/community.js [client] (ecmascript)");
;
;
;
;
;
;
;
;
// See: https://docs.etherscan.io/supported-chains
const Supported = ("1 11155111 17000 560048 2741 11124 33111 33139 42170 " + "42161 421614 43114 43113 8453 84532 80069 80094 199 1029 81457 " + "168587773 56 97 42220 11142220 252 2523 100 999 737373 747474 " + "59144 59141 5000 5003 43521 143 10143 1287 1284 1285 10 " + "11155420 204 5611 80002 137 534352 534351 1329 1328 146 14601 " + "988 2201 1923 1924 167013 167000 130 1301 480 4801 51 50 324 300").split(/ /g);
const THROTTLE = 2000;
function isPromise(value) {
    return value && typeof value.then === "function";
}
const EtherscanPluginId = "org.ethers.plugins.provider.Etherscan";
class EtherscanPlugin extends __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$plugins$2d$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__["NetworkPlugin"] {
    /**
     *  The Etherscan API base URL.
     */ baseUrl;
    /**
     *  Creates a new **EtherscanProvider** which will use
     *  %%baseUrl%%.
     */ constructor(baseUrl){
        super(EtherscanPluginId);
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            baseUrl
        });
    }
    clone() {
        return new EtherscanPlugin(this.baseUrl);
    }
}
const skipKeys = [
    "enableCcipRead"
];
let nextId = 1;
class EtherscanProvider extends __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$abstract$2d$provider$2e$js__$5b$client$5d$__$28$ecmascript$29$__["AbstractProvider"] {
    /**
     *  The connected network.
     */ network;
    /**
     *  The API key or null if using the community provided bandwidth.
     */ apiKey;
    #plugin;
    /**
     *  Creates a new **EtherscanBaseProvider**.
     */ constructor(_network, _apiKey){
        const apiKey = _apiKey != null ? _apiKey : null;
        super();
        const network = __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Network"].from(_network);
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(Supported.indexOf(`${network.chainId}`) >= 0, "unsupported network", "network", network);
        this.#plugin = network.getPlugin(EtherscanPluginId);
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            apiKey,
            network
        });
    }
    /**
     *  Returns the base URL.
     *
     *  If an [[EtherscanPlugin]] is configured on the
     *  [[EtherscanBaseProvider_network]], returns the plugin's
     *  baseUrl.
     *
     *  Deprecated; for Etherscan v2 the base is no longer a simply
     *  host, but instead a URL including a chainId parameter. Changing
     *  this to return a URL prefix could break some libraries, so it
     *  is left intact but will be removed in the future as it is unused.
     */ getBaseUrl() {
        if (this.#plugin) {
            return this.#plugin.baseUrl;
        }
        switch(this.network.name){
            case "mainnet":
                return "https:/\/api.etherscan.io";
            case "goerli":
                return "https:/\/api-goerli.etherscan.io";
            case "sepolia":
                return "https:/\/api-sepolia.etherscan.io";
            case "holesky":
                return "https:/\/api-holesky.etherscan.io";
            case "arbitrum":
                return "https:/\/api.arbiscan.io";
            case "arbitrum-goerli":
                return "https:/\/api-goerli.arbiscan.io";
            case "base":
                return "https:/\/api.basescan.org";
            case "base-sepolia":
                return "https:/\/api-sepolia.basescan.org";
            case "bnb":
                return "https:/\/api.bscscan.com";
            case "bnbt":
                return "https:/\/api-testnet.bscscan.com";
            case "matic":
                return "https:/\/api.polygonscan.com";
            case "matic-amoy":
                return "https:/\/api-amoy.polygonscan.com";
            case "matic-mumbai":
                return "https:/\/api-testnet.polygonscan.com";
            case "optimism":
                return "https:/\/api-optimistic.etherscan.io";
            case "optimism-goerli":
                return "https:/\/api-goerli-optimistic.etherscan.io";
            default:
        }
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, "unsupported network", "network", this.network);
    }
    /**
     *  Returns the URL for the %%module%% and %%params%%.
     */ getUrl(module, params) {
        let query = Object.keys(params).reduce((accum, key)=>{
            const value = params[key];
            if (value != null) {
                accum += `&${key}=${value}`;
            }
            return accum;
        }, "");
        if (this.apiKey) {
            query += `&apikey=${this.apiKey}`;
        }
        return `https:/\/api.etherscan.io/v2/api?chainid=${this.network.chainId}&module=${module}${query}`;
    }
    /**
     *  Returns the URL for using POST requests.
     */ getPostUrl() {
        return `https:/\/api.etherscan.io/v2/api?chainid=${this.network.chainId}`;
    }
    /**
     *  Returns the parameters for using POST requests.
     */ getPostData(module, params) {
        params.module = module;
        params.apikey = this.apiKey;
        params.chainid = this.network.chainId;
        return params;
    }
    async detectNetwork() {
        return this.network;
    }
    /**
     *  Resolves to the result of calling %%module%% with %%params%%.
     *
     *  If %%post%%, the request is made as a POST request.
     */ async fetch(module, params, post) {
        const id = nextId++;
        const url = post ? this.getPostUrl() : this.getUrl(module, params);
        const payload = post ? this.getPostData(module, params) : null;
        this.emit("debug", {
            action: "sendRequest",
            id,
            url,
            payload: payload
        });
        const request = new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$fetch$2e$js__$5b$client$5d$__$28$ecmascript$29$__["FetchRequest"](url);
        request.setThrottleParams({
            slotInterval: 1000
        });
        request.retryFunc = (req, resp, attempt)=>{
            if (this.isCommunityResource()) {
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$community$2e$js__$5b$client$5d$__$28$ecmascript$29$__["showThrottleMessage"])("Etherscan");
            }
            return Promise.resolve(true);
        };
        request.processFunc = async (request, response)=>{
            const result = response.hasBody() ? JSON.parse((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$utf8$2e$js__$5b$client$5d$__$28$ecmascript$29$__["toUtf8String"])(response.body)) : {};
            const throttle = (typeof result.result === "string" ? result.result : "").toLowerCase().indexOf("rate limit") >= 0;
            if (module === "proxy") {
                // This JSON response indicates we are being throttled
                if (result && result.status == 0 && result.message == "NOTOK" && throttle) {
                    this.emit("debug", {
                        action: "receiveError",
                        id,
                        reason: "proxy-NOTOK",
                        error: result
                    });
                    response.throwThrottleError(result.result, THROTTLE);
                }
            } else {
                if (throttle) {
                    this.emit("debug", {
                        action: "receiveError",
                        id,
                        reason: "null result",
                        error: result.result
                    });
                    response.throwThrottleError(result.result, THROTTLE);
                }
            }
            return response;
        };
        if (payload) {
            request.setHeader("content-type", "application/x-www-form-urlencoded; charset=UTF-8");
            request.body = Object.keys(payload).map((k)=>`${k}=${payload[k]}`).join("&");
        }
        const response = await request.send();
        try {
            response.assertOk();
        } catch (error) {
            this.emit("debug", {
                action: "receiveError",
                id,
                error,
                reason: "assertOk"
            });
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, "response error", "SERVER_ERROR", {
                request,
                response
            });
        }
        if (!response.hasBody()) {
            this.emit("debug", {
                action: "receiveError",
                id,
                error: "missing body",
                reason: "null body"
            });
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, "missing response", "SERVER_ERROR", {
                request,
                response
            });
        }
        const result = JSON.parse((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$utf8$2e$js__$5b$client$5d$__$28$ecmascript$29$__["toUtf8String"])(response.body));
        if (module === "proxy") {
            if (result.jsonrpc != "2.0") {
                this.emit("debug", {
                    action: "receiveError",
                    id,
                    result,
                    reason: "invalid JSON-RPC"
                });
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, "invalid JSON-RPC response (missing jsonrpc='2.0')", "SERVER_ERROR", {
                    request,
                    response,
                    info: {
                        result
                    }
                });
            }
            if (result.error) {
                this.emit("debug", {
                    action: "receiveError",
                    id,
                    result,
                    reason: "JSON-RPC error"
                });
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, "error response", "SERVER_ERROR", {
                    request,
                    response,
                    info: {
                        result
                    }
                });
            }
            this.emit("debug", {
                action: "receiveRequest",
                id,
                result
            });
            return result.result;
        } else {
            // getLogs, getHistory have weird success responses
            if (result.status == 0 && (result.message === "No records found" || result.message === "No transactions found")) {
                this.emit("debug", {
                    action: "receiveRequest",
                    id,
                    result
                });
                return result.result;
            }
            if (result.status != 1 || typeof result.message === "string" && !result.message.match(/^OK/)) {
                this.emit("debug", {
                    action: "receiveError",
                    id,
                    result
                });
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, "error response", "SERVER_ERROR", {
                    request,
                    response,
                    info: {
                        result
                    }
                });
            }
            this.emit("debug", {
                action: "receiveRequest",
                id,
                result
            });
            return result.result;
        }
    }
    /**
     *  Returns %%transaction%% normalized for the Etherscan API.
     */ _getTransactionPostData(transaction) {
        const result = {};
        for(let key in transaction){
            if (skipKeys.indexOf(key) >= 0) {
                continue;
            }
            if (transaction[key] == null) {
                continue;
            }
            let value = transaction[key];
            if (key === "type" && value === 0) {
                continue;
            }
            if (key === "blockTag" && value === "latest") {
                continue;
            }
            // Quantity-types require no leading zero, unless 0
            if (({
                type: true,
                gasLimit: true,
                gasPrice: true,
                maxFeePerGs: true,
                maxPriorityFeePerGas: true,
                nonce: true,
                value: true
            })[key]) {
                value = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["toQuantity"])(value);
            } else if (key === "accessList") {
                value = "[" + (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$transaction$2f$accesslist$2e$js__$5b$client$5d$__$28$ecmascript$29$__["accessListify"])(value).map((set)=>{
                    return `{address:"${set.address}",storageKeys:["${set.storageKeys.join('","')}"]}`;
                }).join(",") + "]";
            } else if (key === "blobVersionedHashes") {
                if (value.length === 0) {
                    continue;
                }
                // @TODO: update this once the API supports blobs
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, "Etherscan API does not support blobVersionedHashes", "UNSUPPORTED_OPERATION", {
                    operation: "_getTransactionPostData",
                    info: {
                        transaction
                    }
                });
            } else {
                value = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["hexlify"])(value);
            }
            result[key] = value;
        }
        return result;
    }
    /**
     *  Throws the normalized Etherscan error.
     */ _checkError(req, error, transaction) {
        // Pull any message out if, possible
        let message = "";
        if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isError"])(error, "SERVER_ERROR")) {
            // Check for an error emitted by a proxy call
            try {
                message = error.info.result.error.message;
            } catch (e) {}
            if (!message) {
                try {
                    message = error.info.message;
                } catch (e) {}
            }
        }
        if (req.method === "estimateGas") {
            if (!message.match(/revert/i) && message.match(/insufficient funds/i)) {
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, "insufficient funds", "INSUFFICIENT_FUNDS", {
                    transaction: req.transaction
                });
            }
        }
        if (req.method === "call" || req.method === "estimateGas") {
            if (message.match(/execution reverted/i)) {
                let data = "";
                try {
                    data = error.info.result.error.data;
                } catch (error) {}
                const e = __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$abi$2f$abi$2d$coder$2e$js__$5b$client$5d$__$28$ecmascript$29$__["AbiCoder"].getBuiltinCallException(req.method, req.transaction, data);
                e.info = {
                    request: req,
                    error
                };
                throw e;
            }
        }
        if (message) {
            if (req.method === "broadcastTransaction") {
                const transaction = __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$transaction$2f$transaction$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Transaction"].from(req.signedTransaction);
                if (message.match(/replacement/i) && message.match(/underpriced/i)) {
                    (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, "replacement fee too low", "REPLACEMENT_UNDERPRICED", {
                        transaction
                    });
                }
                if (message.match(/insufficient funds/)) {
                    (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, "insufficient funds for intrinsic transaction cost", "INSUFFICIENT_FUNDS", {
                        transaction
                    });
                }
                if (message.match(/same hash was already imported|transaction nonce is too low|nonce too low/)) {
                    (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, "nonce has already been used", "NONCE_EXPIRED", {
                        transaction
                    });
                }
            }
        }
        // Something we could not process
        throw error;
    }
    async _detectNetwork() {
        return this.network;
    }
    async _perform(req) {
        switch(req.method){
            case "chainId":
                return this.network.chainId;
            case "getBlockNumber":
                return this.fetch("proxy", {
                    action: "eth_blockNumber"
                });
            case "getGasPrice":
                return this.fetch("proxy", {
                    action: "eth_gasPrice"
                });
            case "getPriorityFee":
                // This is temporary until Etherscan completes support
                if (this.network.name === "mainnet") {
                    return "1000000000";
                } else if (this.network.name === "optimism") {
                    return "1000000";
                } else {
                    throw new Error("fallback onto the AbstractProvider default");
                }
            /* Working with Etherscan to get this added:
            try {
                const test = await this.fetch("proxy", {
                    action: "eth_maxPriorityFeePerGas"
                });
                console.log(test);
                return test;
            } catch (e) {
                console.log("DEBUG", e);
                throw e;
            }
            */ /* This might be safe; but due to rounding neither myself
               or Etherscan are necessarily comfortable with this. :)
            try {
                const result = await this.fetch("gastracker", { action: "gasoracle" });
                console.log(result);
                const gasPrice = parseUnits(result.SafeGasPrice, "gwei");
                const baseFee = parseUnits(result.suggestBaseFee, "gwei");
                const priorityFee = gasPrice - baseFee;
                if (priorityFee < 0) { throw new Error("negative priority fee; defer to abstract provider default"); }
                return priorityFee;
            } catch (error) {
                console.log("DEBUG", error);
                throw error;
            }
            */ case "getBalance":
                // Returns base-10 result
                return this.fetch("account", {
                    action: "balance",
                    address: req.address,
                    tag: req.blockTag
                });
            case "getTransactionCount":
                return this.fetch("proxy", {
                    action: "eth_getTransactionCount",
                    address: req.address,
                    tag: req.blockTag
                });
            case "getCode":
                return this.fetch("proxy", {
                    action: "eth_getCode",
                    address: req.address,
                    tag: req.blockTag
                });
            case "getStorage":
                return this.fetch("proxy", {
                    action: "eth_getStorageAt",
                    address: req.address,
                    position: req.position,
                    tag: req.blockTag
                });
            case "broadcastTransaction":
                return this.fetch("proxy", {
                    action: "eth_sendRawTransaction",
                    hex: req.signedTransaction
                }, true).catch((error)=>{
                    return this._checkError(req, error, req.signedTransaction);
                });
            case "getBlock":
                if ("blockTag" in req) {
                    return this.fetch("proxy", {
                        action: "eth_getBlockByNumber",
                        tag: req.blockTag,
                        boolean: req.includeTransactions ? "true" : "false"
                    });
                }
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, "getBlock by blockHash not supported by Etherscan", "UNSUPPORTED_OPERATION", {
                    operation: "getBlock(blockHash)"
                });
            case "getTransaction":
                return this.fetch("proxy", {
                    action: "eth_getTransactionByHash",
                    txhash: req.hash
                });
            case "getTransactionReceipt":
                return this.fetch("proxy", {
                    action: "eth_getTransactionReceipt",
                    txhash: req.hash
                });
            case "call":
                {
                    if (req.blockTag !== "latest") {
                        throw new Error("EtherscanProvider does not support blockTag for call");
                    }
                    const postData = this._getTransactionPostData(req.transaction);
                    postData.module = "proxy";
                    postData.action = "eth_call";
                    try {
                        return await this.fetch("proxy", postData, true);
                    } catch (error) {
                        return this._checkError(req, error, req.transaction);
                    }
                }
            case "estimateGas":
                {
                    const postData = this._getTransactionPostData(req.transaction);
                    postData.module = "proxy";
                    postData.action = "eth_estimateGas";
                    try {
                        return await this.fetch("proxy", postData, true);
                    } catch (error) {
                        return this._checkError(req, error, req.transaction);
                    }
                }
            /*
                        case "getLogs": {
                            // Needs to complain if more than one address is passed in
                            const args: Record<string, any> = { action: "getLogs" }
            
                            if (params.filter.fromBlock) {
                                args.fromBlock = checkLogTag(params.filter.fromBlock);
                            }
            
                            if (params.filter.toBlock) {
                                args.toBlock = checkLogTag(params.filter.toBlock);
                            }
            
                            if (params.filter.address) {
                                args.address = params.filter.address;
                            }
            
                            // @TODO: We can handle slightly more complicated logs using the logs API
                            if (params.filter.topics && params.filter.topics.length > 0) {
                                if (params.filter.topics.length > 1) {
                                    logger.throwError("unsupported topic count", Logger.Errors.UNSUPPORTED_OPERATION, { topics: params.filter.topics });
                                }
                                if (params.filter.topics.length === 1) {
                                    const topic0 = params.filter.topics[0];
                                    if (typeof(topic0) !== "string" || topic0.length !== 66) {
                                        logger.throwError("unsupported topic format", Logger.Errors.UNSUPPORTED_OPERATION, { topic0: topic0 });
                                    }
                                    args.topic0 = topic0;
                                }
                            }
            
                            const logs: Array<any> = await this.fetch("logs", args);
            
                            // Cache txHash => blockHash
                            let blocks: { [tag: string]: string } = {};
            
                            // Add any missing blockHash to the logs
                            for (let i = 0; i < logs.length; i++) {
                                const log = logs[i];
                                if (log.blockHash != null) { continue; }
                                if (blocks[log.blockNumber] == null) {
                                    const block = await this.getBlock(log.blockNumber);
                                    if (block) {
                                        blocks[log.blockNumber] = block.hash;
                                    }
                                }
            
                                log.blockHash = blocks[log.blockNumber];
                            }
            
                            return logs;
                        }
            */ default:
                break;
        }
        return super._perform(req);
    }
    async getNetwork() {
        return this.network;
    }
    /**
     *  Resolves to the current price of ether.
     *
     *  This returns ``0`` on any network other than ``mainnet``.
     */ async getEtherPrice() {
        if (this.network.name !== "mainnet") {
            return 0.0;
        }
        return parseFloat((await this.fetch("stats", {
            action: "ethprice"
        })).ethusd);
    }
    /**
     *  Resolves to a [Contract]] for %%address%%, using the
     *  Etherscan API to retreive the Contract ABI.
     */ async getContract(_address) {
        let address = this._getAddress(_address);
        if (isPromise(address)) {
            address = await address;
        }
        try {
            const resp = await this.fetch("contract", {
                action: "getabi",
                address
            });
            const abi = JSON.parse(resp);
            return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$contract$2f$contract$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Contract"](address, abi, this);
        } catch (error) {
            return null;
        }
    }
    isCommunityResource() {
        return this.apiKey == null;
    }
} //# sourceMappingURL=provider-etherscan.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/ws-browser.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "WebSocket",
    ()=>_WebSocket
]);
function getGlobal() {
    if (typeof self !== 'undefined') {
        return self;
    }
    if (typeof window !== 'undefined') {
        return window;
    }
    if ("TURBOPACK compile-time truthy", 1) {
        return /*TURBOPACK member replacement*/ __turbopack_context__.g;
    }
    //TURBOPACK unreachable
    ;
}
;
const _WebSocket = getGlobal().WebSocket;
;
 //# sourceMappingURL=ws-browser.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-socket.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "SocketBlockSubscriber",
    ()=>SocketBlockSubscriber,
    "SocketEventSubscriber",
    ()=>SocketEventSubscriber,
    "SocketPendingSubscriber",
    ()=>SocketPendingSubscriber,
    "SocketProvider",
    ()=>SocketProvider,
    "SocketSubscriber",
    ()=>SocketSubscriber
]);
/**
 *  Generic long-lived socket provider.
 *
 *  Sub-classing notes
 *  - a sub-class MUST call the `_start()` method once connected
 *  - a sub-class MUST override the `_write(string)` method
 *  - a sub-class MUST call `_processMessage(string)` for each message
 *
 *  @_subsection: api/providers/abstract-provider:Socket Providers  [about-socketProvider]
 */ var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$abstract$2d$provider$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/abstract-provider.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/errors.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$jsonrpc$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-jsonrpc.js [client] (ecmascript)");
;
;
;
class SocketSubscriber {
    #provider;
    #filter;
    /**
     *  The filter.
     */ get filter() {
        return JSON.parse(this.#filter);
    }
    #filterId;
    #paused;
    #emitPromise;
    /**
     *  Creates a new **SocketSubscriber** attached to %%provider%% listening
     *  to %%filter%%.
     */ constructor(provider, filter){
        this.#provider = provider;
        this.#filter = JSON.stringify(filter);
        this.#filterId = null;
        this.#paused = null;
        this.#emitPromise = null;
    }
    start() {
        this.#filterId = this.#provider.send("eth_subscribe", this.filter).then((filterId)=>{
            ;
            this.#provider._register(filterId, this);
            return filterId;
        });
    }
    stop() {
        this.#filterId.then((filterId)=>{
            if (this.#provider.destroyed) {
                return;
            }
            this.#provider.send("eth_unsubscribe", [
                filterId
            ]);
        });
        this.#filterId = null;
    }
    // @TODO: pause should trap the current blockNumber, unsub, and on resume use getLogs
    //        and resume
    pause(dropWhilePaused) {
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(dropWhilePaused, "preserve logs while paused not supported by SocketSubscriber yet", "UNSUPPORTED_OPERATION", {
            operation: "pause(false)"
        });
        this.#paused = !!dropWhilePaused;
    }
    resume() {
        this.#paused = null;
    }
    /**
     *  @_ignore:
     */ _handleMessage(message) {
        if (this.#filterId == null) {
            return;
        }
        if (this.#paused === null) {
            let emitPromise = this.#emitPromise;
            if (emitPromise == null) {
                emitPromise = this._emit(this.#provider, message);
            } else {
                emitPromise = emitPromise.then(async ()=>{
                    await this._emit(this.#provider, message);
                });
            }
            this.#emitPromise = emitPromise.then(()=>{
                if (this.#emitPromise === emitPromise) {
                    this.#emitPromise = null;
                }
            });
        }
    }
    /**
     *  Sub-classes **must** override this to emit the events on the
     *  provider.
     */ async _emit(provider, message) {
        throw new Error("sub-classes must implemente this; _emit");
    }
}
class SocketBlockSubscriber extends SocketSubscriber {
    /**
     *  @_ignore:
     */ constructor(provider){
        super(provider, [
            "newHeads"
        ]);
    }
    async _emit(provider, message) {
        provider.emit("block", parseInt(message.number));
    }
}
class SocketPendingSubscriber extends SocketSubscriber {
    /**
     *  @_ignore:
     */ constructor(provider){
        super(provider, [
            "newPendingTransactions"
        ]);
    }
    async _emit(provider, message) {
        provider.emit("pending", message);
    }
}
class SocketEventSubscriber extends SocketSubscriber {
    #logFilter;
    /**
     *  The filter.
     */ get logFilter() {
        return JSON.parse(this.#logFilter);
    }
    /**
     *  @_ignore:
     */ constructor(provider, filter){
        super(provider, [
            "logs",
            filter
        ]);
        this.#logFilter = JSON.stringify(filter);
    }
    async _emit(provider, message) {
        provider.emit(this.logFilter, provider._wrapLog(message, provider._network));
    }
}
class SocketProvider extends __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$jsonrpc$2e$js__$5b$client$5d$__$28$ecmascript$29$__["JsonRpcApiProvider"] {
    #callbacks;
    // Maps each filterId to its subscriber
    #subs;
    // If any events come in before a subscriber has finished
    // registering, queue them
    #pending;
    /**
     *  Creates a new **SocketProvider** connected to %%network%%.
     *
     *  If unspecified, the network will be discovered.
     */ constructor(network, _options){
        // Copy the options
        const options = Object.assign({}, _options != null ? _options : {});
        // Support for batches is generally not supported for
        // connection-base providers; if this changes in the future
        // the _send should be updated to reflect this
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(options.batchMaxCount == null || options.batchMaxCount === 1, "sockets-based providers do not support batches", "options.batchMaxCount", _options);
        options.batchMaxCount = 1;
        // Socket-based Providers (generally) cannot change their network,
        // since they have a long-lived connection; but let people override
        // this if they have just cause.
        if (options.staticNetwork == null) {
            options.staticNetwork = true;
        }
        super(network, options);
        this.#callbacks = new Map();
        this.#subs = new Map();
        this.#pending = new Map();
    }
    // This value is only valid after _start has been called
    /*
    get _network(): Network {
        if (this.#network == null) {
            throw new Error("this shouldn't happen");
        }
        return this.#network.clone();
    }
    */ _getSubscriber(sub) {
        switch(sub.type){
            case "close":
                return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$abstract$2d$provider$2e$js__$5b$client$5d$__$28$ecmascript$29$__["UnmanagedSubscriber"]("close");
            case "block":
                return new SocketBlockSubscriber(this);
            case "pending":
                return new SocketPendingSubscriber(this);
            case "event":
                return new SocketEventSubscriber(this, sub.filter);
            case "orphan":
                // Handled auto-matically within AbstractProvider
                // when the log.removed = true
                if (sub.filter.orphan === "drop-log") {
                    return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$abstract$2d$provider$2e$js__$5b$client$5d$__$28$ecmascript$29$__["UnmanagedSubscriber"]("drop-log");
                }
        }
        return super._getSubscriber(sub);
    }
    /**
     *  Register a new subscriber. This is used internalled by Subscribers
     *  and generally is unecessary unless extending capabilities.
     */ _register(filterId, subscriber) {
        this.#subs.set(filterId, subscriber);
        const pending = this.#pending.get(filterId);
        if (pending) {
            for (const message of pending){
                subscriber._handleMessage(message);
            }
            this.#pending.delete(filterId);
        }
    }
    async _send(payload) {
        // WebSocket provider doesn't accept batches
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(!Array.isArray(payload), "WebSocket does not support batch send", "payload", payload);
        // @TODO: stringify payloads here and store to prevent mutations
        // Prepare a promise to respond to
        const promise = new Promise((resolve, reject)=>{
            this.#callbacks.set(payload.id, {
                payload,
                resolve,
                reject
            });
        });
        // Wait until the socket is connected before writing to it
        await this._waitUntilReady();
        // Write the request to the socket
        await this._write(JSON.stringify(payload));
        return [
            await promise
        ];
    }
    // Sub-classes must call this once they are connected
    /*
    async _start(): Promise<void> {
        if (this.#ready) { return; }

        for (const { payload } of this.#callbacks.values()) {
            await this._write(JSON.stringify(payload));
        }

        this.#ready = (async function() {
            await super._start();
        })();
    }
    */ /**
     *  Sub-classes **must** call this with messages received over their
     *  transport to be processed and dispatched.
     */ async _processMessage(message) {
        const result = JSON.parse(message);
        if (result && typeof result === "object" && "id" in result) {
            const callback = this.#callbacks.get(result.id);
            if (callback == null) {
                this.emit("error", (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["makeError"])("received result for unknown id", "UNKNOWN_ERROR", {
                    reasonCode: "UNKNOWN_ID",
                    result
                }));
                return;
            }
            this.#callbacks.delete(result.id);
            callback.resolve(result);
        } else if (result && result.method === "eth_subscription") {
            const filterId = result.params.subscription;
            const subscriber = this.#subs.get(filterId);
            if (subscriber) {
                subscriber._handleMessage(result.params.result);
            } else {
                let pending = this.#pending.get(filterId);
                if (pending == null) {
                    pending = [];
                    this.#pending.set(filterId, pending);
                }
                pending.push(result.params.result);
            }
        } else {
            this.emit("error", (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["makeError"])("received unexpected message", "UNKNOWN_ERROR", {
                reasonCode: "UNEXPECTED_MESSAGE",
                result
            }));
            return;
        }
    }
    /**
     *  Sub-classes **must** override this to send %%message%% over their
     *  transport.
     */ async _write(message) {
        throw new Error("sub-classes must override this");
    }
} //# sourceMappingURL=provider-socket.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-websocket.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "WebSocketProvider",
    ()=>WebSocketProvider
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$ws$2d$browser$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/ws-browser.js [client] (ecmascript)"); /*-browser*/ 
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$socket$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-socket.js [client] (ecmascript)");
;
;
class WebSocketProvider extends __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$socket$2e$js__$5b$client$5d$__$28$ecmascript$29$__["SocketProvider"] {
    #connect;
    #websocket;
    get websocket() {
        if (this.#websocket == null) {
            throw new Error("websocket closed");
        }
        return this.#websocket;
    }
    constructor(url, network, options){
        super(network, options);
        if (typeof url === "string") {
            this.#connect = ()=>{
                return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$ws$2d$browser$2e$js__$5b$client$5d$__$28$ecmascript$29$__["WebSocket"](url);
            };
            this.#websocket = this.#connect();
        } else if (typeof url === "function") {
            this.#connect = url;
            this.#websocket = url();
        } else {
            this.#connect = null;
            this.#websocket = url;
        }
        this.websocket.onopen = async ()=>{
            try {
                await this._start();
                this.resume();
            } catch (error) {
                console.log("failed to start WebsocketProvider", error);
            // @TODO: now what? Attempt reconnect?
            }
        };
        this.websocket.onmessage = (message)=>{
            this._processMessage(message.data);
        };
    /*
                this.websocket.onclose = (event) => {
                    // @TODO: What event.code should we reconnect on?
                    const reconnect = false;
                    if (reconnect) {
                        this.pause(true);
                        if (this.#connect) {
                            this.#websocket = this.#connect();
                            this.#websocket.onopen = ...
                            // @TODO: this requires the super class to rebroadcast; move it there
                        }
                        this._reconnect();
                    }
                };
        */ }
    async _write(message) {
        this.websocket.send(message);
    }
    async destroy() {
        if (this.#websocket != null) {
            this.#websocket.close();
            this.#websocket = null;
        }
        super.destroy();
    }
} //# sourceMappingURL=provider-websocket.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-infura.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "InfuraProvider",
    ()=>InfuraProvider,
    "InfuraWebSocketProvider",
    ()=>InfuraWebSocketProvider
]);
/**
 *  [[link-infura]] provides a third-party service for connecting to
 *  various blockchains over JSON-RPC.
 *
 *  **Supported Networks**
 *
 *  - Ethereum Mainnet (``mainnet``)
 *  - Goerli Testnet (``goerli``)
 *  - Sepolia Testnet (``sepolia``)
 *  - Arbitrum (``arbitrum``)
 *  - Arbitrum Goerli Testnet (``arbitrum-goerli``)
 *  - Arbitrum Sepolia Testnet (``arbitrum-sepolia``)
 *  - Base (``base``)
 *  - Base Goerlia Testnet (``base-goerli``)
 *  - Base Sepolia Testnet (``base-sepolia``)
 *  - BNB Smart Chain Mainnet (``bnb``)
 *  - BNB Smart Chain Testnet (``bnbt``)
 *  - Linea (``linea``)
 *  - Linea Goerli Testnet (``linea-goerli``)
 *  - Linea Sepolia Testnet (``linea-sepolia``)
 *  - Optimism (``optimism``)
 *  - Optimism Goerli Testnet (``optimism-goerli``)
 *  - Optimism Sepolia Testnet (``optimism-sepolia``)
 *  - Polygon (``matic``)
 *  - Polygon Amoy Testnet (``matic-amoy``)
 *  - Polygon Mumbai Testnet (``matic-mumbai``)
 *
 *  @_subsection: api/providers/thirdparty:INFURA  [providers-infura]
 */ var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/properties.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$fetch$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/fetch.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/errors.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$community$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/community.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/network.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$jsonrpc$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-jsonrpc.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$websocket$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-websocket.js [client] (ecmascript)");
;
;
;
;
;
const defaultProjectId = "84842078b09946638c03157f83405213";
function getHost(name) {
    switch(name){
        case "mainnet":
            return "mainnet.infura.io";
        case "goerli":
            return "goerli.infura.io";
        case "sepolia":
            return "sepolia.infura.io";
        case "arbitrum":
            return "arbitrum-mainnet.infura.io";
        case "arbitrum-goerli":
            return "arbitrum-goerli.infura.io";
        case "arbitrum-sepolia":
            return "arbitrum-sepolia.infura.io";
        case "base":
            return "base-mainnet.infura.io";
        case "base-goerlia":
        case "base-goerli":
            return "base-goerli.infura.io";
        case "base-sepolia":
            return "base-sepolia.infura.io";
        case "bnb":
            return "bsc-mainnet.infura.io";
        case "bnbt":
            return "bsc-testnet.infura.io";
        case "linea":
            return "linea-mainnet.infura.io";
        case "linea-goerli":
            return "linea-goerli.infura.io";
        case "linea-sepolia":
            return "linea-sepolia.infura.io";
        case "matic":
            return "polygon-mainnet.infura.io";
        case "matic-amoy":
            return "polygon-amoy.infura.io";
        case "matic-mumbai":
            return "polygon-mumbai.infura.io";
        case "optimism":
            return "optimism-mainnet.infura.io";
        case "optimism-goerli":
            return "optimism-goerli.infura.io";
        case "optimism-sepolia":
            return "optimism-sepolia.infura.io";
    }
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, "unsupported network", "network", name);
}
class InfuraWebSocketProvider extends __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$websocket$2e$js__$5b$client$5d$__$28$ecmascript$29$__["WebSocketProvider"] {
    /**
     *  The Project ID for the INFURA connection.
     */ projectId;
    /**
     *  The Project Secret.
     *
     *  If null, no authenticated requests are made. This should not
     *  be used outside of private contexts.
     */ projectSecret;
    /**
     *  Creates a new **InfuraWebSocketProvider**.
     */ constructor(network, projectId){
        const provider = new InfuraProvider(network, projectId);
        const req = provider._getConnection();
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(!req.credentials, "INFURA WebSocket project secrets unsupported", "UNSUPPORTED_OPERATION", {
            operation: "InfuraProvider.getWebSocketProvider()"
        });
        const url = req.url.replace(/^http/i, "ws").replace("/v3/", "/ws/v3/");
        super(url, provider._network);
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            projectId: provider.projectId,
            projectSecret: provider.projectSecret
        });
    }
    isCommunityResource() {
        return this.projectId === defaultProjectId;
    }
}
class InfuraProvider extends __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$jsonrpc$2e$js__$5b$client$5d$__$28$ecmascript$29$__["JsonRpcProvider"] {
    /**
     *  The Project ID for the INFURA connection.
     */ projectId;
    /**
     *  The Project Secret.
     *
     *  If null, no authenticated requests are made. This should not
     *  be used outside of private contexts.
     */ projectSecret;
    /**
     *  Creates a new **InfuraProvider**.
     */ constructor(_network, projectId, projectSecret){
        if (_network == null) {
            _network = "mainnet";
        }
        const network = __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Network"].from(_network);
        if (projectId == null) {
            projectId = defaultProjectId;
        }
        if (projectSecret == null) {
            projectSecret = null;
        }
        const request = InfuraProvider.getRequest(network, projectId, projectSecret);
        super(request, network, {
            staticNetwork: network
        });
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            projectId,
            projectSecret
        });
    }
    _getProvider(chainId) {
        try {
            return new InfuraProvider(chainId, this.projectId, this.projectSecret);
        } catch (error) {}
        return super._getProvider(chainId);
    }
    isCommunityResource() {
        return this.projectId === defaultProjectId;
    }
    /**
     *  Creates a new **InfuraWebSocketProvider**.
     */ static getWebSocketProvider(network, projectId) {
        return new InfuraWebSocketProvider(network, projectId);
    }
    /**
     *  Returns a prepared request for connecting to %%network%%
     *  with %%projectId%% and %%projectSecret%%.
     */ static getRequest(network, projectId, projectSecret) {
        if (projectId == null) {
            projectId = defaultProjectId;
        }
        if (projectSecret == null) {
            projectSecret = null;
        }
        const request = new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$fetch$2e$js__$5b$client$5d$__$28$ecmascript$29$__["FetchRequest"](`https:/\/${getHost(network.name)}/v3/${projectId}`);
        request.allowGzip = true;
        if (projectSecret) {
            request.setCredentials("", projectSecret);
        }
        if (projectId === defaultProjectId) {
            request.retryFunc = async (request, response, attempt)=>{
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$community$2e$js__$5b$client$5d$__$28$ecmascript$29$__["showThrottleMessage"])("InfuraProvider");
                return true;
            };
        }
        return request;
    }
} //# sourceMappingURL=provider-infura.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-quicknode.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "QuickNodeProvider",
    ()=>QuickNodeProvider
]);
/**
 *  [[link-quicknode]] provides a third-party service for connecting to
 *  various blockchains over JSON-RPC.
 *
 *  **Supported Networks**
 *
 *  - Ethereum Mainnet (``mainnet``)
 *  - Goerli Testnet (``goerli``)
 *  - Sepolia Testnet (``sepolia``)
 *  - Holesky Testnet (``holesky``)
 *  - Arbitrum (``arbitrum``)
 *  - Arbitrum Goerli Testnet (``arbitrum-goerli``)
 *  - Arbitrum Sepolia Testnet (``arbitrum-sepolia``)
 *  - Base Mainnet (``base``);
 *  - Base Goerli Testnet (``base-goerli``);
 *  - Base Sepolia Testnet (``base-sepolia``);
 *  - BNB Smart Chain Mainnet (``bnb``)
 *  - BNB Smart Chain Testnet (``bnbt``)
 *  - Optimism (``optimism``)
 *  - Optimism Goerli Testnet (``optimism-goerli``)
 *  - Optimism Sepolia Testnet (``optimism-sepolia``)
 *  - Polygon (``matic``)
 *  - Polygon Mumbai Testnet (``matic-mumbai``)
 *
 *  @_subsection: api/providers/thirdparty:QuickNode  [providers-quicknode]
 */ var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/properties.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$fetch$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/fetch.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/errors.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$community$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/community.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/network.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$jsonrpc$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-jsonrpc.js [client] (ecmascript)");
;
;
;
;
const defaultToken = "919b412a057b5e9c9b6dce193c5a60242d6efadb";
function getHost(name) {
    switch(name){
        case "mainnet":
            return "ethers.quiknode.pro";
        case "goerli":
            return "ethers.ethereum-goerli.quiknode.pro";
        case "sepolia":
            return "ethers.ethereum-sepolia.quiknode.pro";
        case "holesky":
            return "ethers.ethereum-holesky.quiknode.pro";
        case "arbitrum":
            return "ethers.arbitrum-mainnet.quiknode.pro";
        case "arbitrum-goerli":
            return "ethers.arbitrum-goerli.quiknode.pro";
        case "arbitrum-sepolia":
            return "ethers.arbitrum-sepolia.quiknode.pro";
        case "base":
            return "ethers.base-mainnet.quiknode.pro";
        case "base-goerli":
            return "ethers.base-goerli.quiknode.pro";
        case "base-spolia":
            return "ethers.base-sepolia.quiknode.pro";
        case "bnb":
            return "ethers.bsc.quiknode.pro";
        case "bnbt":
            return "ethers.bsc-testnet.quiknode.pro";
        case "matic":
            return "ethers.matic.quiknode.pro";
        case "matic-mumbai":
            return "ethers.matic-testnet.quiknode.pro";
        case "optimism":
            return "ethers.optimism.quiknode.pro";
        case "optimism-goerli":
            return "ethers.optimism-goerli.quiknode.pro";
        case "optimism-sepolia":
            return "ethers.optimism-sepolia.quiknode.pro";
        case "xdai":
            return "ethers.xdai.quiknode.pro";
    }
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, "unsupported network", "network", name);
}
class QuickNodeProvider extends __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$jsonrpc$2e$js__$5b$client$5d$__$28$ecmascript$29$__["JsonRpcProvider"] {
    /**
     *  The API token.
     */ token;
    /**
     *  Creates a new **QuickNodeProvider**.
     */ constructor(_network, token){
        if (_network == null) {
            _network = "mainnet";
        }
        const network = __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Network"].from(_network);
        if (token == null) {
            token = defaultToken;
        }
        const request = QuickNodeProvider.getRequest(network, token);
        super(request, network, {
            staticNetwork: network
        });
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            token
        });
    }
    _getProvider(chainId) {
        try {
            return new QuickNodeProvider(chainId, this.token);
        } catch (error) {}
        return super._getProvider(chainId);
    }
    isCommunityResource() {
        return this.token === defaultToken;
    }
    /**
     *  Returns a new request prepared for %%network%% and the
     *  %%token%%.
     */ static getRequest(network, token) {
        if (token == null) {
            token = defaultToken;
        }
        const request = new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$fetch$2e$js__$5b$client$5d$__$28$ecmascript$29$__["FetchRequest"](`https:/\/${getHost(network.name)}/${token}`);
        request.allowGzip = true;
        //if (projectSecret) { request.setCredentials("", projectSecret); }
        if (token === defaultToken) {
            request.retryFunc = async (request, response, attempt)=>{
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$community$2e$js__$5b$client$5d$__$28$ecmascript$29$__["showThrottleMessage"])("QuickNodeProvider");
                return true;
            };
        }
        return request;
    }
} //# sourceMappingURL=provider-quicknode.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-fallback.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "FallbackProvider",
    ()=>FallbackProvider
]);
/**
 *  A **FallbackProvider** provides resilience, security and performance
 *  in a way that is customizable and configurable.
 *
 *  @_section: api/providers/fallback-provider:Fallback Provider [about-fallback-provider]
 */ var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/errors.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/maths.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$abstract$2d$provider$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/abstract-provider.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/network.js [client] (ecmascript)");
;
;
;
const BN_1 = BigInt("1");
const BN_2 = BigInt("2");
function shuffle(array) {
    for(let i = array.length - 1; i > 0; i--){
        const j = Math.floor(Math.random() * (i + 1));
        const tmp = array[i];
        array[i] = array[j];
        array[j] = tmp;
    }
}
function stall(duration) {
    return new Promise((resolve)=>{
        setTimeout(resolve, duration);
    });
}
function getTime() {
    return new Date().getTime();
}
function stringify(value) {
    return JSON.stringify(value, (key, value)=>{
        if (typeof value === "bigint") {
            return {
                type: "bigint",
                value: value.toString()
            };
        }
        return value;
    });
}
;
const defaultConfig = {
    stallTimeout: 400,
    priority: 1,
    weight: 1
};
const defaultState = {
    blockNumber: -2,
    requests: 0,
    lateResponses: 0,
    errorResponses: 0,
    outOfSync: -1,
    unsupportedEvents: 0,
    rollingDuration: 0,
    score: 0,
    _network: null,
    _updateNumber: null,
    _totalTime: 0,
    _lastFatalError: null,
    _lastFatalErrorTimestamp: 0
};
async function waitForSync(config, blockNumber) {
    while(config.blockNumber < 0 || config.blockNumber < blockNumber){
        if (!config._updateNumber) {
            config._updateNumber = (async ()=>{
                try {
                    const blockNumber = await config.provider.getBlockNumber();
                    if (blockNumber > config.blockNumber) {
                        config.blockNumber = blockNumber;
                    }
                } catch (error) {
                    config.blockNumber = -2;
                    config._lastFatalError = error;
                    config._lastFatalErrorTimestamp = getTime();
                }
                config._updateNumber = null;
            })();
        }
        await config._updateNumber;
        config.outOfSync++;
        if (config._lastFatalError) {
            break;
        }
    }
}
function _normalize(value) {
    if (value == null) {
        return "null";
    }
    if (Array.isArray(value)) {
        return "[" + value.map(_normalize).join(",") + "]";
    }
    if (typeof value === "object" && typeof value.toJSON === "function") {
        return _normalize(value.toJSON());
    }
    switch(typeof value){
        case "boolean":
        case "symbol":
            return value.toString();
        case "bigint":
        case "number":
            return BigInt(value).toString();
        case "string":
            return JSON.stringify(value);
        case "object":
            {
                const keys = Object.keys(value);
                keys.sort();
                return "{" + keys.map((k)=>`${JSON.stringify(k)}:${_normalize(value[k])}`).join(",") + "}";
            }
    }
    console.log("Could not serialize", value);
    throw new Error("Hmm...");
}
function normalizeResult(method, value) {
    if ("error" in value) {
        const error = value.error;
        let tag;
        if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isError"])(error, "CALL_EXCEPTION")) {
            tag = _normalize(Object.assign({}, error, {
                shortMessage: undefined,
                reason: undefined,
                info: undefined
            }));
        } else {
            tag = _normalize(error);
        }
        return {
            tag,
            value: error
        };
    }
    const result = value.result;
    return {
        tag: _normalize(result),
        value: result
    };
}
// This strategy picks the highest weight result, as long as the weight is
// equal to or greater than quorum
function checkQuorum(quorum, results) {
    const tally = new Map();
    for (const { value, tag, weight } of results){
        const t = tally.get(tag) || {
            value,
            weight: 0
        };
        t.weight += weight;
        tally.set(tag, t);
    }
    let best = null;
    for (const r of tally.values()){
        if (r.weight >= quorum && (!best || r.weight > best.weight)) {
            best = r;
        }
    }
    if (best) {
        return best.value;
    }
    return undefined;
}
function getMedian(quorum, results) {
    let resultWeight = 0;
    const errorMap = new Map();
    let bestError = null;
    const values = [];
    for (const { value, tag, weight } of results){
        if (value instanceof Error) {
            const e = errorMap.get(tag) || {
                value,
                weight: 0
            };
            e.weight += weight;
            errorMap.set(tag, e);
            if (bestError == null || e.weight > bestError.weight) {
                bestError = e;
            }
        } else {
            values.push(BigInt(value));
            resultWeight += weight;
        }
    }
    if (resultWeight < quorum) {
        // We have quorum for an error
        if (bestError && bestError.weight >= quorum) {
            return bestError.value;
        }
        // We do not have quorum for a result
        return undefined;
    }
    // Get the sorted values
    values.sort((a, b)=>a < b ? -1 : b > a ? 1 : 0);
    const mid = Math.floor(values.length / 2);
    // Odd-length; take the middle value
    if (values.length % 2) {
        return values[mid];
    }
    // Even length; take the ceiling of the mean of the center two values
    return (values[mid - 1] + values[mid] + BN_1) / BN_2;
}
function getAnyResult(quorum, results) {
    // If any value or error meets quorum, that is our preferred result
    const result = checkQuorum(quorum, results);
    if (result !== undefined) {
        return result;
    }
    // Otherwise, do we have any result?
    for (const r of results){
        if (r.value) {
            return r.value;
        }
    }
    // Nope!
    return undefined;
}
function getFuzzyMode(quorum, results) {
    if (quorum === 1) {
        return (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"])(getMedian(quorum, results), "%internal");
    }
    const tally = new Map();
    const add = (result, weight)=>{
        const t = tally.get(result) || {
            result,
            weight: 0
        };
        t.weight += weight;
        tally.set(result, t);
    };
    for (const { weight, value } of results){
        const r = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"])(value);
        add(r - 1, weight);
        add(r, weight);
        add(r + 1, weight);
    }
    let bestWeight = 0;
    let bestResult = undefined;
    for (const { weight, result } of tally.values()){
        // Use this result, if this result meets quorum and has either:
        // - a better weight
        // - or equal weight, but the result is larger
        if (weight >= quorum && (weight > bestWeight || bestResult != null && weight === bestWeight && result > bestResult)) {
            bestWeight = weight;
            bestResult = result;
        }
    }
    return bestResult;
}
class FallbackProvider extends __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$abstract$2d$provider$2e$js__$5b$client$5d$__$28$ecmascript$29$__["AbstractProvider"] {
    /**
     *  The number of backends that must agree on a value before it is
     *  accpeted.
     */ quorum;
    /**
     *  @_ignore:
     */ eventQuorum;
    /**
     *  @_ignore:
     */ eventWorkers;
    #configs;
    #height;
    #initialSyncPromise;
    /**
     *  Creates a new **FallbackProvider** with %%providers%% connected to
     *  %%network%%.
     *
     *  If a [[Provider]] is included in %%providers%%, defaults are used
     *  for the configuration.
     */ constructor(providers, network, options){
        super(network, options);
        this.#configs = providers.map((p)=>{
            if (p instanceof __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$abstract$2d$provider$2e$js__$5b$client$5d$__$28$ecmascript$29$__["AbstractProvider"]) {
                return Object.assign({
                    provider: p
                }, defaultConfig, defaultState);
            } else {
                return Object.assign({}, defaultConfig, p, defaultState);
            }
        });
        this.#height = -2;
        this.#initialSyncPromise = null;
        if (options && options.quorum != null) {
            this.quorum = options.quorum;
        } else {
            this.quorum = Math.ceil(this.#configs.reduce((accum, config)=>{
                accum += config.weight;
                return accum;
            }, 0) / 2);
        }
        this.eventQuorum = 1;
        this.eventWorkers = 1;
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(this.quorum <= this.#configs.reduce((a, c)=>a + c.weight, 0), "quorum exceed provider weight", "quorum", this.quorum);
    }
    get providerConfigs() {
        return this.#configs.map((c)=>{
            const result = Object.assign({}, c);
            for(const key in result){
                if (key[0] === "_") {
                    delete result[key];
                }
            }
            return result;
        });
    }
    async _detectNetwork() {
        return __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Network"].from((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getBigInt"])(await this._perform({
            method: "chainId"
        })));
    }
    // @TODO: Add support to select providers to be the event subscriber
    //_getSubscriber(sub: Subscription): Subscriber {
    //    throw new Error("@TODO");
    //}
    /**
     *  Transforms a %%req%% into the correct method call on %%provider%%.
     */ async _translatePerform(provider, req) {
        switch(req.method){
            case "broadcastTransaction":
                return await provider.broadcastTransaction(req.signedTransaction);
            case "call":
                return await provider.call(Object.assign({}, req.transaction, {
                    blockTag: req.blockTag
                }));
            case "chainId":
                return (await provider.getNetwork()).chainId;
            case "estimateGas":
                return await provider.estimateGas(req.transaction);
            case "getBalance":
                return await provider.getBalance(req.address, req.blockTag);
            case "getBlock":
                {
                    const block = "blockHash" in req ? req.blockHash : req.blockTag;
                    return await provider.getBlock(block, req.includeTransactions);
                }
            case "getBlockNumber":
                return await provider.getBlockNumber();
            case "getCode":
                return await provider.getCode(req.address, req.blockTag);
            case "getGasPrice":
                return (await provider.getFeeData()).gasPrice;
            case "getPriorityFee":
                return (await provider.getFeeData()).maxPriorityFeePerGas;
            case "getLogs":
                return await provider.getLogs(req.filter);
            case "getStorage":
                return await provider.getStorage(req.address, req.position, req.blockTag);
            case "getTransaction":
                return await provider.getTransaction(req.hash);
            case "getTransactionCount":
                return await provider.getTransactionCount(req.address, req.blockTag);
            case "getTransactionReceipt":
                return await provider.getTransactionReceipt(req.hash);
            case "getTransactionResult":
                return await provider.getTransactionResult(req.hash);
        }
    }
    // Grab the next (random) config that is not already part of
    // the running set
    #getNextConfig(running) {
        // @TODO: Maybe do a check here to favour (heavily) providers that
        //        do not require waitForSync and disfavour providers that
        //        seem down-ish or are behaving slowly
        const configs = Array.from(running).map((r)=>r.config);
        // Shuffle the states, sorted by priority
        const allConfigs = this.#configs.slice();
        shuffle(allConfigs);
        allConfigs.sort((a, b)=>a.priority - b.priority);
        for (const config of allConfigs){
            if (config._lastFatalError) {
                continue;
            }
            if (configs.indexOf(config) === -1) {
                return config;
            }
        }
        return null;
    }
    // Adds a new runner (if available) to running.
    #addRunner(running, req) {
        const config = this.#getNextConfig(running);
        // No runners available
        if (config == null) {
            return null;
        }
        // Create a new runner
        const runner = {
            config,
            result: null,
            didBump: false,
            perform: null,
            staller: null
        };
        const now = getTime();
        // Start performing this operation
        runner.perform = (async ()=>{
            try {
                config.requests++;
                const result = await this._translatePerform(config.provider, req);
                runner.result = {
                    result
                };
            } catch (error) {
                config.errorResponses++;
                runner.result = {
                    error
                };
            }
            const dt = getTime() - now;
            config._totalTime += dt;
            config.rollingDuration = 0.95 * config.rollingDuration + 0.05 * dt;
            runner.perform = null;
        })();
        // Start a staller; when this times out, it's time to force
        // kicking off another runner because we are taking too long
        runner.staller = (async ()=>{
            await stall(config.stallTimeout);
            runner.staller = null;
        })();
        running.add(runner);
        return runner;
    }
    // Initializes the blockNumber and network for each runner and
    // blocks until initialized
    async #initialSync() {
        let initialSync = this.#initialSyncPromise;
        if (!initialSync) {
            const promises = [];
            this.#configs.forEach((config)=>{
                promises.push((async ()=>{
                    await waitForSync(config, 0);
                    if (!config._lastFatalError) {
                        config._network = await config.provider.getNetwork();
                    }
                })());
            });
            this.#initialSyncPromise = initialSync = (async ()=>{
                // Wait for all providers to have a block number and network
                await Promise.all(promises);
                // Check all the networks match
                let chainId = null;
                for (const config of this.#configs){
                    if (config._lastFatalError) {
                        continue;
                    }
                    const network = config._network;
                    if (chainId == null) {
                        chainId = network.chainId;
                    } else if (network.chainId !== chainId) {
                        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, "cannot mix providers on different networks", "UNSUPPORTED_OPERATION", {
                            operation: "new FallbackProvider"
                        });
                    }
                }
            })();
        }
        await initialSync;
    }
    async #checkQuorum(running, req) {
        // Get all the result objects
        const results = [];
        for (const runner of running){
            if (runner.result != null) {
                const { tag, value } = normalizeResult(req.method, runner.result);
                results.push({
                    tag,
                    value,
                    weight: runner.config.weight
                });
            }
        }
        // Are there enough results to event meet quorum?
        if (results.reduce((a, r)=>a + r.weight, 0) < this.quorum) {
            return undefined;
        }
        switch(req.method){
            case "getBlockNumber":
                {
                    // We need to get the bootstrap block height
                    if (this.#height === -2) {
                        this.#height = Math.ceil((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"])(getMedian(this.quorum, this.#configs.filter((c)=>!c._lastFatalError).map((c)=>({
                                value: c.blockNumber,
                                tag: (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$maths$2e$js__$5b$client$5d$__$28$ecmascript$29$__["getNumber"])(c.blockNumber).toString(),
                                weight: c.weight
                            })))));
                    }
                    // Find the mode across all the providers, allowing for
                    // a little drift between block heights
                    const mode = getFuzzyMode(this.quorum, results);
                    if (mode === undefined) {
                        return undefined;
                    }
                    if (mode > this.#height) {
                        this.#height = mode;
                    }
                    return this.#height;
                }
            case "getGasPrice":
            case "getPriorityFee":
            case "estimateGas":
                return getMedian(this.quorum, results);
            case "getBlock":
                // Pending blocks are in the mempool and already
                // quite untrustworthy; just grab anything
                if ("blockTag" in req && req.blockTag === "pending") {
                    return getAnyResult(this.quorum, results);
                }
                return checkQuorum(this.quorum, results);
            case "call":
            case "chainId":
            case "getBalance":
            case "getTransactionCount":
            case "getCode":
            case "getStorage":
            case "getTransaction":
            case "getTransactionReceipt":
            case "getLogs":
                return checkQuorum(this.quorum, results);
            case "broadcastTransaction":
                return getAnyResult(this.quorum, results);
        }
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(false, "unsupported method", "UNSUPPORTED_OPERATION", {
            operation: `_perform(${stringify(req.method)})`
        });
    }
    async #waitForQuorum(running, req) {
        if (running.size === 0) {
            throw new Error("no runners?!");
        }
        // Any promises that are interesting to watch for; an expired stall
        // or a successful perform
        const interesting = [];
        let newRunners = 0;
        for (const runner of running){
            // No responses, yet; keep an eye on it
            if (runner.perform) {
                interesting.push(runner.perform);
            }
            // Still stalling...
            if (runner.staller) {
                interesting.push(runner.staller);
                continue;
            }
            // This runner has already triggered another runner
            if (runner.didBump) {
                continue;
            }
            // Got a response (result or error) or stalled; kick off another runner
            runner.didBump = true;
            newRunners++;
        }
        // Check if we have reached quorum on a result (or error)
        const value = await this.#checkQuorum(running, req);
        if (value !== undefined) {
            if (value instanceof Error) {
                throw value;
            }
            return value;
        }
        // Add any new runners, because a staller timed out or a result
        // or error response came in.
        for(let i = 0; i < newRunners; i++){
            this.#addRunner(running, req);
        }
        // All providers have returned, and we have no result
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(interesting.length > 0, "quorum not met", "SERVER_ERROR", {
            request: "%sub-requests",
            info: {
                request: req,
                results: Array.from(running).map((r)=>stringify(r.result))
            }
        });
        // Wait for someone to either complete its perform or stall out
        await Promise.race(interesting);
        // This is recursive, but at worst case the depth is 2x the
        // number of providers (each has a perform and a staller)
        return await this.#waitForQuorum(running, req);
    }
    async _perform(req) {
        // Broadcasting a transaction is rare (ish) and already incurs
        // a cost on the user, so spamming is safe-ish. Just send it to
        // every backend.
        if (req.method === "broadcastTransaction") {
            // Once any broadcast provides a positive result, use it. No
            // need to wait for anyone else
            const results = this.#configs.map((c)=>null);
            const broadcasts = this.#configs.map(async ({ provider, weight }, index)=>{
                try {
                    const result = await provider._perform(req);
                    results[index] = Object.assign(normalizeResult(req.method, {
                        result
                    }), {
                        weight
                    });
                } catch (error) {
                    results[index] = Object.assign(normalizeResult(req.method, {
                        error
                    }), {
                        weight
                    });
                }
            });
            // As each promise finishes...
            while(true){
                // Check for a valid broadcast result
                const done = results.filter((r)=>r != null);
                for (const { value } of done){
                    if (!(value instanceof Error)) {
                        return value;
                    }
                }
                // Check for a legit broadcast error (one which we cannot
                // recover from; some nodes may return the following red
                // herring events:
                // - alredy seend (UNKNOWN_ERROR)
                // - NONCE_EXPIRED
                // - REPLACEMENT_UNDERPRICED
                const result = checkQuorum(this.quorum, results.filter((r)=>r != null));
                if ((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isError"])(result, "INSUFFICIENT_FUNDS")) {
                    throw result;
                }
                // Kick off the next provider (if any)
                const waiting = broadcasts.filter((b, i)=>results[i] == null);
                if (waiting.length === 0) {
                    break;
                }
                await Promise.race(waiting);
            }
            // Use standard quorum results; any result was returned above,
            // so this will find any error that met quorum if any
            const result = getAnyResult(this.quorum, results);
            (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(result !== undefined, "problem multi-broadcasting", "SERVER_ERROR", {
                request: "%sub-requests",
                info: {
                    request: req,
                    results: results.map(stringify)
                }
            });
            if (result instanceof Error) {
                throw result;
            }
            return result;
        }
        await this.#initialSync();
        // Bootstrap enough runners to meet quorum
        const running = new Set();
        let inflightQuorum = 0;
        while(true){
            const runner = this.#addRunner(running, req);
            if (runner == null) {
                break;
            }
            inflightQuorum += runner.config.weight;
            if (inflightQuorum >= this.quorum) {
                break;
            }
        }
        const result = await this.#waitForQuorum(running, req);
        // Track requests sent to a provider that are still
        // outstanding after quorum has been otherwise found
        for (const runner of running){
            if (runner.perform && runner.result == null) {
                runner.config.lateResponses++;
            }
        }
        return result;
    }
    async destroy() {
        for (const { provider } of this.#configs){
            provider.destroy();
        }
        super.destroy();
    }
} //# sourceMappingURL=provider-fallback.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/default-provider.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "getDefaultProvider",
    ()=>getDefaultProvider
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/errors.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$ankr$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-ankr.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$alchemy$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-alchemy.js [client] (ecmascript)");
//import { BlockscoutProvider } from "./provider-blockscout.js";
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$chainstack$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-chainstack.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$cloudflare$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-cloudflare.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$etherscan$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-etherscan.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$infura$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-infura.js [client] (ecmascript)");
//import { PocketProvider } from "./provider-pocket.js";
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$quicknode$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-quicknode.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$fallback$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-fallback.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$jsonrpc$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-jsonrpc.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/network.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$websocket$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-websocket.js [client] (ecmascript)");
;
;
;
;
;
;
;
;
;
;
;
;
function isWebSocketLike(value) {
    return value && typeof value.send === "function" && typeof value.close === "function";
}
const Testnets = "goerli kovan sepolia classicKotti optimism-goerli arbitrum-goerli matic-mumbai bnbt".split(" ");
function getDefaultProvider(network, options) {
    if (options == null) {
        options = {};
    }
    const allowService = (name)=>{
        if (options[name] === "-") {
            return false;
        }
        if (typeof options.exclusive === "string") {
            return name === options.exclusive;
        }
        if (Array.isArray(options.exclusive)) {
            return options.exclusive.indexOf(name) !== -1;
        }
        return true;
    };
    if (typeof network === "string" && network.match(/^https?:/)) {
        return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$jsonrpc$2e$js__$5b$client$5d$__$28$ecmascript$29$__["JsonRpcProvider"](network);
    }
    if (typeof network === "string" && network.match(/^wss?:/) || isWebSocketLike(network)) {
        return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$websocket$2e$js__$5b$client$5d$__$28$ecmascript$29$__["WebSocketProvider"](network);
    }
    // Get the network and name, if possible
    let staticNetwork = null;
    try {
        staticNetwork = __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Network"].from(network);
    } catch (error) {}
    const providers = [];
    if (allowService("publicPolygon") && staticNetwork) {
        if (staticNetwork.name === "matic") {
            providers.push(new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$jsonrpc$2e$js__$5b$client$5d$__$28$ecmascript$29$__["JsonRpcProvider"]("https:/\/polygon-rpc.com/", staticNetwork, {
                staticNetwork
            }));
        } else if (staticNetwork.name === "matic-amoy") {
            providers.push(new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$jsonrpc$2e$js__$5b$client$5d$__$28$ecmascript$29$__["JsonRpcProvider"]("https:/\/rpc-amoy.polygon.technology/", staticNetwork, {
                staticNetwork
            }));
        }
    }
    if (allowService("alchemy")) {
        try {
            providers.push(new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$alchemy$2e$js__$5b$client$5d$__$28$ecmascript$29$__["AlchemyProvider"](network, options.alchemy));
        } catch (error) {}
    }
    if (allowService("ankr") && options.ankr != null) {
        try {
            providers.push(new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$ankr$2e$js__$5b$client$5d$__$28$ecmascript$29$__["AnkrProvider"](network, options.ankr));
        } catch (error) {}
    }
    /* Temporarily remove until custom error issue is fixed
        if (allowService("blockscout")) {
            try {
                providers.push(new BlockscoutProvider(network, options.blockscout));
            } catch (error) { }
        }
    */ if (allowService("chainstack")) {
        try {
            providers.push(new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$chainstack$2e$js__$5b$client$5d$__$28$ecmascript$29$__["ChainstackProvider"](network, options.chainstack));
        } catch (error) {}
    }
    if (allowService("cloudflare")) {
        try {
            providers.push(new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$cloudflare$2e$js__$5b$client$5d$__$28$ecmascript$29$__["CloudflareProvider"](network));
        } catch (error) {}
    }
    if (allowService("etherscan")) {
        try {
            providers.push(new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$etherscan$2e$js__$5b$client$5d$__$28$ecmascript$29$__["EtherscanProvider"](network, options.etherscan));
        } catch (error) {}
    }
    if (allowService("infura")) {
        try {
            let projectId = options.infura;
            let projectSecret = undefined;
            if (typeof projectId === "object") {
                projectSecret = projectId.projectSecret;
                projectId = projectId.projectId;
            }
            providers.push(new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$infura$2e$js__$5b$client$5d$__$28$ecmascript$29$__["InfuraProvider"](network, projectId, projectSecret));
        } catch (error) {}
    }
    /*
        if (options.pocket !== "-") {
            try {
                let appId = options.pocket;
                let secretKey: undefined | string = undefined;
                let loadBalancer: undefined | boolean = undefined;
                if (typeof(appId) === "object") {
                    loadBalancer = !!appId.loadBalancer;
                    secretKey = appId.secretKey;
                    appId = appId.appId;
                }
                providers.push(new PocketProvider(network, appId, secretKey, loadBalancer));
            } catch (error) { console.log(error); }
        }
    */ if (allowService("quicknode")) {
        try {
            let token = options.quicknode;
            providers.push(new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$quicknode$2e$js__$5b$client$5d$__$28$ecmascript$29$__["QuickNodeProvider"](network, token));
        } catch (error) {}
    }
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assert"])(providers.length, "unsupported default network", "UNSUPPORTED_OPERATION", {
        operation: "getDefaultProvider"
    });
    // No need for a FallbackProvider
    if (providers.length === 1) {
        return providers[0];
    }
    // We use the floor because public third-party providers can be unreliable,
    // so a low number of providers with a large quorum will fail too often
    let quorum = Math.floor(providers.length / 2);
    if (quorum > 2) {
        quorum = 2;
    }
    // Testnets don't need as strong a security gaurantee and speed is
    // more useful during testing
    if (staticNetwork && Testnets.indexOf(staticNetwork.name) !== -1) {
        quorum = 1;
    }
    // Provided override qorum takes priority
    if (options && options.quorum) {
        quorum = options.quorum;
    }
    return new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$fallback$2e$js__$5b$client$5d$__$28$ecmascript$29$__["FallbackProvider"](providers, undefined, {
        quorum
    });
} //# sourceMappingURL=default-provider.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/signer-noncemanager.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "NonceManager",
    ()=>NonceManager
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/properties.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$abstract$2d$signer$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/abstract-signer.js [client] (ecmascript)");
;
;
class NonceManager extends __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$abstract$2d$signer$2e$js__$5b$client$5d$__$28$ecmascript$29$__["AbstractSigner"] {
    /**
     *  The Signer being managed.
     */ signer;
    #noncePromise;
    #delta;
    /**
     *  Creates a new **NonceManager** to manage %%signer%%.
     */ constructor(signer){
        super(signer.provider);
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            signer
        });
        this.#noncePromise = null;
        this.#delta = 0;
    }
    async getAddress() {
        return this.signer.getAddress();
    }
    connect(provider) {
        return new NonceManager(this.signer.connect(provider));
    }
    async getNonce(blockTag) {
        if (blockTag === "pending") {
            if (this.#noncePromise == null) {
                this.#noncePromise = super.getNonce("pending");
            }
            const delta = this.#delta;
            return await this.#noncePromise + delta;
        }
        return super.getNonce(blockTag);
    }
    /**
     *  Manually increment the nonce. This may be useful when managng
     *  offline transactions.
     */ increment() {
        this.#delta++;
    }
    /**
     *  Resets the nonce, causing the **NonceManager** to reload the current
     *  nonce from the blockchain on the next transaction.
     */ reset() {
        this.#delta = 0;
        this.#noncePromise = null;
    }
    async sendTransaction(tx) {
        const noncePromise = this.getNonce("pending");
        this.increment();
        tx = await this.signer.populateTransaction(tx);
        tx.nonce = await noncePromise;
        // @TODO: Maybe handle interesting/recoverable errors?
        // Like don't increment if the tx was certainly not sent
        return await this.signer.sendTransaction(tx);
    }
    signTransaction(tx) {
        return this.signer.signTransaction(tx);
    }
    signMessage(message) {
        return this.signer.signMessage(message);
    }
    signTypedData(domain, types, value) {
        return this.signer.signTypedData(domain, types, value);
    }
} //# sourceMappingURL=signer-noncemanager.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-browser.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "BrowserProvider",
    ()=>BrowserProvider
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/errors.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$jsonrpc$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-jsonrpc.js [client] (ecmascript)");
;
;
;
class BrowserProvider extends __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$jsonrpc$2e$js__$5b$client$5d$__$28$ecmascript$29$__["JsonRpcApiPollingProvider"] {
    #request;
    #providerInfo;
    /**
     *  Connect to the %%ethereum%% provider, optionally forcing the
     *  %%network%%.
     */ constructor(ethereum, network, _options){
        // Copy the options
        const options = Object.assign({}, _options != null ? _options : {}, {
            batchMaxCount: 1
        });
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(ethereum && ethereum.request, "invalid EIP-1193 provider", "ethereum", ethereum);
        super(network, options);
        this.#providerInfo = null;
        if (_options && _options.providerInfo) {
            this.#providerInfo = _options.providerInfo;
        }
        this.#request = async (method, params)=>{
            const payload = {
                method,
                params
            };
            this.emit("debug", {
                action: "sendEip1193Request",
                payload
            });
            try {
                const result = await ethereum.request(payload);
                this.emit("debug", {
                    action: "receiveEip1193Result",
                    result
                });
                return result;
            } catch (e) {
                const error = new Error(e.message);
                error.code = e.code;
                error.data = e.data;
                error.payload = payload;
                this.emit("debug", {
                    action: "receiveEip1193Error",
                    error
                });
                throw error;
            }
        };
    }
    get providerInfo() {
        return this.#providerInfo;
    }
    async send(method, params) {
        await this._start();
        return await super.send(method, params);
    }
    async _send(payload) {
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(!Array.isArray(payload), "EIP-1193 does not support batch request", "payload", payload);
        try {
            const result = await this.#request(payload.method, payload.params || []);
            return [
                {
                    id: payload.id,
                    result
                }
            ];
        } catch (e) {
            return [
                {
                    id: payload.id,
                    error: {
                        code: e.code,
                        data: e.data,
                        message: e.message
                    }
                }
            ];
        }
    }
    getRpcError(payload, error) {
        error = JSON.parse(JSON.stringify(error));
        // EIP-1193 gives us some machine-readable error codes, so rewrite
        // them into Ethers standard errors.
        switch(error.error.code || -1){
            case 4001:
                error.error.message = `ethers-user-denied: ${error.error.message}`;
                break;
            case 4200:
                error.error.message = `ethers-unsupported: ${error.error.message}`;
                break;
        }
        return super.getRpcError(payload, error);
    }
    /**
     *  Resolves to ``true`` if the provider manages the %%address%%.
     */ async hasSigner(address) {
        if (address == null) {
            address = 0;
        }
        const accounts = await this.send("eth_accounts", []);
        if (typeof address === "number") {
            return accounts.length > address;
        }
        address = address.toLowerCase();
        return accounts.filter((a)=>a.toLowerCase() === address).length !== 0;
    }
    async getSigner(address) {
        if (address == null) {
            address = 0;
        }
        if (!await this.hasSigner(address)) {
            try {
                await this.#request("eth_requestAccounts", []);
            } catch (error) {
                const payload = error.payload;
                throw this.getRpcError(payload, {
                    id: payload.id,
                    error
                });
            }
        }
        return await super.getSigner(address);
    }
    /**
     *  Discover and connect to a Provider in the Browser using the
     *  [[link-eip-6963]] discovery mechanism. If no providers are
     *  present, ``null`` is resolved.
     */ static async discover(options) {
        if (options == null) {
            options = {};
        }
        if (options.provider) {
            return new BrowserProvider(options.provider);
        }
        const context = options.window ? options.window : typeof window !== "undefined" ? window : null;
        if (context == null) {
            return null;
        }
        const anyProvider = options.anyProvider;
        if (anyProvider && context.ethereum) {
            return new BrowserProvider(context.ethereum);
        }
        if (!("addEventListener" in context && "dispatchEvent" in context && "removeEventListener" in context)) {
            return null;
        }
        const timeout = options.timeout ? options.timeout : 300;
        if (timeout === 0) {
            return null;
        }
        return await new Promise((resolve, reject)=>{
            let found = [];
            const addProvider = (event)=>{
                found.push(event.detail);
                if (anyProvider) {
                    finalize();
                }
            };
            const finalize = ()=>{
                clearTimeout(timer);
                if (found.length) {
                    // If filtering is provided:
                    if (options && options.filter) {
                        // Call filter, with a copies of found provider infos
                        const filtered = options.filter(found.map((i)=>Object.assign({}, i.info)));
                        if (filtered == null) {
                            // No provider selected
                            resolve(null);
                        } else if (filtered instanceof BrowserProvider) {
                            // Custom provider created
                            resolve(filtered);
                        } else {
                            // Find the matching provider
                            let match = null;
                            if (filtered.uuid) {
                                const matches = found.filter((f)=>filtered.uuid === f.info.uuid);
                                // @TODO: What should happen if multiple values
                                //        for the same UUID?
                                match = matches[0];
                            }
                            if (match) {
                                const { provider, info } = match;
                                resolve(new BrowserProvider(provider, undefined, {
                                    providerInfo: info
                                }));
                            } else {
                                reject((0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["makeError"])("filter returned unknown info", "UNSUPPORTED_OPERATION", {
                                    value: filtered
                                }));
                            }
                        }
                    } else {
                        // Pick the first found provider
                        const { provider, info } = found[0];
                        resolve(new BrowserProvider(provider, undefined, {
                            providerInfo: info
                        }));
                    }
                } else {
                    // Nothing found
                    resolve(null);
                }
                context.removeEventListener("eip6963:announceProvider", addProvider);
            };
            const timer = setTimeout(()=>{
                finalize();
            }, timeout);
            context.addEventListener("eip6963:announceProvider", addProvider);
            context.dispatchEvent(new Event("eip6963:requestProvider"));
        });
    }
} //# sourceMappingURL=provider-browser.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-blockscout.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "BlockscoutProvider",
    ()=>BlockscoutProvider
]);
/**
 *  [[link-blockscout]] provides a third-party service for connecting to
 *  various blockchains over JSON-RPC.
 *
 *  **Supported Networks**
 *
 *  - Ethereum Mainnet (``mainnet``)
 *  - Sepolia Testnet (``sepolia``)
 *  - Holesky Testnet (``holesky``)
 *  - Ethereum Classic (``classic``)
 *  - Arbitrum (``arbitrum``)
 *  - Base (``base``)
 *  - Base Sepolia Testnet (``base-sepolia``)
 *  - Gnosis (``xdai``)
 *  - Optimism (``optimism``)
 *  - Optimism Sepolia Testnet (``optimism-sepolia``)
 *  - Polygon (``matic``)
 *
 *  @_subsection: api/providers/thirdparty:Blockscout  [providers-blockscout]
 */ var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/errors.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/properties.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$fetch$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/fetch.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/data.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/network.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$jsonrpc$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-jsonrpc.js [client] (ecmascript)");
;
;
;
function getUrl(name) {
    switch(name){
        case "mainnet":
            return "https:/\/eth.blockscout.com/api/eth-rpc";
        case "sepolia":
            return "https:/\/eth-sepolia.blockscout.com/api/eth-rpc";
        case "holesky":
            return "https:/\/eth-holesky.blockscout.com/api/eth-rpc";
        case "classic":
            return "https:/\/etc.blockscout.com/api/eth-rpc";
        case "arbitrum":
            return "https:/\/arbitrum.blockscout.com/api/eth-rpc";
        case "base":
            return "https:/\/base.blockscout.com/api/eth-rpc";
        case "base-sepolia":
            return "https:/\/base-sepolia.blockscout.com/api/eth-rpc";
        case "matic":
            return "https:/\/polygon.blockscout.com/api/eth-rpc";
        case "optimism":
            return "https:/\/optimism.blockscout.com/api/eth-rpc";
        case "optimism-sepolia":
            return "https:/\/optimism-sepolia.blockscout.com/api/eth-rpc";
        case "xdai":
            return "https:/\/gnosis.blockscout.com/api/eth-rpc";
    }
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, "unsupported network", "network", name);
}
class BlockscoutProvider extends __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$jsonrpc$2e$js__$5b$client$5d$__$28$ecmascript$29$__["JsonRpcProvider"] {
    /**
     *  The API key.
     */ apiKey;
    /**
     *  Creates a new **BlockscoutProvider**.
     */ constructor(_network, apiKey){
        if (_network == null) {
            _network = "mainnet";
        }
        const network = __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Network"].from(_network);
        if (apiKey == null) {
            apiKey = null;
        }
        const request = BlockscoutProvider.getRequest(network);
        super(request, network, {
            staticNetwork: network
        });
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            apiKey
        });
    }
    _getProvider(chainId) {
        try {
            return new BlockscoutProvider(chainId, this.apiKey);
        } catch (error) {}
        return super._getProvider(chainId);
    }
    isCommunityResource() {
        return this.apiKey === null;
    }
    getRpcRequest(req) {
        // Blockscout enforces the TAG argument for estimateGas
        const resp = super.getRpcRequest(req);
        if (resp && resp.method === "eth_estimateGas" && resp.args.length == 1) {
            resp.args = resp.args.slice();
            resp.args.push("latest");
        }
        return resp;
    }
    getRpcError(payload, _error) {
        const error = _error ? _error.error : null;
        // Blockscout currently drops the VM result and replaces it with a
        // human-readable string, so we need to make it machine-readable.
        if (error && error.code === -32015 && !(0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$data$2e$js__$5b$client$5d$__$28$ecmascript$29$__["isHexString"])(error.data || "", true)) {
            const panicCodes = {
                "assert(false)": "01",
                "arithmetic underflow or overflow": "11",
                "division or modulo by zero": "12",
                "out-of-bounds array access; popping on an empty array": "31",
                "out-of-bounds access of an array or bytesN": "32"
            };
            let panicCode = "";
            if (error.message === "VM execution error.") {
                // eth_call passes this message
                panicCode = panicCodes[error.data] || "";
            } else if (panicCodes[error.message || ""]) {
                panicCode = panicCodes[error.message || ""];
            }
            if (panicCode) {
                error.message += ` (reverted: ${error.data})`;
                error.data = "0x4e487b7100000000000000000000000000000000000000000000000000000000000000" + panicCode;
            }
        } else if (error && error.code === -32000) {
            if (error.message === "wrong transaction nonce") {
                error.message += " (nonce too low)";
            }
        }
        return super.getRpcError(payload, _error);
    }
    /**
     *  Returns a prepared request for connecting to %%network%%
     *  with %%apiKey%%.
     */ static getRequest(network) {
        const request = new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$fetch$2e$js__$5b$client$5d$__$28$ecmascript$29$__["FetchRequest"](getUrl(network.name));
        request.allowGzip = true;
        return request;
    }
} //# sourceMappingURL=provider-blockscout.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-pocket.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "PocketProvider",
    ()=>PocketProvider
]);
/**
 *  [[link-pocket]] provides a third-party service for connecting to
 *  various blockchains over JSON-RPC.
 *
 *  **Supported Networks**
 *
 *  - Ethereum Mainnet (``mainnet``)
 *  - Goerli Testnet (``goerli``)
 *  - Polygon (``matic``)
 *  - Arbitrum (``arbitrum``)
 *
 *  @_subsection: api/providers/thirdparty:Pocket  [providers-pocket]
 */ var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/properties.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$fetch$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/fetch.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/utils/errors.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$community$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/community.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/network.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$jsonrpc$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-jsonrpc.js [client] (ecmascript)");
;
;
;
;
const defaultApplicationId = "62e1ad51b37b8e00394bda3b";
function getHost(name) {
    switch(name){
        case "mainnet":
            return "eth-mainnet.gateway.pokt.network";
        case "goerli":
            return "eth-goerli.gateway.pokt.network";
        case "matic":
            return "poly-mainnet.gateway.pokt.network";
        case "matic-mumbai":
            return "polygon-mumbai-rpc.gateway.pokt.network";
    }
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$errors$2e$js__$5b$client$5d$__$28$ecmascript$29$__["assertArgument"])(false, "unsupported network", "network", name);
}
class PocketProvider extends __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$provider$2d$jsonrpc$2e$js__$5b$client$5d$__$28$ecmascript$29$__["JsonRpcProvider"] {
    /**
     *  The Application ID for the Pocket connection.
     */ applicationId;
    /**
     *  The Application Secret for making authenticated requests
     *  to the Pocket connection.
     */ applicationSecret;
    /**
     *  Create a new **PocketProvider**.
     *
     *  By default connecting to ``mainnet`` with a highly throttled
     *  API key.
     */ constructor(_network, applicationId, applicationSecret){
        if (_network == null) {
            _network = "mainnet";
        }
        const network = __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$network$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Network"].from(_network);
        if (applicationId == null) {
            applicationId = defaultApplicationId;
        }
        if (applicationSecret == null) {
            applicationSecret = null;
        }
        const options = {
            staticNetwork: network
        };
        const request = PocketProvider.getRequest(network, applicationId, applicationSecret);
        super(request, network, options);
        (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$properties$2e$js__$5b$client$5d$__$28$ecmascript$29$__["defineProperties"])(this, {
            applicationId,
            applicationSecret
        });
    }
    _getProvider(chainId) {
        try {
            return new PocketProvider(chainId, this.applicationId, this.applicationSecret);
        } catch (error) {}
        return super._getProvider(chainId);
    }
    /**
     *  Returns a prepared request for connecting to %%network%% with
     *  %%applicationId%%.
     */ static getRequest(network, applicationId, applicationSecret) {
        if (applicationId == null) {
            applicationId = defaultApplicationId;
        }
        const request = new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$utils$2f$fetch$2e$js__$5b$client$5d$__$28$ecmascript$29$__["FetchRequest"](`https:/\/${getHost(network.name)}/v1/lb/${applicationId}`);
        request.allowGzip = true;
        if (applicationSecret) {
            request.setCredentials("", applicationSecret);
        }
        if (applicationId === defaultApplicationId) {
            request.retryFunc = async (request, response, attempt)=>{
                (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$providers$2f$community$2e$js__$5b$client$5d$__$28$ecmascript$29$__["showThrottleMessage"])("PocketProvider");
                return true;
            };
        }
        return request;
    }
    isCommunityResource() {
        return this.applicationId === defaultApplicationId;
    }
} //# sourceMappingURL=provider-pocket.js.map
}),
"[project]/demo-frontend2/node_modules/ethers/lib.esm/providers/provider-ipcsocket-browser.js [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "IpcSocketProvider",
    ()=>IpcSocketProvider
]);
const IpcSocketProvider = undefined;
;
 //# sourceMappingURL=provider-ipcsocket-browser.js.map
}),
]);

//# sourceMappingURL=f03d5_ethers_lib_esm_providers_18506234._.js.map