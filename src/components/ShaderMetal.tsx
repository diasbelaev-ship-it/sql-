'use client';

import { useEffect, useRef } from 'react';
import { createShaderMetal } from './shader-metal-vanilla';

export default function ShaderMetal() {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const shader = createShaderMetal(canvas, {
      metal: 'chrome',
      color: '#B8BEC7',
      ribbons: 3,
      speed: 0.3,
      iridescence: 0.12,
      interactive: true,
      theme: 'light',
    });

    return () => shader?.destroy();
  }, []);

  return (
    <div className="shader-metal-background" aria-hidden="true">
      <canvas ref={canvasRef} />
    </div>
  );
}
