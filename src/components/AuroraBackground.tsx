'use client';

/**
 * Adapted from Aurora by Kevin Girelli on 21st.dev.
 * A low-intensity, brand-matched version of its three drifting radial lights.
 * https://21st.dev/@kevingirelli/components/aurora
 */
export default function AuroraBackground() {
  return (
    <div className="aurora-shader-background" aria-hidden="true">
      <span className="aurora-shader-background__light aurora-shader-background__light--teal" />
      <span className="aurora-shader-background__light aurora-shader-background__light--green" />
      <span className="aurora-shader-background__light aurora-shader-background__light--mist" />
    </div>
  );
}
