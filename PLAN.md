# Black Hole Visualization Implementation Plan

## Overall Strategy

**Black hole visualizations** typically involve:
1. **Ray tracing** through curved spacetime (the core physics)
2. **Gravitational lensing** (light bending around the black hole)
3. **Accretion disk** rendering (glowing matter spiraling in)
4. **Event horizon** and photon sphere visualization

## Technical Approach

### 1. Physics Foundation
You'll need to solve the **geodesic equations** for light rays near a black hole. For a Schwarzschild (non-rotating) black hole:
- Use the Schwarzschild metric
- Solve null geodesics (light paths) numerically
- For rotating black holes (more realistic), use the Kerr metric

### 2. Implementation Architecture

**Fragment Shader Approach** (Recommended for real-time):
- Each pixel shoots a ray from the camera
- Numerically integrate the geodesic equation in the fragment shader
- Sample background texture/skybox along the bent light path
- Render accretion disk with doppler shifting and gravitational redshift

**Compute Shader + Texture** (Alternative):
- Pre-compute light ray paths
- Store in lookup textures
- Fragment shader samples these for rendering

### 3. Step-by-Step Implementation Plan

#### Phase 1: Basic Ray Marching Setup
- Set up a full-screen quad with fragment shader
- Implement basic ray marching (distance from camera)
- Add camera controls (orbit around black hole)

#### Phase 2: Schwarzschild Metric Integration
- Implement RK4 or similar integrator in GLSL
- Solve geodesic equations for each ray
- Start with simple 2D case, then extend to 3D

#### Phase 3: Environment Mapping
- Add a skybox/environment texture
- Sample along curved ray paths
- Implement gravitational lensing effect

#### Phase 4: Accretion Disk
- Add procedural or textured disk geometry
- Implement doppler shifting (blue/red shift)
- Add temperature-based color (black body radiation)
- Implement gravitational time dilation effects

#### Phase 5: Advanced Effects
- Photon sphere (unstable orbit at 1.5× Schwarzschild radius)
- Einstein rings
- Multiple image formation
- Frame dragging (for Kerr black holes)

## Code Structure Recommendation

```
src/
├── main.zig              # Window, OpenGL setup
├── camera.zig            # Camera controls
├── renderer.zig          # Rendering pipeline
└── shaders/
    ├── blackhole.vert    # Simple passthrough
    ├── blackhole.frag    # Main ray tracing logic
    ├── common.glsl       # Shared constants/functions
    └── physics.glsl      # Geodesic integration
```

## Key Differential Equations

For a **Schwarzschild black hole**, the null geodesics in the equatorial plane:

```glsl
// Simplified geodesic equations (equatorial plane)
// r = radius, phi = angle, b = impact parameter
float dr_dlambda = sqrt(E*E - (1.0 - rs/r) * (1.0 + b*b/(r*r)));
float dphi_dlambda = b / (r * r);
```

Where:
- `rs` = Schwarzschild radius (2GM/c²)
- `E` = conserved energy
- `b` = impact parameter (angular momentum)

## Resources to Study

1. **Papers**: "Visualizing Interstellar's Wormhole" (Kip Thorne et al.)
2. **Shadertoy examples**: Search for "black hole" - many great implementations
3. **Riccardo Antonelli's work** on real-time black hole rendering
4. **"Black Hole Flight Simulator"** by Andrew Hamilton

## Starting Simple

Recommended starting point:
1. A **2D gravitational lensing demo** first (simpler math)
2. Just background distortion without accretion disk
3. Then gradually add complexity

## Current Status

- [x] OpenGL + GLFW + Zig boilerplate
- [x] Basic shader loading from files
- [x] Rectangle rendering (fullscreen quad ready)
- [ ] Phase 1: Basic ray marching setup
- [ ] Phase 2: Schwarzschild metric integration
- [ ] Phase 3: Environment mapping
- [ ] Phase 4: Accretion disk
- [ ] Phase 5: Advanced effects
