import { create } from 'zustand';
import { Address } from 'viem';

interface UIState {
  selectedSequencer: Address | null;
  isStakeModalOpen: boolean;
  isUnstakeModalOpen: boolean;
  isClaimModalOpen: boolean;
  isWithdrawModalOpen: boolean;
  isRedelegateModalOpen: boolean;

  setSelectedSequencer: (sequencer: Address | null) => void;
  openStakeModal: (sequencer: Address) => void;
  closeStakeModal: () => void;
  openUnstakeModal: (sequencer: Address) => void;
  closeUnstakeModal: () => void;
  openClaimModal: (sequencer: Address) => void;
  closeClaimModal: () => void;
  openWithdrawModal: (sequencer: Address) => void;
  closeWithdrawModal: () => void;
  openRedelegateModal: (sequencer: Address) => void;
  closeRedelegateModal: () => void;
}

export const useUIStore = create<UIState>((set) => ({
  selectedSequencer: null,
  isStakeModalOpen: false,
  isUnstakeModalOpen: false,
  isClaimModalOpen: false,
  isWithdrawModalOpen: false,
  isRedelegateModalOpen: false,

  setSelectedSequencer: (sequencer) => set({ selectedSequencer: sequencer }),

  openStakeModal: (sequencer) => set({ selectedSequencer: sequencer, isStakeModalOpen: true }),
  closeStakeModal: () => set({ isStakeModalOpen: false }),

  openUnstakeModal: (sequencer) => set({ selectedSequencer: sequencer, isUnstakeModalOpen: true }),
  closeUnstakeModal: () => set({ isUnstakeModalOpen: false }),

  openClaimModal: (sequencer) => set({ selectedSequencer: sequencer, isClaimModalOpen: true }),
  closeClaimModal: () => set({ isClaimModalOpen: false }),

  openWithdrawModal: (sequencer) => set({ selectedSequencer: sequencer, isWithdrawModalOpen: true }),
  closeWithdrawModal: () => set({ isWithdrawModalOpen: false }),

  openRedelegateModal: (sequencer) => set({ selectedSequencer: sequencer, isRedelegateModalOpen: true }),
  closeRedelegateModal: () => set({ isRedelegateModalOpen: false }),
}));
