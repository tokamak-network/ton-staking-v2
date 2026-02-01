import { create } from 'zustand';
import { Address } from 'viem';

interface UIState {
  selectedSequencer: Address | null;
  isStakeModalOpen: boolean;
  isUnstakeModalOpen: boolean;

  setSelectedSequencer: (sequencer: Address | null) => void;
  openStakeModal: (sequencer: Address) => void;
  closeStakeModal: () => void;
  openUnstakeModal: (sequencer: Address) => void;
  closeUnstakeModal: () => void;
}

export const useUIStore = create<UIState>((set) => ({
  selectedSequencer: null,
  isStakeModalOpen: false,
  isUnstakeModalOpen: false,

  setSelectedSequencer: (sequencer) => set({ selectedSequencer: sequencer }),

  openStakeModal: (sequencer) => set({ selectedSequencer: sequencer, isStakeModalOpen: true }),
  closeStakeModal: () => set({ isStakeModalOpen: false }),

  openUnstakeModal: (sequencer) => set({ selectedSequencer: sequencer, isUnstakeModalOpen: true }),
  closeUnstakeModal: () => set({ isUnstakeModalOpen: false }),
}));
