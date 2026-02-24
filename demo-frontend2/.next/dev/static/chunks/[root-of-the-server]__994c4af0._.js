(globalThis.TURBOPACK || (globalThis.TURBOPACK = [])).push([typeof document === "object" ? document.currentScript : undefined,
"[turbopack]/browser/dev/hmr-client/hmr-client.ts [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

/// <reference path="../../../shared/runtime-types.d.ts" />
/// <reference path="../../runtime/base/dev-globals.d.ts" />
/// <reference path="../../runtime/base/dev-protocol.d.ts" />
/// <reference path="../../runtime/base/dev-extensions.ts" />
__turbopack_context__.s([
    "connect",
    ()=>connect,
    "setHooks",
    ()=>setHooks,
    "subscribeToUpdate",
    ()=>subscribeToUpdate
]);
function connect({ addMessageListener, sendMessage, onUpdateError = console.error }) {
    addMessageListener((msg)=>{
        switch(msg.type){
            case 'turbopack-connected':
                handleSocketConnected(sendMessage);
                break;
            default:
                try {
                    if (Array.isArray(msg.data)) {
                        for(let i = 0; i < msg.data.length; i++){
                            handleSocketMessage(msg.data[i]);
                        }
                    } else {
                        handleSocketMessage(msg.data);
                    }
                    applyAggregatedUpdates();
                } catch (e) {
                    console.warn('[Fast Refresh] performing full reload\n\n' + "Fast Refresh will perform a full reload when you edit a file that's imported by modules outside of the React rendering tree.\n" + 'You might have a file which exports a React component but also exports a value that is imported by a non-React component file.\n' + 'Consider migrating the non-React component export to a separate file and importing it into both files.\n\n' + 'It is also possible the parent component of the component you edited is a class component, which disables Fast Refresh.\n' + 'Fast Refresh requires at least one parent function component in your React tree.');
                    onUpdateError(e);
                    location.reload();
                }
                break;
        }
    });
    const queued = globalThis.TURBOPACK_CHUNK_UPDATE_LISTENERS;
    if (queued != null && !Array.isArray(queued)) {
        throw new Error('A separate HMR handler was already registered');
    }
    globalThis.TURBOPACK_CHUNK_UPDATE_LISTENERS = {
        push: ([chunkPath, callback])=>{
            subscribeToChunkUpdate(chunkPath, sendMessage, callback);
        }
    };
    if (Array.isArray(queued)) {
        for (const [chunkPath, callback] of queued){
            subscribeToChunkUpdate(chunkPath, sendMessage, callback);
        }
    }
}
const updateCallbackSets = new Map();
function sendJSON(sendMessage, message) {
    sendMessage(JSON.stringify(message));
}
function resourceKey(resource) {
    return JSON.stringify({
        path: resource.path,
        headers: resource.headers || null
    });
}
function subscribeToUpdates(sendMessage, resource) {
    sendJSON(sendMessage, {
        type: 'turbopack-subscribe',
        ...resource
    });
    return ()=>{
        sendJSON(sendMessage, {
            type: 'turbopack-unsubscribe',
            ...resource
        });
    };
}
function handleSocketConnected(sendMessage) {
    for (const key of updateCallbackSets.keys()){
        subscribeToUpdates(sendMessage, JSON.parse(key));
    }
}
// we aggregate all pending updates until the issues are resolved
const chunkListsWithPendingUpdates = new Map();
function aggregateUpdates(msg) {
    const key = resourceKey(msg.resource);
    let aggregated = chunkListsWithPendingUpdates.get(key);
    if (aggregated) {
        aggregated.instruction = mergeChunkListUpdates(aggregated.instruction, msg.instruction);
    } else {
        chunkListsWithPendingUpdates.set(key, msg);
    }
}
function applyAggregatedUpdates() {
    if (chunkListsWithPendingUpdates.size === 0) return;
    hooks.beforeRefresh();
    for (const msg of chunkListsWithPendingUpdates.values()){
        triggerUpdate(msg);
    }
    chunkListsWithPendingUpdates.clear();
    finalizeUpdate();
}
function mergeChunkListUpdates(updateA, updateB) {
    let chunks;
    if (updateA.chunks != null) {
        if (updateB.chunks == null) {
            chunks = updateA.chunks;
        } else {
            chunks = mergeChunkListChunks(updateA.chunks, updateB.chunks);
        }
    } else if (updateB.chunks != null) {
        chunks = updateB.chunks;
    }
    let merged;
    if (updateA.merged != null) {
        if (updateB.merged == null) {
            merged = updateA.merged;
        } else {
            // Since `merged` is an array of updates, we need to merge them all into
            // one, consistent update.
            // Since there can only be `EcmascriptMergeUpdates` in the array, there is
            // no need to key on the `type` field.
            let update = updateA.merged[0];
            for(let i = 1; i < updateA.merged.length; i++){
                update = mergeChunkListEcmascriptMergedUpdates(update, updateA.merged[i]);
            }
            for(let i = 0; i < updateB.merged.length; i++){
                update = mergeChunkListEcmascriptMergedUpdates(update, updateB.merged[i]);
            }
            merged = [
                update
            ];
        }
    } else if (updateB.merged != null) {
        merged = updateB.merged;
    }
    return {
        type: 'ChunkListUpdate',
        chunks,
        merged
    };
}
function mergeChunkListChunks(chunksA, chunksB) {
    const chunks = {};
    for (const [chunkPath, chunkUpdateA] of Object.entries(chunksA)){
        const chunkUpdateB = chunksB[chunkPath];
        if (chunkUpdateB != null) {
            const mergedUpdate = mergeChunkUpdates(chunkUpdateA, chunkUpdateB);
            if (mergedUpdate != null) {
                chunks[chunkPath] = mergedUpdate;
            }
        } else {
            chunks[chunkPath] = chunkUpdateA;
        }
    }
    for (const [chunkPath, chunkUpdateB] of Object.entries(chunksB)){
        if (chunks[chunkPath] == null) {
            chunks[chunkPath] = chunkUpdateB;
        }
    }
    return chunks;
}
function mergeChunkUpdates(updateA, updateB) {
    if (updateA.type === 'added' && updateB.type === 'deleted' || updateA.type === 'deleted' && updateB.type === 'added') {
        return undefined;
    }
    if (updateA.type === 'partial') {
        invariant(updateA.instruction, 'Partial updates are unsupported');
    }
    if (updateB.type === 'partial') {
        invariant(updateB.instruction, 'Partial updates are unsupported');
    }
    return undefined;
}
function mergeChunkListEcmascriptMergedUpdates(mergedA, mergedB) {
    const entries = mergeEcmascriptChunkEntries(mergedA.entries, mergedB.entries);
    const chunks = mergeEcmascriptChunksUpdates(mergedA.chunks, mergedB.chunks);
    return {
        type: 'EcmascriptMergedUpdate',
        entries,
        chunks
    };
}
function mergeEcmascriptChunkEntries(entriesA, entriesB) {
    return {
        ...entriesA,
        ...entriesB
    };
}
function mergeEcmascriptChunksUpdates(chunksA, chunksB) {
    if (chunksA == null) {
        return chunksB;
    }
    if (chunksB == null) {
        return chunksA;
    }
    const chunks = {};
    for (const [chunkPath, chunkUpdateA] of Object.entries(chunksA)){
        const chunkUpdateB = chunksB[chunkPath];
        if (chunkUpdateB != null) {
            const mergedUpdate = mergeEcmascriptChunkUpdates(chunkUpdateA, chunkUpdateB);
            if (mergedUpdate != null) {
                chunks[chunkPath] = mergedUpdate;
            }
        } else {
            chunks[chunkPath] = chunkUpdateA;
        }
    }
    for (const [chunkPath, chunkUpdateB] of Object.entries(chunksB)){
        if (chunks[chunkPath] == null) {
            chunks[chunkPath] = chunkUpdateB;
        }
    }
    if (Object.keys(chunks).length === 0) {
        return undefined;
    }
    return chunks;
}
function mergeEcmascriptChunkUpdates(updateA, updateB) {
    if (updateA.type === 'added' && updateB.type === 'deleted') {
        // These two completely cancel each other out.
        return undefined;
    }
    if (updateA.type === 'deleted' && updateB.type === 'added') {
        const added = [];
        const deleted = [];
        const deletedModules = new Set(updateA.modules ?? []);
        const addedModules = new Set(updateB.modules ?? []);
        for (const moduleId of addedModules){
            if (!deletedModules.has(moduleId)) {
                added.push(moduleId);
            }
        }
        for (const moduleId of deletedModules){
            if (!addedModules.has(moduleId)) {
                deleted.push(moduleId);
            }
        }
        if (added.length === 0 && deleted.length === 0) {
            return undefined;
        }
        return {
            type: 'partial',
            added,
            deleted
        };
    }
    if (updateA.type === 'partial' && updateB.type === 'partial') {
        const added = new Set([
            ...updateA.added ?? [],
            ...updateB.added ?? []
        ]);
        const deleted = new Set([
            ...updateA.deleted ?? [],
            ...updateB.deleted ?? []
        ]);
        if (updateB.added != null) {
            for (const moduleId of updateB.added){
                deleted.delete(moduleId);
            }
        }
        if (updateB.deleted != null) {
            for (const moduleId of updateB.deleted){
                added.delete(moduleId);
            }
        }
        return {
            type: 'partial',
            added: [
                ...added
            ],
            deleted: [
                ...deleted
            ]
        };
    }
    if (updateA.type === 'added' && updateB.type === 'partial') {
        const modules = new Set([
            ...updateA.modules ?? [],
            ...updateB.added ?? []
        ]);
        for (const moduleId of updateB.deleted ?? []){
            modules.delete(moduleId);
        }
        return {
            type: 'added',
            modules: [
                ...modules
            ]
        };
    }
    if (updateA.type === 'partial' && updateB.type === 'deleted') {
        // We could eagerly return `updateB` here, but this would potentially be
        // incorrect if `updateA` has added modules.
        const modules = new Set(updateB.modules ?? []);
        if (updateA.added != null) {
            for (const moduleId of updateA.added){
                modules.delete(moduleId);
            }
        }
        return {
            type: 'deleted',
            modules: [
                ...modules
            ]
        };
    }
    // Any other update combination is invalid.
    return undefined;
}
function invariant(_, message) {
    throw new Error(`Invariant: ${message}`);
}
const CRITICAL = [
    'bug',
    'error',
    'fatal'
];
function compareByList(list, a, b) {
    const aI = list.indexOf(a) + 1 || list.length;
    const bI = list.indexOf(b) + 1 || list.length;
    return aI - bI;
}
const chunksWithIssues = new Map();
function emitIssues() {
    const issues = [];
    const deduplicationSet = new Set();
    for (const [_, chunkIssues] of chunksWithIssues){
        for (const chunkIssue of chunkIssues){
            if (deduplicationSet.has(chunkIssue.formatted)) continue;
            issues.push(chunkIssue);
            deduplicationSet.add(chunkIssue.formatted);
        }
    }
    sortIssues(issues);
    hooks.issues(issues);
}
function handleIssues(msg) {
    const key = resourceKey(msg.resource);
    let hasCriticalIssues = false;
    for (const issue of msg.issues){
        if (CRITICAL.includes(issue.severity)) {
            hasCriticalIssues = true;
        }
    }
    if (msg.issues.length > 0) {
        chunksWithIssues.set(key, msg.issues);
    } else if (chunksWithIssues.has(key)) {
        chunksWithIssues.delete(key);
    }
    emitIssues();
    return hasCriticalIssues;
}
const SEVERITY_ORDER = [
    'bug',
    'fatal',
    'error',
    'warning',
    'info',
    'log'
];
const CATEGORY_ORDER = [
    'parse',
    'resolve',
    'code generation',
    'rendering',
    'typescript',
    'other'
];
function sortIssues(issues) {
    issues.sort((a, b)=>{
        const first = compareByList(SEVERITY_ORDER, a.severity, b.severity);
        if (first !== 0) return first;
        return compareByList(CATEGORY_ORDER, a.category, b.category);
    });
}
const hooks = {
    beforeRefresh: ()=>{},
    refresh: ()=>{},
    buildOk: ()=>{},
    issues: (_issues)=>{}
};
function setHooks(newHooks) {
    Object.assign(hooks, newHooks);
}
function handleSocketMessage(msg) {
    sortIssues(msg.issues);
    handleIssues(msg);
    switch(msg.type){
        case 'issues':
            break;
        case 'partial':
            // aggregate updates
            aggregateUpdates(msg);
            break;
        default:
            // run single update
            const runHooks = chunkListsWithPendingUpdates.size === 0;
            if (runHooks) hooks.beforeRefresh();
            triggerUpdate(msg);
            if (runHooks) finalizeUpdate();
            break;
    }
}
function finalizeUpdate() {
    hooks.refresh();
    hooks.buildOk();
    // This is used by the Next.js integration test suite to notify it when HMR
    // updates have been completed.
    // TODO: Only run this in test environments (gate by `process.env.__NEXT_TEST_MODE`)
    if (globalThis.__NEXT_HMR_CB) {
        globalThis.__NEXT_HMR_CB();
        globalThis.__NEXT_HMR_CB = null;
    }
}
function subscribeToChunkUpdate(chunkListPath, sendMessage, callback) {
    return subscribeToUpdate({
        path: chunkListPath
    }, sendMessage, callback);
}
function subscribeToUpdate(resource, sendMessage, callback) {
    const key = resourceKey(resource);
    let callbackSet;
    const existingCallbackSet = updateCallbackSets.get(key);
    if (!existingCallbackSet) {
        callbackSet = {
            callbacks: new Set([
                callback
            ]),
            unsubscribe: subscribeToUpdates(sendMessage, resource)
        };
        updateCallbackSets.set(key, callbackSet);
    } else {
        existingCallbackSet.callbacks.add(callback);
        callbackSet = existingCallbackSet;
    }
    return ()=>{
        callbackSet.callbacks.delete(callback);
        if (callbackSet.callbacks.size === 0) {
            callbackSet.unsubscribe();
            updateCallbackSets.delete(key);
        }
    };
}
function triggerUpdate(msg) {
    const key = resourceKey(msg.resource);
    const callbackSet = updateCallbackSets.get(key);
    if (!callbackSet) {
        return;
    }
    for (const callback of callbackSet.callbacks){
        callback(msg);
    }
    if (msg.type === 'notFound') {
        // This indicates that the resource which we subscribed to either does not exist or
        // has been deleted. In either case, we should clear all update callbacks, so if a
        // new subscription is created for the same resource, it will send a new "subscribe"
        // message to the server.
        // No need to send an "unsubscribe" message to the server, it will have already
        // dropped the update stream before sending the "notFound" message.
        updateCallbackSets.delete(key);
    }
}
}),
"[project]/demo-frontend2/src/lib/interactiveApi.ts [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "interactiveApi",
    ()=>interactiveApi
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$next$2f$dist$2f$build$2f$polyfills$2f$process$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = /*#__PURE__*/ __turbopack_context__.i("[project]/demo-frontend2/node_modules/next/dist/build/polyfills/process.js [client] (ecmascript)");
const BACKEND_URL = ("TURBOPACK compile-time value", "http://localhost:3001") || 'http://localhost:3001';
const interactiveApi = {
    // 게임 생성
    createGame: async (rootBlock, userAddress)=>{
        const res = await fetch(`${BACKEND_URL}/api/game/create`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                rootBlock,
                userAddress
            })
        });
        const data = await res.json();
        if (!data.success) throw new Error('Failed to create game');
        return data.game;
    },
    // 게임 상태 조회
    getGameStatus: async (gameId)=>{
        const res = await fetch(`${BACKEND_URL}/api/game/${gameId}/status`);
        const data = await res.json();
        if (!data.success) throw new Error('Failed to get game status');
        return data.game;
    },
    // 유효한 move들 조회
    getValidMoves: async (gameId, userAddress)=>{
        const res = await fetch(`${BACKEND_URL}/api/game/${gameId}/moves?userAddress=${userAddress}`);
        const data = await res.json();
        if (!data.success) throw new Error('Failed to get valid moves');
        return data.moves;
    },
    // move 제출
    submitMove: async (gameId, moveId, userAddress)=>{
        const res = await fetch(`${BACKEND_URL}/api/game/${gameId}/move/submit`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                moveId,
                userAddress
            })
        });
        const data = await res.json();
        if (!data.success) throw new Error('Failed to submit move');
        return data.claimId;
    },
    // 게임 종료
    resolveGame: async (gameId)=>{
        const res = await fetch(`${BACKEND_URL}/api/game/${gameId}/resolve`, {
            method: 'POST'
        });
        const data = await res.json();
        if (!data.success) throw new Error('Failed to resolve game');
        return data.reward;
    }
};
if (typeof globalThis.$RefreshHelpers$ === 'object' && globalThis.$RefreshHelpers !== null) {
    __turbopack_context__.k.registerExports(__turbopack_context__.m, globalThis.$RefreshHelpers$);
}
}),
"[project]/demo-frontend2/src/hooks/useInteractiveGame.ts [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "useInteractiveGame",
    ()=>useInteractiveGame
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$index$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/react/index.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$lib$2f$interactiveApi$2e$ts__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/src/lib/interactiveApi.ts [client] (ecmascript)");
var _s = __turbopack_context__.k.signature();
;
;
function useInteractiveGame(userAddress) {
    _s();
    const [game, setGame] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$index$2e$js__$5b$client$5d$__$28$ecmascript$29$__["useState"])(null);
    const [moves, setMoves] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$index$2e$js__$5b$client$5d$__$28$ecmascript$29$__["useState"])([]);
    const [selectedMove, setSelectedMove] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$index$2e$js__$5b$client$5d$__$28$ecmascript$29$__["useState"])(null);
    const [loading, setLoading] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$index$2e$js__$5b$client$5d$__$28$ecmascript$29$__["useState"])(false);
    const [error, setError] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$index$2e$js__$5b$client$5d$__$28$ecmascript$29$__["useState"])(null);
    // 게임 생성
    const createGame = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$index$2e$js__$5b$client$5d$__$28$ecmascript$29$__["useCallback"])({
        "useInteractiveGame.useCallback[createGame]": async (rootBlock)=>{
            setLoading(true);
            setError(null);
            try {
                const newGame = await __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$lib$2f$interactiveApi$2e$ts__$5b$client$5d$__$28$ecmascript$29$__["interactiveApi"].createGame(rootBlock, userAddress);
                setGame(newGame);
                return newGame;
            } catch (err) {
                setError(err.message || 'Failed to create game');
                throw err;
            } finally{
                setLoading(false);
            }
        }
    }["useInteractiveGame.useCallback[createGame]"], [
        userAddress
    ]);
    // 게임 상태 갱신
    const refreshGame = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$index$2e$js__$5b$client$5d$__$28$ecmascript$29$__["useCallback"])({
        "useInteractiveGame.useCallback[refreshGame]": async ()=>{
            if (!game?.id) return;
            setLoading(true);
            setError(null);
            try {
                const updatedGame = await __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$lib$2f$interactiveApi$2e$ts__$5b$client$5d$__$28$ecmascript$29$__["interactiveApi"].getGameStatus(game.id);
                setGame(updatedGame);
            } catch (err) {
                setError(err.message || 'Failed to refresh game');
            } finally{
                setLoading(false);
            }
        }
    }["useInteractiveGame.useCallback[refreshGame]"], [
        game?.id
    ]);
    // 유효한 move들 로드
    const loadMoves = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$index$2e$js__$5b$client$5d$__$28$ecmascript$29$__["useCallback"])({
        "useInteractiveGame.useCallback[loadMoves]": async ()=>{
            if (!game?.id) return;
            setLoading(true);
            setError(null);
            try {
                const validMoves = await __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$lib$2f$interactiveApi$2e$ts__$5b$client$5d$__$28$ecmascript$29$__["interactiveApi"].getValidMoves(game.id, userAddress);
                setMoves(validMoves);
            } catch (err) {
                setError(err.message || 'Failed to load moves');
            } finally{
                setLoading(false);
            }
        }
    }["useInteractiveGame.useCallback[loadMoves]"], [
        game?.id,
        userAddress
    ]);
    // move 제출
    const submitMove = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$index$2e$js__$5b$client$5d$__$28$ecmascript$29$__["useCallback"])({
        "useInteractiveGame.useCallback[submitMove]": async ()=>{
            if (!game?.id || !selectedMove) return;
            setLoading(true);
            setError(null);
            try {
                await __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$lib$2f$interactiveApi$2e$ts__$5b$client$5d$__$28$ecmascript$29$__["interactiveApi"].submitMove(game.id, selectedMove.id, userAddress);
                setSelectedMove(null);
                setMoves([]);
                await refreshGame();
            } catch (err) {
                setError(err.message || 'Failed to submit move');
                throw err;
            } finally{
                setLoading(false);
            }
        }
    }["useInteractiveGame.useCallback[submitMove]"], [
        game?.id,
        selectedMove,
        userAddress,
        refreshGame
    ]);
    // 게임 종료
    const resolveGame = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$index$2e$js__$5b$client$5d$__$28$ecmascript$29$__["useCallback"])({
        "useInteractiveGame.useCallback[resolveGame]": async ()=>{
            if (!game?.id) return;
            setLoading(true);
            setError(null);
            try {
                const reward = await __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$lib$2f$interactiveApi$2e$ts__$5b$client$5d$__$28$ecmascript$29$__["interactiveApi"].resolveGame(game.id);
                await refreshGame();
                return reward;
            } catch (err) {
                setError(err.message || 'Failed to resolve game');
                throw err;
            } finally{
                setLoading(false);
            }
        }
    }["useInteractiveGame.useCallback[resolveGame]"], [
        game?.id,
        refreshGame
    ]);
    // 주기적으로 상태 갱신
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$index$2e$js__$5b$client$5d$__$28$ecmascript$29$__["useEffect"])({
        "useInteractiveGame.useEffect": ()=>{
            if (!game?.id) return;
            const interval = setInterval({
                "useInteractiveGame.useEffect.interval": ()=>{
                    refreshGame();
                }
            }["useInteractiveGame.useEffect.interval"], 5000); // 5초마다 갱신
            return ({
                "useInteractiveGame.useEffect": ()=>clearInterval(interval)
            })["useInteractiveGame.useEffect"];
        }
    }["useInteractiveGame.useEffect"], [
        game?.id,
        refreshGame
    ]);
    return {
        game,
        moves,
        selectedMove,
        setSelectedMove,
        loading,
        error,
        createGame,
        refreshGame,
        loadMoves,
        submitMove,
        resolveGame
    };
}
_s(useInteractiveGame, "a7C3MwJZfw4rQNDWuwXUkGgklRQ=");
if (typeof globalThis.$RefreshHelpers$ === 'object' && globalThis.$RefreshHelpers !== null) {
    __turbopack_context__.k.registerExports(__turbopack_context__.m, globalThis.$RefreshHelpers$);
}
}),
"[project]/demo-frontend2/src/components/GameInfoPanel.tsx [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "default",
    ()=>GameInfoPanel
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/react/jsx-dev-runtime.js [client] (ecmascript)");
;
function GameInfoPanel({ game }) {
    if (!game) {
        return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
            className: "bg-white rounded-lg shadow p-6",
            children: [
                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("h2", {
                    className: "text-xl font-bold mb-4",
                    children: "🎮 게임 정보"
                }, void 0, false, {
                    fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
                    lineNumber: 11,
                    columnNumber: 9
                }, this),
                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                    className: "text-gray-600",
                    children: "게임이 생성되지 않았습니다."
                }, void 0, false, {
                    fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
                    lineNumber: 12,
                    columnNumber: 9
                }, this)
            ]
        }, void 0, true, {
            fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
            lineNumber: 10,
            columnNumber: 7
        }, this);
    }
    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
        className: "bg-white rounded-lg shadow p-6",
        children: [
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("h2", {
                className: "text-xl font-bold mb-4",
                children: "🎮 게임 정보"
            }, void 0, false, {
                fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
                lineNumber: 19,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                className: "space-y-3",
                children: [
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "flex justify-between",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                className: "text-gray-600",
                                children: "게임 ID:"
                            }, void 0, false, {
                                fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
                                lineNumber: 23,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                className: "font-mono text-sm",
                                children: [
                                    game.id.slice(0, 10),
                                    "..."
                                ]
                            }, void 0, true, {
                                fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
                                lineNumber: 24,
                                columnNumber: 11
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
                        lineNumber: 22,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "flex justify-between",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                className: "text-gray-600",
                                children: "상태:"
                            }, void 0, false, {
                                fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
                                lineNumber: 28,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                className: `font-bold ${game.status === 'IN_PROGRESS' ? 'text-blue-600' : game.status === 'CHALLENGER_WINS' ? 'text-green-600' : 'text-red-600'}`,
                                children: game.status === 'IN_PROGRESS' ? '진행 중' : game.status === 'CHALLENGER_WINS' ? '챌린저 승리!' : '제안자 승리'
                            }, void 0, false, {
                                fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
                                lineNumber: 29,
                                columnNumber: 11
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
                        lineNumber: 27,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "flex justify-between",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                className: "text-gray-600",
                                children: "Root Block:"
                            }, void 0, false, {
                                fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
                                lineNumber: 41,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                children: [
                                    "#",
                                    game.rootBlock
                                ]
                            }, void 0, true, {
                                fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
                                lineNumber: 42,
                                columnNumber: 11
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
                        lineNumber: 40,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "flex justify-between",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                className: "text-gray-600",
                                children: "Max Depth:"
                            }, void 0, false, {
                                fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
                                lineNumber: 46,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                children: game.maxDepth
                            }, void 0, false, {
                                fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
                                lineNumber: 47,
                                columnNumber: 11
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
                        lineNumber: 45,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "flex justify-between",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                className: "text-gray-600",
                                children: "Claim 수:"
                            }, void 0, false, {
                                fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
                                lineNumber: 51,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                children: game.claims.length
                            }, void 0, false, {
                                fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
                                lineNumber: 52,
                                columnNumber: 11
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
                        lineNumber: 50,
                        columnNumber: 9
                    }, this),
                    game.winner && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "mt-4 p-3 bg-green-50 rounded",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                className: "text-gray-600",
                                children: "승자:"
                            }, void 0, false, {
                                fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
                                lineNumber: 57,
                                columnNumber: 13
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                className: "font-mono text-sm ml-2",
                                children: [
                                    game.winner.slice(0, 10),
                                    "..."
                                ]
                            }, void 0, true, {
                                fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
                                lineNumber: 58,
                                columnNumber: 13
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
                        lineNumber: 56,
                        columnNumber: 11
                    }, this)
                ]
            }, void 0, true, {
                fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
                lineNumber: 21,
                columnNumber: 7
            }, this)
        ]
    }, void 0, true, {
        fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
        lineNumber: 18,
        columnNumber: 5
    }, this);
}
_c = GameInfoPanel;
var _c;
__turbopack_context__.k.register(_c, "GameInfoPanel");
if (typeof globalThis.$RefreshHelpers$ === 'object' && globalThis.$RefreshHelpers !== null) {
    __turbopack_context__.k.registerExports(__turbopack_context__.m, globalThis.$RefreshHelpers$);
}
}),
"[project]/demo-frontend2/src/components/MoveSelectionPanel.tsx [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "default",
    ()=>MoveSelectionPanel
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/react/jsx-dev-runtime.js [client] (ecmascript)");
;
function MoveSelectionPanel({ moves, selectedMove, onSelectMove, onSubmit, loading }) {
    if (moves.length === 0) {
        return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
            className: "bg-white rounded-lg shadow p-6",
            children: [
                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("h2", {
                    className: "text-xl font-bold mb-4",
                    children: "🎯 Move 선택"
                }, void 0, false, {
                    fileName: "[project]/demo-frontend2/src/components/MoveSelectionPanel.tsx",
                    lineNumber: 21,
                    columnNumber: 9
                }, this),
                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                    className: "text-gray-600",
                    children: "가능한 move가 없습니다."
                }, void 0, false, {
                    fileName: "[project]/demo-frontend2/src/components/MoveSelectionPanel.tsx",
                    lineNumber: 22,
                    columnNumber: 9
                }, this)
            ]
        }, void 0, true, {
            fileName: "[project]/demo-frontend2/src/components/MoveSelectionPanel.tsx",
            lineNumber: 20,
            columnNumber: 7
        }, this);
    }
    const getRiskColor = (level)=>{
        switch(level){
            case 'low':
                return 'bg-green-100 text-green-800';
            case 'medium':
                return 'bg-yellow-100 text-yellow-800';
            case 'high':
                return 'bg-red-100 text-red-800';
            default:
                return 'bg-gray-100 text-gray-800';
        }
    };
    const getOutcomeIcon = (outcome)=>{
        switch(outcome){
            case 'win':
                return '✅';
            case 'lose':
                return '❌';
            default:
                return '❓';
        }
    };
    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
        className: "bg-white rounded-lg shadow p-6",
        children: [
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("h2", {
                className: "text-xl font-bold mb-4",
                children: "🎯 당신의 차례!"
            }, void 0, false, {
                fileName: "[project]/demo-frontend2/src/components/MoveSelectionPanel.tsx",
                lineNumber: 46,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                className: "text-gray-600 mb-6",
                children: "다음 중 하나를 선택하세요:"
            }, void 0, false, {
                fileName: "[project]/demo-frontend2/src/components/MoveSelectionPanel.tsx",
                lineNumber: 47,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                className: "grid grid-cols-1 md:grid-cols-2 gap-4 mb-6",
                children: moves.map((move)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: `p-4 rounded-lg border-2 cursor-pointer transition-all ${selectedMove?.id === move.id ? 'border-primary-500 bg-primary-50' : 'border-gray-200 hover:border-primary-300 hover:bg-gray-50'}`,
                        onClick: ()=>onSelectMove(move),
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "flex items-center justify-between mb-3",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        className: "flex items-center gap-2",
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                className: "text-2xl",
                                                children: move.type === 'attack' ? '🗡️' : '🛡️'
                                            }, void 0, false, {
                                                fileName: "[project]/demo-frontend2/src/components/MoveSelectionPanel.tsx",
                                                lineNumber: 62,
                                                columnNumber: 17
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                className: "font-bold uppercase text-sm",
                                                children: move.type
                                            }, void 0, false, {
                                                fileName: "[project]/demo-frontend2/src/components/MoveSelectionPanel.tsx",
                                                lineNumber: 65,
                                                columnNumber: 17
                                            }, this)
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/demo-frontend2/src/components/MoveSelectionPanel.tsx",
                                        lineNumber: 61,
                                        columnNumber: 15
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                        className: "text-lg",
                                        children: getOutcomeIcon(move.expectedOutcome)
                                    }, void 0, false, {
                                        fileName: "[project]/demo-frontend2/src/components/MoveSelectionPanel.tsx",
                                        lineNumber: 69,
                                        columnNumber: 15
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/demo-frontend2/src/components/MoveSelectionPanel.tsx",
                                lineNumber: 60,
                                columnNumber: 13
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("h3", {
                                className: "font-semibold mb-2",
                                children: move.description
                            }, void 0, false, {
                                fileName: "[project]/demo-frontend2/src/components/MoveSelectionPanel.tsx",
                                lineNumber: 74,
                                columnNumber: 13
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: `inline-block px-2 py-1 rounded text-xs font-medium ${getRiskColor(move.riskLevel)} mb-3`,
                                children: move.riskLevel.toUpperCase()
                            }, void 0, false, {
                                fileName: "[project]/demo-frontend2/src/components/MoveSelectionPanel.tsx",
                                lineNumber: 76,
                                columnNumber: 13
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "text-sm text-gray-600 bg-gray-50 p-2 rounded",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                        className: "font-medium",
                                        children: "💡 "
                                    }, void 0, false, {
                                        fileName: "[project]/demo-frontend2/src/components/MoveSelectionPanel.tsx",
                                        lineNumber: 81,
                                        columnNumber: 15
                                    }, this),
                                    move.strategyHint
                                ]
                            }, void 0, true, {
                                fileName: "[project]/demo-frontend2/src/components/MoveSelectionPanel.tsx",
                                lineNumber: 80,
                                columnNumber: 13
                            }, this)
                        ]
                    }, move.id, true, {
                        fileName: "[project]/demo-frontend2/src/components/MoveSelectionPanel.tsx",
                        lineNumber: 51,
                        columnNumber: 11
                    }, this))
            }, void 0, false, {
                fileName: "[project]/demo-frontend2/src/components/MoveSelectionPanel.tsx",
                lineNumber: 49,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                onClick: onSubmit,
                disabled: !selectedMove || loading,
                className: `w-full py-3 px-6 rounded-lg font-bold text-white transition-colors ${!selectedMove || loading ? 'bg-gray-300 cursor-not-allowed' : 'bg-primary-600 hover:bg-primary-700'}`,
                children: loading ? '제출 중...' : '선택한 Move 제출하기'
            }, void 0, false, {
                fileName: "[project]/demo-frontend2/src/components/MoveSelectionPanel.tsx",
                lineNumber: 88,
                columnNumber: 7
            }, this)
        ]
    }, void 0, true, {
        fileName: "[project]/demo-frontend2/src/components/MoveSelectionPanel.tsx",
        lineNumber: 45,
        columnNumber: 5
    }, this);
}
_c = MoveSelectionPanel;
var _c;
__turbopack_context__.k.register(_c, "MoveSelectionPanel");
if (typeof globalThis.$RefreshHelpers$ === 'object' && globalThis.$RefreshHelpers !== null) {
    __turbopack_context__.k.registerExports(__turbopack_context__.m, globalThis.$RefreshHelpers$);
}
}),
"[project]/demo-frontend2/src/components/RewardPanel.tsx [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "default",
    ()=>RewardPanel
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/react/jsx-dev-runtime.js [client] (ecmascript)");
;
function RewardPanel({ reward, userAddress }) {
    if (!reward) {
        return null;
    }
    const isUserWinner = reward.winner?.toLowerCase() === userAddress.toLowerCase();
    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
        className: "bg-white rounded-lg shadow p-6",
        children: [
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("h2", {
                className: "text-xl font-bold mb-4",
                children: "🎁 보상 분배"
            }, void 0, false, {
                fileName: "[project]/demo-frontend2/src/components/RewardPanel.tsx",
                lineNumber: 15,
                columnNumber: 7
            }, this),
            isUserWinner ? /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                className: "bg-green-50 border-green-200 rounded-lg p-6 text-center",
                children: [
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "text-6xl mb-4",
                        children: "🎉"
                    }, void 0, false, {
                        fileName: "[project]/demo-frontend2/src/components/RewardPanel.tsx",
                        lineNumber: 19,
                        columnNumber: 11
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("h3", {
                        className: "text-2xl font-bold text-green-800 mb-2",
                        children: "축하합니다! 승리하셨습니다!"
                    }, void 0, false, {
                        fileName: "[project]/demo-frontend2/src/components/RewardPanel.tsx",
                        lineNumber: 20,
                        columnNumber: 11
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                        className: "text-green-700",
                        children: [
                            "보상: ",
                            reward.rewardAmount,
                            " WTON"
                        ]
                    }, void 0, true, {
                        fileName: "[project]/demo-frontend2/src/components/RewardPanel.tsx",
                        lineNumber: 23,
                        columnNumber: 11
                    }, this)
                ]
            }, void 0, true, {
                fileName: "[project]/demo-frontend2/src/components/RewardPanel.tsx",
                lineNumber: 18,
                columnNumber: 9
            }, this) : /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                className: "bg-red-50 border-red-200 rounded-lg p-6 text-center",
                children: [
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "text-6xl mb-4",
                        children: "😢"
                    }, void 0, false, {
                        fileName: "[project]/demo-frontend2/src/components/RewardPanel.tsx",
                        lineNumber: 29,
                        columnNumber: 11
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("h3", {
                        className: "text-2xl font-bold text-red-800 mb-2",
                        children: "아쉽네요..."
                    }, void 0, false, {
                        fileName: "[project]/demo-frontend2/src/components/RewardPanel.tsx",
                        lineNumber: 30,
                        columnNumber: 11
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                        className: "text-red-700",
                        children: [
                            "승자: ",
                            reward.winner?.slice(0, 10),
                            "..."
                        ]
                    }, void 0, true, {
                        fileName: "[project]/demo-frontend2/src/components/RewardPanel.tsx",
                        lineNumber: 33,
                        columnNumber: 11
                    }, this)
                ]
            }, void 0, true, {
                fileName: "[project]/demo-frontend2/src/components/RewardPanel.tsx",
                lineNumber: 28,
                columnNumber: 9
            }, this),
            reward.slashedAddresses && reward.slashedAddresses.length > 0 && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                className: "mt-4 p-4 bg-orange-50 rounded-lg",
                children: [
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("h4", {
                        className: "font-semibold mb-2",
                        children: "슬래싱된 계정:"
                    }, void 0, false, {
                        fileName: "[project]/demo-frontend2/src/components/RewardPanel.tsx",
                        lineNumber: 41,
                        columnNumber: 11
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "space-y-2",
                        children: reward.slashedAddresses.map((addr, i)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "text-sm font-mono",
                                children: [
                                    addr.slice(0, 10),
                                    "... - ",
                                    reward.slashedAmounts[i],
                                    " WTON"
                                ]
                            }, i, true, {
                                fileName: "[project]/demo-frontend2/src/components/RewardPanel.tsx",
                                lineNumber: 44,
                                columnNumber: 15
                            }, this))
                    }, void 0, false, {
                        fileName: "[project]/demo-frontend2/src/components/RewardPanel.tsx",
                        lineNumber: 42,
                        columnNumber: 11
                    }, this)
                ]
            }, void 0, true, {
                fileName: "[project]/demo-frontend2/src/components/RewardPanel.tsx",
                lineNumber: 40,
                columnNumber: 9
            }, this)
        ]
    }, void 0, true, {
        fileName: "[project]/demo-frontend2/src/components/RewardPanel.tsx",
        lineNumber: 14,
        columnNumber: 5
    }, this);
}
_c = RewardPanel;
var _c;
__turbopack_context__.k.register(_c, "RewardPanel");
if (typeof globalThis.$RefreshHelpers$ === 'object' && globalThis.$RefreshHelpers !== null) {
    __turbopack_context__.k.registerExports(__turbopack_context__.m, globalThis.$RefreshHelpers$);
}
}),
"[project]/demo-frontend2/src/components/GameLogPanel.tsx [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "default",
    ()=>GameLogPanel
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/react/jsx-dev-runtime.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$index$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/react/index.js [client] (ecmascript)");
;
var _s = __turbopack_context__.k.signature();
;
function GameLogPanel() {
    _s();
    const [logs, setLogs] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$index$2e$js__$5b$client$5d$__$28$ecmascript$29$__["useState"])([]);
    const addLog = (message)=>{
        const time = new Date().toLocaleTimeString();
        setLogs((prev)=>[
                {
                    time,
                    message
                },
                ...prev
            ]);
    };
    // 컴포넌트에서 사용할 수 있도록
    // 실제로는 부모 컴포넌트에서 로그를 전달받아야 함
    // 여기서는 예시로 정적 로그를 보여줌
    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
        className: "bg-white rounded-lg shadow p-6",
        children: [
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("h2", {
                className: "text-xl font-bold mb-4",
                children: "📜 게임 로그"
            }, void 0, false, {
                fileName: "[project]/demo-frontend2/src/components/GameLogPanel.tsx",
                lineNumber: 22,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                className: "bg-gray-50 rounded-lg p-4 h-64 overflow-y-auto",
                children: logs.length === 0 ? /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                    className: "text-gray-500 text-center py-8",
                    children: "아직 로그가 없습니다."
                }, void 0, false, {
                    fileName: "[project]/demo-frontend2/src/components/GameLogPanel.tsx",
                    lineNumber: 26,
                    columnNumber: 11
                }, this) : /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                    className: "space-y-2",
                    children: logs.map((log, i)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                            className: "text-sm",
                            children: [
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                    className: "text-gray-500",
                                    children: [
                                        "[",
                                        log.time,
                                        "]"
                                    ]
                                }, void 0, true, {
                                    fileName: "[project]/demo-frontend2/src/components/GameLogPanel.tsx",
                                    lineNumber: 33,
                                    columnNumber: 17
                                }, this),
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                    className: "ml-2",
                                    children: log.message
                                }, void 0, false, {
                                    fileName: "[project]/demo-frontend2/src/components/GameLogPanel.tsx",
                                    lineNumber: 34,
                                    columnNumber: 17
                                }, this)
                            ]
                        }, i, true, {
                            fileName: "[project]/demo-frontend2/src/components/GameLogPanel.tsx",
                            lineNumber: 32,
                            columnNumber: 15
                        }, this))
                }, void 0, false, {
                    fileName: "[project]/demo-frontend2/src/components/GameLogPanel.tsx",
                    lineNumber: 30,
                    columnNumber: 11
                }, this)
            }, void 0, false, {
                fileName: "[project]/demo-frontend2/src/components/GameLogPanel.tsx",
                lineNumber: 24,
                columnNumber: 7
            }, this)
        ]
    }, void 0, true, {
        fileName: "[project]/demo-frontend2/src/components/GameLogPanel.tsx",
        lineNumber: 21,
        columnNumber: 5
    }, this);
}
_s(GameLogPanel, "GxyoezjKB8UqdI+3Omr/91JEeIM=");
_c = GameLogPanel;
var _c;
__turbopack_context__.k.register(_c, "GameLogPanel");
if (typeof globalThis.$RefreshHelpers$ === 'object' && globalThis.$RefreshHelpers !== null) {
    __turbopack_context__.k.registerExports(__turbopack_context__.m, globalThis.$RefreshHelpers$);
}
}),
"[project]/demo-frontend2/src/pages/index.tsx [client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "default",
    ()=>HomePage
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/react/jsx-dev-runtime.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$index$2e$js__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/react/index.js [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$ethers$2e$js__$5b$client$5d$__$28$ecmascript$29$__$3c$export__$2a$__as__ethers$3e$__ = __turbopack_context__.i("[project]/demo-frontend2/node_modules/ethers/lib.esm/ethers.js [client] (ecmascript) <export * as ethers>");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$hooks$2f$useInteractiveGame$2e$ts__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/src/hooks/useInteractiveGame.ts [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$components$2f$GameInfoPanel$2e$tsx__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/src/components/GameInfoPanel.tsx [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$components$2f$MoveSelectionPanel$2e$tsx__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/src/components/MoveSelectionPanel.tsx [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$components$2f$RewardPanel$2e$tsx__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/src/components/RewardPanel.tsx [client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$components$2f$GameLogPanel$2e$tsx__$5b$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/src/components/GameLogPanel.tsx [client] (ecmascript)");
;
var _s = __turbopack_context__.k.signature();
;
;
;
;
;
;
;
function HomePage() {
    _s();
    const [userAddress, setUserAddress] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$index$2e$js__$5b$client$5d$__$28$ecmascript$29$__["useState"])('');
    const [reward, setReward] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$index$2e$js__$5b$client$5d$__$28$ecmascript$29$__["useState"])(null);
    const [rootBlock, setRootBlock] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$index$2e$js__$5b$client$5d$__$28$ecmascript$29$__["useState"])(1000);
    const { game, moves, selectedMove, setSelectedMove, loading, error, createGame, loadMoves, submitMove, resolveGame } = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$hooks$2f$useInteractiveGame$2e$ts__$5b$client$5d$__$28$ecmascript$29$__["useInteractiveGame"])(userAddress);
    // 지갑 연결
    const connectWallet = async ()=>{
        if (("TURBOPACK compile-time value", "object") !== 'undefined' && window.ethereum) {
            try {
                const provider = new __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$2f$lib$2e$esm$2f$ethers$2e$js__$5b$client$5d$__$28$ecmascript$29$__$3c$export__$2a$__as__ethers$3e$__["ethers"].BrowserProvider(window.ethereum);
                const signer = await provider.getSigner();
                const address = await signer.getAddress();
                setUserAddress(address);
            } catch (err) {
                console.error('Failed to connect wallet:', err);
                alert('지갑 연결에 실패했습니다.');
            }
        } else {
            alert('MetaMask를 설치해주세요.');
        }
    };
    // 게임 생성
    const handleCreateGame = async ()=>{
        try {
            await createGame(rootBlock);
            await loadMoves();
        } catch (err) {
            console.error('Failed to create game:', err);
        }
    };
    // move 제출
    const handleSubmitMove = async ()=>{
        try {
            await submitMove();
            await loadMoves();
        } catch (err) {
            console.error('Failed to submit move:', err);
        }
    };
    // 게임 종료
    const handleResolveGame = async ()=>{
        try {
            const rewardData = await resolveGame();
            setReward(rewardData);
        } catch (err) {
            console.error('Failed to resolve game:', err);
        }
    };
    // 새 게임 시작
    const handleNewGame = ()=>{
        setGame(null);
        setMoves([]);
        setSelectedMove(null);
        setReward(null);
    };
    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
        className: "min-h-screen bg-gray-100",
        children: [
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("header", {
                className: "bg-white shadow",
                children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                    className: "max-w-7xl mx-auto px-4 py-6",
                    children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "flex items-center justify-between",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("h1", {
                                        className: "text-3xl font-bold text-gray-900",
                                        children: "🎮 Interactive Challenger Demo"
                                    }, void 0, false, {
                                        fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                                        lineNumber: 89,
                                        columnNumber: 15
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                        className: "text-gray-600 mt-1",
                                        children: "옵션 1: 선택형 Challenger"
                                    }, void 0, false, {
                                        fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                                        lineNumber: 92,
                                        columnNumber: 15
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                                lineNumber: 88,
                                columnNumber: 13
                            }, this),
                            userAddress ? /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "text-right",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                        className: "text-sm text-gray-600",
                                        children: "연결된 지갑:"
                                    }, void 0, false, {
                                        fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                                        lineNumber: 99,
                                        columnNumber: 17
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                        className: "font-mono text-sm",
                                        children: [
                                            userAddress.slice(0, 10),
                                            "...",
                                            userAddress.slice(-8)
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                                        lineNumber: 100,
                                        columnNumber: 17
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                                lineNumber: 98,
                                columnNumber: 15
                            }, this) : /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                onClick: connectWallet,
                                className: "bg-primary-600 text-white px-6 py-2 rounded-lg hover:bg-primary-700 transition-colors",
                                children: "지갑 연결"
                            }, void 0, false, {
                                fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                                lineNumber: 105,
                                columnNumber: 15
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                        lineNumber: 87,
                        columnNumber: 11
                    }, this)
                }, void 0, false, {
                    fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                    lineNumber: 86,
                    columnNumber: 9
                }, this)
            }, void 0, false, {
                fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                lineNumber: 85,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("main", {
                className: "max-w-7xl mx-auto px-4 py-8",
                children: [
                    error && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "bg-red-50 border-red-200 text-red-800 px-4 py-3 rounded mb-6",
                        children: error
                    }, void 0, false, {
                        fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                        lineNumber: 119,
                        columnNumber: 11
                    }, this),
                    !userAddress && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "bg-blue-50 border-blue-200 text-blue-800 px-4 py-3 rounded mb-6",
                        children: "시작하려면 지갑을 연결해주세요."
                    }, void 0, false, {
                        fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                        lineNumber: 125,
                        columnNumber: 11
                    }, this),
                    !game && userAddress && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "bg-white rounded-lg shadow p-6 mb-6",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("h2", {
                                className: "text-xl font-bold mb-4",
                                children: "새 게임 시작"
                            }, void 0, false, {
                                fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                                lineNumber: 132,
                                columnNumber: 13
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "mb-4",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("label", {
                                        className: "block text-gray-700 font-medium mb-2",
                                        children: "Root Block Number"
                                    }, void 0, false, {
                                        fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                                        lineNumber: 135,
                                        columnNumber: 15
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("input", {
                                        type: "number",
                                        value: rootBlock,
                                        onChange: (e)=>setRootBlock(Number(e.target.value)),
                                        className: "w-full px-4 py-2 border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                                    }, void 0, false, {
                                        fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                                        lineNumber: 138,
                                        columnNumber: 15
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                                lineNumber: 134,
                                columnNumber: 13
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                onClick: handleCreateGame,
                                disabled: loading,
                                className: `w-full py-3 px-6 rounded-lg font-bold text-white ${loading ? 'bg-gray-300 cursor-not-allowed' : 'bg-primary-600 hover:bg-primary-700'}`,
                                children: loading ? '생성 중...' : '게임 생성'
                            }, void 0, false, {
                                fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                                lineNumber: 146,
                                columnNumber: 13
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                        lineNumber: 131,
                        columnNumber: 11
                    }, this),
                    game && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "grid grid-cols-1 lg:grid-cols-2 gap-6",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "space-y-6",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$components$2f$GameInfoPanel$2e$tsx__$5b$client$5d$__$28$ecmascript$29$__["default"], {
                                        game: game
                                    }, void 0, false, {
                                        fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                                        lineNumber: 162,
                                        columnNumber: 15
                                    }, this),
                                    game.status === 'IN_PROGRESS' && !reward && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$components$2f$MoveSelectionPanel$2e$tsx__$5b$client$5d$__$28$ecmascript$29$__["default"], {
                                        moves: moves,
                                        selectedMove: selectedMove,
                                        onSelectMove: setSelectedMove,
                                        onSubmit: handleSubmitMove,
                                        loading: loading
                                    }, void 0, false, {
                                        fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                                        lineNumber: 165,
                                        columnNumber: 17
                                    }, this),
                                    game.status !== 'IN_PROGRESS' && !reward && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        className: "bg-white rounded-lg shadow p-6",
                                        children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                            onClick: handleResolveGame,
                                            disabled: loading,
                                            className: "w-full py-3 px-6 rounded-lg font-bold text-white bg-green-600 hover:bg-green-700 transition-colors",
                                            children: loading ? '종료 중...' : '게임 종료 및 보상 분배'
                                        }, void 0, false, {
                                            fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                                            lineNumber: 176,
                                            columnNumber: 19
                                        }, this)
                                    }, void 0, false, {
                                        fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                                        lineNumber: 175,
                                        columnNumber: 17
                                    }, this),
                                    reward && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["Fragment"], {
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$components$2f$RewardPanel$2e$tsx__$5b$client$5d$__$28$ecmascript$29$__["default"], {
                                                reward: reward,
                                                userAddress: userAddress
                                            }, void 0, false, {
                                                fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                                                lineNumber: 188,
                                                columnNumber: 19
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                                onClick: handleNewGame,
                                                className: "w-full py-3 px-6 rounded-lg font-bold text-white bg-primary-600 hover:bg-primary-700 transition-colors",
                                                children: "새로운 게임 시작"
                                            }, void 0, false, {
                                                fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                                                lineNumber: 189,
                                                columnNumber: 19
                                            }, this)
                                        ]
                                    }, void 0, true)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                                lineNumber: 161,
                                columnNumber: 13
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$components$2f$GameLogPanel$2e$tsx__$5b$client$5d$__$28$ecmascript$29$__["default"], {}, void 0, false, {
                                    fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                                    lineNumber: 201,
                                    columnNumber: 15
                                }, this)
                            }, void 0, false, {
                                fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                                lineNumber: 200,
                                columnNumber: 13
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                        lineNumber: 159,
                        columnNumber: 11
                    }, this)
                ]
            }, void 0, true, {
                fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                lineNumber: 117,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("footer", {
                className: "bg-white border-t mt-12 py-6",
                children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                    className: "max-w-7xl mx-auto px-4 text-center text-gray-600",
                    children: [
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                            children: "Interactive Challenger Demo - Option 1"
                        }, void 0, false, {
                            fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                            lineNumber: 210,
                            columnNumber: 11
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                            className: "text-sm mt-1",
                            children: "demo-backend2 + demo-frontend2"
                        }, void 0, false, {
                            fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                            lineNumber: 211,
                            columnNumber: 11
                        }, this)
                    ]
                }, void 0, true, {
                    fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                    lineNumber: 209,
                    columnNumber: 9
                }, this)
            }, void 0, false, {
                fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                lineNumber: 208,
                columnNumber: 7
            }, this)
        ]
    }, void 0, true, {
        fileName: "[project]/demo-frontend2/src/pages/index.tsx",
        lineNumber: 83,
        columnNumber: 5
    }, this);
}
_s(HomePage, "nCqbGT0ZMDyJho32mKanuy2ZEyc=", false, function() {
    return [
        __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$hooks$2f$useInteractiveGame$2e$ts__$5b$client$5d$__$28$ecmascript$29$__["useInteractiveGame"]
    ];
});
_c = HomePage;
var _c;
__turbopack_context__.k.register(_c, "HomePage");
if (typeof globalThis.$RefreshHelpers$ === 'object' && globalThis.$RefreshHelpers !== null) {
    __turbopack_context__.k.registerExports(__turbopack_context__.m, globalThis.$RefreshHelpers$);
}
}),
"[next]/entry/page-loader.ts { PAGE => \"[project]/demo-frontend2/src/pages/index.tsx [client] (ecmascript)\" } [client] (ecmascript)", ((__turbopack_context__, module, exports) => {

const PAGE_PATH = "/";
(window.__NEXT_P = window.__NEXT_P || []).push([
    PAGE_PATH,
    ()=>{
        return __turbopack_context__.r("[project]/demo-frontend2/src/pages/index.tsx [client] (ecmascript)");
    }
]);
// @ts-expect-error module.hot exists
if (module.hot) {
    // @ts-expect-error module.hot exists
    module.hot.dispose(function() {
        window.__NEXT_P.push([
            PAGE_PATH
        ]);
    });
}
}),
"[hmr-entry]/hmr-entry.js { ENTRY => \"[project]/demo-frontend2/src/pages/index\" }", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.r("[next]/entry/page-loader.ts { PAGE => \"[project]/demo-frontend2/src/pages/index.tsx [client] (ecmascript)\" } [client] (ecmascript)");
}),
]);

//# sourceMappingURL=%5Broot-of-the-server%5D__994c4af0._.js.map