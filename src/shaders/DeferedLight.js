import fragment from "./DeferedLight.glslf";
import vertex from "./Ortho.glslv";
import { Matrix4 } from "three"

let DeferedLight = {
  vertexShader: vertex,
  fragmentShader: fragment,
  uniforms: {
    environmentMap: { type: "t", value: null },
    u_depth: { type: "t", value: null },
    u_normal: { type: "t", value: null },
    u_color: { type: "t", value: null },
    u_ssao_mask: { type: "t", value: null },
    u_shadow_depth: { type: "t", value: null },

    projectionMatrixInverse: { type: "m4", value: new Matrix4() },
    viewMatrixInverse: { type: "m4", value: new Matrix4() },

    positionCamera: { type: "v3", value: null },
    lightPosition: { type: "v3", value: null },

    lightIntensity: { type: "f", value: 0 },
    lightRadius: { type: "f", value: 0 },
    attenuationRadius: { type: "f", value: 0 },

    roughness: { type: "f", value: 0 },
    metallic: { type: "f", value: 0 },
    u_spec: { type: "f", value: 0 },
    ambientColor: { type: "v3", value: null },
    ambientIntensity: { type: "f", value: 0 },
    envMapIntensity: { type: "f", value: 0 },
    toneMappingExposure: { type: "f", value: 0 },
    shadowDarkness: { type: "f", value: 0 },
    globalScale: { type: "f", value: 0 },

    shadowProjectionMatrix: { type: "m4", value: new Matrix4() },
    shadowViewMatrix: { type: "m4", value: new Matrix4() },
    shadowProjectionMatrixInverse: { type: "m4", value: new Matrix4() },
    shadowViewMatrixInverse: { type: "m4", value: new Matrix4() },

    shadowRadius: { type: "f", value: 0 },
    shadowBias: { type: "f", value: 0 },
    numOfPoissonDisks: { type: "f", value: 0 },
    useShadows: { type: "f", value: 0 }
  },
  defines: {
    LIGHTING: 1,
    POSTGREY: 0,
    ONECOLOR: 0
  }
};

export default DeferedLight;
