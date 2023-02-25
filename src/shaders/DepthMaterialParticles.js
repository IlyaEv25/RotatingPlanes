import fragment from "./White.glslf";
import vertex from "./DepthMaterialParticles.glslv";

let DepthMaterialParticles = {
  vertexShader: vertex,
  fragmentShader: fragment,
  uniforms: {
    modelViewMatrix: { type: "m4", value: null },
    shadowViewMatrix: { type: "m4", value: null },
    shadowProjectionMatrix: { type: "m4", value: null },
    center: {
      type: "v3",
      value: null,
    },
    currentPositions: { type: "t", value: null },
    previousPositions: { type: "t", value: null },
    scale: { type: "v3", value: null },
    squashiness: { type: "f", value: null },
    globalRotation: { type: "m3", value: null },
    u_counter: { type: "f", value: null },
    resolution: { type: "v2", value: null }
  },
};

export default DepthMaterialParticles;
