import { useState, useEffect } from 'react'
import { ConnectWallet } from './components/ConnectWallet'
import { LotteryInfo } from './components/LotteryInfo'
import { UserBalance } from './components/UserBalance'
import { DepositForm } from './components/DepositForm'
import { LotteryActions } from './components/LotteryActions'
import { SeignioragePanel } from './components/SeignioragePanel'
import { PastRounds } from './components/PastRounds'

interface DeploymentConfig {
  ton: `0x${string}`
  wton: `0x${string}`
  lotteryCandidate: `0x${string}`
  operator: `0x${string}`
}

const DEFAULT_CONFIG: DeploymentConfig = {
  ton: '0x0000000000000000000000000000000000000000',
  wton: '0x0000000000000000000000000000000000000000',
  lotteryCandidate: '0x0000000000000000000000000000000000000000',
  operator: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
}

function App() {
  const [config, setConfig] = useState<DeploymentConfig>(DEFAULT_CONFIG)
  const [showConfig, setShowConfig] = useState(true)
  const [configInput, setConfigInput] = useState('')

  useEffect(() => {
    const saved = localStorage.getItem('lotteryDemoConfig')
    if (saved) {
      try {
        const parsed = JSON.parse(saved)
        setConfig({
          ton: parsed.ton as `0x${string}`,
          wton: parsed.wton as `0x${string}`,
          lotteryCandidate: parsed.lotteryCandidate as `0x${string}`,
          operator: parsed.operator as `0x${string}`,
        })
        setShowConfig(false)
      } catch {
        console.log('Failed to parse saved config')
      }
    }
  }, [])

  const handleConfigSubmit = () => {
    try {
      const parsed = JSON.parse(configInput)
      const newConfig = {
        ton: parsed.ton as `0x${string}`,
        wton: parsed.wton as `0x${string}`,
        lotteryCandidate: parsed.lotteryCandidate as `0x${string}`,
        operator: parsed.operator as `0x${string}`,
      }
      setConfig(newConfig)
      localStorage.setItem('lotteryDemoConfig', JSON.stringify(newConfig))
      setShowConfig(false)
    } catch (e) {
      alert('Invalid JSON configuration')
    }
  }

  const isConfigured = config.lotteryCandidate !== '0x0000000000000000000000000000000000000000'

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900">
      <header className="bg-black/30 backdrop-blur-sm border-b border-white/10">
        <div className="max-w-7xl mx-auto px-4 py-4 flex justify-between items-center">
          <h1 className="text-2xl font-bold text-white">
            🎰 LotteryCandidate Demo
          </h1>
          <div className="flex items-center gap-4">
            <button
              onClick={() => setShowConfig(!showConfig)}
              className="px-3 py-1 bg-white/10 text-white rounded-lg hover:bg-white/20 text-sm"
            >
              ⚙️ Config
            </button>
            <ConnectWallet />
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 py-8">
        {showConfig && (
          <div className="mb-8 bg-white rounded-xl shadow-lg p-6">
            <h2 className="text-xl font-bold mb-4">📋 Deployment Configuration</h2>
            <p className="text-sm text-gray-600 mb-4">
              Paste the deployment JSON from the forge script output:
            </p>
            <textarea
              value={configInput}
              onChange={(e) => setConfigInput(e.target.value)}
              placeholder='{"ton": "0x...", "wton": "0x...", "lotteryCandidate": "0x...", "operator": "0x..."}'
              className="w-full h-32 p-3 border rounded-lg font-mono text-sm"
            />
            <div className="flex gap-2 mt-4">
              <button
                onClick={handleConfigSubmit}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
              >
                Save Config
              </button>
              {isConfigured && (
                <button
                  onClick={() => setShowConfig(false)}
                  className="px-4 py-2 bg-gray-200 rounded-lg hover:bg-gray-300"
                >
                  Cancel
                </button>
              )}
            </div>
            {isConfigured && (
              <div className="mt-4 p-3 bg-green-50 rounded-lg">
                <p className="text-sm text-green-700">Current Configuration:</p>
                <p className="font-mono text-xs mt-1">
                  LotteryCandidate: {config.lotteryCandidate}
                </p>
              </div>
            )}
          </div>
        )}

        {!isConfigured && !showConfig && (
          <div className="text-center py-12">
            <p className="text-white text-xl mb-4">
              Please configure the deployment addresses first
            </p>
            <button
              onClick={() => setShowConfig(true)}
              className="px-6 py-3 bg-white text-blue-600 rounded-lg font-bold hover:bg-gray-100"
            >
              Open Configuration
            </button>
          </div>
        )}

        {isConfigured && (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <div className="lg:col-span-2 space-y-6">
              <LotteryInfo lotteryCandidateAddress={config.lotteryCandidate} />
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <DepositForm
                  tonAddress={config.ton}
                  lotteryCandidateAddress={config.lotteryCandidate}
                />
                <LotteryActions
                  lotteryCandidateAddress={config.lotteryCandidate}
                  operatorAddress={config.operator}
                />
              </div>

              <PastRounds lotteryCandidateAddress={config.lotteryCandidate} />
            </div>

            <div className="space-y-6">
              <UserBalance
                tonAddress={config.ton}
                wtonAddress={config.wton}
                lotteryCandidateAddress={config.lotteryCandidate}
              />
              <SeignioragePanel lotteryCandidateAddress={config.lotteryCandidate} />
            </div>
          </div>
        )}
      </main>

      <footer className="mt-8 py-6 text-center text-white/50 text-sm">
        <p>LotteryCandidate Demo - Tokamak Network</p>
        <p className="mt-1">Connect to Anvil (localhost:8545) for testing</p>
      </footer>
    </div>
  )
}

export default App
