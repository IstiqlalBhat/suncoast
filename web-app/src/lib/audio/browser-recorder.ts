import { downsampleBuffer, floatTo16BitPcm, mergeUint8Arrays } from "@/lib/audio/pcm";

type RecorderOptions = {
  onChunk?: (chunk: Uint8Array) => void;
  onLevel?: (level: number) => void;
};

declare global {
  interface Window {
    webkitAudioContext?: typeof AudioContext;
  }
}

export class BrowserPcmRecorder {
  private readonly targetSampleRate = 16000;
  private readonly bufferedChunks: Uint8Array[] = [];
  private readonly options: RecorderOptions;
  private stream?: MediaStream;
  private context?: AudioContext;
  private source?: MediaStreamAudioSourceNode;
  private processor?: ScriptProcessorNode;
  private silenceGain?: GainNode;

  constructor(options: RecorderOptions = {}) {
    this.options = options;
  }

  async start() {
    const stream = await navigator.mediaDevices.getUserMedia({
      audio: {
        channelCount: 1,
        echoCancellation: true,
        noiseSuppression: true,
      },
    });

    const AudioContextCtor = window.AudioContext ?? window.webkitAudioContext;
    if (!AudioContextCtor) {
      throw new Error("AudioContext is not supported in this browser.");
    }

    const context = new AudioContextCtor();
    const source = context.createMediaStreamSource(stream);
    const processor = context.createScriptProcessor(4096, 1, 1);
    const silenceGain = context.createGain();
    silenceGain.gain.value = 0;

    processor.onaudioprocess = (event) => {
      const input = event.inputBuffer.getChannelData(0);
      const downsampled = downsampleBuffer(
        input,
        context.sampleRate,
        this.targetSampleRate,
      );
      const pcm = floatTo16BitPcm(downsampled);
      this.bufferedChunks.push(pcm);
      this.options.onChunk?.(pcm);

      const level =
        input.reduce((sum, sample) => sum + Math.abs(sample), 0) / input.length;
      this.options.onLevel?.(level);
    };

    source.connect(processor);
    processor.connect(silenceGain);
    silenceGain.connect(context.destination);

    this.stream = stream;
    this.context = context;
    this.source = source;
    this.processor = processor;
    this.silenceGain = silenceGain;
  }

  consume() {
    const merged = mergeUint8Arrays(this.bufferedChunks);
    this.bufferedChunks.length = 0;
    return merged;
  }

  async stop() {
    this.processor?.disconnect();
    this.source?.disconnect();
    this.silenceGain?.disconnect();
    this.stream?.getTracks().forEach((track) => track.stop());

    if (this.context?.state !== "closed") {
      await this.context?.close();
    }

    this.processor = undefined;
    this.source = undefined;
    this.silenceGain = undefined;
    this.stream = undefined;
    this.context = undefined;
  }
}
