import fragment from "./GBuffer.glslf";
import vertex from "./GBuffer.glslv";
import { GLSL3 } from "three";

let GBuffer = {
  defines: {
    LIGHTING: 1,
    ONECOLOR: 0,
    POSTGREY: 1,
  },

  uniforms: {
  

    modelMatrix: { type: "m4", value: null },
    modelViewMatrix: { type: "m4", value: null },
    projectionMatrix: { type: "m4", value: null },
    previousModelMatrix: { type: "m4", value: null },
    previousViewMatrix: { type: 'm4', value: null },
  
    color: { type: "v3", value: null },
    roughness: { type: "f", value: null },
    metalness: { type: "f", value: null}, 
    emissiveColor: { type: "v3", value: null },
    emissiveStrength: { type: "f", value: null },
  


    resolution:  { type: "v2", value: null },
    u_counter: { type: "f", value: null},
  },
  fragmentShader: fragment,
  vertexShader: vertex,
};

export default GBuffer;