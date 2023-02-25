import vertex from "./GBufferParticles.glslv"; //wrong actually...
import fragment from "./ForwardMaterial.glslf";

import * as THREE from "three";

let ForwardMaterial = {
  defines: {
    LIGHTING: 0,
    ONECOLOR: 0,
    POSTGREY: 1,
  },

  uniforms: {
    scale: { type: "v3", value: null },
    squashiness: { type: "f", value: null },
    noForces: { type: "t", value: null },
    curPos: { type: "t", value: null },
    center: {
      type: "v3",
      value: null,
    },
    prevPos: { type: "t", value: null },
    depthTexture: { type: "t", value: null },
    shadowRadius: { type: "f", value: null },
    shadowBias: { type: "f", value: null },
    numOfPoissonDisks: { type: "f", value: null },
    useShadows: { type: "f", value: null },
    toneMappingExposure: { type: "f", value: null },
    t: { type: "f", value: null },
    lightPosition: { type: "v3", value: null },
    shadowMVP: { type: "m4", value: null },
    shadowV: { type: "m4", value: null },
    shadowP: { type: "m4", value: null },
    shadow: { float: "t", value: null },
    time: { type: "f", value: null },
    effectColor: { type: "v3", value: null },
    baseColor: { type: "v3", value: null },
    baseColor2: { type: "v3", value: null },
    baseColor3: { type: "v3", value: null },
    baseColor4: { type: "v3", value: null },
    metallic: { type: "f", value: null },
    ambientColor: {
      type: "v3",
      value: null,
    },
    ambientIntensity: { type: "f", value: null },

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
    u_spec: { type: "f", value: null },

    lightIntensity: { type: "f", value: null },
    lightRadius: { type: "f", value: null },
    attenuationRadius: { type: "f", value: null },
    cameraPos: { type: "v3", value: null },
    shadowDarkness: { type: "f", value: null },
    globalScale: { type: "f", value: null },
    globalRotation: { type: "m3", value: null },

    ...THREE.ShaderLib.standard.uniforms,
  },
  vertexShader: vertex,
  fragmentShader: fragment,
  side: THREE.FrontSide,
};
