import { describe, expect, it } from "vitest";
import {
  downsampleBuffer,
  floatTo16BitPcm,
  mergeUint8Arrays,
} from "@/lib/audio/pcm";

describe("audio pcm helpers", () => {
  it("merges byte chunks in order", () => {
    const merged = mergeUint8Arrays([
      Uint8Array.from([1, 2]),
      Uint8Array.from([3, 4]),
    ]);

    expect(Array.from(merged)).toEqual([1, 2, 3, 4]);
  });

  it("downsamples a float buffer to the target sample rate", () => {
    const input = new Float32Array([0, 0.5, 1, 0.5]);
    const output = downsampleBuffer(input, 32000, 16000);

    expect(output.length).toBe(2);
    expect(output[0]).toBeCloseTo(0.25);
    expect(output[1]).toBeCloseTo(0.75);
  });

  it("encodes float audio data into 16-bit PCM bytes", () => {
    const pcm = floatTo16BitPcm(new Float32Array([0, 1, -1]));

    expect(pcm.length).toBe(6);
    expect(Array.from(pcm.slice(0, 2))).toEqual([0, 0]);
  });
});
