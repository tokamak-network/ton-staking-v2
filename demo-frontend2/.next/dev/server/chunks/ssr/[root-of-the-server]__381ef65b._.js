module.exports = [
"[project]/demo-frontend2/src/lib/interactiveApi.ts [ssr] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "interactiveApi",
    ()=>interactiveApi
]);
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
}),
"[project]/demo-frontend2/src/hooks/useInteractiveGame.ts [ssr] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "useInteractiveGame",
    ()=>useInteractiveGame
]);
var __TURBOPACK__imported__module__$5b$externals$5d2f$react__$5b$external$5d$__$28$react$2c$__cjs$29$__ = __turbopack_context__.i("[externals]/react [external] (react, cjs)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$lib$2f$interactiveApi$2e$ts__$5b$ssr$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/src/lib/interactiveApi.ts [ssr] (ecmascript)");
;
;
function useInteractiveGame(userAddress) {
    const [game, setGame] = (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react__$5b$external$5d$__$28$react$2c$__cjs$29$__["useState"])(null);
    const [moves, setMoves] = (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react__$5b$external$5d$__$28$react$2c$__cjs$29$__["useState"])([]);
    const [selectedMove, setSelectedMove] = (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react__$5b$external$5d$__$28$react$2c$__cjs$29$__["useState"])(null);
    const [loading, setLoading] = (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react__$5b$external$5d$__$28$react$2c$__cjs$29$__["useState"])(false);
    const [error, setError] = (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react__$5b$external$5d$__$28$react$2c$__cjs$29$__["useState"])(null);
    // 게임 생성
    const createGame = (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react__$5b$external$5d$__$28$react$2c$__cjs$29$__["useCallback"])(async (rootBlock)=>{
        setLoading(true);
        setError(null);
        try {
            const newGame = await __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$lib$2f$interactiveApi$2e$ts__$5b$ssr$5d$__$28$ecmascript$29$__["interactiveApi"].createGame(rootBlock, userAddress);
            setGame(newGame);
            return newGame;
        } catch (err) {
            setError(err.message || 'Failed to create game');
            throw err;
        } finally{
            setLoading(false);
        }
    }, [
        userAddress
    ]);
    // 게임 상태 갱신
    const refreshGame = (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react__$5b$external$5d$__$28$react$2c$__cjs$29$__["useCallback"])(async ()=>{
        if (!game?.id) return;
        setLoading(true);
        setError(null);
        try {
            const updatedGame = await __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$lib$2f$interactiveApi$2e$ts__$5b$ssr$5d$__$28$ecmascript$29$__["interactiveApi"].getGameStatus(game.id);
            setGame(updatedGame);
        } catch (err) {
            setError(err.message || 'Failed to refresh game');
        } finally{
            setLoading(false);
        }
    }, [
        game?.id
    ]);
    // 유효한 move들 로드
    const loadMoves = (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react__$5b$external$5d$__$28$react$2c$__cjs$29$__["useCallback"])(async ()=>{
        if (!game?.id) return;
        setLoading(true);
        setError(null);
        try {
            const validMoves = await __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$lib$2f$interactiveApi$2e$ts__$5b$ssr$5d$__$28$ecmascript$29$__["interactiveApi"].getValidMoves(game.id, userAddress);
            setMoves(validMoves);
        } catch (err) {
            setError(err.message || 'Failed to load moves');
        } finally{
            setLoading(false);
        }
    }, [
        game?.id,
        userAddress
    ]);
    // move 제출
    const submitMove = (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react__$5b$external$5d$__$28$react$2c$__cjs$29$__["useCallback"])(async ()=>{
        if (!game?.id || !selectedMove) return;
        setLoading(true);
        setError(null);
        try {
            await __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$lib$2f$interactiveApi$2e$ts__$5b$ssr$5d$__$28$ecmascript$29$__["interactiveApi"].submitMove(game.id, selectedMove.id, userAddress);
            setSelectedMove(null);
            setMoves([]);
            await refreshGame();
        } catch (err) {
            setError(err.message || 'Failed to submit move');
            throw err;
        } finally{
            setLoading(false);
        }
    }, [
        game?.id,
        selectedMove,
        userAddress,
        refreshGame
    ]);
    // 게임 종료
    const resolveGame = (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react__$5b$external$5d$__$28$react$2c$__cjs$29$__["useCallback"])(async ()=>{
        if (!game?.id) return;
        setLoading(true);
        setError(null);
        try {
            const reward = await __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$lib$2f$interactiveApi$2e$ts__$5b$ssr$5d$__$28$ecmascript$29$__["interactiveApi"].resolveGame(game.id);
            await refreshGame();
            return reward;
        } catch (err) {
            setError(err.message || 'Failed to resolve game');
            throw err;
        } finally{
            setLoading(false);
        }
    }, [
        game?.id,
        refreshGame
    ]);
    // 주기적으로 상태 갱신
    (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react__$5b$external$5d$__$28$react$2c$__cjs$29$__["useEffect"])(()=>{
        if (!game?.id) return;
        const interval = setInterval(()=>{
            refreshGame();
        }, 5000); // 5초마다 갱신
        return ()=>clearInterval(interval);
    }, [
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
}),
"[project]/demo-frontend2/src/components/GameInfoPanel.tsx [ssr] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "default",
    ()=>GameInfoPanel
]);
var __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__ = __turbopack_context__.i("[externals]/react/jsx-dev-runtime [external] (react/jsx-dev-runtime, cjs)");
;
function GameInfoPanel({ game }) {
    if (!game) {
        return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
            className: "bg-white rounded-lg shadow p-6",
            children: [
                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("h2", {
                    className: "text-xl font-bold mb-4",
                    children: "🎮 게임 정보"
                }, void 0, false, {
                    fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
                    lineNumber: 11,
                    columnNumber: 9
                }, this),
                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("p", {
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
    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
        className: "bg-white rounded-lg shadow p-6",
        children: [
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("h2", {
                className: "text-xl font-bold mb-4",
                children: "🎮 게임 정보"
            }, void 0, false, {
                fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
                lineNumber: 19,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                className: "space-y-3",
                children: [
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                        className: "flex justify-between",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("span", {
                                className: "text-gray-600",
                                children: "게임 ID:"
                            }, void 0, false, {
                                fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
                                lineNumber: 23,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("span", {
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
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                        className: "flex justify-between",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("span", {
                                className: "text-gray-600",
                                children: "상태:"
                            }, void 0, false, {
                                fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
                                lineNumber: 28,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("span", {
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
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                        className: "flex justify-between",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("span", {
                                className: "text-gray-600",
                                children: "Root Block:"
                            }, void 0, false, {
                                fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
                                lineNumber: 41,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("span", {
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
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                        className: "flex justify-between",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("span", {
                                className: "text-gray-600",
                                children: "Max Depth:"
                            }, void 0, false, {
                                fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
                                lineNumber: 46,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("span", {
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
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                        className: "flex justify-between",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("span", {
                                className: "text-gray-600",
                                children: "Claim 수:"
                            }, void 0, false, {
                                fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
                                lineNumber: 51,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("span", {
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
                    game.winner && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                        className: "mt-4 p-3 bg-green-50 rounded",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("span", {
                                className: "text-gray-600",
                                children: "승자:"
                            }, void 0, false, {
                                fileName: "[project]/demo-frontend2/src/components/GameInfoPanel.tsx",
                                lineNumber: 57,
                                columnNumber: 13
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("span", {
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
}),
"[project]/demo-frontend2/src/components/MoveSelectionPanel.tsx [ssr] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "default",
    ()=>MoveSelectionPanel
]);
var __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__ = __turbopack_context__.i("[externals]/react/jsx-dev-runtime [external] (react/jsx-dev-runtime, cjs)");
;
function MoveSelectionPanel({ moves, selectedMove, onSelectMove, onSubmit, loading }) {
    if (moves.length === 0) {
        return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
            className: "bg-white rounded-lg shadow p-6",
            children: [
                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("h2", {
                    className: "text-xl font-bold mb-4",
                    children: "🎯 Move 선택"
                }, void 0, false, {
                    fileName: "[project]/demo-frontend2/src/components/MoveSelectionPanel.tsx",
                    lineNumber: 21,
                    columnNumber: 9
                }, this),
                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("p", {
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
    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
        className: "bg-white rounded-lg shadow p-6",
        children: [
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("h2", {
                className: "text-xl font-bold mb-4",
                children: "🎯 당신의 차례!"
            }, void 0, false, {
                fileName: "[project]/demo-frontend2/src/components/MoveSelectionPanel.tsx",
                lineNumber: 46,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("p", {
                className: "text-gray-600 mb-6",
                children: "다음 중 하나를 선택하세요:"
            }, void 0, false, {
                fileName: "[project]/demo-frontend2/src/components/MoveSelectionPanel.tsx",
                lineNumber: 47,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                className: "grid grid-cols-1 md:grid-cols-2 gap-4 mb-6",
                children: moves.map((move)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                        className: `p-4 rounded-lg border-2 cursor-pointer transition-all ${selectedMove?.id === move.id ? 'border-primary-500 bg-primary-50' : 'border-gray-200 hover:border-primary-300 hover:bg-gray-50'}`,
                        onClick: ()=>onSelectMove(move),
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                                className: "flex items-center justify-between mb-3",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                                        className: "flex items-center gap-2",
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("span", {
                                                className: "text-2xl",
                                                children: move.type === 'attack' ? '🗡️' : '🛡️'
                                            }, void 0, false, {
                                                fileName: "[project]/demo-frontend2/src/components/MoveSelectionPanel.tsx",
                                                lineNumber: 62,
                                                columnNumber: 17
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("span", {
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
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("span", {
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
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("h3", {
                                className: "font-semibold mb-2",
                                children: move.description
                            }, void 0, false, {
                                fileName: "[project]/demo-frontend2/src/components/MoveSelectionPanel.tsx",
                                lineNumber: 74,
                                columnNumber: 13
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                                className: `inline-block px-2 py-1 rounded text-xs font-medium ${getRiskColor(move.riskLevel)} mb-3`,
                                children: move.riskLevel.toUpperCase()
                            }, void 0, false, {
                                fileName: "[project]/demo-frontend2/src/components/MoveSelectionPanel.tsx",
                                lineNumber: 76,
                                columnNumber: 13
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                                className: "text-sm text-gray-600 bg-gray-50 p-2 rounded",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("span", {
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
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("button", {
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
}),
"[project]/demo-frontend2/src/components/RewardPanel.tsx [ssr] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "default",
    ()=>RewardPanel
]);
var __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__ = __turbopack_context__.i("[externals]/react/jsx-dev-runtime [external] (react/jsx-dev-runtime, cjs)");
;
function RewardPanel({ reward, userAddress }) {
    if (!reward) {
        return null;
    }
    const isUserWinner = reward.winner?.toLowerCase() === userAddress.toLowerCase();
    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
        className: "bg-white rounded-lg shadow p-6",
        children: [
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("h2", {
                className: "text-xl font-bold mb-4",
                children: "🎁 보상 분배"
            }, void 0, false, {
                fileName: "[project]/demo-frontend2/src/components/RewardPanel.tsx",
                lineNumber: 15,
                columnNumber: 7
            }, this),
            isUserWinner ? /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                className: "bg-green-50 border-green-200 rounded-lg p-6 text-center",
                children: [
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                        className: "text-6xl mb-4",
                        children: "🎉"
                    }, void 0, false, {
                        fileName: "[project]/demo-frontend2/src/components/RewardPanel.tsx",
                        lineNumber: 19,
                        columnNumber: 11
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("h3", {
                        className: "text-2xl font-bold text-green-800 mb-2",
                        children: "축하합니다! 승리하셨습니다!"
                    }, void 0, false, {
                        fileName: "[project]/demo-frontend2/src/components/RewardPanel.tsx",
                        lineNumber: 20,
                        columnNumber: 11
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("p", {
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
            }, this) : /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                className: "bg-red-50 border-red-200 rounded-lg p-6 text-center",
                children: [
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                        className: "text-6xl mb-4",
                        children: "😢"
                    }, void 0, false, {
                        fileName: "[project]/demo-frontend2/src/components/RewardPanel.tsx",
                        lineNumber: 29,
                        columnNumber: 11
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("h3", {
                        className: "text-2xl font-bold text-red-800 mb-2",
                        children: "아쉽네요..."
                    }, void 0, false, {
                        fileName: "[project]/demo-frontend2/src/components/RewardPanel.tsx",
                        lineNumber: 30,
                        columnNumber: 11
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("p", {
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
            reward.slashedAddresses && reward.slashedAddresses.length > 0 && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                className: "mt-4 p-4 bg-orange-50 rounded-lg",
                children: [
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("h4", {
                        className: "font-semibold mb-2",
                        children: "슬래싱된 계정:"
                    }, void 0, false, {
                        fileName: "[project]/demo-frontend2/src/components/RewardPanel.tsx",
                        lineNumber: 41,
                        columnNumber: 11
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                        className: "space-y-2",
                        children: reward.slashedAddresses.map((addr, i)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
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
}),
"[project]/demo-frontend2/src/components/GameLogPanel.tsx [ssr] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "default",
    ()=>GameLogPanel
]);
var __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__ = __turbopack_context__.i("[externals]/react/jsx-dev-runtime [external] (react/jsx-dev-runtime, cjs)");
var __TURBOPACK__imported__module__$5b$externals$5d2f$react__$5b$external$5d$__$28$react$2c$__cjs$29$__ = __turbopack_context__.i("[externals]/react [external] (react, cjs)");
;
;
function GameLogPanel() {
    const [logs, setLogs] = (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react__$5b$external$5d$__$28$react$2c$__cjs$29$__["useState"])([]);
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
    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
        className: "bg-white rounded-lg shadow p-6",
        children: [
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("h2", {
                className: "text-xl font-bold mb-4",
                children: "📜 게임 로그"
            }, void 0, false, {
                fileName: "[project]/demo-frontend2/src/components/GameLogPanel.tsx",
                lineNumber: 22,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                className: "bg-gray-50 rounded-lg p-4 h-64 overflow-y-auto",
                children: logs.length === 0 ? /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("p", {
                    className: "text-gray-500 text-center py-8",
                    children: "아직 로그가 없습니다."
                }, void 0, false, {
                    fileName: "[project]/demo-frontend2/src/components/GameLogPanel.tsx",
                    lineNumber: 26,
                    columnNumber: 11
                }, this) : /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                    className: "space-y-2",
                    children: logs.map((log, i)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                            className: "text-sm",
                            children: [
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("span", {
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
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("span", {
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
}),
"[project]/demo-frontend2/src/pages/index.tsx [ssr] (ecmascript)", ((__turbopack_context__) => {
"use strict";

return __turbopack_context__.a(async (__turbopack_handle_async_dependencies__, __turbopack_async_result__) => { try {

__turbopack_context__.s([
    "default",
    ()=>HomePage
]);
var __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__ = __turbopack_context__.i("[externals]/react/jsx-dev-runtime [external] (react/jsx-dev-runtime, cjs)");
var __TURBOPACK__imported__module__$5b$externals$5d2f$react__$5b$external$5d$__$28$react$2c$__cjs$29$__ = __turbopack_context__.i("[externals]/react [external] (react, cjs)");
var __TURBOPACK__imported__module__$5b$externals$5d2f$ethers__$5b$external$5d$__$28$ethers$2c$__esm_import$2c$__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$29$__ = __turbopack_context__.i("[externals]/ethers [external] (ethers, esm_import, [project]/demo-frontend2/node_modules/ethers)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$hooks$2f$useInteractiveGame$2e$ts__$5b$ssr$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/src/hooks/useInteractiveGame.ts [ssr] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$components$2f$GameInfoPanel$2e$tsx__$5b$ssr$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/src/components/GameInfoPanel.tsx [ssr] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$components$2f$MoveSelectionPanel$2e$tsx__$5b$ssr$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/src/components/MoveSelectionPanel.tsx [ssr] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$components$2f$RewardPanel$2e$tsx__$5b$ssr$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/src/components/RewardPanel.tsx [ssr] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$components$2f$GameLogPanel$2e$tsx__$5b$ssr$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/demo-frontend2/src/components/GameLogPanel.tsx [ssr] (ecmascript)");
var __turbopack_async_dependencies__ = __turbopack_handle_async_dependencies__([
    __TURBOPACK__imported__module__$5b$externals$5d2f$ethers__$5b$external$5d$__$28$ethers$2c$__esm_import$2c$__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$29$__
]);
[__TURBOPACK__imported__module__$5b$externals$5d2f$ethers__$5b$external$5d$__$28$ethers$2c$__esm_import$2c$__$5b$project$5d2f$demo$2d$frontend2$2f$node_modules$2f$ethers$29$__] = __turbopack_async_dependencies__.then ? (await __turbopack_async_dependencies__)() : __turbopack_async_dependencies__;
;
;
;
;
;
;
;
;
function HomePage() {
    const [userAddress, setUserAddress] = (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react__$5b$external$5d$__$28$react$2c$__cjs$29$__["useState"])('');
    const [reward, setReward] = (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react__$5b$external$5d$__$28$react$2c$__cjs$29$__["useState"])(null);
    const [rootBlock, setRootBlock] = (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react__$5b$external$5d$__$28$react$2c$__cjs$29$__["useState"])(1000);
    const { game, moves, selectedMove, setSelectedMove, loading, error, createGame, loadMoves, submitMove, resolveGame } = (0, __TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$hooks$2f$useInteractiveGame$2e$ts__$5b$ssr$5d$__$28$ecmascript$29$__["useInteractiveGame"])(userAddress);
    // 지갑 연결
    const connectWallet = async ()=>{
        if ("TURBOPACK compile-time falsy", 0) //TURBOPACK unreachable
        ;
        else {
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
    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
        className: "min-h-screen bg-gray-100",
        children: [
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("header", {
                className: "bg-white shadow",
                children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                    className: "max-w-7xl mx-auto px-4 py-6",
                    children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                        className: "flex items-center justify-between",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("h1", {
                                        className: "text-3xl font-bold text-gray-900",
                                        children: "🎮 Interactive Challenger Demo"
                                    }, void 0, false, {
                                        fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                                        lineNumber: 89,
                                        columnNumber: 15
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("p", {
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
                            userAddress ? /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                                className: "text-right",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("p", {
                                        className: "text-sm text-gray-600",
                                        children: "연결된 지갑:"
                                    }, void 0, false, {
                                        fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                                        lineNumber: 99,
                                        columnNumber: 17
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("p", {
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
                            }, this) : /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("button", {
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
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("main", {
                className: "max-w-7xl mx-auto px-4 py-8",
                children: [
                    error && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                        className: "bg-red-50 border-red-200 text-red-800 px-4 py-3 rounded mb-6",
                        children: error
                    }, void 0, false, {
                        fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                        lineNumber: 119,
                        columnNumber: 11
                    }, this),
                    !userAddress && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                        className: "bg-blue-50 border-blue-200 text-blue-800 px-4 py-3 rounded mb-6",
                        children: "시작하려면 지갑을 연결해주세요."
                    }, void 0, false, {
                        fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                        lineNumber: 125,
                        columnNumber: 11
                    }, this),
                    !game && userAddress && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                        className: "bg-white rounded-lg shadow p-6 mb-6",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("h2", {
                                className: "text-xl font-bold mb-4",
                                children: "새 게임 시작"
                            }, void 0, false, {
                                fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                                lineNumber: 132,
                                columnNumber: 13
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                                className: "mb-4",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("label", {
                                        className: "block text-gray-700 font-medium mb-2",
                                        children: "Root Block Number"
                                    }, void 0, false, {
                                        fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                                        lineNumber: 135,
                                        columnNumber: 15
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("input", {
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
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("button", {
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
                    game && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                        className: "grid grid-cols-1 lg:grid-cols-2 gap-6",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                                className: "space-y-6",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$components$2f$GameInfoPanel$2e$tsx__$5b$ssr$5d$__$28$ecmascript$29$__["default"], {
                                        game: game
                                    }, void 0, false, {
                                        fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                                        lineNumber: 162,
                                        columnNumber: 15
                                    }, this),
                                    game.status === 'IN_PROGRESS' && !reward && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$components$2f$MoveSelectionPanel$2e$tsx__$5b$ssr$5d$__$28$ecmascript$29$__["default"], {
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
                                    game.status !== 'IN_PROGRESS' && !reward && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                                        className: "bg-white rounded-lg shadow p-6",
                                        children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("button", {
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
                                    reward && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["Fragment"], {
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$components$2f$RewardPanel$2e$tsx__$5b$ssr$5d$__$28$ecmascript$29$__["default"], {
                                                reward: reward,
                                                userAddress: userAddress
                                            }, void 0, false, {
                                                fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                                                lineNumber: 188,
                                                columnNumber: 19
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("button", {
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
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                                children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$demo$2d$frontend2$2f$src$2f$components$2f$GameLogPanel$2e$tsx__$5b$ssr$5d$__$28$ecmascript$29$__["default"], {}, void 0, false, {
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
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("footer", {
                className: "bg-white border-t mt-12 py-6",
                children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("div", {
                    className: "max-w-7xl mx-auto px-4 text-center text-gray-600",
                    children: [
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("p", {
                            children: "Interactive Challenger Demo - Option 1"
                        }, void 0, false, {
                            fileName: "[project]/demo-frontend2/src/pages/index.tsx",
                            lineNumber: 210,
                            columnNumber: 11
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$externals$5d2f$react$2f$jsx$2d$dev$2d$runtime__$5b$external$5d$__$28$react$2f$jsx$2d$dev$2d$runtime$2c$__cjs$29$__["jsxDEV"])("p", {
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
__turbopack_async_result__();
} catch(e) { __turbopack_async_result__(e); } }, false);}),
"[externals]/next/dist/shared/lib/no-fallback-error.external.js [external] (next/dist/shared/lib/no-fallback-error.external.js, cjs)", ((__turbopack_context__, module, exports) => {

const mod = __turbopack_context__.x("next/dist/shared/lib/no-fallback-error.external.js", () => require("next/dist/shared/lib/no-fallback-error.external.js"));

module.exports = mod;
}),
];

//# sourceMappingURL=%5Broot-of-the-server%5D__381ef65b._.js.map