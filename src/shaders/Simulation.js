import vertex from "./RawOrtho.glslv";
import fragment from "./Simulation.glslf";

let Simulation = {
  uniforms: {
    source: { type: "t", value: null },
    forcesT: { type: "t", value: null },
    seed: { type: "t", value: null },
    seed2: { type: "t", value: null },
    initT: { type: "t", value: null },
    time: { type: "f", value: null },
    t: { type: "f", value: null },
    f: { type: "f", value: null },
    persistence: { type: "f", value: null },
    speed: { type: "f", value: null },
    spread: { type: "f", value: null },
    decay: { type: "f", value: null },
    init: { type: "f", value: 1 },
    drag: { type: "f", value: 0 },
    dragT: { type: "f", value: 0 },
    translationM1: { type: "v3", value: null },
    translationM2: { type: "v3", value: null },
    rotationM1: { type: "m3", value: null },
    rotationM2: { type: "m3", value: null },
    scaleM1: { type: "f", value: null },
    scaleM2: { type: "f", value: null },
    animationType: { type: "f", value: 0 },
    attractor: { type: "v3", value: null },
    pAttractor: { type: "v3", value: null },
    zeroP: {
      type: "v3",
      value: null,
    },
    oneP: {
      type: "v3",
      value: null,
    },
  },
  vertexShader: vertex,
  fragmentShader: fragment,
};

export default Simulation;
