import vertex from "./Ortho.glslv";
import fragment from "./BloomUpsample.glslf";

let BloomUpsample = (final) => {
  return {
    vertexShader: vertex,
    fragmentShader: fragment,
    defines: {
      FINAL: final,
    },
    uniforms: {
      u_previous: { type: "t", value: null },
      u_background: { type: "t", value: null },
      filterRadius: { type: "f", value: null },
      bloomStrength: { type: "f", value: null },
    },
  };
};

export default BloomUpsample;
