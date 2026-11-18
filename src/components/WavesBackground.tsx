'use client';

import { ShaderBackground } from './waves-shader';

export default function WavesBackground() {
  return (
    <div className="waves-shader-background" aria-hidden="true">
      <ShaderBackground className="waves-shader-canvas" />
    </div>
  );
}
