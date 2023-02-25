import vertex from "./SkyMaterial.glslv";
import fragment from "./SkyMaterial.glslf";
import * as THREE from "three";

let SkyMaterial = {
  fragmentShader: fragment,
  vertexShader: vertex,
  uniforms: {
    cameraPosition: { type: "v3", value: null },
    // u_counter: { type: "f", value: null },
    // resolution: { type: "v2", value: null },
    ...THREE.ShaderLib.background.uniforms,
    ...THREE.ShaderLib.standard.uniforms,
  },
  depthWrite: false,
  side: THREE.BackSide,
};

export default SkyMaterial;
