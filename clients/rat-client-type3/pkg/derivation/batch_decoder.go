package derivation

import (
	"bytes"
	"compress/zlib"
	"fmt"
	"io"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/rlp"
)

// BatchType represents the type of batch
type BatchType uint8

const (
	BatchTypeSingular BatchType = 0 // SingularBatch
	BatchTypeSpan     BatchType = 1 // SpanBatch
)

// SingularBatch represents a single L2 block
type SingularBatch struct {
	ParentHash   common.Hash
	EpochNum     uint64
	EpochHash    common.Hash
	Timestamp    uint64
	Transactions [][]byte
}

// SpanBatch represents multiple L2 blocks (compressed format)
// Introduced in Optimism Delta upgrade
// See: https://specs.optimism.io/protocol/delta/span-batches.html
type SpanBatch struct {
	// Relative timestamp of first block in span
	RelTimestamp uint64

	// L1 origin number of first block
	L1OriginNum uint64

	// Parent check: first 20 bytes of parent hash
	ParentCheck [20]byte

	// L1 origin check: first 20 bytes of L1 origin hash
	L1OriginCheck [20]byte

	// Block count in this span
	BlockCount uint64

	// Origin bits: bitmap for L1 origin changes
	OriginBits []byte

	// Block transaction counts
	BlockTxCounts []uint64

	// Transactions (RLP-encoded, concatenated)
	Transactions [][]byte

	// Protected bits (optional, for legacy tx types)
	ProtectedBits []byte
}

// Batch is a generic batch interface
type Batch interface {
	IsSingular() bool
	IsSpan() bool
}

// Frame represents a frame from L1 batch data
type Frame struct {
	ChannelID   [16]byte
	FrameNumber uint16
	FrameData   []byte
	IsLast      bool
}

// Channel represents an assembled channel
type Channel struct {
	ID   [16]byte
	Data []byte
}

// BatchDecoder decodes batch data from L1
type BatchDecoder struct {
	// Channel assembly state
	channels map[[16]byte]*channelState
}

type channelState struct {
	frames []*Frame
	size   uint64
}

// NewBatchDecoder creates a new batch decoder
func NewBatchDecoder() *BatchDecoder {
	return &BatchDecoder{
		channels: make(map[[16]byte]*channelState),
	}
}

// DecodeFrames decodes frames from raw L1 batch data
func (d *BatchDecoder) DecodeFrames(data []byte) ([]*Frame, error) {
	var frames []*Frame
	buf := bytes.NewReader(data)

	for buf.Len() > 0 {
		frame, err := d.decodeFrame(buf)
		if err != nil {
			return nil, fmt.Errorf("failed to decode frame: %w", err)
		}
		frames = append(frames, frame)
	}

	return frames, nil
}

// decodeFrame decodes a single frame
func (d *BatchDecoder) decodeFrame(r io.Reader) (*Frame, error) {
	// Frame format:
	// channel_id (16 bytes) | frame_number (2 bytes) | frame_data_length (4 bytes) | frame_data | is_last (1 byte)

	frame := &Frame{}

	// Read channel ID
	if _, err := io.ReadFull(r, frame.ChannelID[:]); err != nil {
		return nil, fmt.Errorf("failed to read channel ID: %w", err)
	}

	// Read frame number
	var frameNum [2]byte
	if _, err := io.ReadFull(r, frameNum[:]); err != nil {
		return nil, fmt.Errorf("failed to read frame number: %w", err)
	}
	frame.FrameNumber = uint16(frameNum[0])<<8 | uint16(frameNum[1])

	// Read frame data length
	var dataLen [4]byte
	if _, err := io.ReadFull(r, dataLen[:]); err != nil {
		return nil, fmt.Errorf("failed to read data length: %w", err)
	}
	length := uint32(dataLen[0])<<24 | uint32(dataLen[1])<<16 | uint32(dataLen[2])<<8 | uint32(dataLen[3])

	// Read frame data
	frame.FrameData = make([]byte, length)
	if _, err := io.ReadFull(r, frame.FrameData); err != nil {
		return nil, fmt.Errorf("failed to read frame data: %w", err)
	}

	// Read is_last flag
	var isLast [1]byte
	if _, err := io.ReadFull(r, isLast[:]); err != nil {
		return nil, fmt.Errorf("failed to read is_last: %w", err)
	}
	frame.IsLast = isLast[0] == 1

	return frame, nil
}

// AssembleChannel assembles frames into a channel
func (d *BatchDecoder) AssembleChannel(frames []*Frame) (*Channel, error) {
	if len(frames) == 0 {
		return nil, fmt.Errorf("no frames to assemble")
	}

	channelID := frames[0].ChannelID

	// Sort frames by frame number and concatenate
	// TODO: Implement proper frame ordering and validation

	var channelData []byte
	for _, frame := range frames {
		if frame.ChannelID != channelID {
			return nil, fmt.Errorf("frame channel ID mismatch")
		}
		channelData = append(channelData, frame.FrameData...)
	}

	return &Channel{
		ID:   channelID,
		Data: channelData,
	}, nil
}

// DecompressChannel decompresses channel data
func (d *BatchDecoder) DecompressChannel(channel *Channel) ([]byte, error) {
	r, err := zlib.NewReader(bytes.NewReader(channel.Data))
	if err != nil {
		return nil, fmt.Errorf("failed to create zlib reader: %w", err)
	}
	defer r.Close()

	decompressed, err := io.ReadAll(r)
	if err != nil {
		return nil, fmt.Errorf("failed to decompress: %w", err)
	}

	return decompressed, nil
}

// DecodeBatches decodes batches from decompressed channel data
func (d *BatchDecoder) DecodeBatches(data []byte) ([]Batch, error) {
	if len(data) == 0 {
		return nil, fmt.Errorf("empty batch data")
	}

	batchType := BatchType(data[0])

	switch batchType {
	case BatchTypeSingular:
		batch, err := d.decodeSingularBatch(data[1:])
		if err != nil {
			return nil, fmt.Errorf("failed to decode singular batch: %w", err)
		}
		return []Batch{batch}, nil

	case BatchTypeSpan:
		batch, err := d.decodeSpanBatch(data[1:])
		if err != nil {
			return nil, fmt.Errorf("failed to decode span batch: %w", err)
		}
		return []Batch{batch}, nil

	default:
		return nil, fmt.Errorf("unknown batch type: %d", batchType)
	}
}

// decodeSingularBatch decodes a SingularBatch
func (d *BatchDecoder) decodeSingularBatch(data []byte) (*SingularBatch, error) {
	// SingularBatch RLP format:
	// [parent_hash, epoch_num, epoch_hash, timestamp, transactions]

	var batch SingularBatch
	if err := rlp.DecodeBytes(data, &batch); err != nil {
		return nil, fmt.Errorf("failed to RLP decode: %w", err)
	}

	return &batch, nil
}

// IsSingular implements Batch interface
func (b *SingularBatch) IsSingular() bool {
	return true
}

// IsSpan implements Batch interface
func (b *SingularBatch) IsSpan() bool {
	return false
}

// IsSingular implements Batch interface
func (b *SpanBatch) IsSingular() bool {
	return false
}

// IsSpan implements Batch interface
func (b *SpanBatch) IsSpan() bool {
	return true
}

// decodeSpanBatch decodes a SpanBatch
func (d *BatchDecoder) decodeSpanBatch(data []byte) (*SpanBatch, error) {
	// SpanBatch encoding is complex and uses varint encoding
	// Format:
	// - rel_timestamp (varint)
	// - l1_origin_num (varint)
	// - parent_check (20 bytes)
	// - l1_origin_check (20 bytes)
	// - block_count (varint)
	// - origin_bits (varint length + bytes)
	// - block_tx_counts (varint array)
	// - transactions (concatenated RLP)
	// - protected_bits (optional)

	buf := bytes.NewReader(data)
	batch := &SpanBatch{}

	// Read rel_timestamp
	relTimestamp, err := readVarint(buf)
	if err != nil {
		return nil, fmt.Errorf("failed to read rel_timestamp: %w", err)
	}
	batch.RelTimestamp = relTimestamp

	// Read l1_origin_num
	l1OriginNum, err := readVarint(buf)
	if err != nil {
		return nil, fmt.Errorf("failed to read l1_origin_num: %w", err)
	}
	batch.L1OriginNum = l1OriginNum

	// Read parent_check (20 bytes)
	if _, err := io.ReadFull(buf, batch.ParentCheck[:]); err != nil {
		return nil, fmt.Errorf("failed to read parent_check: %w", err)
	}

	// Read l1_origin_check (20 bytes)
	if _, err := io.ReadFull(buf, batch.L1OriginCheck[:]); err != nil {
		return nil, fmt.Errorf("failed to read l1_origin_check: %w", err)
	}

	// Read block_count
	blockCount, err := readVarint(buf)
	if err != nil {
		return nil, fmt.Errorf("failed to read block_count: %w", err)
	}
	batch.BlockCount = blockCount

	// Read origin_bits
	originBitsLen, err := readVarint(buf)
	if err != nil {
		return nil, fmt.Errorf("failed to read origin_bits length: %w", err)
	}
	batch.OriginBits = make([]byte, originBitsLen)
	if _, err := io.ReadFull(buf, batch.OriginBits); err != nil {
		return nil, fmt.Errorf("failed to read origin_bits: %w", err)
	}

	// Read block_tx_counts
	batch.BlockTxCounts = make([]uint64, blockCount)
	for i := uint64(0); i < blockCount; i++ {
		count, err := readVarint(buf)
		if err != nil {
			return nil, fmt.Errorf("failed to read block_tx_count[%d]: %w", i, err)
		}
		batch.BlockTxCounts[i] = count
	}

	// Read transactions
	// TODO: Implement transaction decoding
	// SpanBatch uses custom transaction encoding
	// For now, read remaining data as raw transactions
	remainingData, err := io.ReadAll(buf)
	if err != nil {
		return nil, fmt.Errorf("failed to read transactions: %w", err)
	}

	// Parse transactions from remaining data
	// TODO: Proper transaction parsing
	_ = remainingData

	return batch, nil
}

// readVarint reads a varint-encoded uint64
// Uses a simple varint encoding similar to protobuf
func readVarint(r io.Reader) (uint64, error) {
	var result uint64
	var shift uint
	buf := make([]byte, 1)

	for {
		if _, err := io.ReadFull(r, buf); err != nil {
			return 0, err
		}

		b := buf[0]
		result |= uint64(b&0x7F) << shift

		if b&0x80 == 0 {
			break
		}

		shift += 7
		if shift >= 64 {
			return 0, fmt.Errorf("varint overflow")
		}
	}

	return result, nil
}
