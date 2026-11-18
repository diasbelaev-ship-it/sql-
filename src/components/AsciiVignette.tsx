'use client';

import { useEffect, useRef } from 'react';

const glyphs = ['·', ':', '∙', '+', '×', '*', '░', '▒', '▓'];
const colors = ['27,110,102', '42,143,132', '115,164,147', '190,164,105'];

function noise(column: number, row: number) {
  const value = Math.sin(column * 127.1 + row * 311.7) * 43_758.5453;
  return value - Math.floor(value);
}

export default function AsciiVignette() {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    const context = canvas?.getContext('2d', { alpha: true });
    if (!canvas || !context) return;

    let width = 0;
    let height = 0;
    let frame = 0;
    let lastDraw = 0;
    let running = false;
    const motionPreference = window.matchMedia('(prefers-reduced-motion: reduce)');

    const draw = (time: number) => {
      if (!width || !height) return;

      context.clearRect(0, 0, width, height);
      const seconds = time / 1000;
      const centerX = width * (0.5 + Math.sin(seconds * 0.105) * 0.15);
      const centerY = height * (0.43 + Math.sin(seconds * 0.077 + 1.4) * 0.1);
      const radiusX = Math.max(width * 0.34, 220);
      const radiusY = Math.max(height * 0.54, 300);

      const glow = context.createRadialGradient(centerX, centerY, 0, centerX, centerY, radiusX);
      glow.addColorStop(0, 'rgba(89, 166, 143, 0.14)');
      glow.addColorStop(0.45, 'rgba(111, 180, 155, 0.055)');
      glow.addColorStop(1, 'rgba(111, 180, 155, 0)');
      context.fillStyle = glow;
      context.fillRect(0, 0, width, height);

      const cell = width < 700 ? 15 : 17;
      context.font = Math.max(9, Math.round(cell * 0.76)) + 'px ui-monospace, SFMono-Regular, Consolas, monospace';
      context.textAlign = 'center';
      context.textBaseline = 'middle';

      const columns = Math.ceil(width / cell);
      const rows = Math.ceil(height / cell);
      for (let row = 0; row < rows; row += 1) {
        const y = row * cell + cell / 2;
        const vertical = (y - centerY) / radiusY;
        const edgeY = Math.min(y / height, 1 - y / height);
        for (let column = 0; column < columns; column += 1) {
          const x = column * cell + cell / 2;
          const horizontal = (x - centerX) / radiusX;
          const distance = horizontal * horizontal + vertical * vertical;
          const bloom = Math.exp(-distance * 2.15);
          const edgeX = Math.min(x / width, 1 - x / width);
          const vignette = Math.min(1, Math.max(0.22, Math.min(edgeX, edgeY) / 0.19));
          const random = noise(column, row);
          if (random > 0.3 + bloom * 0.68) continue;

          const glyphIndex = Math.min(glyphs.length - 1, Math.floor(random * 3 + bloom * 6.5));
          const colorIndex = Math.min(colors.length - 1, Math.floor(random * 1.8 + bloom * 2.4));
          context.fillStyle = 'rgb(' + colors[colorIndex] + ')';
          context.globalAlpha = (0.035 + bloom * 0.2) * vignette;
          context.fillText(glyphs[glyphIndex], x, y);
        }
      }
      context.globalAlpha = 1;
    };

    const resize = () => {
      width = window.innerWidth;
      height = window.innerHeight;
      const pixelRatio = Math.min(window.devicePixelRatio || 1, 1.5);
      canvas.width = Math.round(width * pixelRatio);
      canvas.height = Math.round(height * pixelRatio);
      context.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0);
      draw(performance.now());
    };

    const stop = () => {
      running = false;
      window.cancelAnimationFrame(frame);
    };

    const tick = (time: number) => {
      if (!running) return;
      frame = window.requestAnimationFrame(tick);
      if (time - lastDraw < 110) return;
      lastDraw = time;
      draw(time);
    };

    const updateMotion = () => {
      stop();
      if (motionPreference.matches) {
        draw(performance.now());
        return;
      }
      running = true;
      lastDraw = 0;
      frame = window.requestAnimationFrame(tick);
    };

    resize();
    updateMotion();
    window.addEventListener('resize', resize, { passive: true });
    motionPreference.addEventListener('change', updateMotion);

    return () => {
      stop();
      window.removeEventListener('resize', resize);
      motionPreference.removeEventListener('change', updateMotion);
    };
  }, []);

  return <canvas ref={canvasRef} className="ascii-vignette" aria-hidden="true" />;
}
