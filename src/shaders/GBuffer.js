import fragment from "./GBufferParticles.glslf";
import vertex from "./GBufferParticles.glslv";
import { GLSL3 } from "three";

let GBufferParticles = {
  defines: {
    LIGHTING: 1,
    ONECOLOR: 0,
    POSTGREY: 1,
  },

  uniforms: {
    effectColor: { type: "v3", value: null },
    baseColor: { type: "v3", value: null },
    baseColor2: { type: "v3", value: null },
    baseColor3: { type: "v3", value: null },
    baseColor4: { type: "v3", value: null },
    baseHue: { type: "f", value: null },
    baseSaturation: { type: "f", value: null },
    baseValue: { type: "f", value: null },
    baseHue2: { type: "f", value: null },
    baseSaturation2: { type: "f", value: null },
    baseValue2: { type: "f", value: null },
    baseHue3: { type: "f", value: null },
    baseSaturation3: { type: "f", value: null },
    baseValue3: { type: "f", value: null },
    baseHue4: { type: "f", value: null },
    baseSaturation4: { type: "f", value: null },
    baseValue4: { type: "f", value: null },

    effectHue: { type: "f", value: null },
    effectSaturation: { type: "f", value: null },
    effectValue: { type: "f", value: null },

    modelMatrix: { type: "m4", value: null },
    modelViewMatrix: { type: "m4", value: null },
    projectionMatrix: { type: "m4", value: null },

    currentPositions: { type: "t", value: null},
    previousPositions: { type: "t", value: null},
    previousPreviousPositions: { type: "t", value: null},
    noForcesPositions: { type: "t", value: null},

    scale: { type: "v3", value: null },
    squashiness: { type: "f", value: null },
    globalScale: { type: "f", value: null },
    globalRotation: { type: "m3", value: null },
    center: { type: "v3", value: null },
    resolution:  { type: "v2", value: null },
    u_counter: { type: "f", value: null},
    previousViewMatrix: { type: 'm4', value: null }
  },
  fragmentShader: fragment,
  vertexShader: vertex,
};

export default GBufferParticles;