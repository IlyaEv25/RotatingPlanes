import fragment from "./DeferedLight.glslf";
import vertex from "./Ortho.glslv";
import { Matrix4 } from "three"

let DeferedLight = {
  vertexShader: vertex,
  fragmentShader: fragment,
  uniforms: {
    environmentMap: { type: "t", value: null },
    u_depth: { type: "t", value: null },
    u_normal_metalness: { type: "t", value: null },
    u_albedo_roughness: { type: "t", value: null },
    u_emission: { type: "t", value: null },
    u_ssao_mask: { type: "t", value: null },
    u_shadow_depth: { value: [] },

    projectionMatrixInverse: { type: "m4", value: new Matrix4() },
    viewMatrixInverse: { type: "m4", value: new Matrix4() },

    positionCamera: { type: "v3", value: null },
    lights: { value: [] },
    

    envMapIntensity: { type: "f", value: 0 },
    shadowDarkness: { type: "f", value: 0 },

    shadowProjectionMatrix: { type: "m4", value: new Matrix4() },
    shadowViewMatrix: { type: "m4", value: new Matrix4() },
    shadowProjectionMatrixInverse: { type: "m4", value: new Matrix4() },
    shadowViewMatrixInverse: { type: "m4", value: new Matrix4() },

    shadowRadius: { type: "f", value: 0 },
    shadowBias: { type: "f", value: 0 },
    numOfPoissonDisks: { type: "f", value: 0 },
  },
  defines: {
    NUM_LIGHTS: 4
  }
};



export default DeferedLight;
