'use client';

import { ShaderBackground } from './aurora-shader-green';

export default function AuroraBackground() {
  return (
    <div className="aurora-shader-background" aria-hidden="true">
      <ShaderBackground className="aurora-shader-canvas" />
    </div>
  );
}
